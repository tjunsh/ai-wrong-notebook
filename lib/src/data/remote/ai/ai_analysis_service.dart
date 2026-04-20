import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';

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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
    ));
  }

  /// 分析题目 - 支持图片输入
  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath, // 可选：图片路径
  }) async {
    final config = await settingsRepository.getAiProviderConfig();

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      return _fakeResult();
    }

    final dio = _createClient(config);
    final systemPrompt = await _loadSystemPrompt();

    try {
      // 如果有图片，尝试使用 vision 模型
      if (imagePath != null && File(imagePath).existsSync()) {
        return await _analyzeWithImage(dio, config, correctedText, subjectName, imagePath, systemPrompt);
      }

      // 没有图片，使用纯文本分析
      return await _analyzeWithText(dio, config, correctedText, subjectName, systemPrompt);
    } on DioException catch (e) {
      // 如果图片分析失败，尝试纯文本
      if (imagePath != null) {
        try {
          return await _analyzeWithText(dio, config, correctedText, subjectName, systemPrompt);
        } catch (_) {}
      }
      throw AiAnalysisException('AI 服务请求失败: ${e.message}');
    } catch (e) {
      throw AiAnalysisException('AI 解析失败: $e');
    }
  }

  /// 使用图片进行分析（发送图片给 AI）
  Future<AnalysisResult> _analyzeWithImage(
    Dio dio,
    AiProviderConfig config,
    String correctedText,
    String subjectName,
    String imagePath,
    String systemPrompt,
  ) async {
    // 读取图片并转为 base64
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    // 根据模型类型选择不同的请求格式
    final model = config.model.toLowerCase();

    if (model.contains('gpt') || model.contains('4o') || model.contains('4-turbo')) {
      return await _analyzeWithOpenAI(dio, config, base64Image, correctedText, subjectName, systemPrompt);
    } else if (model.contains('gemini')) {
      return await _analyzeWithGemini(dio, config, base64Image, correctedText, subjectName, systemPrompt);
    } else {
      // 默认使用 OpenAI 格式
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

  static const _defaultSystemPrompt = '''你是一个专业的错题分析助手。你需要：
1. 识别图片中的题目文本（或使用提供的文本）
2. 分析题目，给出正确答案、解题步骤、知识点、错因分析、学习建议
3. 生成举一反三的练习题

返回格式必须严格如下（不要包含 markdown 代码块标记）：
{
  "finalAnswer": "正确答案",
  "steps": ["解题步骤1", "解题步骤2"],
  "knowledgePoints": ["知识点1", "知识点2"],
  "mistakeReason": "错误原因分析",
  "studyAdvice": "学习建议",
  "generatedExercises": [
    {"id": "e1", "difficulty": "简单", "question": "题目", "answer": "答案", "explanation": "解析"}
  ]
}''';

  Future<String> _loadSystemPrompt() async {
    final custom = await settingsRepository.getString('system_prompt');
    return custom?.isNotEmpty == true ? custom! : _defaultSystemPrompt;
  }

  String _buildPrompt(String correctedText, String subjectName) {
    if (correctedText.isNotEmpty) {
      return '请分析以下$subjectName错题：\n\n$correctedText';
    }
    return '请识别图片中的题目并分析。';
  }

  AnalysisResult _parseResponse(String content) {
    String jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final exercises = (map['generatedExercises'] as List?)?.map((e) {
        final em = e as Map<String, dynamic>;
        return GeneratedExercise(
          id: em['id'] as String? ?? '',
          difficulty: em['difficulty'] as String? ?? '',
          question: em['question'] as String? ?? '',
          answer: em['answer'] as String? ?? '',
          explanation: em['explanation'] as String? ?? '',
        );
      }).toList() ?? <GeneratedExercise>[];

      return AnalysisResult(
        finalAnswer: map['finalAnswer'] as String? ?? '',
        steps: List<String>.from(map['steps'] as List? ?? <String>[]),
        knowledgePoints: List<String>.from(map['knowledgePoints'] as List? ?? <String>[]),
        mistakeReason: map['mistakeReason'] as String? ?? '',
        studyAdvice: map['studyAdvice'] as String? ?? '',
        generatedExercises: exercises,
      );
    } catch (e) {
      throw AiAnalysisException('解析 AI 响应失败: $e');
    }
  }

  AnalysisResult _fakeResult() {
    return const AnalysisResult(
      finalAnswer: 'x = 3',
      steps: <String>['移项得到 x = 5 - 2', '计算得到 x = 3'],
      knowledgePoints: <String>['一元一次方程', '移项'],
      mistakeReason: '对移项规则不熟悉',
      studyAdvice: '先用简单方程练熟移项，再做文字题。',
      generatedExercises: <GeneratedExercise>[
        GeneratedExercise(id: 'e1', difficulty: '简单', question: 'x+1=4', answer: 'x=3', explanation: '两边同时减 1'),
        GeneratedExercise(id: 'e2', difficulty: '同级', question: '2x=8', answer: 'x=4', explanation: '两边同时除以 2'),
        GeneratedExercise(id: 'e3', difficulty: '提高', question: '3x+2=11', answer: 'x=3', explanation: '先减 2 再除以 3'),
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