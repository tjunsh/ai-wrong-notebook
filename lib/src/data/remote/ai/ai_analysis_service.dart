import 'dart:convert';
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
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
  }) async {
    final config = await settingsRepository.getAiProviderConfig();

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      return _fakeResult();
    }

    final dio = _createClient(config);
    final prompt = _buildPrompt(correctedText, subjectName);
    final systemPrompt = await _loadSystemPrompt();

    try {
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
    } on DioException catch (e) {
      throw AiAnalysisException('AI 服务请求失败: ${e.message}');
    } catch (e) {
      throw AiAnalysisException('AI 解析失败: $e');
    }
  }

  static const _defaultSystemPrompt = '''你是一个专业的错题分析助手。请根据学生的错题内容进行分析，并以 JSON 格式返回结果。
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
    return '请分析以下$subjectName错题：\n\n$correctedText';
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
