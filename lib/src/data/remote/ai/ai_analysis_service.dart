import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class AiAnalysisService {
  AiAnalysisService({required this.settingsRepository});

  final SettingsRepository settingsRepository;

  factory AiAnalysisService.fake() =>
      AiAnalysisService(settingsRepository: InMemorySettingsRepository());

  Dio _createClient(AiProviderConfig config) {
    return Dio(BaseOptions(
      baseUrl: config.baseUrl.endsWith('/')
          ? config.baseUrl.substring(0, config.baseUrl.length - 1)
          : config.baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json',
        if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 180),
    ));
  }

  /// 测试 API 连接
  Future<void> testConnection(AiProviderConfig config) async {
    debugPrint('[AiAnalysisService] testConnection called');
    debugPrint('[AiAnalysisService] baseUrl: ${config.baseUrl}');
    debugPrint('[AiAnalysisService] model: ${config.model}');

    final dio = _createClient(config);
    final baseUrl = config.baseUrl.toLowerCase();

    try {
      String responseText;

      // OpenRouter 使用 OpenAI 兼容格式
      if (baseUrl.contains('openrouter')) {
        debugPrint('[AiAnalysisService] Using OpenAI format for OpenRouter');
        final response = await dio.post('/chat/completions', data: <String, dynamic>{
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'Hi, reply with "OK" if you receive this.'},
          ],
          'max_tokens': 10,
        });
        responseText = response.data['choices'][0]['message']['content'] as String;
      } else if (config.model.toLowerCase().contains('gemini')) {
        // Gemini 原生格式
        debugPrint('[AiAnalysisService] Using Gemini format');
        final response = await dio.post(
          '/v1beta/models/${config.model}:generateContent',
          data: <String, dynamic>{
            'contents': [
              {'parts': [{'text': 'Hi, reply with "OK" if you receive this.'}]},
            ],
            'generationConfig': {'maxOutputTokens': 10},
          },
        );
        responseText = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        // 默认 OpenAI 格式
        debugPrint('[AiAnalysisService] Using default OpenAI format');
        final response = await dio.post('/chat/completions', data: <String, dynamic>{
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'Hi, reply with "OK" if you receive this.'},
          ],
          'max_tokens': 10,
        });
        responseText = response.data['choices'][0]['message']['content'] as String;
      }

      debugPrint('[AiAnalysisService] Response: $responseText');

      if (!responseText.toLowerCase().contains('ok')) {
        throw AiAnalysisException('API 返回异常: $responseText');
      }
    } on DioException catch (e) {
      debugPrint('[AiAnalysisService] testConnection DioException: type=${e.type}, message=${e.message}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      throw AiAnalysisException('测试失败: $e');
    }
  }

  /// 分析题目 - 支持图片输入
  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath, // 可选：图片路径
  }) async {
    debugPrint('[AiAnalysisService] analyzeQuestion called');
    debugPrint('[AiAnalysisService] - correctedText: ${correctedText.isNotEmpty ? "provided (${correctedText.length} chars)" : "empty"}');
    debugPrint('[AiAnalysisService] - subjectName: $subjectName');
    debugPrint('[AiAnalysisService] - imagePath: $imagePath');

    final config = await settingsRepository.getAiProviderConfig();

    debugPrint('[AiAnalysisService] config: ${config != null ? "loaded" : "null"}');
    if (config != null) {
      debugPrint('[AiAnalysisService] - baseUrl: ${config.baseUrl}');
      debugPrint('[AiAnalysisService] - model: ${config.model}');
      debugPrint('[AiAnalysisService] - apiKey length: ${config.apiKey.length}');
    }

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      debugPrint('[AiAnalysisService] No config - throwing error');
      throw AiAnalysisException('AI 未配置，请在设置中配置 API 地址、API Key 和模型');
    }

    final dio = _createClient(config);
    final systemPrompt = await _loadSystemPrompt();
    debugPrint('[AiAnalysisService] systemPrompt loaded, length: ${systemPrompt.length}');

    try {
      // 如果有图片，尝试使用 vision 模型
      if (imagePath != null && File(imagePath).existsSync()) {
        debugPrint('[AiAnalysisService] Using image analysis path');
        return await _analyzeWithImage(dio, config, correctedText, subjectName, imagePath, systemPrompt);
      }

      // 没有图片，使用纯文本分析
      debugPrint('[AiAnalysisService] Using text-only analysis path');
      return await _analyzeWithText(dio, config, correctedText, subjectName, systemPrompt);
    } on DioException catch (e) {
      debugPrint('[AiAnalysisService] DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}');
      // 如果图片分析失败，尝试纯文本
      if (imagePath != null) {
        try {
          return await _analyzeWithText(dio, config, correctedText, subjectName, systemPrompt);
        } catch (_) {}
      }
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      throw AiAnalysisException('AI 解析失败: $e');
    }
  }

  String _dioErrorMessage(DioException e) {
    final buffer = StringBuffer('AI 服务请求失败');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      buffer.write(': 请求超时，请检查网络后重试');
    } else if (e.type == DioExceptionType.connectionError) {
      buffer.write(': 网络连接失败，请检查网络');
    } else if (e.response != null) {
      final status = e.response!.statusCode;
      final body = e.response!.data;
      if (status != null) {
        buffer.write(' (HTTP $status)');
        if (body != null && body is Map && body['error'] != null) {
          final errMsg = body['error'];
          if (errMsg is Map) {
            buffer.write(': ${errMsg['message'] ?? errMsg}');
          } else {
            buffer.write(': $errMsg');
          }
        } else if (body is String && body.isNotEmpty) {
          buffer.write(': ${body.length > 100 ? '${body.substring(0, 100)}...' : body}');
        }
      } else if (e.message != null) {
        buffer.write(': ${e.message}');
      }
    } else if (e.message != null) {
      buffer.write(': ${e.message}');
    }
    return buffer.toString();
  }

  /// 测试 API 连接

  /// 使用图片进行分析（发送图片给 AI）
  Future<AnalysisResult> _analyzeWithImage(
    Dio dio,
    AiProviderConfig config,
    String correctedText,
    String subjectName,
    String imagePath,
    String systemPrompt,
  ) async {
    debugPrint('[AiAnalysisService] _analyzeWithImage started');
    debugPrint('[AiAnalysisService] imagePath: $imagePath');

    // 读取图片并转为 base64
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    debugPrint('[AiAnalysisService] Image encoded to base64, size: ${imageBytes.length} bytes');

    // 根据 baseUrl 判断 API 兼容格式
    final baseUrl = config.baseUrl.toLowerCase();
    debugPrint('[AiAnalysisService] baseUrl: ${config.baseUrl}');

    // OpenRouter 使用 OpenAI 兼容格式
    if (baseUrl.contains('openrouter')) {
      debugPrint('[AiAnalysisService] Using OpenAI format (OpenRouter compatible)');
      return await _analyzeWithOpenAI(dio, config, base64Image, correctedText, subjectName, systemPrompt);
    }

    // 根据模型类型选择格式
    final model = config.model.toLowerCase();

    if (model.contains('gpt') || model.contains('4o') || model.contains('4-turbo')) {
      debugPrint('[AiAnalysisService] Using OpenAI format');
      return await _analyzeWithOpenAI(dio, config, base64Image, correctedText, subjectName, systemPrompt);
    } else if (model.contains('gemini') && !baseUrl.contains('openrouter')) {
      debugPrint('[AiAnalysisService] Using Gemini format');
      return await _analyzeWithGemini(dio, config, base64Image, correctedText, subjectName, systemPrompt);
    } else {
      // 默认使用 OpenAI 格式
      debugPrint('[AiAnalysisService] Using default OpenAI format');
      return await _analyzeWithOpenAI(dio, config, base64Image, correctedText, subjectName, systemPrompt);
    }
  }

  /// OpenAI/GPT-4o 格式（支持 vision）
  Future<AnalysisResult> _analyzeWithOpenAI(
    Dio dio,
    AiProviderConfig config,
    String base64Image,
    String correctedText,
    String subjectName,
    String systemPrompt,
  ) async {
    final prompt = _buildPrompt(correctedText, subjectName);

    // 构造 vision 消息
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      },
    ];

    final response = await dio.post('/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
    });

    final content = response.data['choices'][0]['message']['content'] as String;
    return _parseResponse(content);
  }

  /// Gemini 格式
  Future<AnalysisResult> _analyzeWithGemini(
    Dio dio,
    AiProviderConfig config,
    String base64Image,
    String correctedText,
    String subjectName,
    String systemPrompt,
  ) async {
    // Gemini 使用不同的 API 格式
    final prompt = '''$systemPrompt

请分析以下$subjectName错题图片：

$correctedText

请以 JSON 格式返回分析结果。''';

    final response = await dio.post(
      '/v1beta/models/${config.model}:generateContent',
      data: <String, dynamic>{
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image}},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2000,
        },
      },
    );

    final text = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
    return _parseResponse(text);
  }

  /// 纯文本分析（无图片）
  Future<AnalysisResult> _analyzeWithText(
    Dio dio,
    AiProviderConfig config,
    String correctedText,
    String subjectName,
    String systemPrompt,
  ) async {
    final prompt = _buildPrompt(correctedText, subjectName);

    final response = await dio.post('/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 2000,
    });

    final content = response.data['choices'][0]['message']['content'] as String;
    return _parseResponse(content);
  }

  static const _defaultSystemPrompt = '''你是一个专业的错题分析助手，专门帮助学生分析和理解错题。

你的任务是：
1. 识别图片中的题目内容（包括文本、图表、公式等）
2. 根据题目内容判断所属科目（数学、语文、英语、物理、化学、生物、历史、地理、政治等）
3. 提供正确的解题思路和答案
4. 分析学生可能犯错误的原因
5. 提供学习建议和相关的知识点
6. 生成举一反三的练习题（选择题格式，带 A/B/C/D 选项）

重要规则：
- 科目判断：根据图片中的实际内容判断，比如有数学公式/计算=数学，有古诗词=语文，有英语单词=英语，有电路图=物理，有化学式=化学
- 如果图片中包含题目，请仔细识别并分析
- 如果无法从图片识别题目内容，请根据你看到的实际情况回答，不要虚构题目
- 答案必须准确、有条理
- 生成的练习题应该难度适中、与原题相关
- 练习题必须是选择题格式，包含 A/B/C/D 四个选项，其中一个是正确答案
- 答案字段填写正确选项的字母（如 "A"）
- aiTags 要求简短精炼（2-8个字），数量 2-4 个，如 ["压强", "力学", "公式"]
- knowledgePoints 可以详细描述，长度不限，如 ["压强公式p=f/s，压强与压力的关系", "受力面积相同时，压力越大压强越大"]

返回格式必须严格如下（不要包含 markdown 代码块标记，使用纯 JSON）：
{
  "subject": "自动判断的科目名称",
  "finalAnswer": "正确答案或解题要点",
  "steps": ["解题步骤1", "解题步骤2"],
  "aiTags": ["短标签1", "短标签2", "短标签3"],
  "knowledgePoints": ["知识点1详细描述", "知识点2详细描述"],
  "mistakeReason": "错误原因分析",
  "studyAdvice": "学习建议",
  "generatedExercises": [
    {"id": "e1", "difficulty": "简单", "question": "练习题目", "options": ["A. 选项1", "B. 选项2", "C. 选项3", "D. 选项4"], "answer": "A", "explanation": "解析"}
  ]
}''';

  Future<String> _loadSystemPrompt() async {
    final custom = await settingsRepository.getString('system_prompt');
    return custom?.isNotEmpty == true ? custom! : _defaultSystemPrompt;
  }

  String _buildPrompt(String correctedText, String subjectName) {
    final buffer = StringBuffer();
    buffer.writeln('请分析以下$subjectName科目的错题：');
    buffer.writeln();

    if (correctedText.isNotEmpty) {
      buffer.writeln('用户已识别的题目文本：');
      buffer.writeln(correctedText);
      buffer.writeln();
    }

    buffer.writeln('请仔细查看附带图片中的题目（如果有），结合上述文本进行准确分析。');
    buffer.writeln();
    buffer.writeln('请根据图片内容自动判断题目所属科目，并在返回的 JSON 中包含 "subject" 字段。');
    buffer.writeln();
    buffer.writeln('请以 JSON 格式返回完整的分析结果，包含 subject、finalAnswer、steps、knowledgePoints、mistakeReason、studyAdvice、generatedExercises 字段。');

    return buffer.toString();
  }

  AnalysisResult _parseResponse(String content) {
    debugPrint('[AiAnalysisService] Raw AI response: $content');

    String jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      debugPrint('[AiAnalysisService] Parsed JSON keys: ${map.keys.toList()}');

      final exercises = (map['generatedExercises'] as List?)?.map((e) {
        final em = e as Map<String, dynamic>;
        List<String>? options;
        if (em['options'] != null) {
          options = List<String>.from(em['options'] as List);
        }
        return GeneratedExercise(
          id: em['id'] as String? ?? '',
          difficulty: em['difficulty'] as String? ?? '',
          question: em['question'] as String? ?? '',
          answer: em['answer'] as String? ?? '',
          explanation: em['explanation'] as String? ?? '',
          options: options,
        );
      }).toList() ?? <GeneratedExercise>[];

      // 解析 subject 字段
      Subject? subject;
      final subjectStr = map['subject'] as String?;
      if (subjectStr != null && subjectStr.isNotEmpty) {
        debugPrint('[AiAnalysisService] AI returned subject: $subjectStr');
        subject = _parseSubject(subjectStr);
        debugPrint('[AiAnalysisService] Parsed subject: $subject');
      }

      return AnalysisResult(
        subject: subject,
        finalAnswer: map['finalAnswer'] as String? ?? '',
        steps: List<String>.from(map['steps'] as List? ?? <String>[]),
        aiTags: List<String>.from(map['aiTags'] as List? ?? <String>[]),
        knowledgePoints: List<String>.from(map['knowledgePoints'] as List? ?? <String>[]),
        mistakeReason: map['mistakeReason'] as String? ?? '',
        studyAdvice: map['studyAdvice'] as String? ?? '',
        generatedExercises: exercises,
      );
    } catch (e) {
      debugPrint('[AiAnalysisService] Parse error: $e');
      throw AiAnalysisException('解析 AI 响应失败: $e');
    }
  }

  static Subject? _parseSubject(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('物理') || lower == 'wuli' || lower == 'physics') return Subject.physics;
    if (lower.contains('语文') || lower == 'chinese') return Subject.chinese;
    if (lower.contains('英语') || lower.contains('english')) return Subject.english;
    if (lower.contains('化学') || lower == 'chemistry') return Subject.chemistry;
    if (lower.contains('生物') || lower == 'biology') return Subject.biology;
    if (lower.contains('历史') || lower == 'history') return Subject.history;
    if (lower.contains('地理') || lower == 'geography') return Subject.geography;
    if (lower.contains('政治') || lower == 'politics') return Subject.politics;
    if (lower.contains('科学') || lower == 'science') return Subject.science;
    if (lower.contains('数学') || lower == 'math') return Subject.math;
    return null;
  }

    /// AI 判断用户答案是否正确
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) async {
    debugPrint('[AiAnalysisService] judgeAnswer called');
    debugPrint('[AiAnalysisService] - question: $question');
    debugPrint('[AiAnalysisService] - userAnswer: $userAnswer');
    debugPrint('[AiAnalysisService] - correctAnswer: $correctAnswer');

    final config = await settingsRepository.getAiProviderConfig();

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      debugPrint('[AiAnalysisService] No config - using direct compare');
      return userAnswer == correctAnswer;
    }

    final dio = _createClient(config);
    final prompt = _buildJudgePrompt(question, userAnswer, correctAnswer, options);

    try {
      final response = await dio.post('/chat/completions', data: <String, dynamic>{
        'model': config.model,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'system', 'content': '你是一个判断答案是否正确的助手。请仔细分析题目和答案，给出判断结果。'},
          <String, String>{'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
        'max_tokens': 50,
      });

      final content = response.data['choices'][0]['message']['content'] as String;
      debugPrint('[AiAnalysisService] judgeAnswer response: $content');

      // 解析 AI 判断结果
      final lower = content.toLowerCase();
      if (lower.contains('正确') && !lower.contains('不正')) {
        return true;
      } else if (lower.contains('错误') || lower.contains('不对')) {
        return false;
      }

      // 默认回退到直接比较
      return userAnswer == correctAnswer;
    } catch (e) {
      debugPrint('[AiAnalysisService] judgeAnswer error: $e');
      // 回退到直接比较
      return userAnswer == correctAnswer;
    }
  }

  String _buildJudgePrompt(String question, String userAnswer, String correctAnswer, List<String>? options) {
    final buffer = StringBuffer();
    buffer.writeln('请判断以下答案是否正确：');
    buffer.writeln();
    buffer.writeln('题目：$question');
    if (options != null && options.isNotEmpty) {
      buffer.writeln('选项：');
      for (final option in options) {
        buffer.writeln(option);
      }
    }
    buffer.writeln();
    buffer.writeln('正确答案：$correctAnswer');
    buffer.writeln('用户答案：$userAnswer');
    buffer.writeln();
    buffer.writeln('请只回答"正确"或"错误"，不需要其他解释。');

    return buffer.toString();
  }

  AnalysisResult _fakeResult() {
    return const AnalysisResult(
      subject: Subject.math,
      finalAnswer: 'x = 3',
      steps: <String>['移项得到 x = 5 - 2', '计算得到 x = 3'],
      aiTags: <String>['一元一次方程', '移项', '方程'],
      knowledgePoints: <String>['一元一次方程的基本概念', '移项规则：将项从等式一边移到另一边时需要变号'],
      mistakeReason: '对移项规则不熟悉',
      studyAdvice: '先用简单方程练熟移项，再做文字题。',
      generatedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          difficulty: '简单',
          question: 'x+1=4，求 x 的值',
          options: ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
          answer: 'B',
          explanation: '移项得 x=4-1=3',
        ),
        GeneratedExercise(
          id: 'e2',
          difficulty: '同级',
          question: '2x=8，求 x 的值',
          options: ['A. 2', 'B. 3', 'C. 4', 'D. 6'],
          answer: 'C',
          explanation: '两边同时除以 2 得 x=4',
        ),
        GeneratedExercise(
          id: 'e3',
          difficulty: '提高',
          question: '3x+2=11，求 x 的值',
          options: ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
          answer: 'B',
          explanation: '先减 2 再除以 3: 3x=9, x=3',
        ),
      ],
    );
  }
}

class AiAnalysisException implements Exception {
  AiAnalysisException(this.message);
  final String message;
  @override
  String toString() => message;
}