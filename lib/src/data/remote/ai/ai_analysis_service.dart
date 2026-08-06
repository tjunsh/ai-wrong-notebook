import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/shared/utils/composite_worksheet_detector.dart';

enum _ExerciseDomain {
  generic,
  algebraEquation,
  equationSystem,
  functionEvaluation,
  proportionalRelation,
  organicChemistry,
  physicsCircuit,
  planeGeometryArea,
  planeGeometryAngle,
  planeGeometryLength,
  solidGeometryVolume,
}

enum _ExerciseObject {
  generic,
  linearEquation,
  quadraticEquation,
  equationSystem,
  functionExpression,
  proportionalRelation,
  organicSynthesis,
  circuit,
  circleFamily,
  square,
  triangle,
  rightTriangle,
  coneCylinder,
}

final _escapedNumberedQuestionBreak = RegExp(
  r'(?:(?:\\r)?\\n)+(?=\s*(?:第\s*)?\d+(?:[、．)]|\.(?!\d)))',
);

class _Point2 {
  const _Point2(this.x, this.y);

  final double x;
  final double y;
}

class _ExteriorAngleSpec {
  const _ExteriorAngleSpec({
    required this.extensionPoint,
    required this.vertex,
    required this.basePoint,
  });

  final String extensionPoint;
  final String vertex;
  final String basePoint;
}

class _FramedSemicircleSpec {
  const _FramedSemicircleSpec({
    required this.top,
    required this.bottom,
    required this.height,
  });

  final int top;
  final int bottom;
  final int height;

  int get horizontalDiff => (bottom - top).abs();
  int get diameterSquared => horizontalDiff * horizontalDiff + height * height;
}

enum _ExerciseMethod {
  linearSolve,
  squareRoot,
  elimination,
  functionSubstitution,
  ratioRelation,
  formulaSubstitution,
  halfArea,
  largeMinusSmall,
  splitAndCombine,
  shadedArea,
  angleSum,
  pythagorean,
  equalLengthRelation,
  perpendicularBisector,
  coordinateGeometry,
}

enum _ExerciseVariant {
  rightTriangleLength,
  circleArea,
  semicircleArea,
  compositeSemicircleArea,
  annulusOrShadedArea,
  squarePerpendicularBisectorLength,
  coneVolume,
  cylinderVolume,
}

enum _TopicProfileSource { sourceQuestion, exercise }

class _ExerciseTopicProfile {
  const _ExerciseTopicProfile({
    required this.domain,
    required this.object,
    required this.methods,
    required this.hasStrongSignal,
    this.variant,
  });

  final _ExerciseDomain domain;
  final _ExerciseObject object;
  final Set<_ExerciseMethod> methods;
  final bool hasStrongSignal;
  final _ExerciseVariant? variant;
}

class AiQuestionExtractionResult {
  const AiQuestionExtractionResult({
    required this.extractedQuestionText,
    required this.normalizedQuestionText,
    this.subject,
    this.splitResult,
  });

  factory AiQuestionExtractionResult.fromJson(Map<String, dynamic> json) {
    final subjectName = json['subject'] as String?;
    final splitResultJson = json['splitResult'];
    Subject? subject;
    for (final candidate in Subject.values) {
      if (candidate.name == subjectName || candidate.label == subjectName) {
        subject = candidate;
        break;
      }
    }
    return AiQuestionExtractionResult(
      extractedQuestionText: json['extractedQuestionText'] as String? ?? '',
      normalizedQuestionText: json['normalizedQuestionText'] as String? ?? '',
      subject: subject,
      splitResult: splitResultJson is Map
          ? QuestionSplitResult.fromJson(
              Map<String, dynamic>.from(splitResultJson),
            )
          : null,
    );
  }

  final String extractedQuestionText;
  final String normalizedQuestionText;
  final Subject? subject;
  final QuestionSplitResult? splitResult;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'extractedQuestionText': extractedQuestionText,
      'normalizedQuestionText': normalizedQuestionText,
      'subject': subject?.name,
      'splitResult': splitResult?.toJson(),
    };
  }
}

class AiFollowUpMessage {
  const AiFollowUpMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;
}

class AiAnalysisService {
  AiAnalysisService({required this.settingsRepository});

  final SettingsRepository settingsRepository;

  static const _maxRetries = 2; // 最多重试2次（总共3次请求）
  static const _baseDelayMs = 1000; // 基础延迟1秒
  static const _connectionProbeImageBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

  /// 带重试的 POST 请求（指数退避）
  Future<Response<T>> _retryPost<T>(
    Dio dio,
    String path, {
    required Map<String, dynamic> data,
    int attempt = 1,
    Set<int> retryStatusCodes = const <int>{},
  }) async {
    try {
      return await dio.post<T>(path, data: data);
    } on DioException catch (e) {
      final shouldRetry = _shouldRetryPost(
        e,
        retryStatusCodes: retryStatusCodes,
      );

      if (shouldRetry && attempt <= _maxRetries) {
        final delayMs = _baseDelayMs * attempt;
        debugPrint(
            '[AiAnalysisService] 请求失败，${delayMs}ms 后重试 (第 $attempt 次)...');
        await Future.delayed(Duration(milliseconds: delayMs));
        return _retryPost(
          dio,
          path,
          data: data,
          attempt: attempt + 1,
          retryStatusCodes: retryStatusCodes,
        );
      }
      rethrow;
    }
  }

  factory AiAnalysisService.fake() => _FakeAiAnalysisService();

  /// 从 Dio response 中安全提取 OpenAI 格式的 content 字段。
  /// 代理服务偶尔返回非 application/json content-type，导致 response.data 为原始 String。
  String _extractContentFromResponse(Response response) {
    dynamic data = response.data;
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.startsWith('data:')) {
        return _extractContentFromSse(trimmed);
      }
      data = jsonDecode(trimmed);
    }
    return (data as Map<String, dynamic>)['choices'][0]['message']['content']
        as String;
  }

  String _extractContentFromSse(String body) {
    final buffer = StringBuffer();
    for (final line in const LineSplitter().convert(body)) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty || payload == '[DONE]') continue;
      final json = jsonDecode(payload) as Map<String, dynamic>;
      final choices = json['choices'] as List? ?? const [];
      if (choices.isEmpty || choices.first is! Map) continue;
      final choice = choices.first as Map;
      final delta = choice['delta'];
      final message = choice['message'];
      final content = delta is Map
          ? delta['content']
          : message is Map
              ? message['content']
              : null;
      if (content is String) buffer.write(content);
    }
    final content = buffer.toString();
    if (content.isEmpty) {
      throw const FormatException('Empty SSE chat completion content.');
    }
    return content;
  }

  Dio _createClient(AiProviderConfig config) {
    final baseUrl = config.effectiveBaseUrl;
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json',
        if (config.apiKey.isNotEmpty)
          'Authorization': 'Bearer ${config.apiKey}',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 240),
    ));
  }

  /// Returns the model ids that this API key can access through the standard
  /// OpenAI-compatible endpoint. A successful request does not imply that
  /// every returned model accepts images.
  Future<List<String>> fetchAvailableModels(AiProviderConfig config) async {
    if (config.baseUrl.trim().isEmpty || config.apiKey.trim().isEmpty) {
      throw AiAnalysisException('请先选择服务商并填写 API Key');
    }

    try {
      final response = await _createClient(config).get<dynamic>('/models');
      final payload = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final data = payload is Map ? payload['data'] : null;
      if (data is! List) {
        throw const FormatException('模型列表格式无效');
      }

      final modelIds = <String>{};
      for (final entry in data) {
        final id = entry is Map ? entry['id'] : entry;
        if (id is String && id.trim().isNotEmpty) {
          modelIds.add(id.trim());
        }
      }
      if (modelIds.isEmpty) {
        throw const FormatException('当前 Key 没有可用模型');
      }
      final models = modelIds.toList()..sort();
      return models;
    } on DioException catch (e) {
      throw AiAnalysisException(_dioErrorMessage(e));
    } on AiAnalysisException {
      rethrow;
    } catch (e) {
      throw AiAnalysisException('获取模型列表失败：$e');
    }
  }

  /// Tests the selected model with a tiny image request, rather than a text
  /// ping, so the setup flow catches text-only models before scan time.
  Future<void> testConnection(AiProviderConfig config) async {
    debugPrint('[AiAnalysisService] testConnection called');
    debugPrint('[AiAnalysisService] baseUrl: ${config.baseUrl}');
    debugPrint('[AiAnalysisService] model: ${config.model}');

    final dio = _createClient(config);
    final baseUrl = config.effectiveBaseUrl.toLowerCase();

    try {
      // 只检查 HTTP 200 状态码，不检查返回内容
      if (baseUrl.contains('openrouter')) {
        debugPrint('[AiAnalysisService] Testing OpenRouter endpoint');
        await dio.post('/chat/completions', data: <String, dynamic>{
          'model': config.model,
          'messages': [
            {
              'role': 'user',
              'content': _visionProbeContent(),
            },
          ],
          'max_tokens': 8,
        });
      } else if (config.model.toLowerCase().contains('gemini')) {
        debugPrint('[AiAnalysisService] Testing Gemini endpoint');
        await dio.post(
          '/v1beta/models/${config.model}:generateContent',
          data: <String, dynamic>{
            'contents': [
              {
                'parts': [
                  {'text': '请确认你能接收图片。只回复 OK。'},
                  {
                    'inline_data': {
                      'mime_type': 'image/png',
                      'data': _connectionProbeImageBase64,
                    },
                  },
                ]
              },
            ],
            'generationConfig': {'maxOutputTokens': 8},
          },
        );
      } else {
        debugPrint('[AiAnalysisService] Testing default OpenAI endpoint');
        await dio.post('/chat/completions', data: <String, dynamic>{
          'model': config.model,
          'messages': [
            {
              'role': 'user',
              'content': _visionProbeContent(),
            },
          ],
          'max_tokens': 8,
        });
      }

      debugPrint('[AiAnalysisService] Connection test passed (HTTP 200)');
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] testConnection DioException: type=${e.type}, message=${e.message}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      throw AiAnalysisException('测试失败: $e');
    }
  }

  List<Map<String, dynamic>> _visionProbeContent() {
    return <Map<String, dynamic>>[
      <String, dynamic>{
        'type': 'text',
        'text': '请确认你能接收图片。只回复 OK。',
      },
      <String, dynamic>{
        'type': 'image_url',
        'image_url': <String, String>{
          'url': 'data:image/png;base64,$_connectionProbeImageBase64',
          'detail': 'low',
        },
      },
    ];
  }

  /// 分析题目 - 图形题先直接读图解题，其他带图题保持先提取结构再分析。
  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath, // 可选：图片路径
  }) async {
    debugPrint('[AiAnalysisService] analyzeQuestion called');
    debugPrint(
        '[AiAnalysisService] - correctedText: ${correctedText.isNotEmpty ? "provided (${correctedText.length} chars)" : "empty"}');
    debugPrint('[AiAnalysisService] - subjectName: $subjectName');
    debugPrint('[AiAnalysisService] - imagePath: $imagePath');

    var textForAnalysis = correctedText;
    var resolvedSubject = _parseSubject(subjectName);

    if (imagePath != null && File(imagePath).existsSync()) {
      final shouldSolveImageDirectly = isGraphicalQuestion(
        correctedText,
        subjectName,
        imagePath: imagePath,
      );
      if (shouldSolveImageDirectly) {
        return analyzeExtractedQuestion(
          correctedText: correctedText,
          subjectName: resolvedSubject?.name ?? subjectName,
          imagePath: imagePath,
        );
      }

      final extraction = await extractQuestionStructure(
        subjectName: subjectName,
        imagePath: imagePath,
        textHint: correctedText,
      );
      if (extraction.normalizedQuestionText.isNotEmpty) {
        textForAnalysis = extraction.normalizedQuestionText;
      }
      resolvedSubject ??= extraction.subject;
    }

    return analyzeExtractedQuestion(
      correctedText: textForAnalysis,
      subjectName: resolvedSubject?.name ?? subjectName,
      imagePath: imagePath,
    );
  }

  Future<QuestionSplitResult> splitQuestionCandidates({
    required String text,
    String? subjectName,
    QuestionSplitResult Function(String text)? fallbackSplit,
  }) async {
    final subject = subjectName != null ? _parseSubject(subjectName) : null;
    final splitter = fallbackSplit ??
        (String t) => _defaultSplitQuestionCandidates(t, subject: subject);
    return splitter(text);
  }

  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    debugPrint('[AiAnalysisService] extractQuestionStructure called');

    final config = await _requireConfig();
    final imageBytes = await File(imagePath).readAsBytes();
    try {
      final extractionContent = await _requestAiContentWithImage(
        config: config,
        systemPrompt: await _loadExtractionSystemPrompt(),
        prompt: _buildExtractionPrompt(
            subjectName: subjectName, textHint: textHint),
        imageBytes: imageBytes,
        maxTokens: 1600,
        imageDetail: 'auto',
      );
      final extraction = _parseExtractionResponse(extractionContent);

      return AiQuestionExtractionResult(
        extractedQuestionText: extraction.extractedQuestionText,
        normalizedQuestionText: extraction.normalizedQuestionText,
        subject: extraction.subject,
        splitResult: extraction.splitResult,
      );
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] extract DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}, body=${e.response?.data}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] extract Exception: $e');
      if (e is AiAnalysisException) rethrow;
      throw AiAnalysisException('AI 识别题目失败: $e');
    }
  }

  Future<List<CandidateAnalysisPayload>> analyzeSplitCandidates({
    required String questionId,
    required String subjectName,
    required QuestionSplitResult splitResult,
    String? imagePath,
    void Function(int completed, int total, {int failed})? onProgress,
  }) async {
    final candidates = splitResult.candidates;
    final total = candidates.length;
    var completed = 0;
    var failed = 0;
    final payloads = <CandidateAnalysisPayload>[];

    debugPrint(
        '[AiAnalysisService] analyzeSplitCandidates: $total candidates, serial');

    for (final candidate in candidates) {
      try {
        final payload = await _analyzeSplitCandidateWithRetry(
          questionId: questionId,
          subjectName: subjectName,
          candidate: candidate,
          imagePath: imagePath,
        );
        payloads.add(payload);
      } catch (e) {
        debugPrint(
            '[AiAnalysisService] candidate ${candidate.order} failed after retry: $e');
        failed++;
        payloads.add(CandidateAnalysisPayload.failed(
          candidateId: candidate.id,
          order: candidate.order,
          questionText: candidate.text,
          errorMessage: e.toString(),
        ));
      } finally {
        completed++;
        onProgress?.call(completed, total, failed: failed);
      }
    }

    payloads.sort((a, b) => a.order.compareTo(b.order));
    return payloads;
  }

  /// Re-analyzes exactly one already-extracted candidate. This deliberately
  /// skips OCR and question splitting so a transient failure never redoes the
  /// completed parts of a multi-question scan.
  Future<CandidateAnalysisPayload> retrySplitCandidate({
    required String questionId,
    required String subjectName,
    required QuestionSplitCandidate candidate,
    String? imagePath,
  }) {
    return _analyzeSplitCandidateWithRetry(
      questionId: questionId,
      subjectName: subjectName,
      candidate: candidate,
      imagePath: imagePath,
    );
  }

  Future<CandidateAnalysisPayload> _analyzeSplitCandidateWithRetry({
    required String questionId,
    required String subjectName,
    required QuestionSplitCandidate candidate,
    String? imagePath,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final candidateText = candidate.text;
        final candidateImagePath = isGraphicalQuestion(
          candidateText,
          subjectName,
          imagePath: imagePath,
        )
            ? imagePath
            : null;
        final analysis = await analyzeExtractedQuestion(
          correctedText: candidateText,
          subjectName: subjectName,
          imagePath: candidateImagePath,
        );

        return CandidateAnalysisPayload(
          candidateId: candidate.id,
          order: candidate.order,
          questionText: candidateText,
          analysisResult: analysis,
          savedExercises: const <GeneratedExercise>[],
          subject: analysis.subject,
          aiTags: analysis.aiTags,
          aiKnowledgePoints: analysis.knowledgePoints,
        );
      } catch (e) {
        lastError = e;
        debugPrint(
            '[AiAnalysisService] candidate ${candidate.order} attempt $attempt failed: $e');
        if (!_shouldRetrySplitCandidateFailure(e)) break;
      }
    }
    throw lastError ?? AiAnalysisException('解析失败');
  }

  bool _shouldRetrySplitCandidateFailure(Object error) {
    return !RegExp(r'HTTP\s*524', caseSensitive: false)
        .hasMatch(error.toString());
  }

  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    debugPrint('[AiAnalysisService] analyzeExtractedQuestion called');

    final config = await _requireConfig();
    final isGraphicalQuestion = this.isGraphicalQuestion(
      correctedText,
      subjectName,
      imagePath: imagePath,
    );
    final shouldAnalyzeImageFirst = isGraphicalQuestion ||
        _shouldAnalyzeImageFirst(
          correctedText,
          subjectName,
          imagePath: imagePath,
        );
    final prompt = _buildAnalysisPrompt(
      correctedText,
      subjectName,
      isGraphicalQuestion: shouldAnalyzeImageFirst,
    );
    final systemPrompt = await _loadAnalysisSystemPrompt();
    final isCompositeLanguageAnalysis =
        _isCompositeLanguageAnalysis(correctedText, subjectName);
    final shouldSendImageForAnalysis = shouldAnalyzeImageFirst ||
        isCompositeLanguageAnalysis ||
        _isInstructionOnlyImagePrompt(correctedText) ||
        _shouldAnalyzeScienceImageFirst(correctedText, subjectName);

    try {
      if (imagePath != null &&
          shouldSendImageForAnalysis &&
          File(imagePath).existsSync()) {
        final imageBytes = await File(imagePath).readAsBytes();

        final String imagePrompt;
        if (isCompositeLanguageAnalysis) {
          imagePrompt =
              '$prompt\n\n请按一整道复合题分析，不要拆成多道独立题；英语按空号逐项解析，语文按文常、字词、翻译/释义模块解析。';
        } else {
          imagePrompt = prompt;
        }

        try {
          final content = await _requestAiContentWithImage(
            config: config,
            systemPrompt: systemPrompt,
            prompt: imagePrompt,
            imageBytes: imageBytes,
            maxTokens: isCompositeLanguageAnalysis || shouldAnalyzeImageFirst
                ? 3000
                : 2000,
            imageDetail: isCompositeLanguageAnalysis || shouldAnalyzeImageFirst
                ? 'high'
                : 'auto',
          );
          final analysis = _parseAnalysisResponse(content);
          return _ensureAnalysisConsistency(
            analysis,
            questionText: correctedText,
            subjectName: subjectName,
            imagePath: imagePath,
            config: config,
            imageBytes: imageBytes,
          );
        } on DioException catch (e) {
          if (_shouldUseExtractedTextFallbackAfterImageFailure(
              e, subjectName)) {
            return _analyzeAfterImageFailureWithTextFallback(
              config: config,
              systemPrompt: systemPrompt,
              correctedText: correctedText,
              subjectName: subjectName,
              imagePath: imagePath,
            );
          }
          if (!_shouldRetryWithCompactImage(e) ||
              !isCompositeLanguageAnalysis && !shouldAnalyzeImageFirst) {
            rethrow;
          }
          debugPrint(
              '[AiAnalysisService] High detail image analysis failed, retrying compact image request: ${e.type}, status=${e.response?.statusCode}');
          final content = await _requestAiContentWithImage(
            config: config,
            systemPrompt: systemPrompt,
            prompt: prompt,
            imageBytes: imageBytes,
            maxTokens: 2200,
            imageDetail: 'auto',
          );
          final analysis = _parseAnalysisResponse(content);
          return _ensureAnalysisConsistency(
            analysis,
            questionText: correctedText,
            subjectName: subjectName,
            imagePath: imagePath,
            config: config,
            imageBytes: imageBytes,
          );
        } on FormatException catch (e) {
          if (_shouldUseExtractedTextFallbackAfterImageFormatFailure(
            e,
            subjectName,
          )) {
            return _analyzeAfterImageFailureWithTextFallback(
              config: config,
              systemPrompt: systemPrompt,
              correctedText: correctedText,
              subjectName: subjectName,
              imagePath: imagePath,
            );
          }
          rethrow;
        }
      }

      String content;
      try {
        content = await _requestAiContent(
          config: config,
          systemPrompt: systemPrompt,
          prompt: prompt,
          maxTokens: isCompositeLanguageAnalysis ? 3000 : 2000,
        );
      } on DioException catch (e) {
        if (!_shouldRetryTextAnalysisWithCompact(e)) rethrow;
        debugPrint(
            '[AiAnalysisService] Text analysis failed, retrying compact analysis: ${e.type}, status=${e.response?.statusCode}');
        content = await _requestAiContent(
          config: config,
          systemPrompt: systemPrompt,
          prompt: _buildCompactAnalysisPrompt(correctedText, subjectName),
          maxTokens: 1800,
          temperature: 0.2,
        );
      }
      final analysis = _parseAnalysisResponse(content);
      return _ensureAnalysisConsistency(
        analysis,
        questionText: correctedText,
        subjectName: subjectName,
        imagePath: null,
        config: config,
      );
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}, body=${e.response?.data}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      if (e is FormatException) {
        throw AiAnalysisException('AI 返回内容格式异常，请重试或换一张更清晰的图片');
      }
      throw AiAnalysisException('AI 解析失败: $e');
    }
  }

  Future<List<GeneratedExercise>> generateExercisesForQuestion(
    QuestionRecord question,
  ) async {
    final analysis = question.analysisResult;
    final sourceQuestionText = question.normalizedQuestionText.trim().isNotEmpty
        ? question.normalizedQuestionText.trim()
        : question.extractedQuestionText.trim();

    if (analysis == null) {
      return _filterDuplicateGeneratedExercises(
        _defaultGeneratedExercises(
          question.id,
          sourceQuestionText: sourceQuestionText,
        ),
        existingExercises: question.savedExercises,
      );
    }

    final config = await _requireConfig();
    final prompt = _buildExerciseGenerationPrompt(question);

    try {
      final content = await _requestAiContent(
        config: config,
        systemPrompt: _exerciseGenerationSystemPrompt,
        prompt: prompt,
        maxTokens: 1800,
        temperature: 0.45,
      );
      final map = _parseResponseJson(content);
      return _parseGeneratedExercises(
        map,
        questionId: question.id,
        analysis: analysis,
        sourceQuestionText: sourceQuestionText,
        existingExercises: question.savedExercises,
      );
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] exercise generation DioException: type=${e.type}, status=${e.response?.statusCode}, body=${e.response?.data}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] exercise generation Exception: $e');
      if (e is AiAnalysisException) rethrow;
      throw AiAnalysisException('AI 生成举一反三失败: $e');
    }
  }

  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) async {
    final trimmedQuestion = userQuestion.trim();
    if (trimmedQuestion.isEmpty) {
      throw AiAnalysisException('请输入要追问的问题');
    }

    final config = await _requireConfig();
    final prompt = _buildFollowUpPrompt(
      question: question,
      userQuestion: trimmedQuestion,
      history: history,
    );

    try {
      final content = await _requestAiContent(
        config: config,
        systemPrompt: _followUpSystemPrompt,
        prompt: prompt,
        maxTokens: 1200,
        temperature: 0.35,
      );
      final answer = content.trim();
      if (answer.isEmpty) throw AiAnalysisException('AI 暂未返回答疑内容');
      return _normalizeExtractedQuestionText(answer);
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] follow-up DioException: type=${e.type}, status=${e.response?.statusCode}, body=${e.response?.data}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] follow-up Exception: $e');
      if (e is AiAnalysisException) rethrow;
      throw AiAnalysisException('AI 答疑失败: $e');
    }
  }

  Future<AnalysisResult> _ensureAnalysisConsistency(
    AnalysisResult analysis, {
    required String questionText,
    required String subjectName,
    required String? imagePath,
    required AiProviderConfig config,
    Uint8List? imageBytes,
  }) async {
    final check = _detectAnalysisConsistencyIssue(
      analysis,
      questionText: questionText,
    );

    if (check.forceManualReview) {
      return analysis.copyWith(
        consistencyStatus: AnalysisConsistencyStatus.needsReview,
        consistencyNote: check.note,
        wasVerifierUsed: false,
      );
    }

    if (!check.isSuspicious) {
      // Visual assumption uncertainty and answer consistency are independent
      // dimensions. When local check finds no conflict, we still set the
      // appropriate status — but visual uncertainty upgrades the status to
      // needsReview without triggering the verifier (no internal conflict to
      // repair).
      final visualNeedsReview =
          analysis.visualAssumptionStatus == VisualAssumptionStatus.needsReview;
      final AnalysisConsistencyStatus status;
      final String note;
      if (visualNeedsReview) {
        status = AnalysisConsistencyStatus.needsReview;
        note = _visualAssumptionReviewNote(analysis.visualAssumptions);
      } else if (check.isUnverifiable) {
        status = AnalysisConsistencyStatus.unverifiable;
        note = check.note;
      } else {
        status = AnalysisConsistencyStatus.consistent;
        note = check.note;
      }
      return analysis.copyWith(
        consistencyStatus: status,
        consistencyNote: note,
        wasVerifierUsed: false,
      );
    }

    try {
      final prompt = _buildConsistencyVerificationPrompt(
        questionText: questionText,
        subjectName: subjectName,
        analysis: analysis,
        issueSummary: check.note,
      );
      final content = imageBytes != null && imagePath != null
          ? await _requestAiContentWithImage(
              config: config,
              systemPrompt: _consistencyVerifierSystemPrompt,
              prompt: prompt,
              imageBytes: imageBytes,
              maxTokens: 1200,
              imageDetail: 'high',
              temperature: 0.1,
            )
          : await _requestAiContent(
              config: config,
              systemPrompt: _consistencyVerifierSystemPrompt,
              prompt: prompt,
              maxTokens: 1000,
              temperature: 0.1,
            );
      final verification = _parseConsistencyVerificationResponse(content);
      return _applyConsistencyVerification(analysis, verification);
    } catch (e) {
      debugPrint('[AiAnalysisService] consistency verifier failed: $e');
      return analysis.copyWith(
        consistencyStatus: AnalysisConsistencyStatus.needsReview,
        consistencyNote: '答案与步骤可能不一致，自动复核失败，请人工核对。',
        wasVerifierUsed: true,
      );
    }
  }

  _ConsistencyCheck _detectAnalysisConsistencyIssue(
    AnalysisResult analysis, {
    String? questionText,
  }) {
    final targetMismatch = _detectGraphicalTargetMismatch(
      analysis,
      questionText: questionText,
    );
    if (targetMismatch != null) return targetMismatch;

    final formulaIssue = _detectHighRiskFormulaChainIssue(
      analysis,
      questionText: questionText,
    );
    if (formulaIssue != null) return formulaIssue;

    // Generic: detect contradictory conclusion values within the last few steps.
    final stepContradiction = _detectStepInternalContradiction(analysis);
    if (stepContradiction != null) return stepContradiction;

    final finalTokens = _extractLikelyConclusionTokens(analysis.finalAnswer);
    final derivationTokens = _extractLikelyConclusionTokens(
      analysis.finalAnswerDerivation,
    );
    final stepConclusionTokens = <String>{
      for (final step in analysis.steps.reversed.take(2))
        ..._extractLikelyConclusionTokens(step),
    };

    if (finalTokens.isEmpty ||
        derivationTokens.isEmpty && stepConclusionTokens.isEmpty) {
      return const _ConsistencyCheck(
        isSuspicious: false,
        isUnverifiable: true,
        note: '未提取到足够明确的答案结论，未自动复核。',
      );
    }

    if (stepConclusionTokens.isNotEmpty &&
        finalTokens.intersection(stepConclusionTokens).isEmpty) {
      return _ConsistencyCheck(
        isSuspicious: true,
        isUnverifiable: false,
        note:
            'finalAnswer 提取为 ${finalTokens.join(', ')}，步骤最终结论提取为 ${stepConclusionTokens.join(', ')}。',
      );
    }

    if (derivationTokens.isNotEmpty &&
        finalTokens.intersection(derivationTokens).isEmpty) {
      return _ConsistencyCheck(
        isSuspicious: true,
        isUnverifiable: false,
        note:
            'finalAnswer 提取为 ${finalTokens.join(', ')}，答案来源提取为 ${derivationTokens.join(', ')}。',
      );
    }

    if (derivationTokens.isNotEmpty &&
        stepConclusionTokens.isNotEmpty &&
        derivationTokens.intersection(stepConclusionTokens).isEmpty) {
      return _ConsistencyCheck(
        isSuspicious: true,
        isUnverifiable: false,
        note:
            '答案来源提取为 ${derivationTokens.join(', ')}，步骤最终结论提取为 ${stepConclusionTokens.join(', ')}。',
      );
    }

    return const _ConsistencyCheck(
      isSuspicious: false,
      isUnverifiable: false,
      note: '答案与步骤结论一致。',
    );
  }

  _ConsistencyCheck? _detectGraphicalTargetMismatch(
    AnalysisResult analysis, {
    String? questionText,
  }) {
    final source = questionText?.toLowerCase() ?? '';
    if (source.isEmpty) return null;

    final asksCompositeRegion = _hasCompositeAreaTargetSignal(source);
    if (!asksCompositeRegion) return null;

    final targetText = <String>[
      analysis.reconstructedQuestionText,
      analysis.visualAssumptions?.targetObject ?? '',
      analysis.visualAssumptions?.targetQuestion ?? '',
    ].join(' ').toLowerCase();
    if (targetText.isEmpty) return null;

    final targetsOnlySemicircle = _hasAnySignal(targetText, <String>[
          '求半圆面积',
          '求该半圆的面积',
          '求这个半圆的面积',
          '求阴影半圆面积',
          '半圆面积',
        ]) &&
        !_hasCompositeAreaTargetSignal(targetText);

    if (!targetsOnlySemicircle) return null;

    return const _ConsistencyCheck(
      isSuspicious: true,
      isUnverifiable: false,
      forceManualReview: true,
      note: '参考题干指向括号状/剩余区域面积，但 AI 重构目标变成只求半圆面积，需复核读图目标。',
    );
  }

  bool _hasCompositeAreaTargetSignal(String text) {
    return _hasAnySignal(text, <String>[
      '括号',
      '括号状',
      '剩余区域',
      '剩余面积',
      '剩余部分',
      '半圆外',
      '外框内',
      '外边界与半圆',
      '目标区域',
      '所示区域',
      '阴影区域',
      '阴影部分',
      '空白部分',
    ]);
  }

  _ConsistencyCheck? _detectHighRiskFormulaChainIssue(
    AnalysisResult analysis, {
    String? questionText,
  }) {
    final combined = <String>[
      questionText ?? '',
      analysis.finalAnswer,
      analysis.finalAnswerDerivation,
      ...analysis.steps,
      analysis.mistakeReason,
      ...analysis.aiTags,
      ...analysis.knowledgePoints,
    ].join(' ').toLowerCase();
    if (!_hasPlaneGeometryAreaSignal(combined) ||
        !_hasCircleAreaSignal(combined) ||
        !_hasAnySignal(combined, <String>[
          '半圆',
          '一半',
          r'\frac{1}{2}',
          '1/2',
          '阴影',
        ])) {
      return null;
    }

    final canonical = _canonicalMathText(combined);
    final has25PiHalf = _hasAnySignal(canonical, <String>[
      '25\\pi/2',
      '\\frac{25\\pi}{2}',
      '\\frac{25pi}{2}',
    ]);
    final has29PiHalf = _hasAnySignal(canonical, <String>[
      '29\\pi/2',
      '\\frac{29\\pi}{2}',
      '\\frac{29pi}{2}',
    ]);
    final finalTokens = _extractLikelyConclusionTokens(analysis.finalAnswer);
    if (has25PiHalf &&
        has29PiHalf &&
        (finalTokens.contains(r'25\pi') ||
            finalTokens.contains(r'25\pi/2') ||
            finalTokens.contains(r'29\pi/2'))) {
      return const _ConsistencyCheck(
        isSuspicious: true,
        isUnverifiable: false,
        note: '图形面积解析中同时出现 25π/2、29π/2 或 25π 等不同结论，需复核最终答案。',
      );
    }

    if (_hasAnySignal(canonical, <String>[
      '25\\pi/2*2=25\\pi',
      '25\\pi/2×2=25\\pi',
      '25\\pi/2乘2=25\\pi',
      '1/2\\pi*5^2=25\\pi',
      '1/2\\pi×5^2=25\\pi',
      '1/2*\\pi*5^2=25\\pi',
      '1/2×\\pi×5^2=25\\pi',
    ])) {
      return const _ConsistencyCheck(
        isSuspicious: true,
        isUnverifiable: false,
        note: '半圆面积公式链出现从 25π/2 跳到 25π 的矛盾，需复核最终答案。',
      );
    }

    final hasHalfCircleFormula = _hasAnySignal(canonical, <String>[
      '1/2\\pi r^2',
      '1/2\\pir^2',
      '1/2*\\pi*r^2',
      '1/2×\\pi×r^2',
      '1/2\\pi×r^2',
      '1/2\\pi*5^2',
      '1/2\\pi×5^2',
      '\\frac{1}{2}\\pi r^2',
      '\\frac{1}{2}\\pir^2',
      '\\frac{1}{2}\\pi×5^2',
      '\\frac{1}{2}\\pi*5^2',
    ]);
    final derivesHalfOf25Pi = _hasAnySignal(canonical, <String>[
      '25\\pi/2',
      '\\frac{25\\pi}{2}',
      '\\frac{25pi}{2}',
    ]);
    if (hasHalfCircleFormula &&
        derivesHalfOf25Pi &&
        finalTokens.contains(r'25\pi') &&
        !finalTokens.any((token) => token.contains('/2'))) {
      return const _ConsistencyCheck(
        isSuspicious: true,
        isUnverifiable: false,
        note: '半圆面积推导中已得到 25π/2，但 finalAnswer 是 25π，需复核最终答案。',
      );
    }

    return null;
  }

  /// Generic detection: checks if any single step contains mutually exclusive
  /// final-answer-like conclusions. Unlike [_detectHighRiskFormulaChainIssue]
  /// this is not hardcoded to specific values.
  ///
  /// Only flags cases where a step has **separate conclusion statements**
  /// (e.g. "所以面积为 10π" and later "最终答案是 29π/2") pointing to
  /// different values. Continuous formula chains like "= 25π/2 × 2 = 25π"
  /// are NOT flagged — they are valid computation chains even if the math
  /// is wrong (math correctness is the verifier's job).
  _ConsistencyCheck? _detectStepInternalContradiction(
    AnalysisResult analysis,
  ) {
    if (analysis.steps.isEmpty) return null;

    // Look for conclusion keywords that introduce final-answer-like values.
    final conclusionPattern = RegExp(
      r'(?:答案|所以|因此|故|得|最终|最后)[^=]*?(?:为|是|=)\s*([^\s,，。；]+)',
    );

    for (final step in analysis.steps.reversed.take(3)) {
      final matches = conclusionPattern.allMatches(step).toList();
      if (matches.length < 2) continue;

      // Extract numeric tokens from each conclusion fragment.
      final conclusionTokens = <Set<String>>[];
      for (final match in matches) {
        final fragment = match.group(1) ?? '';
        final tokens = _extractAnswerTokens(fragment)
            .where((t) => RegExp(r'\d|\\pi|pi').hasMatch(t))
            .toSet();
        if (tokens.isNotEmpty) conclusionTokens.add(tokens);
      }

      // If two conclusion statements in the same step point to
      // different numeric values, that's a genuine contradiction.
      if (conclusionTokens.length >= 2) {
        final last = conclusionTokens.last;
        for (var i = 0; i < conclusionTokens.length - 1; i++) {
          final earlier = conclusionTokens[i];
          if (earlier.intersection(last).isEmpty) {
            return _ConsistencyCheck(
              isSuspicious: true,
              isUnverifiable: false,
              note:
                  '步骤内部结论矛盾：同一步中先结论 ${earlier.join(', ')}，后结论 ${last.join(', ')}，需复核。',
            );
          }
        }
      }
    }

    return null;
  }

  String _canonicalMathText(String text) {
    return text
        .replaceAll(' ', '')
        .replaceAll('，', ',')
        .replaceAll('。', '')
        .replaceAll('＝', '=')
        .replaceAll('π', r'\pi')
        .replaceAll('−', '-')
        .replaceAll('·', '*')
        .replaceAll('×', '×')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\cdot', '*')
        .replaceAll(r'\left', '')
        .replaceAll(r'\right', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .toLowerCase();
  }

  Set<String> _extractLikelyConclusionTokens(String text) {
    final normalized = text
        .replaceAll(' ', '')
        .replaceAll('，', ',')
        .replaceAll('。', '')
        .replaceAll('＝', '=')
        .replaceAll('π', r'\pi')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .toLowerCase();
    final keywordMatch = RegExp(r'(?:答案|选|应选|所以|因此|故|得|为|是)[:：]?([^。；;，,]*)')
        .allMatches(normalized)
        .lastOrNull;
    if (keywordMatch != null) {
      final tokens = _extractAnswerTokens(keywordMatch.group(1)!);
      if (tokens.isNotEmpty) return tokens;
    }

    final equalsIndex = normalized.lastIndexOf('=');
    if (equalsIndex >= 0 && equalsIndex < normalized.length - 1) {
      final tokens =
          _extractAnswerTokens(normalized.substring(equalsIndex + 1));
      if (tokens.isNotEmpty) return tokens;
    }

    return _extractAnswerTokens(normalized);
  }

  Set<String> _extractAnswerTokens(String text) {
    final normalized = text
        .replaceAll(' ', '')
        .replaceAll('，', ',')
        .replaceAll('。', '')
        .replaceAll('＝', '=')
        .replaceAll('π', r'\pi')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .toLowerCase();
    final tokens = <String>{};

    for (final match
        in RegExp(r'(?<![a-z])[a-d](?![a-z])').allMatches(normalized)) {
      tokens.add(match.group(0)!.toUpperCase());
    }
    for (final match in RegExp(
            r'(?:\\frac\{[^{}]+\}\{[^{}]+\}|\d+(?:\.\d+)?(?:\\pi|pi)?(?:/\d+(?:\.\d+)?)?|(?:\\pi|pi)(?:/\d+(?:\.\d+)?)?)')
        .allMatches(normalized)) {
      final token = match.group(0)!;
      if (RegExp(r'\d|\\pi|pi').hasMatch(token)) tokens.add(token);
    }
    for (final match
        in RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}').allMatches(normalized)) {
      tokens.add('${match.group(1)}/${match.group(2)}');
    }
    return tokens
        .where((token) => token.length > 1 || RegExp(r'[A-D]').hasMatch(token))
        .toSet();
  }

  @visibleForTesting
  String extractContentFromResponseForTest(Response response) {
    return _extractContentFromResponse(response);
  }

  @visibleForTesting
  AnalysisResult parseAnalysisResponseForTest(String content) {
    return _parseAnalysisResponse(content);
  }

  @visibleForTesting
  AnalysisResult applyConsistencyVerificationForTest(
    AnalysisResult analysis,
    String verificationContent,
  ) {
    return _applyConsistencyVerification(
      analysis,
      _parseConsistencyVerificationResponse(verificationContent),
    );
  }

  /// Returns `true` if [_detectAnalysisConsistencyIssue] would mark the
  /// analysis as suspicious (i.e. would trigger the verifier in production).
  @visibleForTesting
  bool detectConsistencyIssueForTest(
    AnalysisResult analysis, {
    String? questionText,
  }) {
    return _detectAnalysisConsistencyIssue(
      analysis,
      questionText: questionText,
    ).isSuspicious;
  }

  @visibleForTesting
  bool shouldUseExtractedTextFallbackAfterImageFailureForTest(
    DioException error,
    String subjectName,
  ) {
    return _shouldUseExtractedTextFallbackAfterImageFailure(error, subjectName);
  }

  @visibleForTesting
  bool shouldUseExtractedTextFallbackAfterImageFormatFailureForTest(
    Object error,
    String subjectName,
  ) {
    return _shouldUseExtractedTextFallbackAfterImageFormatFailure(
      error,
      subjectName,
    );
  }

  @visibleForTesting
  bool shouldRetryPostForTest(DioException error) {
    return _shouldRetryPost(error);
  }

  @visibleForTesting
  bool shouldRetryPostWithStatusCodesForTest(
    DioException error,
    Set<int> retryStatusCodes,
  ) {
    return _shouldRetryPost(error, retryStatusCodes: retryStatusCodes);
  }

  @visibleForTesting
  Set<int> extractionRetryStatusCodesForSubjectForTest(String subjectName) {
    return _extractionRetryStatusCodesForSubject(subjectName);
  }

  @visibleForTesting
  bool shouldRetryEmptySseExtractionForTest(
    Object error,
    String subjectName,
  ) {
    return _shouldRetryEmptySseExtraction(error, subjectName);
  }

  @visibleForTesting
  AnalysisResult markExtractionFallbackForReviewForTest(
    AnalysisResult analysis, {
    required String extractedText,
  }) {
    return _markExtractionFallbackForReview(
      analysis,
      extractedText: extractedText,
    );
  }

  @visibleForTesting
  bool consistencyIssueForcesManualReviewForTest(
    AnalysisResult analysis, {
    String? questionText,
  }) {
    return _detectAnalysisConsistencyIssue(
      analysis,
      questionText: questionText,
    ).forceManualReview;
  }

  String _buildConsistencyVerificationPrompt({
    required String questionText,
    required String subjectName,
    required AnalysisResult analysis,
    required String issueSummary,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('请复核以下错题解析的最终答案一致性。');
    buffer.writeln('科目：$subjectName');
    buffer.writeln('题目：$questionText');
    buffer.writeln('冲突摘要：$issueSummary');
    buffer.writeln();
    buffer.writeln('原 finalAnswer：${analysis.finalAnswer}');
    buffer.writeln('原 finalAnswerDerivation：${analysis.finalAnswerDerivation}');
    buffer.writeln('原 steps：');
    for (var i = 0; i < analysis.steps.length; i++) {
      buffer.writeln('${i + 1}. ${analysis.steps[i]}');
    }
    buffer.writeln('原 mistakeReason：${analysis.mistakeReason}');
    buffer.writeln();
    buffer.writeln('只判断 finalAnswer 是否与最终推导/步骤一致；不要重新生成举一反三。');
    buffer.writeln(
        '如果 steps 内部公式链本身错误，必须返回 correctedSteps，且 correctedSteps 不能保留原错误公式链。');
    buffer.writeln('如果不一致，只返回应该采用的最终答案、最终答案来源说明、必要的修正步骤和错因。');
    return buffer.toString();
  }

  static const _consistencyVerifierSystemPrompt =
      '''你是错题解析一致性复核器，只检查 finalAnswer 是否与 finalAnswerDerivation 和 steps 的最终结论一致。
不要把 mistakeReason 中复述的旧答案当作最终结论。
不要扩写举一反三。
只有在非常明确时才修正；如果不确定，设置 needsManualReview=true。
如果 steps 内部有错误公式链或错误结论，必须返回 correctedSteps，不能只修正 finalAnswer。
如果不能可靠修正 steps，设置 needsManualReview=true。
返回纯 JSON，不要 markdown：
{
  "isConsistent": false,
  "correctFinalAnswer": "",
  "correctedFinalAnswerDerivation": "",
  "correctedSteps": [],
  "correctedMistakeReason": "",
  "confidence": "high|medium|low",
  "needsManualReview": false,
  "reason": ""
}''';

  _ConsistencyVerification _parseConsistencyVerificationResponse(
      String content) {
    final map = _parseResponseJson(content);
    return _ConsistencyVerification(
      isConsistent: map['isConsistent'] as bool? ?? false,
      correctFinalAnswer: (map['correctFinalAnswer'] as String?)?.trim() ?? '',
      correctedFinalAnswerDerivation:
          (map['correctedFinalAnswerDerivation'] as String?)?.trim() ?? '',
      correctedSteps: List<String>.from(
        (map['correctedSteps'] as List? ?? <String>[])
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      ),
      correctedMistakeReason:
          (map['correctedMistakeReason'] as String?)?.trim() ?? '',
      confidence: (map['confidence'] as String?)?.trim().toLowerCase() ?? 'low',
      needsManualReview: map['needsManualReview'] as bool? ?? true,
      reason: (map['reason'] as String?)?.trim() ?? '',
    );
  }

  AnalysisResult _applyConsistencyVerification(
    AnalysisResult analysis,
    _ConsistencyVerification verification,
  ) {
    if (verification.isConsistent) {
      final visualNeedsReview =
          analysis.visualAssumptionStatus == VisualAssumptionStatus.needsReview;
      return analysis.copyWith(
        consistencyStatus: visualNeedsReview
            ? AnalysisConsistencyStatus.needsReview
            : AnalysisConsistencyStatus.consistent,
        consistencyNote: visualNeedsReview
            ? _visualAssumptionReviewNote(analysis.visualAssumptions)
            : (verification.reason.isNotEmpty
                ? verification.reason
                : 'AI 已复核答案与步骤一致。'),
        wasVerifierUsed: true,
      );
    }

    final canRepair = !verification.needsManualReview &&
        (verification.confidence == 'high' ||
            verification.confidence == 'medium') &&
        verification.correctFinalAnswer.isNotEmpty;
    if (!canRepair) {
      return analysis.copyWith(
        consistencyStatus: AnalysisConsistencyStatus.needsReview,
        consistencyNote: verification.reason.isNotEmpty
            ? verification.reason
            : '答案与步骤可能不一致，请人工核对。',
        wasVerifierUsed: true,
      );
    }

    final repairedSteps = verification.correctedSteps.isNotEmpty
        ? verification.correctedSteps
            .map(_normalizeExtractedQuestionText)
            .where((step) => step.isNotEmpty)
            .toList()
        : analysis.steps;
    final repairedMistakeReason = verification.correctedMistakeReason.isNotEmpty
        ? _normalizeExtractedQuestionText(verification.correctedMistakeReason)
        : analysis.mistakeReason;
    final repaired = analysis.copyWith(
      finalAnswer:
          _normalizeExtractedQuestionText(verification.correctFinalAnswer),
      finalAnswerDerivation: _normalizeExtractedQuestionText(
        verification.correctedFinalAnswerDerivation.isNotEmpty
            ? verification.correctedFinalAnswerDerivation
            : analysis.finalAnswerDerivation,
      ),
      reconstructedQuestionText: analysis.reconstructedQuestionText,
      steps: repairedSteps,
      mistakeReason: repairedMistakeReason,
      consistencyStatus: AnalysisConsistencyStatus.repaired,
      consistencyNote:
          verification.reason.isNotEmpty ? verification.reason : 'AI 已复核并修正答案。',
      wasVerifierUsed: true,
    );
    final check = _detectAnalysisConsistencyIssue(repaired);
    if (check.isSuspicious) {
      return analysis.copyWith(
        consistencyStatus: AnalysisConsistencyStatus.needsReview,
        consistencyNote: 'AI 复核后仍无法确认最终答案，请人工核对。',
        wasVerifierUsed: true,
      );
    }
    if (repaired.visualAssumptionStatus == VisualAssumptionStatus.needsReview) {
      return repaired.copyWith(
        consistencyStatus: AnalysisConsistencyStatus.needsReview,
        consistencyNote:
            'AI 已复核并修正答案；${_visualAssumptionReviewNote(repaired.visualAssumptions)}',
        wasVerifierUsed: true,
      );
    }
    return repaired;
  }

  Future<AiProviderConfig> _requireConfig() async {
    final config = await settingsRepository.getAiProviderConfig();

    debugPrint(
        '[AiAnalysisService] config: ${config != null ? "loaded" : "null"}');
    if (config != null) {
      debugPrint('[AiAnalysisService] - baseUrl: ${config.baseUrl}');
      debugPrint('[AiAnalysisService] - model: ${config.model}');
      debugPrint(
          '[AiAnalysisService] - apiKey length: ${config.apiKey.length}');
    }

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      debugPrint('[AiAnalysisService] No config - throwing error');
      throw AiAnalysisException('AI 未配置，请在设置中配置 API 地址、API Key 和模型');
    }

    return config;
  }

  bool _shouldRetryWithCompactImage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = e.response?.statusCode;
    return status == 408 ||
        status == 429 ||
        status == 500 ||
        status == 502 ||
        status == 503 ||
        status == 504;
  }

  bool _shouldRetryPost(
    DioException e, {
    Set<int> retryStatusCodes = const <int>{},
  }) {
    final status = e.response?.statusCode;
    if (status != null) return retryStatusCodes.contains(status);
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    return e.type == DioExceptionType.unknown;
  }

  Set<int> _extractionRetryStatusCodesForSubject(String subjectName) {
    final subject = _parseSubject(subjectName);
    if (subject == Subject.chemistry || subject == Subject.biology) {
      return const <int>{524};
    }
    return const <int>{};
  }

  bool _shouldRetryEmptySseExtraction(Object error, String subjectName) {
    return error is FormatException &&
        error.message.contains('Empty SSE chat completion content') &&
        _extractionRetryStatusCodesForSubject(subjectName).isNotEmpty;
  }

  bool _shouldUseExtractedTextFallbackAfterImageFailure(
    DioException e,
    String subjectName,
  ) {
    final status = e.response?.statusCode;
    return status == 524 &&
        _extractionRetryStatusCodesForSubject(subjectName).isNotEmpty;
  }

  bool _shouldUseExtractedTextFallbackAfterImageFormatFailure(
    Object error,
    String subjectName,
  ) {
    return _shouldRetryEmptySseExtraction(error, subjectName);
  }

  bool _isInstructionOnlyImagePrompt(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    return _hasAnySignal(trimmed, const <String>[
          '请识别图片',
          '识别图片中的',
          '整理完整题干',
          '整理题干',
          '作答思路',
        ]) &&
        !_hasAnySignal(trimmed, const <String>[
          '已知',
          '若',
          '函数',
          '方程',
          '合成路线',
          '分子式',
          '短文',
          '阅读',
          '选项',
        ]);
  }

  AnalysisResult _markExtractionFallbackForReview(
    AnalysisResult analysis, {
    required String extractedText,
  }) {
    final existing = analysis.visualAssumptions;
    return analysis.copyWith(
      visualAssumptions: VisualAssumptions(
        targetObject: existing?.targetObject ?? '图片题目',
        targetQuestion: existing?.targetQuestion ?? '根据降级提取文本完成解析',
        measurements: existing?.measurements ?? const [],
        solutionBasis: existing?.solutionBasis ??
            <String>[
              if (extractedText.trim().isNotEmpty)
                '图像请求失败后，使用已提取题干文本继续解析。'
              else
                '图像请求失败后，使用已有题干文本继续解析。',
            ],
        uncertainItems: existing?.uncertainItems ?? const <String>['原图关键标注'],
        needsManualReview: true,
        reviewReason: existing?.reviewReason.isNotEmpty == true
            ? existing!.reviewReason
            : '图像分析降级为文本解析，请核对原图关键标注。',
      ),
      visualAssumptionStatus: VisualAssumptionStatus.needsReview,
      consistencyStatus: AnalysisConsistencyStatus.needsReview,
      consistencyNote: '图像分析降级为文本解析，请核对原图关键标注。',
      wasVerifierUsed: false,
    );
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
          buffer.write(
              ': ${body.length > 100 ? '${body.substring(0, 100)}...' : body}');
        }
      } else if (e.message != null) {
        buffer.write(': ${e.message}');
      }
    } else if (e.message != null) {
      buffer.write(': ${e.message}');
    }
    return buffer.toString();
  }

  QuestionSplitResult _defaultSplitQuestionCandidates(String text,
      {Subject? subject}) {
    final normalized = _normalizeExtractedQuestionText(
      text.replaceAll('\r\n', '\n').trim(),
    );
    if (normalized.isEmpty) {
      return const QuestionSplitResult(
        sourceText: '',
        candidates: <QuestionSplitCandidate>[],
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (isCompositeLanguageWorksheet(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (_isCompositeQuestionWithSubparts(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final numberedSegments = _splitByNumberedQuestions(normalized);
    if (numberedSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            numberedSegments, QuestionSplitStrategy.numbered),
        strategy: QuestionSplitStrategy.numbered,
      );
    }

    if (isSingleChoiceQuestionWithOptionBlock(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (isSingleQuestionWithSupportingBlocks(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final paragraphSegments = normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (paragraphSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            paragraphSegments, QuestionSplitStrategy.paragraph),
        strategy: QuestionSplitStrategy.paragraph,
      );
    }

    return QuestionSplitResult(
      sourceText: normalized,
      candidates: _buildSplitCandidates(
          <String>[normalized], QuestionSplitStrategy.fallback),
      strategy: QuestionSplitStrategy.fallback,
    );
  }

  String _normalizeExtractedQuestionText(String text) {
    final normalized = text
        .replaceAll(_escapedNumberedQuestionBreak, '\n')
        .replaceAllMapped(
          RegExp(
              r'(?<!\\)xrightarrow\s*([A-Za-z0-9_+\-/().]+(?:\s*[,，、]\s*(?:Δ|Delta|[A-Za-z0-9_+\-/().]+))*)'),
          (match) {
            final condition = _normalizeXrightarrowCondition(match.group(1)!);
            return '\\xrightarrow{$condition}';
          },
        )
        .replaceAllMapped(
          RegExp(r'begin\{(cases|aligned)\}([\s\S]*?)end\{(?:cases|aligned)\}'),
          (match) {
            final body = match.group(2)!.trim().replaceAllMapped(
                  RegExp(r'(?<=[0-9A-Za-z一-龥])\s+(?=[A-Za-z])'),
                  (_) => r' \\ ',
                );
            return '\\begin{${match.group(1)}} $body \\end{${match.group(1)}}';
          },
        )
        .replaceAllMapped(RegExp(r'\\+tri\\+angle\s*'), (_) => r'\triangle ')
        .replaceAllMapped(RegExp(r'\\?tri\\?angle\s*|\\?tri∠|tri(?=\\angle)'),
            (_) => r'\triangle ')
        .replaceAllMapped(RegExp(r'(?<!\\)angle\b'), (_) => r'\angle')
        .replaceAllMapped(RegExp(r'(?<!\\)circ\b'), (_) => r'\circ')
        .replaceAllMapped(RegExp(r'(?<!\\)pm(?=[A-Za-z0-9])'), (_) => r'\pm ')
        .replaceAllMapped(RegExp(r'(?<!\\)pm\b'), (_) => r'\pm');

    return normalized
        .replaceAll(RegExp(r'\\+tri\\+angle\s*'), r'\triangle ')
        .replaceAll(RegExp(r'tri\\+angle\s*'), r'\triangle ')
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri∠'), r'\triangle ')
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri(?=\\angle|/)'), r'\triangle ')
        .replaceAll(
          RegExp(r'(?<![A-Za-z\\])text(?=kg|m|cm|g|s|N|Pa|J|W|V|A|Ω)'),
          r'\mathrm',
        )
        .replaceAllMapped(
          RegExp(r'\\?mathrm([A-Za-zΩ]+)(\^-?\d+)?'),
          (match) => '\\mathrm{${match.group(1)}}${match.group(2) ?? ''}',
        );
  }

  String _normalizeXrightarrowCondition(String condition) {
    return condition
        .split(RegExp(r'[,，、]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .map((part) {
      if (part == 'Δ' || part.toLowerCase() == 'delta') {
        return r'\Delta';
      }
      return part;
    }).join(', ');
  }

  bool _isCompositeLanguageAnalysis(String text, String subjectName) {
    final subject = _parseSubject(subjectName);
    if ((subject == Subject.english || subject == Subject.chinese) &&
        text.trim().isEmpty) {
      return true;
    }
    return isCompositeLanguageWorksheet(text, subject: subject);
  }

  bool _isCompositeQuestionWithSubparts(String text, {Subject? subject}) {
    if (subject == Subject.chinese ||
        subject == Subject.english ||
        subject == Subject.history ||
        subject == Subject.geography ||
        subject == Subject.politics) {
      return false;
    }
    final hasSubQuestions =
        RegExp(r'（\s*\d+\s*）|\(\s*\d+\s*\)').allMatches(text).length >= 2;
    if (!hasSubQuestions) return false;

    final independentQuestionCount =
        RegExp(r'(^|\n)\s*(?:第\s*\d+\s*题|\d+[\.、．)])\s*', multiLine: true)
            .allMatches(text)
            .length;
    if (independentQuestionCount >= 2) return false;

    return _hasSharedCompositeStemSignal(text, subject: subject);
  }

  bool _hasSharedCompositeStemSignal(String text, {Subject? subject}) {
    final lower = text.toLowerCase();
    final hasGenericStem = _hasAnySignal(text, <String>[
      '如图',
      '根据下列',
      '结合材料',
      '已知',
      '条件',
      '回答下列问题',
      '完成下列问题',
    ]);
    final hasMathPhysicsStem = _hasAnySignal(text, <String>[
      '电路',
      '装置',
      '实验',
      '函数图像',
      '坐标系',
      '正方形',
      '矩形',
      '三角形',
      '圆',
    ]);
    final hasChemistryStem = _hasAnySignal(text, <String>[
      '合成路线',
      '流程',
      '路线',
      '转化关系',
      '可通过如下',
      '如图',
      '条件',
      '已知',
      '写出',
      '结构简式',
      '分子式',
      '化学方程式',
      '反应类型',
    ]);
    final hasChemistryContext = _hasAnySignal(lower, <String>[
      'naoh',
      'nh2oh',
      'hcl',
      'br',
      'fecl3',
      'c6h',
      '苯',
      '酯',
      '醇',
      '醛',
      '羧酸',
      '有机',
      '官能团',
      '同分异构体',
    ]);
    if (subject == Subject.chemistry) {
      return hasGenericStem || hasChemistryStem || hasChemistryContext;
    }
    if (subject == Subject.math || subject == Subject.physics) {
      return hasGenericStem || hasMathPhysicsStem;
    }
    return hasGenericStem || hasMathPhysicsStem || hasChemistryStem;
  }

  List<QuestionSplitCandidate> _buildSplitCandidates(
      List<String> segments, QuestionSplitStrategy strategy) {
    return segments.asMap().entries.map((entry) {
      return QuestionSplitCandidate(
        id: 'candidate-${entry.key}',
        order: entry.key + 1,
        text: entry.value,
        strategy: strategy,
      );
    }).toList();
  }

  List<String> _splitByNumberedQuestions(String text) {
    final matches = RegExp(
      r'(^|\n)\s*(?:第\s*\d+\s*题|\d+(?:[、．)]|\.(?!\d)))\s*',
      multiLine: true,
    ).allMatches(text).toList();
    if (matches.length < 2) return const <String>[];

    final segments = <String>[];
    for (var index = 0; index < matches.length; index++) {
      final current = matches[index];
      final start = current.start + (current.group(1)?.length ?? 0);
      final end =
          index + 1 < matches.length ? matches[index + 1].start : text.length;
      final segment = text.substring(start, end).trim();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    return segments;
  }

  Future<String> _requestAiContent({
    required AiProviderConfig config,
    required String systemPrompt,
    required String prompt,
    int maxTokens = 2000,
    double temperature = 0.7,
  }) async {
    final dio = _createClient(config);
    final response =
        await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    return _extractContentFromResponse(response);
  }

  bool _usesOpenAiCompatibleChat(AiProviderConfig config) {
    final baseUrl = config.baseUrl.toLowerCase();
    final model = config.model.toLowerCase();
    return baseUrl.contains('/v1') ||
        baseUrl.contains('openrouter') ||
        model.contains('gpt') ||
        model.contains('4o') ||
        model.contains('4-turbo');
  }

  Future<String> _requestAiContentWithImage({
    required AiProviderConfig config,
    required String systemPrompt,
    required String prompt,
    required Uint8List imageBytes,
    int maxTokens = 2000,
    String imageDetail = 'auto',
    double temperature = 0.7,
  }) async {
    final dio = _createClient(config);
    final base64Image = base64Encode(imageBytes);
    const mimeType = 'image/jpeg';
    final baseUrl = config.baseUrl.toLowerCase();
    final model = config.model.toLowerCase();

    if (_usesOpenAiCompatibleChat(config)) {
      final response =
          await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
        'model': config.model,
        'messages': <Map<String, dynamic>>[
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                  'detail': imageDetail
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      });
      return _extractContentFromResponse(response);
    }

    if (model.contains('gemini') && !baseUrl.contains('openrouter')) {
      final response = await dio.post(
        '/v1beta/models/${config.model}:generateContent',
        data: <String, dynamic>{
          'contents': [
            {
              'parts': [
                {'text': '$systemPrompt\n\n$prompt'},
                {
                  'inlineData': {'mimeType': mimeType, 'data': base64Image}
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxTokens,
          },
        },
      );
      return response.data['candidates'][0]['content']['parts'][0]['text']
          as String;
    }

    final response =
        await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
                'detail': imageDetail
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });
    return response.data['choices'][0]['message']['content'] as String;
  }

  static const _defaultAnalysisSystemPrompt = r'''你是一个专业的错题分析助手，专门帮助学生分析和理解错题。

你的任务是：
1. 基于题目文本或图片内容进行学习分析
2. 根据题目内容判断所属科目（数学、语文、英语、物理、化学、生物、历史、地理、政治等）
3. 提供正确的解题思路和答案
4. 分析学生可能犯错误的原因
5. 提供学习建议和相关的知识点

重要规则：
- 本次只做本题解析，不生成额外练习题，不输出与练习题相关的内容
- 优先使用用户已确认的题目文本；如果输入包含图片且文本不足，必须直接根据图片理解题目并解题
- reconstructedQuestionText 必须整理出完整题干；图形题应基于读图理解补全已知条件和求解目标
- 答案必须准确、有条理
- finalAnswer 只能填写题目最终要求的答案，不要填写中间量；必须与 steps 最后一条最终结论一致
- finalAnswerDerivation 必须用一句话说明最终答案来源，且必须与 finalAnswer 一致；如果 steps、mistakeReason 中出现其他中间答案，不得把中间答案写入 finalAnswer
- 输出 JSON 前必须自检 finalAnswer、finalAnswerDerivation、steps、mistakeReason 是否一致；若不一致，以重新验算后的最终结论同步修正
- aiTags 要求简短精炼（2-8个字），数量 2-4 个，如 ["压强", "力学", "公式"]
- knowledgePoints 可以详细描述，长度不限，如 ["压强公式p=f/s，压强与压力的关系", "受力面积相同时，压力越大压强越大"]
- 如果内容包含 LaTeX，必须先生成合法 JSON：所有 LaTeX 反斜杠都写成 JSON 转义形式，例如 \\frac、\\times、\\(x\\)、\\[x\\]
- 方程组或多行公式必须使用 KaTeX 兼容的 aligned 或 cases 环境，例如 \\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}，不要使用 \\newline
- 不要在 JSON 字符串内部直接换行；换行必须写成 \\n
- 【LaTeX 格式强制规范——必须严格遵守】
  1. 所有数学公式必须使用标准 LaTeX 定界符包裹：行内公式用 \(公式\)，独立公式用 \[公式\]。禁止使用方括号 [(...) 或 [...] 作为 LaTeX 定界符。
  2. LaTeX 命令必须使用完整的反斜杠前缀，禁止省略反斜杠：
     - 正确命令：\frac、\angle、\triangle、\circ、\times、\cdot、\pm、\sqrt、\pi、\rho、\alpha、\beta、\gamma、\theta、\Delta、\lambda、\mu、\sigma、\omega、\leq、\geq、\neq、\approx、\sin、\cos、\tan、\log、\ln、\mathrm、\rightarrow、\leftarrow
     - 错误写法：frac、angle、triangle、circ、times、cdot、pm、sqrt、pi、rho、alpha
     - 注意：乘号用 \times，除法用 \frac，分数用 \frac{a}{b}，圆周率用 \pi，密度用 \rho
  3. 角度/度数统一用 ^\circ，圆周率统一用 \pi
  4. 上标用 ^{n} 格式，禁止裸 ^n
  5. 物理单位用 \mathrm{}：\mathrm{kg}、\mathrm{m}、\mathrm{N}、\mathrm{Pa}、\mathrm{J}、\mathrm{W}、\mathrm{V}、\mathrm{A}、\mathrm{\Omega}
  6. JSON 转义规则：反斜杠双写，\ → \\，\\ → \\\\。换行用 \\n。cases 环境行分隔符 \\ → \\\\
     - 示例：\\(x^2=4\)\\n  所以 x=\\pm 2  // JSON 中 \\n = 换行，\\pi = \pi，\\pm = \pm
     - 示例：\[\\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}\]  // \\\\ 在 JSON 中表示 LaTeX 换行符 \\
返回格式必须严格如下（不要包含 markdown 代码块标记，使用纯 JSON）：
{
  "subject": "自动判断的科目名称",
  "reconstructedQuestionText": "根据文本或图片理解整理出的完整题干",
  "visualAssumptions": {
    "targetObject": "",
    "targetQuestion": "",
    "measurements": [{"label": "", "meaning": "", "usedInSolution": true, "evidence": "image|text|inferred", "confidence": "high|medium|low"}],
    "solutionBasis": [""],
    "uncertainItems": [""],
    "needsManualReview": false,
    "reviewReason": ""
  },
  "finalAnswer": "正确答案或解题要点",
  "finalAnswerDerivation": "最终答案来源说明，必须与 finalAnswer 一致",
  "steps": ["解题步骤1", "解题步骤2"],
  "aiTags": ["短标签1", "短标签2", "短标签3"],
  "knowledgePoints": ["知识点1详细描述", "知识点2详细描述"],
  "mistakeReason": "错误原因分析",
  "studyAdvice": "学习建议"
}''';

  static const _defaultExtractionSystemPrompt =
      r'''你是一个专业的教辅录入员，负责把题目图片整理成可存储、可检索的结构化文本。

你的任务是：
1. 识别图片中的原始题目内容
2. 忽略无关的手写批改痕迹、圈画、红叉等内容
3. 输出适合存入题库的规范化题目文本
4. 判断题目所属科目
5. 数学公式使用 LaTeX 或 Markdown 友好的表达，保持题意完整

重要规则：
- 必须以图片内容为准，不要虚构缺失内容
- extractedQuestionText 保留尽量忠实的识别结果
- normalizedQuestionText 输出更适合展示、搜索和后续 AI 分析的规范文本
- 如果图片无法识别出有效题目，两个文本字段都返回空字符串
- 如果内容包含 LaTeX，必须先生成合法 JSON：所有 LaTeX 反斜杠都写成 JSON 转义形式，例如 \\frac、\\times、\\(x\\)、\\[x\\]
- 方程组或多行公式必须使用 KaTeX 兼容的 aligned 或 cases 环境，例如 \\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}，不要使用 \\newline
- 不要在 JSON 字符串内部直接换行；换行必须写成 \\n
- 【LaTeX 格式强制规范——必须严格遵守】
  1. 所有数学公式必须使用标准 LaTeX 定界符包裹：行内公式用 \(公式\)，独立公式用 \[公式\]。禁止使用方括号 [(...) 或 [...] 作为 LaTeX 定界符。
  2. LaTeX 命令必须使用完整的反斜杠前缀，禁止省略反斜杠：
     - 正确命令：\frac、\angle、\triangle、\circ、\times、\cdot、\pm、\sqrt、\pi、\rho、\alpha、\beta、\gamma、\theta、\Delta、\lambda、\mu、\sigma、\omega、\leq、\geq、\neq、\approx、\sin、\cos、\tan、\log、\ln、\mathrm、\rightarrow、\leftarrow
     - 错误写法：frac、angle、triangle、circ、times、cdot、pm、sqrt、pi、rho、alpha
     - 注意：乘号用 \times，除法用 \frac，分数用 \frac{a}{b}，圆周率用 \pi，密度用 \rho
  3. 角度/度数统一用 ^\circ，圆周率统一用 \pi
  4. 上标用 ^{n} 格式，禁止裸 ^n
  5. 物理单位用 \mathrm{}：\mathrm{kg}、\mathrm{m}、\mathrm{N}、\mathrm{Pa}、\mathrm{J}、\mathrm{W}、\mathrm{V}、\mathrm{A}、\mathrm{\Omega}
  6. JSON 转义规则：反斜杠双写，\ → \\，\\ → \\\\。换行用 \\n。cases 环境行分隔符 \\ → \\\\
     - 示例：\\(x^2=4\)\\n  所以 x=\\pm 2  // JSON 中 \\n = 换行，\\pi = \pi，\\pm = \pm
     - 示例：\[\\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}\]  // \\\\ 在 JSON 中表示 LaTeX 换行符 \\
返回格式必须严格如下（不要包含 markdown 代码块标记，使用纯 JSON）：
{
  "subject": "自动判断的科目名称",
  "extractedQuestionText": "从图片提取的原始题目文本",
  "normalizedQuestionText": "整理后的标准题目文本"
}''';

  static const _exerciseGenerationSystemPrompt = r'''你是一个专业的错题练习生成助手。

你的任务是：
1. 只基于用户提供的已保存错题、答案、步骤、知识点和错因，生成举一反三练习
2. 不重新 OCR，不重新解析原图，不改写原题答案
3. 练习必须贴近原题核心知识点，不能漂移到无关题型
4. 最多生成 3 道题，优先覆盖简单、同级、提高；如果无法保证质量，可以少于 3 道
5. 每道题尽量提供 A-D 四个选项、正确答案和简短解析

重要规则：
- 返回纯 JSON，不要包含 markdown 代码块
- 顶层只返回 generatedExercises 字段
- generatedExercises 可以是 0 到 3 道；宁可少生成，也不要生成无关、错误或占位练习
- 每道题字段包含 difficulty、question、options、answer、explanation
- answer 使用选项字母，例如 "A"；没有选择题条件时也要尽量改写成选择题
- 如果内容包含 LaTeX，必须先生成合法 JSON：所有 LaTeX 反斜杠都写成 JSON 转义形式，例如 \\frac、\\times、\\(x\\)、\\[x\\]
- 方程组或多行公式必须使用 KaTeX 兼容的 aligned 或 cases 环境，例如 \\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}，不要使用 \\newline

返回格式：
{
  "generatedExercises": [
    {
      "difficulty": "简单",
      "question": "题目",
      "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
      "answer": "A",
      "explanation": "解析"
    }
  ]
}''';

  static const _followUpSystemPrompt = r'''你是一个耐心、准确的错题答疑老师。

你的任务是：
1. 只围绕用户当前保存的这道错题答疑
2. 使用题干、答案、解题步骤、错因、知识点和学习建议作为上下文
3. 针对学生的追问给出清晰、分步骤、可理解的解释
4. 不重新 OCR，不重新分析图片，不生成举一反三练习
5. 如果用户追问超出本题范围，可以简短说明，并把回答拉回本题相关知识点

回答规则：
- 直接回答学生问题，不输出 JSON
- 不要推翻已给解析；如果发现解析可能有疑点，用“需要核对”的方式谨慎说明
- 数学、物理、化学公式用标准 LaTeX 定界符：行内 \(公式\)，独立 \[公式\]
- 排版要适合手机阅读：每段 1-3 句话，关键公式单独成行
- 普通变量、单个数字、简单符号不要频繁包成 LaTeX，例如直接写 x、+1、1；完整公式再使用 LaTeX
- 不要把一个普通句子拆成很多单字或单公式换行
- 回答尽量短而清楚，优先解释“为什么”和“下一步怎么想”
''';

  Future<String> _loadAnalysisSystemPrompt() async {
    final custom = await settingsRepository.getString('system_prompt');
    return custom?.isNotEmpty == true ? custom! : _defaultAnalysisSystemPrompt;
  }

  Future<String> _loadExtractionSystemPrompt() async {
    final custom =
        await settingsRepository.getString('extraction_system_prompt');
    return custom?.isNotEmpty == true
        ? custom!
        : _defaultExtractionSystemPrompt;
  }

  String _buildExtractionPrompt({
    required String subjectName,
    required String textHint,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('请先做题目结构化提取。');
    final subject = _parseSubject(subjectName);
    if (subject != null && subject != Subject.unknown) {
      buffer.writeln('用户当前选择的科目提示：$subjectName');
    }
    if (textHint.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('用户已有文本提示：');
      buffer.writeln(textHint);
      buffer.writeln('文本提示可能来自 OCR 或上次整理，只能作参考；图片中的图形、标注和区域关系必须以原图为准。');
    }
    buffer.writeln();
    buffer.writeln(
        '若题目包含图形/示意图，请先忠实描述原图中真实看到的图形类型、边界、标注和目标区域；看不清就写不确定，不要猜成梯形/半圆/扇形等特定题型。');
    buffer.writeln(
        '请输出 subject、extractedQuestionText、normalizedQuestionText。方程组或多行公式请使用 aligned/cases 环境，不要使用 \\newline。');
    return buffer.toString();
  }

  @visibleForTesting
  String buildExtractionPromptForTest({
    required String subjectName,
    required String textHint,
  }) {
    return _buildExtractionPrompt(
      subjectName: subjectName,
      textHint: textHint,
    );
  }

  bool isGraphicalQuestion(
    String text,
    String subjectName, {
    String? imagePath,
  }) {
    if (imagePath == null || imagePath.isEmpty) return false;
    final subject = _parseSubject(subjectName);
    if (subject != Subject.math &&
        subject != Subject.physics &&
        subject != Subject.science) {
      return false;
    }

    final normalized = text.toLowerCase();
    final hasDiagramCue =
        RegExp(r'如图|下图|上图|图中|示意图|阴影|图形|图示|图所示').hasMatch(normalized);
    final hasGraphicalFeature = RegExp(
            r'面积|周长|角|度|直角|边长|半径|直径|高|底|宽|长|三角形|矩形|长方形|正方形|梯形|圆|半圆|扇形|立方体|长方体|圆柱|圆锥|cm|厘米|mm|毫米|m\b|米|°|∠|速度|相向|每小时')
        .hasMatch(text);
    return hasDiagramCue && hasGraphicalFeature;
  }

  bool _shouldAnalyzeImageFirst(
    String text,
    String subjectName, {
    String? imagePath,
  }) {
    if (imagePath == null || imagePath.isEmpty) return false;
    final subject = _parseSubject(subjectName);
    if (subject != Subject.math &&
        subject != Subject.physics &&
        subject != Subject.science) {
      return false;
    }

    final normalized = text.toLowerCase().trim();
    if (normalized.isEmpty || normalized.length < 80) return true;
    return RegExp(r'如图|下图|上图|图中|示意图|阴影|图形|图示|图所示|看图|观察图').hasMatch(normalized);
  }

  bool _shouldAnalyzeScienceImageFirst(String text, String subjectName) {
    final subject = _parseSubject(subjectName);
    if (subject != Subject.chemistry && subject != Subject.biology) {
      return false;
    }

    final normalized = text.toLowerCase();
    final hasImageRouteCue = _hasAnySignal(normalized, <String>[
      '如图',
      '图示',
      '图中',
      '下图',
      '路线图',
      '结构式',
      '合成路线',
    ]);
    if (!hasImageRouteCue) return false;

    final conditionCount = RegExp(
      r'cl2|fecl3|naoh|h\+|hno3|h2so4|nh2oh|pd/hcl|cs2|ch3oh|乙酸酐|浓硝酸|浓硫酸|加热|催化|分子式',
    ).allMatches(normalized).length;
    final hasEnoughExtractedRoute = text.length >= 80 && conditionCount >= 2;
    return !hasEnoughExtractedRoute;
  }

  @visibleForTesting
  String buildAnalysisPromptForTest(
    String correctedText,
    String subjectName, {
    bool isGraphicalQuestion = false,
  }) {
    return _buildAnalysisPrompt(
      correctedText,
      subjectName,
      isGraphicalQuestion: isGraphicalQuestion,
    );
  }

  String _buildAnalysisPrompt(
    String correctedText,
    String subjectName, {
    bool isGraphicalQuestion = false,
  }) {
    final buffer = StringBuffer();
    if (_parseSubject(subjectName) == Subject.unknown) {
      buffer.writeln('请分析以下错题，请先根据题目内容判断科目：');
    } else {
      buffer.writeln('请分析以下$subjectName科目的错题：');
    }
    buffer.writeln();
    buffer.writeln('解析优先模式：本次只做解析，不生成额外练习题。');
    buffer.writeln();
    if (isGraphicalQuestion) {
      buffer.writeln('图片题输入说明：');
      buffer.writeln(
          '下面文本可能来自 OCR 或上一步整理，只能作为参考线索，不是已确认题干；图片中的图形、标注、区域关系和求解目标优先级最高。');
      buffer.writeln('参考文本：');
    } else {
      buffer.writeln('已确认题目文本：');
    }
    buffer.writeln(correctedText);
    buffer.writeln();
    if (isGraphicalQuestion) {
      buffer.writeln('图形/示意图题分析要求：');
      buffer.writeln('1. 第一目标是直接根据原图理解题目并完成解题，不要把人工确认作为解题前置条件。');
      buffer.writeln('2. 先读图：只依据图片确认图形结构、可见标注、边界、目标区域或求解对象；参考文本不能覆盖图片观察。');
      buffer.writeln(
          '3. 再解题：基于已读出的图形关系选择公式并计算；如果需要辅助线或构造，请说明应该连接哪些点、延长哪条线或把区域拆成哪些基础图形。');
      buffer.writeln('4. 不要因为参考文本出现面积、阴影、圆、半圆等词就硬套梯形、三角形、半圆或扇形；图形类型必须来自原图观察。');
      buffer.writeln('5. 不要为了写完整题干而强行命名外部轮廓；除非图片或题干明确说明，不要把外边框称为梯形、三角形、矩形等。');
      buffer.writeln(
          '6. 图中数字只能按可确认的标注关系使用；不能自动解释成上底、下底、高、半径或直径。无关或含义不确定的数字不要写入解题条件。');
      buffer.writeln(
          '7. reconstructedQuestionText 只重构与求解目标直接相关且能从图片确认的条件；如果目标是求某个圆/半圆/阴影区域面积，不要把无关外框条件编入题干。');
      buffer.writeln(
          '8. 只有关键标注、目标区域或半径/直径关系确实无法从图中判断，才在 mistakeReason 或 studyAdvice 中提示需要人工核对；不要因此跳过解题。');
      buffer.writeln(
          '9. 解题步骤必须基于 reconstructedQuestionText 中的可靠读图关系展开；不要在步骤中引入未确认的外部形状名称或边长含义。');
      buffer.writeln(
          '10. 必须输出 visualAssumptions 对象，用于声明读图假设和关键标注可信度；如果关键标注含义不确定，visualAssumptions.needsManualReview 必须为 true。');
      buffer.writeln(
          '11. finalAnswer、finalAnswerDerivation 和 steps 最后一条必须是同一个最终答案；如果读图假设不确定，也只能给一个“在该假设下”的最终答案，不得在 finalAnswerDerivation 中同时写互斥答案。');
      buffer.writeln();
    }
    buffer.writeln(
        '请以 JSON 格式返回完整的本题分析结果，包含 subject、reconstructedQuestionText、visualAssumptions、finalAnswer、finalAnswerDerivation、steps、aiTags、knowledgePoints、mistakeReason、studyAdvice 字段。reconstructedQuestionText 是 AI 根据题目文本或读图理解整理出的完整题干；图形题的 reconstructedQuestionText 只能包含与求解目标直接相关、且从图片可确认的条件，不要强行命名外部轮廓或解释无关数字。visualAssumptions 格式为 {"targetObject":"","targetQuestion":"","measurements":[{"label":"","meaning":"","usedInSolution":true,"evidence":"image|text|inferred","confidence":"high|medium|low"}],"solutionBasis":[""],"uncertainItems":[""],"needsManualReview":false,"reviewReason":""}；所有步骤使用的图中标注都必须先出现在 measurements 或 solutionBasis 中。finalAnswerDerivation 必须只说明 finalAnswer 的来源，不能列出与 finalAnswer 互斥的另一个答案；finalAnswer、finalAnswerDerivation、steps 最后一条必须一致。方程组或多行公式请使用 aligned/cases 环境，不要使用 \\newline。');
    return buffer.toString();
  }

  String _buildCompactAnalysisPrompt(String correctedText, String subjectName) {
    final buffer = StringBuffer();
    buffer.writeln('紧凑解析模式：上一次请求超时或服务网关失败，本次只做本题解析，不生成额外练习题。');
    if (_parseSubject(subjectName) == Subject.unknown) {
      buffer.writeln('请分析以下错题，请先根据题目内容判断科目，并优先保证 finalAnswer、steps、错因和知识点完整。');
    } else {
      buffer.writeln('请分析以下$subjectName科目的错题，优先保证 finalAnswer、steps、错因和知识点完整。');
    }
    buffer.writeln();
    buffer.writeln('题目文本：');
    buffer.writeln(correctedText);
    buffer.writeln();
    buffer.writeln(
        '只返回 JSON，字段包含 subject、reconstructedQuestionText、visualAssumptions、finalAnswer、finalAnswerDerivation、steps、aiTags、knowledgePoints、mistakeReason、studyAdvice。不要返回 generatedExercises 或 exerciseAnchor。');
    return buffer.toString();
  }

  @visibleForTesting
  String buildExerciseGenerationPromptForTest(QuestionRecord question) {
    return _buildExerciseGenerationPrompt(question);
  }

  String _buildExerciseGenerationPrompt(QuestionRecord question) {
    final analysis = question.analysisResult;
    final questionText = question.normalizedQuestionText.trim().isNotEmpty
        ? question.normalizedQuestionText.trim()
        : question.extractedQuestionText.trim();
    final buffer = StringBuffer();
    buffer.writeln('请为下面这道已保存错题生成举一反三练习。');
    buffer.writeln('本任务只生成练习题，不重新识别图片，不重新解析原题。');
    buffer.writeln();
    buffer.writeln('科目：${question.subject.name}');
    buffer.writeln();
    buffer.writeln('原题题干：');
    buffer.writeln(questionText);
    if (analysis != null) {
      buffer.writeln();
      buffer.writeln('本题答案：');
      buffer.writeln(analysis.finalAnswer);
      if (analysis.finalAnswerDerivation.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('答案来源：');
        buffer.writeln(analysis.finalAnswerDerivation);
      }
      if (analysis.steps.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('解题步骤：');
        for (final step in analysis.steps) {
          buffer.writeln('- $step');
        }
      }
      if (analysis.aiTags.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('标签：${analysis.aiTags.join('、')}');
      }
      if (analysis.knowledgePoints.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('知识点：');
        for (final point in analysis.knowledgePoints) {
          buffer.writeln('- $point');
        }
      }
      if (analysis.mistakeReason.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('错因：${analysis.mistakeReason}');
      }
      if (analysis.studyAdvice.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('学习建议：${analysis.studyAdvice}');
      }
    }
    if (question.savedExercises.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('已有练习题：');
      for (final exercise in question.savedExercises) {
        buffer.writeln('- ${exercise.question}');
      }
      buffer.writeln('请避开以上已有练习题，不要生成与已有练习题重复或高度相似的题。');
    }
    buffer.writeln();
    buffer.writeln('生成要求：');
    buffer.writeln(
        '1. generatedExercises 最多 3 道，优先覆盖简单、同级、提高；如果无法保证质量，可以少于 3 道。');
    buffer.writeln('2. 三道题都要围绕原题同一核心知识点，只改变数字、条件或表达方式，不要漂移到无关题型。');
    buffer.writeln(
        '3. 每题必须包含 question、options、answer、explanation；options 使用 A-D 四项。');
    buffer.writeln('4. 不要为了凑数量生成占位题、通用代数题或与原题无关的题；无法生成可靠练习时返回空数组。');
    buffer.writeln('5. 只返回 JSON，不要返回本题解析、OCR、标签、知识点或其他顶层字段。');
    return buffer.toString();
  }

  @visibleForTesting
  String buildFollowUpPromptForTest({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) {
    return _buildFollowUpPrompt(
      question: question,
      userQuestion: userQuestion,
      history: history,
    );
  }

  String _buildFollowUpPrompt({
    required QuestionRecord question,
    required String userQuestion,
    required List<AiFollowUpMessage> history,
  }) {
    final analysis = question.analysisResult;
    final questionText = question.normalizedQuestionText.trim().isNotEmpty
        ? question.normalizedQuestionText.trim()
        : question.extractedQuestionText.trim();
    final buffer = StringBuffer();
    buffer.writeln('请围绕下面这道已保存错题回答学生追问。');
    buffer.writeln('本任务只做答疑，不重新识别图片，不重新解析原题，不生成举一反三练习。');
    buffer.writeln();
    buffer.writeln('科目：${question.subject.name}');
    buffer.writeln();
    buffer.writeln('原题题干：');
    buffer.writeln(questionText);

    if (analysis != null) {
      buffer.writeln();
      buffer.writeln('本题答案：');
      buffer.writeln(analysis.finalAnswer);
      if (analysis.finalAnswerDerivation.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('答案来源：');
        buffer.writeln(analysis.finalAnswerDerivation);
      }
      if (analysis.steps.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('解题步骤：');
        for (final step in analysis.steps) {
          buffer.writeln('- $step');
        }
      }
      if (analysis.knowledgePoints.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('知识点：');
        for (final point in analysis.knowledgePoints) {
          buffer.writeln('- $point');
        }
      }
      if (analysis.mistakeReason.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('错因：${analysis.mistakeReason}');
      }
      if (analysis.studyAdvice.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln('学习建议：${analysis.studyAdvice}');
      }
    }

    if (history.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('本轮答疑历史：');
      for (final message in history.take(8)) {
        final role = message.role == 'assistant' ? 'AI' : '学生';
        buffer.writeln('$role：${message.content}');
      }
    }

    buffer.writeln();
    buffer.writeln('学生追问：');
    buffer.writeln(userQuestion.trim());
    buffer.writeln();
    buffer.writeln('请直接回答追问，必要时结合原题步骤解释。');
    buffer.writeln('请使用适合手机阅读的短段落；不要把单个 x、1、+1 这类简单内容单独写成公式。');
    return buffer.toString();
  }

  bool _shouldRetryTextAnalysisWithCompact(DioException e) {
    final status = e.response?.statusCode;
    return status == 524 ||
        status == 408 ||
        status == 429 ||
        status == 500 ||
        status == 502 ||
        status == 503 ||
        status == 504 ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  Future<AnalysisResult> _analyzeAfterImageFailureWithTextFallback({
    required AiProviderConfig config,
    required String systemPrompt,
    required String correctedText,
    required String subjectName,
    required String imagePath,
  }) async {
    var fallbackText = correctedText.trim();
    if (_isInstructionOnlyImagePrompt(fallbackText) &&
        File(imagePath).existsSync()) {
      try {
        final extraction = await extractQuestionStructure(
          subjectName: subjectName,
          imagePath: imagePath,
          textHint: correctedText,
        );
        final extracted = extraction.normalizedQuestionText.trim().isNotEmpty
            ? extraction.normalizedQuestionText.trim()
            : extraction.extractedQuestionText.trim();
        if (extracted.isNotEmpty) fallbackText = extracted;
      } catch (e) {
        debugPrint('[AiAnalysisService] extraction fallback failed: $e');
      }
    }

    final content = await _requestAiContent(
      config: config,
      systemPrompt: systemPrompt,
      prompt: _buildCompactAnalysisPrompt(fallbackText, subjectName),
      maxTokens: 1800,
      temperature: 0.2,
    );
    final analysis = _parseAnalysisResponse(content);
    return _markExtractionFallbackForReview(
      analysis,
      extractedText: fallbackText,
    );
  }

  Map<String, dynamic> _parseResponseJson(String content) {
    debugPrint('[AiAnalysisService] Raw AI response: $content');

    final jsonStr = _stripJsonFence(content);

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      debugPrint('[AiAnalysisService] Parsed JSON keys: ${map.keys.toList()}');
      return _normalizeParsedJsonStrings(map);
    } catch (e) {
      final repairedJson = _repairInvalidJsonStringEscapes(jsonStr);
      if (repairedJson != jsonStr) {
        try {
          final map = jsonDecode(repairedJson) as Map<String, dynamic>;
          debugPrint(
              '[AiAnalysisService] Parsed repaired JSON keys: ${map.keys.toList()}');
          return _normalizeParsedJsonStrings(map);
        } catch (repairedError) {
          debugPrint(
              '[AiAnalysisService] Repaired parse error: $repairedError');
          final recoveredMap = _recoverFlatJsonFields(repairedJson);
          if (recoveredMap.isNotEmpty) {
            debugPrint(
                '[AiAnalysisService] Recovered JSON keys: ${recoveredMap.keys.toList()}');
            return _normalizeParsedJsonStrings(recoveredMap);
          }
        }
      }

      debugPrint('[AiAnalysisService] Parse error: $e');
      throw AiAnalysisException('解析 AI 响应失败: $e');
    }
  }

  String _stripJsonFence(String content) {
    var jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }
    final firstJsonBrace = jsonStr.indexOf('{');
    final lastJsonBrace = jsonStr.lastIndexOf('}');
    if (firstJsonBrace >= 0 && lastJsonBrace > firstJsonBrace) {
      jsonStr = jsonStr.substring(firstJsonBrace, lastJsonBrace + 1);
    }
    return jsonStr;
  }

  Map<String, dynamic> _recoverFlatJsonFields(String jsonStr) {
    final result = <String, dynamic>{};
    final keyPattern = RegExp(r'"([^"\\]+)"\s*:');
    final matches = keyPattern.allMatches(jsonStr).toList();

    for (var i = 0; i < matches.length; i++) {
      final key = matches[i].group(1)!;
      final valueStart = matches[i].end;
      final valueEnd = i + 1 < matches.length
          ? matches[i + 1].start
          : jsonStr.lastIndexOf('}');
      if (valueEnd <= valueStart) continue;

      final rawValue = jsonStr
          .substring(valueStart, valueEnd)
          .trim()
          .replaceFirst(RegExp(r',$'), '')
          .trim();
      if (rawValue.startsWith('"')) {
        result[key] = _recoverJsonStringValue(rawValue);
      } else if (rawValue.startsWith('[')) {
        result[key] = _recoverJsonStringArray(rawValue);
      }
    }

    return result;
  }

  String _recoverJsonStringValue(String rawValue) {
    final start = rawValue.indexOf('"');
    final end = rawValue.lastIndexOf('"');
    if (start < 0 || end <= start) return '';
    return rawValue
        .substring(start + 1, end)
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r');
  }

  List<String> _recoverJsonStringArray(String rawValue) {
    final items = <String>[];
    final pattern = RegExp(r'"((?:\\.|[^"\\])*)"', dotAll: true);
    for (final match in pattern.allMatches(rawValue)) {
      items
          .add(match.group(1)!.replaceAll(r'\n', '\n').replaceAll(r'\r', '\r'));
    }
    return items;
  }

  Map<String, dynamic> _normalizeParsedJsonStrings(Map<String, dynamic> map) {
    return map
        .map((key, value) => MapEntry(key, _normalizeParsedJsonValue(value)));
  }

  dynamic _normalizeParsedJsonValue(dynamic value) {
    if (value is String) return _normalizeLatexControlEscapes(value);
    if (value is List) return value.map(_normalizeParsedJsonValue).toList();
    if (value is Map) {
      return value
          .map((key, item) => MapEntry(key, _normalizeParsedJsonValue(item)));
    }
    return value;
  }

  String _normalizeLatexControlEscapes(String value) {
    return value
        .replaceAll(r'\\', r'\')
        .replaceAll('\b', r'\b')
        .replaceAll('\f', r'\f')
        .replaceAll('\t', r'\t');
  }

  String _repairInvalidJsonStringEscapes(String jsonStr) {
    final buffer = StringBuffer();
    var inString = false;
    var escapeRun = 0;

    for (var index = 0; index < jsonStr.length; index++) {
      final char = jsonStr[index];
      final escaped = escapeRun.isOdd;

      if (char == '"' && !escaped) {
        inString = !inString;
        buffer.write(char);
        escapeRun = 0;
        continue;
      }

      if (inString && (char == '\n' || char == '\r')) {
        buffer.write(char == '\n' ? r'\n' : r'\r');
        escapeRun = 0;
        continue;
      }

      if (char == r'\') {
        if (inString) {
          if (escaped) {
            buffer.write(char);
            escapeRun++;
            continue;
          }
          final next = index + 1 < jsonStr.length ? jsonStr[index + 1] : '';
          final nextNext = index + 2 < jsonStr.length ? jsonStr[index + 2] : '';
          if (next.isEmpty || !_isValidJsonEscape(next, nextNext)) {
            buffer.write(r'\\');
            escapeRun = 0;
            continue;
          }
        }

        buffer.write(char);
        escapeRun++;
        continue;
      }

      buffer.write(char);
      escapeRun = 0;
    }

    return buffer.toString();
  }

  bool _isValidJsonEscape(String next, String nextNext) {
    if ('"\\/u'.contains(next)) return true;
    return 'bfnrt'.contains(next) && !_isAsciiLetter(nextNext);
  }

  bool _isAsciiLetter(String value) {
    if (value.isEmpty) return false;
    final code = value.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  AiQuestionExtractionResult _parseExtractionResponse(String content) {
    final map = _parseResponseJson(content);
    final subject = _parseSubject((map['subject'] as String?) ?? '');
    final extractedQuestionText = _normalizeExtractedQuestionText(
      (map['extractedQuestionText'] as String?)?.trim() ?? '',
    );
    final normalizedQuestionText = _normalizeExtractedQuestionText(
      (map['normalizedQuestionText'] as String?)?.trim() ?? '',
    );
    final splitSeed = normalizedQuestionText.isNotEmpty
        ? normalizedQuestionText
        : extractedQuestionText;

    return AiQuestionExtractionResult(
      subject: subject,
      extractedQuestionText: extractedQuestionText,
      normalizedQuestionText: normalizedQuestionText,
      splitResult: _defaultSplitQuestionCandidates(splitSeed, subject: subject),
    );
  }

  AnalysisResult _parseAnalysisResponse(String content) {
    final map = _parseResponseJson(content);

    Subject? subject;
    final subjectStr = map['subject'] as String?;
    if (subjectStr != null && subjectStr.isNotEmpty) {
      debugPrint('[AiAnalysisService] AI returned subject: $subjectStr');
      subject = _parseSubject(subjectStr);
      debugPrint('[AiAnalysisService] Parsed subject: $subject');
    }

    final visualAssumptions = _parseVisualAssumptions(map['visualAssumptions']);

    return ParsedAnalysisResult(
      rawContent: content,
      subject: subject,
      finalAnswer: _normalizeExtractedQuestionText(
        map['finalAnswer'] as String? ?? '',
      ),
      finalAnswerDerivation: _normalizeExtractedQuestionText(
        map['finalAnswerDerivation'] as String? ?? '',
      ),
      reconstructedQuestionText: _normalizeExtractedQuestionText(
        map['reconstructedQuestionText'] as String? ?? '',
      ),
      visualAssumptions: visualAssumptions,
      visualAssumptionStatus: _visualAssumptionStatus(visualAssumptions),
      steps: List<String>.from(map['steps'] as List? ?? <String>[])
          .map(_normalizeExtractedQuestionText)
          .toList(),
      aiTags: List<String>.from(map['aiTags'] as List? ?? <String>[]),
      knowledgePoints:
          List<String>.from(map['knowledgePoints'] as List? ?? <String>[])
              .map(_normalizeExtractedQuestionText)
              .toList(),
      mistakeReason: _normalizeExtractedQuestionText(
        map['mistakeReason'] as String? ?? '',
      ),
      studyAdvice: _normalizeExtractedQuestionText(
        map['studyAdvice'] as String? ?? '',
      ),
    );
  }

  @visibleForTesting
  AiQuestionExtractionResult parseExtractionResultForTest(String content) {
    return _parseExtractionResponse(content);
  }

  List<GeneratedExercise> extractGeneratedExercisesFromContent(
    String content, {
    required String questionId,
    AnalysisResult? analysis,
    String? sourceQuestionText,
    List<GeneratedExercise> existingExercises = const <GeneratedExercise>[],
  }) {
    final map = _parseResponseJson(content);
    return _parseGeneratedExercises(
      map,
      questionId: questionId,
      analysis: analysis,
      sourceQuestionText: sourceQuestionText,
      existingExercises: existingExercises,
    );
  }

  List<GeneratedExercise> extractGeneratedExercises(
    AnalysisResult analysis, {
    required String questionId,
    String? sourceQuestionText,
    List<GeneratedExercise> existingExercises = const <GeneratedExercise>[],
  }) {
    return _filterDuplicateGeneratedExercises(
      _defaultGeneratedExercises(
        questionId,
        analysis: analysis,
        sourceQuestionText: sourceQuestionText,
      ),
      existingExercises: existingExercises,
    );
  }

  List<GeneratedExercise> _parseGeneratedExercises(
    Map<String, dynamic> map, {
    required String questionId,
    AnalysisResult? analysis,
    String? sourceQuestionText,
    List<GeneratedExercise> existingExercises = const <GeneratedExercise>[],
  }) {
    final parsedAnalysis = analysis ?? _analysisFromParsedMap(map);
    if (_shouldSuppressGeneratedExercises(
      parsedAnalysis,
      sourceQuestionText: sourceQuestionText,
    )) {
      return const <GeneratedExercise>[];
    }

    final rawExercises = map['generatedExercises'];
    if (rawExercises is! List || rawExercises.isEmpty) {
      return _filterDuplicateGeneratedExercises(
        _defaultGeneratedExercises(
          questionId,
          analysis: parsedAnalysis,
          sourceQuestionText: sourceQuestionText,
        ),
        existingExercises: existingExercises,
      );
    }

    final sourceProfile = _buildExerciseTopicProfile(
      sourceQuestionText: sourceQuestionText,
      analysis: parsedAnalysis,
    );
    final now = DateTime.now();
    final parsed = <GeneratedExercise>[];
    final usedQuestionKeys = existingExercises
        .map((exercise) => _exerciseDuplicateKey(exercise.question))
        .where((key) => key.isNotEmpty)
        .toSet();

    for (var index = 0; index < rawExercises.length; index++) {
      final item = rawExercises[index];
      if (item is! Map) continue;
      final exerciseMap = Map<String, dynamic>.from(item);
      final id = (exerciseMap['id'] as String?)?.trim();
      final question = _normalizeExtractedQuestionText(
        (exerciseMap['question'] as String?)?.trim() ?? '',
      );
      if (question.isEmpty) continue;

      List<String>? options;
      final rawOptions = exerciseMap['options'];
      if (rawOptions is List) {
        final normalizedOptions = rawOptions
            .map((option) => option?.toString().trim() ?? '')
            .where((option) => option.isNotEmpty)
            .map(_normalizeExtractedQuestionText)
            .toList();
        if (normalizedOptions.isNotEmpty) {
          options = normalizedOptions;
        }
      }

      final diagramRaw = exerciseMap['diagramData'];
      final diagramParsed = _parseDiagramData(diagramRaw);

      final exercise = GeneratedExercise(
        id: id != null && id.isNotEmpty ? id : 'gen_${questionId}_${index + 1}',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: _normalizeExerciseDifficulty(
          (exerciseMap['difficulty'] as String?)?.trim(),
        ),
        question: question,
        answer: _normalizeExtractedQuestionText(
          (exerciseMap['answer'] as String?)?.trim() ?? '',
        ),
        explanation: _normalizeExtractedQuestionText(
          (exerciseMap['explanation'] as String?)?.trim() ?? '',
        ),
        createdAt: now,
        order: index,
        options: options,
        diagramData: diagramParsed,
      );

      final acceptable =
          _isGeneratedExerciseAcceptable(exercise, sourceProfile);
      if (acceptable) {
        final duplicateKey = _exerciseDuplicateKey(exercise.question);
        if (duplicateKey.isEmpty || usedQuestionKeys.contains(duplicateKey)) {
          continue;
        }
        usedQuestionKeys.add(duplicateKey);
        parsed.add(GeneratedExercise(
          id: exercise.id,
          questionId: exercise.questionId,
          generationMode: exercise.generationMode,
          difficulty: exercise.difficulty,
          question: exercise.question,
          answer: exercise.answer,
          explanation: exercise.explanation,
          createdAt: exercise.createdAt,
          order: parsed.length,
          options: exercise.options,
          diagramData: exercise.diagramData,
        ));
      }
    }

    if (sourceProfile.hasStrongSignal) {
      final defaults = _defaultGeneratedExercises(
        questionId,
        analysis: parsedAnalysis,
        sourceQuestionText: sourceQuestionText,
      );
      if (defaults.isEmpty) {
        return _selectPracticeExerciseSet(
          parsed,
          questionId: questionId,
          now: now,
        );
      }
      return _filterDuplicateGeneratedExercises(
        _mergeGeneratedExercisesWithDefaults(
          parsed,
          defaults,
          questionId: questionId,
          now: now,
        ),
        existingExercises: existingExercises,
      );
    }

    final expectedCount = rawExercises.length >= 3 ? 3 : rawExercises.length;
    if (parsed.length < expectedCount) {
      return _filterDuplicateGeneratedExercises(
        _defaultGeneratedExercises(
          questionId,
          analysis: parsedAnalysis,
          sourceQuestionText: sourceQuestionText,
        ),
        existingExercises: existingExercises,
      );
    }

    return _selectPracticeExerciseSet(
      parsed,
      questionId: questionId,
      now: now,
    );
  }

  List<GeneratedExercise> _filterDuplicateGeneratedExercises(
    List<GeneratedExercise> exercises, {
    required List<GeneratedExercise> existingExercises,
  }) {
    if (exercises.isEmpty) return exercises;
    final usedQuestionKeys = existingExercises
        .map((exercise) => _exerciseDuplicateKey(exercise.question))
        .where((key) => key.isNotEmpty)
        .toSet();
    final filtered = <GeneratedExercise>[];
    for (final exercise in exercises) {
      final key = _exerciseDuplicateKey(exercise.question);
      if (key.isEmpty || usedQuestionKeys.contains(key)) continue;
      usedQuestionKeys.add(key);
      filtered.add(GeneratedExercise(
        id: exercise.id,
        questionId: exercise.questionId,
        generationMode: exercise.generationMode,
        difficulty: exercise.difficulty,
        question: exercise.question,
        answer: exercise.answer,
        explanation: exercise.explanation,
        createdAt: exercise.createdAt,
        order: filtered.length,
        options: exercise.options,
        userAnswer: exercise.userAnswer,
        roundIndex: exercise.roundIndex,
        roundTotal: exercise.roundTotal,
        roundGroupId: exercise.roundGroupId,
        sourceExerciseId: exercise.sourceExerciseId,
        diagramData: exercise.diagramData,
      ));
    }
    return filtered;
  }

  String _exerciseDuplicateKey(String question) {
    return question
        .toLowerCase()
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\[', '')
        .replaceAll(r'\]', '')
        .replaceAll(r'\mathrm', '')
        .replaceAll(RegExp(r'[\s`$\\{}（）【】\[\]，。,.；;：:！!？?、]+'), '')
        .trim();
  }

  List<GeneratedExercise> _mergeGeneratedExercisesWithDefaults(
    List<GeneratedExercise> accepted,
    List<GeneratedExercise> defaults, {
    required String questionId,
    required DateTime now,
  }) {
    const difficulties = <String>['简单', '同级', '提高'];
    final byDifficulty = <String, GeneratedExercise>{};

    for (final exercise in accepted) {
      byDifficulty.putIfAbsent(exercise.difficulty, () => exercise);
    }

    final merged = <GeneratedExercise>[];
    for (var index = 0; index < difficulties.length; index++) {
      final difficulty = difficulties[index];
      final fallback = defaults.firstWhere(
        (exercise) => exercise.difficulty == difficulty,
        orElse: () => defaults[index],
      );
      final selected = byDifficulty[difficulty] ?? fallback;
      final selectedIsFallback = identical(selected, fallback);
      merged.add(GeneratedExercise(
        id: selected.id.isNotEmpty
            ? selected.id
            : 'gen_${questionId}_${index + 1}',
        questionId: questionId,
        generationMode: selected.generationMode,
        difficulty: difficulty,
        question: selected.question,
        answer: selected.answer,
        explanation: selected.explanation,
        createdAt: selectedIsFallback ? fallback.createdAt : now,
        order: index,
        options: selected.options,
        diagramData: selected.diagramData,
      ));
    }
    return merged;
  }

  List<GeneratedExercise> _selectPracticeExerciseSet(
    List<GeneratedExercise> exercises, {
    required String questionId,
    required DateTime now,
  }) {
    const difficulties = <String>['简单', '同级', '提高'];
    final selected = <GeneratedExercise>[];
    final used = <String>{};

    for (final difficulty in difficulties) {
      final match = exercises
          .where((exercise) => exercise.difficulty == difficulty)
          .cast<GeneratedExercise?>()
          .firstWhere((exercise) => exercise != null, orElse: () => null);
      if (match != null) {
        selected.add(match);
        used.add(match.id);
      }
    }

    for (final exercise in exercises) {
      if (selected.length >= 3) break;
      if (used.contains(exercise.id)) continue;
      selected.add(exercise);
      used.add(exercise.id);
    }

    return selected.asMap().entries.map((entry) {
      final exercise = entry.value;
      return GeneratedExercise(
        id: exercise.id.isNotEmpty
            ? exercise.id
            : 'gen_${questionId}_${entry.key + 1}',
        questionId: questionId,
        generationMode: exercise.generationMode,
        difficulty: difficulties.length > entry.key
            ? difficulties[entry.key]
            : exercise.difficulty,
        question: exercise.question,
        answer: exercise.answer,
        explanation: exercise.explanation,
        createdAt: exercise.createdAt,
        order: entry.key,
        options: exercise.options,
        diagramData: exercise.diagramData,
      );
    }).toList();
  }

  String _normalizeExerciseDifficulty(String? difficulty) {
    final normalized = difficulty?.trim() ?? '';
    switch (normalized) {
      case '简单':
      case '基础':
      case '容易':
        return '简单';
      case '同级':
      case '中等':
      case '普通':
      case '巩固':
        return '同级';
      case '提高':
      case '提升':
      case '困难':
      case '挑战':
      case '拓展':
        return '提高';
      default:
        return normalized.isEmpty ? '同级' : normalized;
    }
  }

  Map<String, dynamic>? _parseDiagramData(Object? value) {
    if (value is! Map) return null;
    final data = Map<String, dynamic>.from(value);
    final elements = data['elements'];
    if (elements is! List || elements.isEmpty) return null;
    return data;
  }

  VisualAssumptions? _parseVisualAssumptions(Object? value) {
    if (value is Map<String, dynamic>) {
      return VisualAssumptions.fromJson(value);
    }
    if (value is Map) {
      return VisualAssumptions.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  VisualAssumptionStatus _visualAssumptionStatus(
    VisualAssumptions? assumptions,
  ) {
    if (assumptions == null || !assumptions.hasContent) {
      return VisualAssumptionStatus.none;
    }
    if (assumptions.needsManualReview ||
        assumptions.uncertainItems.isNotEmpty ||
        assumptions.measurements.any((item) =>
            item.usedInSolution &&
            _isReviewLevelVisualAssumption(item.confidence))) {
      return VisualAssumptionStatus.needsReview;
    }
    return VisualAssumptionStatus.reliable;
  }

  bool _isReviewLevelVisualAssumption(String confidence) {
    final normalized = confidence.toLowerCase().trim();
    return normalized == 'low' ||
        normalized == 'medium' ||
        normalized == '中' ||
        normalized == '中等' ||
        normalized == '低';
  }

  String _visualAssumptionReviewNote(VisualAssumptions? assumptions) {
    final reason = assumptions?.reviewReason.trim() ?? '';
    if (reason.isNotEmpty) return reason;
    final uncertainItems = assumptions?.uncertainItems ?? const <String>[];
    if (uncertainItems.isNotEmpty) {
      return '图中关键标注含义需核对：${uncertainItems.join('、')}。';
    }
    return '图中关键标注含义需核对，当前解析仅作可能解法。';
  }

  AnalysisResult _analysisFromParsedMap(Map<String, dynamic> map) {
    List<String> listField(String key) {
      final value = map[key];
      if (value is! List) return const <String>[];
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final visualAssumptions = _parseVisualAssumptions(map['visualAssumptions']);

    return AnalysisResult(
      subject: _parseSubject(map['subject']?.toString() ?? ''),
      finalAnswer: map['finalAnswer']?.toString() ?? '',
      finalAnswerDerivation: map['finalAnswerDerivation']?.toString() ?? '',
      reconstructedQuestionText:
          map['reconstructedQuestionText']?.toString() ?? '',
      visualAssumptions: visualAssumptions,
      visualAssumptionStatus: _visualAssumptionStatus(visualAssumptions),
      steps: listField('steps'),
      aiTags: listField('aiTags'),
      knowledgePoints: listField('knowledgePoints'),
      mistakeReason: map['mistakeReason']?.toString() ?? '',
      studyAdvice: map['studyAdvice']?.toString() ?? '',
    );
  }

  bool _isGeneratedExerciseAcceptable(
    GeneratedExercise exercise,
    _ExerciseTopicProfile sourceProfile,
  ) {
    if (exercise.question.trim().isEmpty ||
        exercise.answer.trim().isEmpty ||
        exercise.explanation.trim().isEmpty) {
      return false;
    }

    if (_hasGeneratedExerciseSelfInvalidation(exercise)) {
      return false;
    }

    if (_hasGeneratedExerciseAnswerConflict(exercise)) {
      return false;
    }

    final normalizedAnswer = exercise.answer.trim().toUpperCase();
    if (!RegExp(r'^[A-D]$').hasMatch(normalizedAnswer)) return false;

    final options = exercise.options;
    if (options == null || options.length != 4) return false;
    final optionLetters = options
        .map((option) =>
            option.trim().isEmpty ? '' : option.trim()[0].toUpperCase())
        .toSet();
    if (!optionLetters.containsAll(const <String>{'A', 'B', 'C', 'D'})) {
      return false;
    }

    if (_requiresExerciseDiagram(sourceProfile) &&
        exercise.diagramData == null) {
      return false;
    }
    if (_hasInvalidExteriorAngleDiagram(exercise)) {
      return false;
    }

    if (!sourceProfile.hasStrongSignal) return true;

    final exerciseText =
        '${exercise.question} ${exercise.explanation} ${options.join(' ')}';
    if (!_exerciseMatchesTopicAnchor(exerciseText, sourceProfile)) {
      return false;
    }
    if (!_exerciseMatchesSourceTarget(exerciseText, sourceProfile)) {
      return false;
    }
    if (sourceProfile.domain == _ExerciseDomain.planeGeometryArea &&
        _hasForbiddenPlaneAreaDrift(exerciseText)) {
      return false;
    }

    final exerciseProfile = _buildExerciseTopicProfile(
      sourceQuestionText: exerciseText,
      profileSource: _TopicProfileSource.exercise,
    );
    return _isExerciseProfileCompatible(sourceProfile, exerciseProfile);
  }

  bool _hasInvalidExteriorAngleDiagram(GeneratedExercise exercise) {
    final diagram = exercise.diagramData;
    if (diagram == null) return false;

    final spec = _exteriorAngleSpec(exercise.question);
    if (spec == null) {
      return false;
    }

    final labels = _diagramPointLabels(diagram);
    final vertex = labels[spec.vertex];
    final base = labels[spec.basePoint];
    final extension = labels[spec.extensionPoint];
    if (vertex == null || base == null || extension == null) return true;

    final baseRay = _Point2(base.x - vertex.x, base.y - vertex.y);
    final extensionRay =
        _Point2(extension.x - vertex.x, extension.y - vertex.y);
    final baseLength = math.sqrt(baseRay.x * baseRay.x + baseRay.y * baseRay.y);
    final extensionLength = math.sqrt(
        extensionRay.x * extensionRay.x + extensionRay.y * extensionRay.y);
    if (baseLength < 0.001 || extensionLength < 0.001) return true;

    final cross =
        (baseRay.x * extensionRay.y - baseRay.y * extensionRay.x).abs() /
            (baseLength * extensionLength);
    final dot = baseRay.x * extensionRay.x + baseRay.y * extensionRay.y;
    if (cross > 0.08 || dot >= 0) return true;

    final hasExtensionLine = _hasDiagramLineBetween(diagram, vertex, extension);
    if (!hasExtensionLine) return true;

    final hasExternalArc = _diagramElements(diagram).any((element) {
      if (element['type'] != 'angleArc') return false;
      final vx = element['vx'];
      final vy = element['vy'];
      if (vx is! num || vy is! num) return false;
      if (!_isNear(_Point2(vx.toDouble(), vy.toDouble()), vertex)) {
        return false;
      }
      final role = element['role']?.toString().toLowerCase();
      return role == 'external' || role == 'explicit';
    });
    return !hasExternalArc;
  }

  _ExteriorAngleSpec? _exteriorAngleSpec(String question) {
    final text = question
        .toLowerCase()
        .replaceAll(r'\angle', '∠')
        .replaceAll(RegExp(r'\\[()\[\]{}]'), '')
        .replaceAll(RegExp(r'[\\()\[\]{}\s]'), '');
    if (!text.contains('外角') || !text.contains('延长')) return null;

    final extensionMatch =
        RegExp(r'点?([a-z])在([a-z])([a-z])的?延长线上').firstMatch(text);
    final angleMatch = RegExp(r'∠([a-z])([a-z])([a-z])').firstMatch(text);
    if (extensionMatch == null || angleMatch == null) return null;

    final extensionPoint = angleMatch.group(1)!;
    final vertex = angleMatch.group(2)!;
    final namedExtensionPoint = extensionMatch.group(1)!;
    final segmentStart = extensionMatch.group(2)!;
    final segmentEnd = extensionMatch.group(3)!;

    if (namedExtensionPoint != extensionPoint) return null;
    if (vertex == segmentStart) {
      return _ExteriorAngleSpec(
        extensionPoint: extensionPoint,
        vertex: vertex,
        basePoint: segmentEnd,
      );
    }
    if (vertex == segmentEnd) {
      return _ExteriorAngleSpec(
        extensionPoint: extensionPoint,
        vertex: vertex,
        basePoint: segmentStart,
      );
    }
    return null;
  }

  Map<String, _Point2> _diagramPointLabels(Map<String, dynamic> diagram) {
    final labels = <String, _Point2>{};
    for (final element in _diagramElements(diagram)) {
      final type = element['type'];
      if (type == 'polygon') {
        final points = element['points'];
        final rawLabels = element['labels'];
        if (points is! List || rawLabels is! List) continue;
        for (var i = 0; i < rawLabels.length && i < points.length; i++) {
          final labelMap = rawLabels[i];
          final point = points[i];
          if (labelMap is! Map || point is! List || point.length < 2) continue;
          final label = labelMap['text']?.toString().trim().toLowerCase();
          final x = point[0];
          final y = point[1];
          if (label == null || label.isEmpty || x is! num || y is! num) {
            continue;
          }
          labels[label] = _Point2(x.toDouble(), y.toDouble());
        }
      } else if (type == 'point') {
        final label = element['label']?.toString().trim().toLowerCase();
        final x = element['x'];
        final y = element['y'];
        if (label == null || label.isEmpty || x is! num || y is! num) {
          continue;
        }
        labels[label] = _Point2(x.toDouble(), y.toDouble());
      }
    }
    return labels;
  }

  Iterable<Map<String, dynamic>> _diagramElements(
      Map<String, dynamic> diagram) {
    final elements = diagram['elements'];
    if (elements is! List) return const Iterable<Map<String, dynamic>>.empty();
    return elements.whereType<Map>().map(Map<String, dynamic>.from);
  }

  bool _hasDiagramLineBetween(
    Map<String, dynamic> diagram,
    _Point2 a,
    _Point2 b,
  ) {
    return _diagramElements(diagram).any((element) {
      if (element['type'] != 'line') return false;
      final x1 = element['x1'];
      final y1 = element['y1'];
      final x2 = element['x2'];
      final y2 = element['y2'];
      if (x1 is! num || y1 is! num || x2 is! num || y2 is! num) {
        return false;
      }
      final p1 = _Point2(x1.toDouble(), y1.toDouble());
      final p2 = _Point2(x2.toDouble(), y2.toDouble());
      return (_isNear(p1, a) && _isNear(p2, b)) ||
          (_isNear(p1, b) && _isNear(p2, a));
    });
  }

  bool _isNear(_Point2 a, _Point2 b, {double threshold = 0.04}) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy <= threshold * threshold;
  }

  bool _exerciseMatchesSourceTarget(
    String exerciseText,
    _ExerciseTopicProfile sourceProfile,
  ) {
    if (sourceProfile.domain != _ExerciseDomain.planeGeometryArea) {
      return true;
    }

    if (sourceProfile.variant == _ExerciseVariant.compositeSemicircleArea) {
      return _hasCompositeAreaTargetSignal(exerciseText) &&
          !_targetsOnlySemicircleArea(exerciseText);
    }

    return true;
  }

  bool _targetsOnlySemicircleArea(String text) {
    final normalized = text.toLowerCase();
    final asksSemicircleArea = _hasAnySignal(normalized, <String>[
      '求半圆面积',
      '求该半圆的面积',
      '求这个半圆的面积',
      '求阴影半圆面积',
    ]);
    return asksSemicircleArea && !_hasCompositeAreaTargetSignal(normalized);
  }

  bool _hasGeneratedExerciseSelfInvalidation(GeneratedExercise exercise) {
    final text =
        '${exercise.question} ${exercise.explanation} ${exercise.options?.join(' ') ?? ''}';
    return _hasAnySignal(text, <String>[
      '占位练习',
      '原题图片或文本缺失',
      '题干缺失',
      '没有可识别',
      '无法识别',
      '选项中没有',
      '没有该值',
      '无正确选项',
      '选项设计不严谨',
      '选项有误',
      '原选项设计',
      '需重新检查',
      '需要重新检查',
      '修正后应',
      '应为修正',
      '无法从选项',
      '题目不严谨',
      '本题无解',
    ]);
  }

  bool _requiresExerciseDiagram(_ExerciseTopicProfile sourceProfile) {
    return sourceProfile.domain == _ExerciseDomain.planeGeometryArea ||
        sourceProfile.domain == _ExerciseDomain.planeGeometryAngle ||
        sourceProfile.domain == _ExerciseDomain.planeGeometryLength;
  }

  bool _hasGeneratedExerciseAnswerConflict(GeneratedExercise exercise) {
    final answer = exercise.answer.trim().toUpperCase();
    if (!RegExp(r'^[A-D]$').hasMatch(answer)) return false;
    final text = exercise.explanation.replaceAll(' ', '').toUpperCase();
    final explicitAnswerMatches = RegExp(
      r'(?:答案(?:是|为)?|正确答案(?:是|为)?|正确选项(?:是|为)?|应选|应为|选择|选)([A-D])',
    ).allMatches(text);
    for (final match in explicitAnswerMatches) {
      final stated = match.group(1);
      if (stated != null && stated != answer) return true;
    }

    final options = exercise.options;
    if (options == null || options.length != 4) return false;
    final answerIndex = answer.codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (answerIndex < 0 || answerIndex >= options.length) return false;

    final selectedTokens = _mathConclusionTokens(options[answerIndex]);
    final explanationTokens = _mathConclusionTokens(exercise.explanation);
    if (selectedTokens.isEmpty || explanationTokens.isEmpty) return false;
    if (selectedTokens.intersection(explanationTokens).isNotEmpty) {
      return false;
    }

    final distractorTokens = <String>{};
    for (var i = 0; i < options.length; i++) {
      if (i == answerIndex) continue;
      distractorTokens.addAll(_mathConclusionTokens(options[i]));
    }
    return explanationTokens.intersection(distractorTokens).isNotEmpty;
  }

  Set<String> _mathConclusionTokens(String text) {
    final normalized = text
        .replaceAll('π', r'\pi')
        .replaceAll('，', ' ')
        .replaceAll('。', ' ')
        .replaceAll('；', ' ')
        .replaceAll(';', ' ')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceFirst(RegExp(r'^[A-Da-d][\.、．:]'), '')
        .toLowerCase();
    final tokens = <String>{};

    for (final match in RegExp(
      r'\d+(?:\.\d+)?[-+]\d+(?:\.\d+)?(?:\\pi|pi)(?:/\d+(?:\.\d+)?)?',
    ).allMatches(normalized)) {
      final token = match.group(0);
      if (token != null) tokens.add(_normalizeMathToken(token));
    }

    for (final match in RegExp(
      r'\d+(?:\.\d+)?(?:\\pi|pi)(?:/\d+(?:\.\d+)?)?',
    ).allMatches(normalized)) {
      final token = match.group(0);
      if (token != null) tokens.add(_normalizeMathToken(token));
    }

    for (final match
        in RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}').allMatches(normalized)) {
      final numerator = match.group(1);
      final denominator = match.group(2);
      if (numerator != null && denominator != null) {
        tokens.add(_normalizeMathToken('$numerator/$denominator'));
      }
    }
    return tokens.where((token) => token.isNotEmpty).toSet();
  }

  String _normalizeMathToken(String token) {
    return token
        .replaceAll('π', r'\pi')
        .replaceAll('pi', r'\pi')
        .replaceAllMapped(
          RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}'),
          (match) => '${match.group(1)}/${match.group(2)}',
        )
        .replaceAll(RegExp(r'[\\(){}\[\]\s]'), '');
  }

  bool _hasForbiddenPlaneAreaDrift(String text) {
    final normalized = text.toLowerCase();
    return _hasAnySignal(normalized, <String>[
      '体积',
      '立体几何',
      '圆柱',
      '圆锥',
      '长方体',
      '正方体',
      '棱柱',
      '棱锥',
      'v=',
      r'\frac{1}{3}\pi',
      r'\pi r^2 h',
      'πr^2h',
      'π r^2 h',
      '函数',
      '方程组',
    ]);
  }

  bool _isExerciseProfileCompatible(
    _ExerciseTopicProfile source,
    _ExerciseTopicProfile exercise,
  ) {
    if (source.domain != exercise.domain) return false;
    if (source.object == _ExerciseObject.circleFamily) {
      if (exercise.object != _ExerciseObject.circleFamily) return false;
    } else if (source.object != _ExerciseObject.generic &&
        exercise.object != source.object) {
      return false;
    }
    if (source.methods.isNotEmpty && exercise.methods.isNotEmpty) {
      if (source.methods.intersection(exercise.methods).isEmpty) return false;
    }
    if (source.variant != null && exercise.variant != null) {
      return source.variant == exercise.variant;
    }
    return true;
  }

  bool _exerciseMatchesTopicAnchor(
    String text,
    _ExerciseTopicProfile profile,
  ) {
    final normalized = text.toLowerCase();
    switch (profile.domain) {
      case _ExerciseDomain.organicChemistry:
        return _hasOrganicChemistrySignal(normalized);
      case _ExerciseDomain.physicsCircuit:
        return _hasPhysicsCircuitSignal(normalized);
      case _ExerciseDomain.functionEvaluation:
        return _hasFunctionSignal(normalized) &&
            _hasAnySignal(normalized,
                <String>['求', '代入', '函数值', 'f(', 'g(', 'h(', 'f（', 'g（', 'h（']);
      case _ExerciseDomain.proportionalRelation:
        return _hasProportionalRelationSignal(normalized);
      case _ExerciseDomain.solidGeometryVolume:
        return _hasVolumeSignal(normalized);
      case _ExerciseDomain.equationSystem:
        return _hasEquationSystemSignal(normalized);
      case _ExerciseDomain.planeGeometryAngle:
        return _hasTriangleAngleSignal(normalized);
      case _ExerciseDomain.planeGeometryArea:
        if (_hasForbiddenPlaneAreaDrift(normalized)) return false;
        return _hasPlaneGeometryAreaSignal(normalized);
      case _ExerciseDomain.planeGeometryLength:
        return _hasPlaneGeometryLengthSignal(normalized, profile);
      case _ExerciseDomain.algebraEquation:
        if (profile.object == _ExerciseObject.quadraticEquation) {
          return _hasQuadraticRootSignal(normalized);
        }
        return _hasLinearEquationSignal(normalized);
      case _ExerciseDomain.generic:
        return true;
    }
  }

  _ExerciseTopicProfile _buildExerciseTopicProfile({
    String? sourceQuestionText,
    AnalysisResult? analysis,
    _TopicProfileSource profileSource = _TopicProfileSource.sourceQuestion,
  }) {
    final text = <String>[
      sourceQuestionText ?? '',
      analysis?.subject?.name ?? '',
      analysis?.subject?.label ?? '',
      analysis?.reconstructedQuestionText ?? '',
      ...?analysis?.aiTags,
      ...?analysis?.knowledgePoints,
      analysis?.finalAnswer ?? '',
      ...?analysis?.steps,
      analysis?.mistakeReason ?? '',
      analysis?.studyAdvice ?? '',
    ].join(' ').toLowerCase();

    final hasVolume = _hasVolumeSignal(text);
    final hasPlaneGeometryArea =
        !hasVolume && _hasPlaneGeometryAreaSignal(text);
    final hasFunctionEvaluation = _hasFunctionEvaluationSignal(text);
    final hasProportionalRelation = _hasProportionalRelationSignal(text);
    final hasOrganicChemistry = _hasOrganicChemistrySignal(text);
    final hasPhysicsCircuit = _hasPhysicsCircuitSignal(text);
    final hasSquarePerpendicularBisectorLength = !hasPlaneGeometryArea &&
        !hasVolume &&
        _hasSquarePerpendicularBisectorLengthSignal(text);
    final hasRightTriangleLength = !hasPlaneGeometryArea &&
        !hasVolume &&
        !hasSquarePerpendicularBisectorLength &&
        _hasRightTriangleLengthSignal(text);
    final hasEquationSystem =
        !hasProportionalRelation && _hasEquationSystemSignal(text);
    final hasTriangleAngle = !hasPlaneGeometryArea &&
        !hasRightTriangleLength &&
        _hasTriangleAngleSignal(text);
    final hasQuadraticRoot = !hasVolume &&
        !hasPlaneGeometryArea &&
        !hasFunctionEvaluation &&
        !hasProportionalRelation &&
        !hasRightTriangleLength &&
        _hasQuadraticRootSignal(text, allowBareSquareSymbol: true);
    final hasLinearEquation = !hasQuadraticRoot &&
        !hasEquationSystem &&
        !hasFunctionEvaluation &&
        !hasProportionalRelation &&
        !hasPlaneGeometryArea &&
        !hasRightTriangleLength &&
        _hasLinearEquationSignal(text);

    if (hasPlaneGeometryArea) {
      return _ExerciseTopicProfile(
        domain: _ExerciseDomain.planeGeometryArea,
        object: _hasCircleAreaSignal(text)
            ? _ExerciseObject.circleFamily
            : _ExerciseObject.generic,
        methods: _geometryAreaMethods(text),
        hasStrongSignal: true,
        variant: _circleAreaVariant(text),
      );
    }
    if (hasRightTriangleLength) {
      final methods = <_ExerciseMethod>{_ExerciseMethod.pythagorean};
      if (_hasEqualLengthSignal(text)) {
        methods.add(_ExerciseMethod.equalLengthRelation);
      }
      return _ExerciseTopicProfile(
        domain: _ExerciseDomain.planeGeometryLength,
        object: _ExerciseObject.rightTriangle,
        methods: methods,
        hasStrongSignal: true,
        variant: _ExerciseVariant.rightTriangleLength,
      );
    }
    if (hasSquarePerpendicularBisectorLength) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.planeGeometryLength,
        object: _ExerciseObject.square,
        methods: <_ExerciseMethod>{
          _ExerciseMethod.equalLengthRelation,
          _ExerciseMethod.perpendicularBisector,
          _ExerciseMethod.coordinateGeometry,
        },
        hasStrongSignal: true,
        variant: _ExerciseVariant.squarePerpendicularBisectorLength,
      );
    }
    if (hasVolume) {
      return _ExerciseTopicProfile(
        domain: _ExerciseDomain.solidGeometryVolume,
        object: _ExerciseObject.coneCylinder,
        methods: const <_ExerciseMethod>{_ExerciseMethod.formulaSubstitution},
        hasStrongSignal: true,
        variant: _solidVolumeVariant(text),
      );
    }
    if (hasOrganicChemistry) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.organicChemistry,
        object: _ExerciseObject.organicSynthesis,
        methods: <_ExerciseMethod>{},
        hasStrongSignal: true,
      );
    }
    if (hasPhysicsCircuit) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.physicsCircuit,
        object: _ExerciseObject.circuit,
        methods: <_ExerciseMethod>{},
        hasStrongSignal: true,
      );
    }
    if (hasFunctionEvaluation) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.functionEvaluation,
        object: _ExerciseObject.functionExpression,
        methods: <_ExerciseMethod>{_ExerciseMethod.functionSubstitution},
        hasStrongSignal: true,
      );
    }
    if (hasProportionalRelation) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.proportionalRelation,
        object: _ExerciseObject.proportionalRelation,
        methods: <_ExerciseMethod>{_ExerciseMethod.ratioRelation},
        hasStrongSignal: true,
      );
    }
    if (hasEquationSystem) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.equationSystem,
        object: _ExerciseObject.equationSystem,
        methods: <_ExerciseMethod>{_ExerciseMethod.elimination},
        hasStrongSignal: true,
      );
    }
    if (hasTriangleAngle) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.planeGeometryAngle,
        object: _ExerciseObject.triangle,
        methods: <_ExerciseMethod>{_ExerciseMethod.angleSum},
        hasStrongSignal: true,
      );
    }
    if (hasQuadraticRoot) {
      return const _ExerciseTopicProfile(
        domain: _ExerciseDomain.algebraEquation,
        object: _ExerciseObject.quadraticEquation,
        methods: <_ExerciseMethod>{_ExerciseMethod.squareRoot},
        hasStrongSignal: true,
      );
    }
    if (hasLinearEquation) {
      final isStrong = profileSource == _TopicProfileSource.exercise;
      return _ExerciseTopicProfile(
        domain: _ExerciseDomain.algebraEquation,
        object: _ExerciseObject.linearEquation,
        methods: const <_ExerciseMethod>{_ExerciseMethod.linearSolve},
        hasStrongSignal: isStrong,
      );
    }
    return const _ExerciseTopicProfile(
      domain: _ExerciseDomain.generic,
      object: _ExerciseObject.generic,
      methods: <_ExerciseMethod>{},
      hasStrongSignal: false,
    );
  }

  bool _hasAnySignal(String text, Iterable<String> needles) {
    return needles.any(text.contains);
  }

  bool _hasOrganicChemistrySignal(String text) {
    final normalized = text.toLowerCase();
    return _hasAnySignal(normalized, <String>[
          '有机合成',
          '合成路线',
          '有机物',
          '官能团',
          '结构简式',
          '同分异构',
          'fries',
          'beckmann',
          '银镜',
          '核磁',
          '乙酸酐',
          '苯酚',
          '苯乙酮',
          '苯胺',
          '硝基',
          '甲氧基',
          '羟胺',
          '肟',
          '酰胺',
          '酯化',
          '重排',
          'nh2oh',
          'pd/hcl',
          '浓硝酸',
          '浓硫酸',
        ]) &&
        _hasAnySignal(normalized, <String>[
          '化学',
          '有机',
          '苯',
          'c6h',
          'ch3',
          'cho',
          'cooh',
          'nh2',
          'naoh',
          'hcl',
          '反应',
        ]);
  }

  bool _hasPhysicsCircuitSignal(String text) {
    final normalized = text.toLowerCase();
    return _hasAnySignal(normalized, <String>[
      '物理电学',
      '电路',
      '电流',
      '电压',
      '电阻',
      '欧姆',
      '串联',
      '并联',
      '电表示数',
      '电流表',
      '电压表',
      '滑动变阻器',
      r'i=\frac{u}{r}',
      r'\frac{u}{r}',
      'i=u/r',
    ]);
  }

  bool _hasSquareSymbol(String text) {
    return RegExp(r'(x|a|b|m|n|p|q|r|y)\s*(\^\{?2\}?|²)').hasMatch(text);
  }

  bool _hasEquationSystemSignal(String text) {
    return _hasAnySignal(
        text, <String>['方程组', '消元', 'begin{cases}', 'cases', '二元一次方程组']);
  }

  bool _hasProportionalRelationSignal(String text) {
    final hasRatioSignal = _hasAnySignal(text, <String>[
      '比例',
      '比值',
      '分式关系',
      '分数关系',
      '倍数关系',
      '成比例',
      'a:b',
      'm:n',
      'x:y',
      r'\frac',
    ]);
    if (!hasRatioSignal) return false;
    return _hasAnySignal(text, <String>[
      '和式',
      '差式',
      '和差',
      'a+b',
      'x+y',
      'm+n',
      'a-b',
      'x-y',
      'm-n',
      '求 a',
      '求a',
      '求 x',
      '求x',
      '求两个量',
      '代入法',
      '转化为',
    ]);
  }

  bool _hasTriangleAngleSignal(String text) {
    return _hasAnySignal(
            text, <String>['三角', '等腰', '内角', '外角', '角形', r'\triangle', '△']) &&
        _hasAnySignal(text, <String>['角', '度', r'\angle', '∠', r'^\circ', '°']);
  }

  bool _hasRightTriangleLengthSignal(String text) {
    if (_hasPlaneGeometryAreaSignal(text) || _hasVolumeSignal(text)) {
      return false;
    }
    final hasLengthTarget = _hasAnySignal(text, <String>[
      '线段',
      '边长',
      '长度',
      '斜边',
      '直角边',
      '求bc',
      '求 bc',
      '求 ab',
      '求ab',
      '求 ac',
      '求ac',
      '求 bd',
      '求bd',
    ]);
    if (!hasLengthTarget) return false;
    final hasRightTriangle = _hasAnySignal(text, <String>[
      '直角',
      '90°',
      r'90^\circ',
      r'90^\circ',
      '勾股',
      '斜边',
      '直角三角形',
      r'a^2+b^2=c^2',
      r'a^2 + b^2 = c^2',
    ]);
    return hasRightTriangle &&
        _hasAnySignal(
            text, <String>['三角', '角形', '△', r'\triangle', 'ab', 'bc', 'ac']);
  }

  bool _hasSquarePerpendicularBisectorLengthSignal(String text) {
    if (_hasPlaneGeometryAreaSignal(text) || _hasVolumeSignal(text)) {
      return false;
    }
    final hasLengthTarget = _hasAnySignal(text, <String>[
      '线段',
      '边长',
      '长度',
      '求df',
      '求 df',
      '求af',
      '求 af',
      '求ef',
      '求 ef',
    ]);
    if (!hasLengthTarget) return false;
    final hasSquare = _hasAnySignal(text, <String>['正方形', 'abcd']);
    final hasPerpendicularBisector =
        _hasAnySignal(text, <String>['垂直平分线', '垂直平分', '中垂线']);
    final hasEdgePoint = _hasAnySignal(text, <String>[
      '中点',
      '点f',
      '点 f',
      '边dc',
      '边 dc',
      'dc上',
      'dc 上',
    ]);
    return hasSquare && hasPerpendicularBisector && hasEdgePoint;
  }

  bool _hasPlaneGeometryLengthSignal(
    String text,
    _ExerciseTopicProfile profile,
  ) {
    switch (profile.variant) {
      case _ExerciseVariant.squarePerpendicularBisectorLength:
        return _hasSquarePerpendicularBisectorLengthSignal(text);
      case _ExerciseVariant.rightTriangleLength:
        return _hasRightTriangleLengthSignal(text);
      default:
        return _hasRightTriangleLengthSignal(text) ||
            _hasSquarePerpendicularBisectorLengthSignal(text);
    }
  }

  bool _hasEqualLengthSignal(String text) {
    return _hasAnySignal(text, <String>['等长', '相等', 'bd=bc', 'ab=ac', 'bc=bd']);
  }

  _ExerciseVariant? _circleAreaVariant(String text) {
    if (_hasCompositeSemicircleAreaSignal(text)) {
      return _ExerciseVariant.compositeSemicircleArea;
    }
    if (_hasAnySignal(
        text, <String>['圆环', '大圆', '小圆', '空白', '剩余', '减去', '挖去', '内圆', '外圆'])) {
      return _ExerciseVariant.annulusOrShadedArea;
    }
    if (_hasAnySignal(text, <String>['半圆', '一半', r'\frac{1}{2}', '1/2'])) {
      return _ExerciseVariant.semicircleArea;
    }
    if (_hasAnySignal(text, <String>['阴影'])) {
      return _ExerciseVariant.annulusOrShadedArea;
    }
    if (_hasAnySignal(text, <String>['圆', '半径', '直径', r'\pi', 'π'])) {
      return _ExerciseVariant.circleArea;
    }
    return null;
  }

  bool _hasCompositeSemicircleAreaSignal(String text) {
    final hasSemicircle = _hasAnySignal(text, <String>['半圆']);
    final hasOuterArea = _hasAnySignal(
      text,
      <String>[
        '梯形',
        '上底',
        '下底',
        '上边',
        '下边',
        '底边',
        '水平边',
        '外框',
        '外边界',
        '外框面积',
        '上方水平边',
        '下方水平边',
        '右侧竖直边',
        '右边高',
      ],
    );
    final hasDiameterDerived = _hasAnySignal(
      text,
      <String>[
        '斜边',
        '直径',
        '勾股',
        '水平差',
        '竖直差',
        '高度',
        '高为',
        '右边高',
        '竖直边高',
        '竖直高度',
      ],
    );
    final hasDifference = _hasAnySignal(
      text,
      <String>['剩余', '减去', '减小', '面积差', '外侧', '之间', '括号', '半圆外'],
    );
    return hasSemicircle && hasOuterArea && hasDiameterDerived && hasDifference;
  }

  bool _hasFramedSemicircleDiameterSignal(
    String? sourceQuestionText,
    AnalysisResult? analysis,
  ) {
    final text = <String>[
      sourceQuestionText ?? '',
      ...?analysis?.aiTags,
      ...?analysis?.knowledgePoints,
      ...?analysis?.steps,
      analysis?.mistakeReason ?? '',
      analysis?.studyAdvice ?? '',
    ].join(' ').toLowerCase();
    final hasFramedShape = _hasAnySignal(text, <String>[
      '外框',
      '上边',
      '下边',
      '上底',
      '下底',
      '右边高',
      '水平差',
      '竖直差',
      '左侧斜边',
    ]);
    final hasSemicircleDiameter = _hasAnySignal(text, <String>[
      '半圆直径',
      '半圆以左侧斜边为直径',
      '左侧斜边为半圆直径',
      '斜边为半圆直径',
    ]);
    return hasFramedShape && hasSemicircleDiameter;
  }

  _FramedSemicircleSpec? _framedSemicircleSpecFromSource(
    String? sourceQuestionText,
    AnalysisResult? analysis,
  ) {
    final text = <String>[
      sourceQuestionText ?? '',
      ...?analysis?.steps,
    ].join(' ');
    int? firstNumberAfter(Iterable<String> labels) {
      for (final label in labels) {
        final match =
            RegExp('$label(?:长)?(?:为|是|=)?\\s*(\\d+)').firstMatch(text);
        if (match != null) return int.tryParse(match.group(1)!);
      }
      return null;
    }

    final top = firstNumberAfter(const <String>['上边', '上底', '上水平边']);
    final bottom = firstNumberAfter(const <String>['下边', '下底', '下水平边', '底边']);
    final height = firstNumberAfter(const <String>['右边高', '右侧竖直边高', '高']);
    if (top == null || bottom == null || height == null) return null;
    if (top <= 0 || bottom <= 0 || height <= 0 || top == bottom) return null;
    return _FramedSemicircleSpec(top: top, bottom: bottom, height: height);
  }

  _ExerciseVariant? _solidVolumeVariant(String text) {
    if (_hasAnySignal(text, <String>['圆锥', r'\frac{1}{3}\pi'])) {
      return _ExerciseVariant.coneVolume;
    }
    if (_hasAnySignal(text, <String>['圆柱', 'πr^2h', 'π r^2 h', r'\pi r^2 h'])) {
      return _ExerciseVariant.cylinderVolume;
    }
    return null;
  }

  bool _hasPlaneGeometryAreaSignal(String text) {
    if (!_hasAnySignal(text, <String>[
      '面积',
      '阴影',
      '空白部分',
      '剩余部分',
      'cm²',
      'cm^2',
      'm²',
      'm^2',
      '平方厘米',
      '平方米'
    ])) {
      return false;
    }
    return _hasAnySignal(text, <String>[
      '圆',
      '半圆',
      '扇形',
      '圆环',
      '半径',
      '直径',
      r'\pi',
      'π',
      '三角形',
      '矩形',
      '长方形',
      '正方形',
      '梯形',
      '平行四边形',
      '底',
      '高',
      '宽',
      '长',
    ]);
  }

  bool _hasCircleAreaSignal(String text) {
    return _hasAnySignal(text, <String>[
      '圆',
      '半圆',
      '扇形',
      '圆环',
      '半径',
      '直径',
      '圆心角',
      r'\pi',
      'π',
    ]);
  }

  Set<_ExerciseMethod> _geometryAreaMethods(String text) {
    final methods = <_ExerciseMethod>{_ExerciseMethod.formulaSubstitution};
    if (_hasAnySignal(
        text, <String>['半圆', '一半', r'\frac{1}{2}', '1/2', '比例', '圆心角', '扇形'])) {
      methods.add(_ExerciseMethod.halfArea);
    }
    if (_hasAnySignal(text, <String>['阴影', '空白', '剩余', '剪去', '半圆外'])) {
      methods.add(_ExerciseMethod.shadedArea);
    }
    if (_hasAnySignal(
        text, <String>['减', '减去', '减小', '大圆', '小圆', '圆环', '空白', '半圆外'])) {
      methods.add(_ExerciseMethod.largeMinusSmall);
    }
    if (_hasAnySignal(text, <String>['组合', '拆', '拼', '补'])) {
      methods.add(_ExerciseMethod.splitAndCombine);
    }
    return methods;
  }

  bool _hasVolumeSignal(String text) {
    final hasSolidObject = _hasAnySignal(text, <String>[
      '体积',
      '立体几何',
      '圆柱',
      '圆锥',
      '长方体',
      '正方体',
      '棱柱',
      '棱锥',
      '底面半径',
      r'\frac{1}{3}\pi',
      'πr^2h',
      'π r^2 h',
      r'\pi r^2 h',
    ]);
    if (!hasSolidObject) return false;
    if (_hasPlaneGeometryAreaSignal(text) &&
        !_hasAnySignal(text, <String>['体积', '圆柱', '圆锥', '长方体', '正方体'])) {
      return false;
    }
    return true;
  }

  bool _hasFunctionSignal(String text) {
    return _hasAnySignal(text, <String>[
      'f(',
      'g(',
      'h(',
      'f（',
      'g（',
      'h（',
      r'f\left',
      r'g\left',
      r'h\left'
    ]);
  }

  bool _hasFunctionEvaluationSignal(String text) {
    return _hasAnySignal(text, <String>['函数值', '函数解析式', '代入函数', '自变量']) ||
        (_hasFunctionSignal(text) && _hasAnySignal(text, <String>['代入', '求']));
  }

  bool _hasQuadraticRootSignal(String text,
      {bool allowBareSquareSymbol = false}) {
    final hasRootLanguage = _hasAnySignal(
        text, <String>['平方根', '开平方', '一元二次', '二次方程', '正负根', r'\sqrt', r'\pm']);
    if (hasRootLanguage) return true;
    return allowBareSquareSymbol &&
        _hasSquareSymbol(text) &&
        _hasAnySignal(text, <String>['解方程', '求 x', '求x', 'x 的值', 'x的值']);
  }

  bool _hasLinearEquationSignal(String text) {
    return _hasAnySignal(text, <String>['一元一次', '移项', '解方程']);
  }

  Subject? _parseSubject(String input) {
    final lower = input.toLowerCase();

    for (final subject in Subject.values) {
      if (subject.label == input || subject.name == input) {
        return subject;
      }
    }

    if (lower.contains('物理') || lower == 'wuli' || lower == 'physics') {
      return Subject.physics;
    }
    if (lower.contains('语文') || lower == 'chinese') return Subject.chinese;
    if (lower.contains('英语') || lower.contains('english')) {
      return Subject.english;
    }
    if (lower.contains('化学') || lower == 'chemistry') return Subject.chemistry;
    if (lower.contains('生物') || lower == 'biology') return Subject.biology;
    if (lower.contains('历史') || lower == 'history') return Subject.history;
    if (lower.contains('地理') || lower == 'geography') return Subject.geography;
    if (lower.contains('政治') || lower == 'politics') return Subject.politics;
    if (lower.contains('科学') || lower == 'science') return Subject.science;
    if (lower.contains('数学') ||
        lower == 'math' ||
        lower.contains('mathematics')) {
      return Subject.math;
    }
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
    final prompt =
        _buildJudgePrompt(question, userAnswer, correctAnswer, options);

    try {
      final response =
          await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
        'model': config.model,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'system',
            'content': '你是一个判断答案是否正确的助手。请仔细分析题目和答案，给出判断结果。'
          },
          <String, String>{'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
        'max_tokens': 50,
      });

      final content =
          response.data['choices'][0]['message']['content'] as String;
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

  String _buildJudgePrompt(String question, String userAnswer,
      String correctAnswer, List<String>? options) {
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

  List<GeneratedExercise> _defaultCircleAreaExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'一个圆的半径为 4 cm，求这个圆的面积。',
        options: const [
          r'A. \(8\pi\) cm²',
          r'B. \(12\pi\) cm²',
          r'C. \(16\pi\) cm²',
          r'D. \(32\pi\) cm²',
        ],
        answer: 'C',
        explanation: r'圆面积公式为 \(S=\pi r^2\)，代入 \(r=4\)，得 \(S=16\pi\) cm²。',
        createdAt: now,
        order: 0,
        diagramData: _circleDiagram('4cm'),
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'一个圆的直径为 10 cm，求这个圆的面积。',
        options: const [
          r'A. \(10\pi\) cm²',
          r'B. \(20\pi\) cm²',
          r'C. \(25\pi\) cm²',
          r'D. \(100\pi\) cm²',
        ],
        answer: 'C',
        explanation: r'直径为 10 cm，所以半径为 5 cm，面积为 \(\pi\times5^2=25\pi\) cm²。',
        createdAt: now,
        order: 1,
        diagramData: _circleDiagram('d=10cm'),
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: r'一个圆的周长为 \(12\pi\) cm，求这个圆的面积。',
        options: const [
          r'A. \(24\pi\) cm²',
          r'B. \(36\pi\) cm²',
          r'C. \(48\pi\) cm²',
          r'D. \(144\pi\) cm²',
        ],
        answer: 'B',
        explanation: r'由 \(2\pi r=12\pi\) 得 \(r=6\)，面积为 \(\pi r^2=36\pi\) cm²。',
        createdAt: now,
        order: 2,
        diagramData: _circleDiagram('C=12π'),
      ),
    ];
  }

  List<GeneratedExercise> _defaultSemicircleAreaExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'一个半圆的半径为 4 cm，求这个半圆的面积。',
        options: const [
          r'A. \(4\pi\) cm²',
          r'B. \(8\pi\) cm²',
          r'C. \(16\pi\) cm²',
          r'D. \(32\pi\) cm²',
        ],
        answer: 'B',
        explanation: r'整圆面积为 \(16\pi\) cm²，半圆面积是一半，所以为 \(8\pi\) cm²。',
        createdAt: now,
        order: 0,
        diagramData: _semicircleDiagram('4cm'),
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'一个半圆的直径为 10 cm，求这个半圆的面积。',
        options: const [
          r'A. \(\frac{25\pi}{2}\) cm²',
          r'B. \(25\pi\) cm²',
          r'C. \(50\pi\) cm²',
          r'D. \(10\pi\) cm²',
        ],
        answer: 'A',
        explanation:
            r'直径为 10 cm，半径为 5 cm，半圆面积为 \(\frac{1}{2}\pi\times5^2=\frac{25\pi}{2}\) cm²。',
        createdAt: now,
        order: 1,
        diagramData: _semicircleDiagram('d=10cm'),
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: r'一个半圆的弧所在整圆周长为 \(16\pi\) cm，求这个半圆的面积。',
        options: const [
          r'A. \(16\pi\) cm²',
          r'B. \(24\pi\) cm²',
          r'C. \(32\pi\) cm²',
          r'D. \(64\pi\) cm²',
        ],
        answer: 'C',
        explanation:
            r'由 \(2\pi r=16\pi\) 得 \(r=8\)，半圆面积为 \(\frac{1}{2}\pi\times8^2=32\pi\) cm²。',
        createdAt: now,
        order: 2,
        diagramData: _semicircleDiagram('C=16π'),
      ),
    ];
  }

  List<GeneratedExercise> _defaultCompositeSemicircleAreaExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'如图，上边长为 2，下边长为 5，右边高为 4，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。',
        options: const [
          r'A. \(14-\frac{25\pi}{8}\)',
          r'B. \(14-\frac{25\pi}{4}\)',
          r'C. \(20-\frac{25\pi}{8}\)',
          r'D. \(14-\frac{5\pi}{2}\)',
        ],
        answer: 'A',
        explanation:
            r'外边界面积为 \(\frac{2+5}{2}\times4=14\)。左侧斜边平方为 \((5-2)^2+4^2=25\)，所以半圆面积为 \(\frac{25\pi}{8}\)，目标面积为 \(14-\frac{25\pi}{8}\)。',
        createdAt: now,
        order: 0,
        diagramData: _framedSemicircleDiagram('2', '5', '4'),
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'如图，上边长为 3，下边长为 7，右边高为 10，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。',
        options: const [
          r'A. \(50-29\pi\)',
          r'B. \(50-\frac{29\pi}{2}\)',
          r'C. \(40-\frac{29\pi}{2}\)',
          r'D. \(50-58\pi\)',
        ],
        answer: 'B',
        explanation:
            r'外边界面积为 \(\frac{3+7}{2}\times10=50\)。左侧斜边平方为 \((7-3)^2+10^2=116\)，半径平方为 29，半圆面积为 \(\frac{29\pi}{2}\)，目标面积为 \(50-\frac{29\pi}{2}\)。',
        createdAt: now,
        order: 1,
        diagramData: _framedSemicircleDiagram('3', '7', '10'),
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: r'如图，上边长为 4，下边长为 10，右边高为 8，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。',
        options: const [
          r'A. \(56-50\pi\)',
          r'B. \(48-25\pi\)',
          r'C. \(56-25\pi\)',
          r'D. \(56-\frac{25\pi}{2}\)',
        ],
        answer: 'D',
        explanation:
            r'外边界面积为 \(\frac{4+10}{2}\times8=56\)。左侧斜边平方为 \((10-4)^2+8^2=100\)，半径平方为 25，半圆面积为 \(\frac{25\pi}{2}\)，目标面积为 \(56-\frac{25\pi}{2}\)。',
        createdAt: now,
        order: 2,
        diagramData: _framedSemicircleDiagram('4', '10', '8'),
      ),
    ];
  }

  List<GeneratedExercise> _defaultFramedSemicircleAreaExercises(
    String questionId,
    DateTime now,
    _FramedSemicircleSpec? sourceSpec,
  ) {
    final same = sourceSpec ??
        const _FramedSemicircleSpec(top: 3, bottom: 7, height: 10);
    final simple = _scaledFramedSemicircleSpec(same, difficulty: -1);
    final hard = _scaledFramedSemicircleSpec(same, difficulty: 1);
    return <GeneratedExercise>[
      _framedSemicircleExercise(
        id: 'e1',
        questionId: questionId,
        difficulty: '简单',
        spec: simple,
        createdAt: now,
        order: 0,
      ),
      _framedSemicircleExercise(
        id: 'e2',
        questionId: questionId,
        difficulty: '同级',
        spec: same,
        createdAt: now,
        order: 1,
      ),
      _framedSemicircleExercise(
        id: 'e3',
        questionId: questionId,
        difficulty: '提高',
        spec: hard,
        createdAt: now,
        order: 2,
      ),
    ];
  }

  _FramedSemicircleSpec _scaledFramedSemicircleSpec(
    _FramedSemicircleSpec source, {
    required int difficulty,
  }) {
    if (difficulty < 0) {
      final diff = math.max(3, source.horizontalDiff - 1);
      final height = math.max(4, source.height - 2);
      final top = math.max(2, source.top - 1);
      return _FramedSemicircleSpec(
        top: top,
        bottom: top + diff,
        height: height,
      );
    }
    final diff = source.horizontalDiff + 2;
    final height = source.height + 3;
    final top = source.top + 1;
    return _FramedSemicircleSpec(
      top: top,
      bottom: top + diff,
      height: height,
    );
  }

  GeneratedExercise _framedSemicircleExercise({
    required String id,
    required String questionId,
    required String difficulty,
    required _FramedSemicircleSpec spec,
    required DateTime createdAt,
    required int order,
  }) {
    final area = _formatPiOver8(spec.diameterSquared);
    final distractors = <String>[
      _formatPiOver8(spec.diameterSquared * 2),
      _formatPiOver8(math.max(1, spec.diameterSquared - 8)),
      '${spec.diameterSquared}π',
    ];
    return GeneratedExercise(
      id: id,
      questionId: questionId,
      generationMode: ExerciseGenerationMode.practice,
      difficulty: difficulty,
      question:
          '如图，上边长为 ${spec.top}，下边长为 ${spec.bottom}，右边高为 ${spec.height}，左侧斜边为半圆直径。求该半圆的面积。',
      options: <String>[
        'A. ${distractors[0]}',
        'B. $area',
        'C. ${distractors[1]}',
        'D. ${distractors[2]}',
      ],
      answer: 'B',
      explanation:
          '水平差为 ${spec.horizontalDiff}，高为 ${spec.height}，由勾股定理得直径平方为 ${spec.diameterSquared}，半圆面积为 $area。',
      createdAt: createdAt,
      order: order,
      diagramData: _framedSemicircleDiagram(
        spec.top.toString(),
        spec.bottom.toString(),
        spec.height.toString(),
        targetLabel: '求半圆面积',
      ),
    );
  }

  String _formatPiOver8(int numerator) {
    final divisor = _gcd(numerator, 8);
    final reducedNumerator = numerator ~/ divisor;
    final reducedDenominator = 8 ~/ divisor;
    if (reducedDenominator == 1) return '$reducedNumeratorπ';
    return '$reducedNumeratorπ/$reducedDenominator';
  }

  int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final next = x % y;
      x = y;
      y = next;
    }
    return x == 0 ? 1 : x;
  }

  List<GeneratedExercise> _defaultAnnulusAreaExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'一个圆环的外圆半径为 5 cm，内圆半径为 3 cm，求圆环面积。',
        options: const [
          r'A. \(8\pi\) cm²',
          r'B. \(12\pi\) cm²',
          r'C. \(16\pi\) cm²',
          r'D. \(25\pi\) cm²',
        ],
        answer: 'C',
        explanation: r'圆环面积为大圆面积减小圆面积，\(25\pi-9\pi=16\pi\) cm²。',
        createdAt: now,
        order: 0,
        diagramData: _annulusDiagram('5cm', '3cm'),
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'一个圆形花坛半径为 6 m，中间挖去半径为 2 m 的圆形区域，剩余部分面积是多少？',
        options: const [
          r'A. \(24\pi\) m²',
          r'B. \(28\pi\) m²',
          r'C. \(32\pi\) m²',
          r'D. \(36\pi\) m²',
        ],
        answer: 'C',
        explanation: r'剩余面积为 \(36\pi-4\pi=32\pi\) m²。',
        createdAt: now,
        order: 1,
        diagramData: _annulusDiagram('6m', '2m'),
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: r'一个圆环的外圆直径为 14 cm，内圆直径为 10 cm，求圆环面积。',
        options: const [
          r'A. \(12\pi\) cm²',
          r'B. \(24\pi\) cm²',
          r'C. \(36\pi\) cm²',
          r'D. \(48\pi\) cm²',
        ],
        answer: 'B',
        explanation: r'外半径为 7 cm，内半径为 5 cm，圆环面积为 \(49\pi-25\pi=24\pi\) cm²。',
        createdAt: now,
        order: 2,
        diagramData: _annulusDiagram('d=14', 'd=10'),
      ),
    ];
  }

  List<GeneratedExercise> _defaultRightTriangleLengthExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'如图，直角三角形两条直角边分别为 6 和 8，求斜边的长度。',
        options: const ['A. 8', 'B. 9', 'C. 10', 'D. 12'],
        answer: 'C',
        explanation: r'由勾股定理，斜边 \(c=\sqrt{6^2+8^2}=10\)。',
        createdAt: now,
        order: 0,
        diagramData: _rightTriangleDiagram('6', '8', '?'),
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'如图，直角三角形的斜边为 13，一条直角边为 5，求另一条直角边的长度。',
        options: const ['A. 8', 'B. 10', 'C. 12', 'D. 14'],
        answer: 'C',
        explanation: r'设另一条直角边为 \(x\)，则 \(x^2+5^2=13^2\)，所以 \(x=12\)。',
        createdAt: now,
        order: 1,
        diagramData: _rightTriangleDiagram('5', '?', '13'),
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question:
            r'如图，\(\angle ABC=90^\circ\)，点 \(D\) 在 \(AB\) 上，\(BD=BC\)，\(AD=7\)，\(AC=17\)，求 \(BC\) 的长度。',
        options: const ['A. 6', 'B. 8', 'C. 10', 'D. 12'],
        answer: 'B',
        explanation:
            r'设 \(BC=BD=x\)，则 \(AB=x+7\)。由勾股定理，\((x+7)^2+x^2=17^2\)，解得 \(x=8\)，所以 \(BC=8\)。',
        createdAt: now,
        order: 2,
        diagramData: _rightTriangleCompositeDiagram(),
      ),
    ];
  }

  Map<String, dynamic> _circleDiagram(String label) {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'arc',
          'cx': 0.5,
          'cy': 0.5,
          'r': 0.35,
          'startAngle': 0,
          'sweepAngle': 360,
          'filled': false
        },
        {'type': 'point', 'x': 0.5, 'y': 0.5, 'label': 'O', 'role': 'label'},
        {
          'type': 'line',
          'x1': 0.5,
          'y1': 0.5,
          'x2': 0.85,
          'y2': 0.5,
          'style': 'solid',
          'role': 'known'
        },
        {'type': 'text', 'text': label, 'x': 0.68, 'y': 0.42, 'role': 'known'},
      ],
    };
  }

  Map<String, dynamic> _semicircleDiagram(String label) {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'arc',
          'cx': 0.5,
          'cy': 0.6,
          'r': 0.3,
          'startAngle': 180,
          'sweepAngle': 180,
          'filled': true
        },
        {
          'type': 'line',
          'x1': 0.2,
          'y1': 0.6,
          'x2': 0.8,
          'y2': 0.6,
          'style': 'solid',
          'role': 'known'
        },
        {'type': 'text', 'text': label, 'x': 0.5, 'y': 0.68, 'role': 'known'},
        {'type': 'point', 'x': 0.5, 'y': 0.6, 'label': 'O', 'role': 'label'},
      ],
    };
  }

  Map<String, dynamic> _annulusDiagram(String outer, String inner) {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'arc',
          'cx': 0.5,
          'cy': 0.5,
          'r': 0.4,
          'startAngle': 0,
          'sweepAngle': 360,
          'filled': false
        },
        {
          'type': 'arc',
          'cx': 0.5,
          'cy': 0.5,
          'r': 0.26,
          'startAngle': 0,
          'sweepAngle': 360,
          'filled': false
        },
        {
          'type': 'line',
          'x1': 0.5,
          'y1': 0.5,
          'x2': 0.9,
          'y2': 0.5,
          'style': 'solid',
          'role': 'known'
        },
        {
          'type': 'line',
          'x1': 0.5,
          'y1': 0.5,
          'x2': 0.76,
          'y2': 0.5,
          'style': 'dashed',
          'role': 'known'
        },
        {'type': 'text', 'text': outer, 'x': 0.73, 'y': 0.42, 'role': 'known'},
        {'type': 'text', 'text': inner, 'x': 0.61, 'y': 0.56, 'role': 'known'},
        {'type': 'point', 'x': 0.5, 'y': 0.5, 'label': 'O', 'role': 'label'},
      ],
    };
  }

  Map<String, dynamic> _framedSemicircleDiagram(
    String top,
    String bottom,
    String height, {
    String targetLabel = '求此区域',
  }) {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'polygon',
          'points': [
            [0.36, 0.16],
            [0.76, 0.16],
            [0.76, 0.86],
            [0.12, 0.86],
          ],
          'labels': [
            {'text': 'A', 'x': 0.35, 'y': 0.1},
            {'text': 'B', 'x': 0.79, 'y': 0.12},
            {'text': 'C', 'x': 0.79, 'y': 0.9},
            {'text': 'D', 'x': 0.09, 'y': 0.9},
          ],
        },
        {'type': 'text', 'text': top, 'x': 0.56, 'y': 0.1, 'role': 'known'},
        {'type': 'text', 'text': bottom, 'x': 0.44, 'y': 0.94, 'role': 'known'},
        {'type': 'text', 'text': height, 'x': 0.84, 'y': 0.5, 'role': 'known'},
        {
          'type': 'arc',
          'cx': 0.24,
          'cy': 0.51,
          'r': 0.38,
          'startAngle': -72,
          'sweepAngle': 180,
          'filled': false,
          'role': 'known',
        },
        {'type': 'text', 'text': '半圆', 'x': 0.48, 'y': 0.55, 'role': 'label'},
        {
          'type': 'text',
          'text': targetLabel,
          'x': 0.68,
          'y': 0.39,
          'role': 'target',
        },
        {'type': 'rightAngle', 'x': 0.76, 'y': 0.86},
      ],
      'auxiliaryLines': [
        {
          'type': 'line',
          'x1': 0.36,
          'y1': 0.16,
          'x2': 0.12,
          'y2': 0.86,
          'style': 'dashed',
          'role': 'auxiliary',
        },
      ],
    };
  }

  Map<String, dynamic> _rightTriangleDiagram(
    String legA,
    String legB,
    String hypotenuse,
  ) {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'polygon',
          'points': [
            [0.2, 0.8],
            [0.2, 0.25],
            [0.78, 0.8],
          ],
          'labels': [
            {'text': 'A', 'x': 0.18, 'y': 0.86},
            {'text': 'B', 'x': 0.16, 'y': 0.2},
            {'text': 'C', 'x': 0.82, 'y': 0.86},
          ],
        },
        {'type': 'rightAngle', 'x': 0.2, 'y': 0.8},
        {'type': 'text', 'text': legA, 'x': 0.14, 'y': 0.52, 'role': 'known'},
        {'type': 'text', 'text': legB, 'x': 0.5, 'y': 0.86, 'role': 'known'},
        {
          'type': 'text',
          'text': hypotenuse,
          'x': 0.53,
          'y': 0.48,
          'role': 'target'
        },
      ],
    };
  }

  Map<String, dynamic> _rightTriangleCompositeDiagram() {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'polygon',
          'points': [
            [0.2, 0.82],
            [0.2, 0.22],
            [0.78, 0.82],
          ],
          'labels': [
            {'text': 'A', 'x': 0.18, 'y': 0.16},
            {'text': 'B', 'x': 0.16, 'y': 0.88},
            {'text': 'C', 'x': 0.82, 'y': 0.88},
            {'text': 'D', 'x': 0.18, 'y': 0.56},
          ],
        },
        {'type': 'rightAngle', 'x': 0.2, 'y': 0.82},
        {'type': 'point', 'x': 0.2, 'y': 0.55, 'label': 'D', 'role': 'label'},
        {'type': 'text', 'text': 'AD=7', 'x': 0.1, 'y': 0.38, 'role': 'known'},
        {'type': 'text', 'text': 'BD=x', 'x': 0.1, 'y': 0.68, 'role': 'target'},
        {
          'type': 'text',
          'text': 'BC=x',
          'x': 0.49,
          'y': 0.88,
          'role': 'target'
        },
        {
          'type': 'text',
          'text': 'AC=17',
          'x': 0.55,
          'y': 0.48,
          'role': 'known'
        },
        {
          'type': 'tickMark',
          'x1': 0.2,
          'y1': 0.55,
          'x2': 0.2,
          'y2': 0.82,
          'ticks': 1
        },
        {
          'type': 'tickMark',
          'x1': 0.2,
          'y1': 0.82,
          'x2': 0.78,
          'y2': 0.82,
          'ticks': 1
        },
      ],
    };
  }

  List<GeneratedExercise> _defaultSquarePerpendicularBisectorLengthExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question:
            r'如图，在边长为 \(4\) 的正方形 \(ABCD\) 中，点 \(E\) 是 \(BC\) 的中点，点 \(F\) 在 \(DC\) 上，且 \(F\) 在线段 \(AE\) 的垂直平分线上。求 \(DF\) 的长。',
        options: const [
          r'A. \(\frac{1}{2}\)',
          r'B. \(1\)',
          r'C. \(\frac{3}{2}\)',
          r'D. \(2\)',
        ],
        answer: 'A',
        explanation:
            r'设 \(B(0,0)\)，\(C(4,0)\)，\(D(4,4)\)，\(A(0,4)\)，则 \(E(2,0)\)，设 \(F(4,y)\)。由 \(FA=FE\)，得 \(4^2+(y-4)^2=2^2+y^2\)，解得 \(y=\frac{7}{2}\)，所以 \(DF=4-\frac{7}{2}=\frac{1}{2}\)。',
        createdAt: now,
        order: 0,
        diagramData: _squarePerpendicularBisectorDiagram('4', '求DF'),
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question:
            r'如图，在边长为 \(8\) 的正方形 \(ABCD\) 中，点 \(E\) 是 \(BC\) 的中点，点 \(F\) 在 \(DC\) 上，直线 \(FH\) 垂直平分线段 \(AE\)。求 \(DF\) 的长。',
        options: const [
          r'A. \(\frac{1}{2}\)',
          r'B. \(1\)',
          r'C. \(2\)',
          r'D. \(4\)',
        ],
        answer: 'B',
        explanation:
            r'设 \(B(0,0)\)，\(C(8,0)\)，\(D(8,8)\)，\(A(0,8)\)，则 \(E(4,0)\)，设 \(F(8,y)\)。由 \(FA=FE\)，得 \(8^2+(y-8)^2=4^2+y^2\)，解得 \(y=7\)，所以 \(DF=8-7=1\)。',
        createdAt: now,
        order: 1,
        diagramData: _squarePerpendicularBisectorDiagram('8', '求DF'),
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question:
            r'如图，在边长为 \(6\) 的正方形 \(ABCD\) 中，点 \(E\) 是 \(BC\) 的中点，点 \(F\) 在 \(DC\) 上，且 \(F\) 在线段 \(AE\) 的垂直平分线上。求 \(DF\) 的长。',
        options: const [
          r'A. \(\frac{1}{2}\)',
          r'B. \(\frac{2}{3}\)',
          r'C. \(\frac{3}{4}\)',
          r'D. \(\frac{5}{4}\)',
        ],
        answer: 'C',
        explanation:
            r'设 \(B(0,0)\)，\(C(6,0)\)，\(D(6,6)\)，\(A(0,6)\)，则 \(E(3,0)\)，设 \(F(6,y)\)。由 \(FA=FE\)，得 \(6^2+(y-6)^2=3^2+y^2\)，解得 \(y=\frac{21}{4}\)，所以 \(DF=6-\frac{21}{4}=\frac{3}{4}\)。',
        createdAt: now,
        order: 2,
        diagramData: _squarePerpendicularBisectorDiagram('6', '求DF'),
      ),
    ];
  }

  Map<String, dynamic> _squarePerpendicularBisectorDiagram(
    String side,
    String target,
  ) {
    return <String, dynamic>{
      'elements': [
        {
          'type': 'polygon',
          'points': [
            [0.2, 0.2],
            [0.2, 0.8],
            [0.8, 0.8],
            [0.8, 0.2],
          ],
          'labels': [
            {'text': 'A', 'x': 0.16, 'y': 0.18},
            {'text': 'B', 'x': 0.16, 'y': 0.84},
            {'text': 'C', 'x': 0.82, 'y': 0.84},
            {'text': 'D', 'x': 0.82, 'y': 0.18},
          ],
        },
        {'type': 'point', 'x': 0.5, 'y': 0.8, 'label': 'E', 'role': 'known'},
        {'type': 'point', 'x': 0.8, 'y': 0.275, 'label': 'F', 'role': 'target'},
        {
          'type': 'line',
          'x1': 0.2,
          'y1': 0.2,
          'x2': 0.5,
          'y2': 0.8,
          'style': 'solid',
          'role': 'known'
        },
        {
          'type': 'line',
          'x1': 0.35,
          'y1': 0.5,
          'x2': 0.8,
          'y2': 0.275,
          'style': 'solid',
          'role': 'known'
        },
        {'type': 'point', 'x': 0.35, 'y': 0.5, 'label': 'H', 'role': 'label'},
        {
          'type': 'text',
          'text': '边长$side',
          'x': 0.48,
          'y': 0.14,
          'role': 'known'
        },
        {
          'type': 'line',
          'x1': 0.8,
          'y1': 0.2,
          'x2': 0.8,
          'y2': 0.275,
          'style': 'solid',
          'role': 'target'
        },
        {
          'type': 'text',
          'text': target,
          'x': 0.86,
          'y': 0.24,
          'role': 'target'
        },
      ],
      'auxiliaryLines': [],
    };
  }

  List<GeneratedExercise> _defaultConeVolumeExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'圆锥底面半径为 \(r=2\)，高为 \(h=3\)，则体积 \(V\) 为',
        options: const [
          r'A. \(4\pi\)',
          r'B. \(8\pi\)',
          r'C. \(12\pi\)',
          r'D. \(6\pi\)',
        ],
        answer: 'A',
        explanation:
            r'\(V=\frac{1}{3}\pi r^2 h=\frac{1}{3}\pi \times 4 \times 3=4\pi\)',
        createdAt: now,
        order: 0,
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'圆锥底面半径为 \(r=3\)，高为 \(h=6\)，则体积 \(V\) 为',
        options: const [
          r'A. \(12\pi\)',
          r'B. \(18\pi\)',
          r'C. \(24\pi\)',
          r'D. \(54\pi\)',
        ],
        answer: 'B',
        explanation:
            r'\(V=\frac{1}{3}\pi r^2h=\frac{1}{3}\pi\times9\times6=18\pi\)。',
        createdAt: now,
        order: 1,
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: r'一个圆锥体积为 \(24\pi\)，底面半径为 \(r=3\)，求高 \(h\)。',
        options: const ['A. 6', 'B. 8', 'C. 10', 'D. 12'],
        answer: 'B',
        explanation:
            r'由 \(24\pi=\frac{1}{3}\pi\times9\times h=3\pi h\)，得 \(h=8\)。',
        createdAt: now,
        order: 2,
      ),
    ];
  }

  List<GeneratedExercise> _defaultCylinderVolumeExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: r'圆柱底面半径为 \(r=2\)，高为 \(h=5\)，则圆柱体积为',
        options: const [
          r'A. \(10\pi\)',
          r'B. \(20\pi\)',
          r'C. \(25\pi\)',
          r'D. \(40\pi\)',
        ],
        answer: 'B',
        explanation: r'圆柱体积 \(V=\pi r^2h=\pi\times4\times5=20\pi\)。',
        createdAt: now,
        order: 0,
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: r'圆柱底面直径为 6，高为 4，则圆柱体积为',
        options: const [
          r'A. \(24\pi\)',
          r'B. \(30\pi\)',
          r'C. \(36\pi\)',
          r'D. \(48\pi\)',
        ],
        answer: 'C',
        explanation: r'直径为 6，所以半径为 3，体积 \(V=\pi\times9\times4=36\pi\)。',
        createdAt: now,
        order: 1,
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: r'一个圆柱体积为 \(45\pi\)，底面半径为 3，求高。',
        options: const ['A. 3', 'B. 4', 'C. 5', 'D. 6'],
        answer: 'C',
        explanation: r'由 \(45\pi=\pi\times3^2\times h=9\pi h\)，得 \(h=5\)。',
        createdAt: now,
        order: 2,
      ),
    ];
  }

  List<GeneratedExercise> _defaultGeneratedExercises(
    String questionId, {
    AnalysisResult? analysis,
    String? sourceQuestionText,
  }) {
    if (_shouldSuppressGeneratedExercises(
      analysis,
      sourceQuestionText: sourceQuestionText,
    )) {
      return const <GeneratedExercise>[];
    }

    final now = DateTime.now();
    final profile = _buildExerciseTopicProfile(
      sourceQuestionText: sourceQuestionText,
      analysis: analysis,
    );

    if (profile.domain == _ExerciseDomain.planeGeometryArea &&
        profile.object == _ExerciseObject.circleFamily) {
      if (profile.variant == _ExerciseVariant.compositeSemicircleArea) {
        return _defaultCompositeSemicircleAreaExercises(questionId, now);
      }
      if (profile.variant == _ExerciseVariant.semicircleArea) {
        if (_hasFramedSemicircleDiameterSignal(sourceQuestionText, analysis)) {
          return _defaultFramedSemicircleAreaExercises(
            questionId,
            now,
            _framedSemicircleSpecFromSource(sourceQuestionText, analysis),
          );
        }
        return _defaultSemicircleAreaExercises(questionId, now);
      }
      if (profile.variant == _ExerciseVariant.annulusOrShadedArea) {
        return _defaultAnnulusAreaExercises(questionId, now);
      }
      return _defaultCircleAreaExercises(questionId, now);
    }

    if (profile.domain == _ExerciseDomain.planeGeometryLength &&
        profile.object == _ExerciseObject.rightTriangle) {
      return _defaultRightTriangleLengthExercises(questionId, now);
    }

    if (profile.domain == _ExerciseDomain.planeGeometryLength &&
        profile.object == _ExerciseObject.square &&
        profile.variant == _ExerciseVariant.squarePerpendicularBisectorLength) {
      return _defaultSquarePerpendicularBisectorLengthExercises(
          questionId, now);
    }

    if (profile.domain == _ExerciseDomain.algebraEquation &&
        profile.object == _ExerciseObject.quadraticEquation) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'已知 \(x^2=9\)，求 \(x\) 的值。',
          options: const [
            r'A. \(x=3\)',
            r'B. \(x=-3\)',
            r'C. \(x=\pm 3\)',
            r'D. \(x=9\)',
          ],
          answer: 'C',
          explanation: r'一个数的平方等于 9，这个数可能是 3 或 -3，所以 \(x=\pm 3\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'已知 \(x^2+4=20\)，求 \(x\) 的值。',
          options: const [
            r'A. \(x=4\)',
            r'B. \(x=\pm 4\)',
            r'C. \(x=8\)',
            r'D. \(x=\pm 8\)',
          ],
          answer: 'B',
          explanation: r'两边同时减去 4，得 \(x^2=16\)，所以 \(x=\pm 4\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'已知 \((x-1)^2=25\)，求 \(x\) 的值。',
          options: const [
            r'A. \(x=6\) 或 \(x=-4\)',
            r'B. \(x=5\) 或 \(x=-5\)',
            r'C. \(x=4\) 或 \(x=-6\)',
            r'D. \(x=6\)',
          ],
          answer: 'A',
          explanation:
              r'由 \((x-1)^2=25\) 得 \(x-1=\pm 5\)，所以 \(x=6\) 或 \(x=-4\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.domain == _ExerciseDomain.planeGeometryAngle &&
        profile.object == _ExerciseObject.triangle) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question:
              r'在 \(\triangle ABC\) 中，若 \(\angle A=50^\circ\)，\(\angle B=60^\circ\)，则 \(\angle C\) 是多少？',
          options: const ['A. 60°', 'B. 70°', 'C. 80°', 'D. 90°'],
          answer: 'B',
          explanation:
              r'三角形内角和为 \(180^\circ\)，所以 \(\angle C=180^\circ-50^\circ-60^\circ=70^\circ\)。',
          createdAt: now,
          order: 0,
          diagramData: const <String, dynamic>{
            'elements': [
              {
                'type': 'polygon',
                'points': [
                  [0.5, 0.15],
                  [0.15, 0.85],
                  [0.85, 0.85]
                ],
                'labels': [
                  {'text': 'A', 'x': 0.5, 'y': 0.08},
                  {'text': 'B', 'x': 0.1, 'y': 0.92},
                  {'text': 'C', 'x': 0.9, 'y': 0.92}
                ]
              },
              {
                'type': 'angleArc',
                'vx': 0.5,
                'vy': 0.15,
                'startAngle': 55,
                'sweepAngle': 70,
                'r': 0.08,
                'label': '50°'
              },
              {
                'type': 'angleArc',
                'vx': 0.15,
                'vy': 0.85,
                'startAngle': -10,
                'sweepAngle': 45,
                'r': 0.08,
                'label': '60°'
              },
              {
                'type': 'angleArc',
                'vx': 0.85,
                'vy': 0.85,
                'startAngle': 135,
                'sweepAngle': 35,
                'r': 0.08,
                'label': '?'
              },
            ],
          },
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question:
              r'在等腰 \(\triangle ABC\) 中，\(AB=AC\)，若 \(\angle A=36^\circ\)，则 \(\angle B\) 是多少？',
          options: const ['A. 36°', 'B. 54°', 'C. 72°', 'D. 108°'],
          answer: 'C',
          explanation:
              r'\(AB=AC\)，所以底角 \(\angle B=\angle C\)；两个底角和为 \(144^\circ\)，所以 \(\angle B=72^\circ\)。',
          createdAt: now,
          order: 1,
          diagramData: const <String, dynamic>{
            'elements': [
              {
                'type': 'polygon',
                'points': [
                  [0.5, 0.1],
                  [0.2, 0.85],
                  [0.8, 0.85]
                ],
                'labels': [
                  {'text': 'A', 'x': 0.5, 'y': 0.03},
                  {'text': 'B', 'x': 0.14, 'y': 0.92},
                  {'text': 'C', 'x': 0.86, 'y': 0.92}
                ]
              },
              {
                'type': 'tickMark',
                'x1': 0.5,
                'y1': 0.1,
                'x2': 0.2,
                'y2': 0.85,
                'ticks': 1
              },
              {
                'type': 'tickMark',
                'x1': 0.5,
                'y1': 0.1,
                'x2': 0.8,
                'y2': 0.85,
                'ticks': 1
              },
              {
                'type': 'angleArc',
                'vx': 0.5,
                'vy': 0.1,
                'startAngle': 60,
                'sweepAngle': 60,
                'r': 0.08,
                'label': '36°'
              },
            ],
          },
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question:
              r'在 \(\triangle ABC\) 中，若 \(AB=AC\)，点 \(D\) 在 \(AB\) 的延长线上，且外角 \(\angle DAC=120^\circ\)，求 \(\angle B\)。',
          options: const ['A. 50°', 'B. 55°', 'C. 60°', 'D. 65°'],
          answer: 'C',
          explanation:
              r'因为 \(D\) 在 \(AB\) 的延长线上，所以 \(\angle A+\angle DAC=180^\circ\)，得 \(\angle A=60^\circ\)。又因为 \(AB=AC\)，所以 \(\angle B=\angle C\)，因此 \(\angle B=\frac{180^\circ-60^\circ}{2}=60^\circ\)。',
          createdAt: now,
          order: 2,
          diagramData: const <String, dynamic>{
            'elements': [
              {
                'type': 'polygon',
                'points': [
                  [0.5, 0.35],
                  [0.24, 0.8],
                  [0.76, 0.8]
                ],
                'labels': [
                  {'text': 'A', 'x': 0.5, 'y': 0.27},
                  {'text': 'B', 'x': 0.18, 'y': 0.86},
                  {'text': 'C', 'x': 0.82, 'y': 0.86}
                ]
              },
              {
                'type': 'line',
                'x1': 0.643,
                'y1': 0.103,
                'x2': 0.5,
                'y2': 0.35,
                'style': 'solid',
                'role': 'known'
              },
              {
                'type': 'point',
                'x': 0.643,
                'y': 0.103,
                'label': 'D',
                'role': 'label'
              },
              {
                'type': 'tickMark',
                'x1': 0.5,
                'y1': 0.35,
                'x2': 0.24,
                'y2': 0.8,
                'ticks': 1
              },
              {
                'type': 'tickMark',
                'x1': 0.5,
                'y1': 0.35,
                'x2': 0.76,
                'y2': 0.8,
                'ticks': 1
              },
              {
                'type': 'angleArc',
                'vx': 0.5,
                'vy': 0.35,
                'startAngle': -60,
                'sweepAngle': 120,
                'r': 0.09,
                'label': '120°',
                'role': 'external'
              },
              {
                'type': 'angleArc',
                'vx': 0.24,
                'vy': 0.8,
                'startAngle': -5,
                'sweepAngle': 60,
                'r': 0.08,
                'label': '?'
              },
            ],
          },
        ),
      ];
    }

    if (profile.domain == _ExerciseDomain.proportionalRelation) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'若 \(\frac{a}{b}=2\)，且 \(a+b=12\)，求 \(a\) 的值。',
          options: const ['A. 4', 'B. 6', 'C. 8', 'D. 10'],
          answer: 'C',
          explanation:
              r'由 \(\frac{a}{b}=2\) 得 \(a=2b\)，代入 \(a+b=12\) 得 \(3b=12\)，所以 \(b=4\)，\(a=8\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'若 \(m:n=3:2\)，且 \(m+n=25\)，求 \(m\) 的值。',
          options: const ['A. 10', 'B. 12', 'C. 15', 'D. 18'],
          answer: 'C',
          explanation:
              r'由 \(m:n=3:2\) 可设 \(m=3k\)，\(n=2k\)，代入 \(m+n=25\) 得 \(5k=25\)，所以 \(m=15\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'若 \(\frac{x}{y}=\frac{4}{3}\)，且 \(x-y=5\)，求 \(x\) 的值。',
          options: const ['A. 10', 'B. 15', 'C. 20', 'D. 25'],
          answer: 'C',
          explanation:
              r'由 \(\frac{x}{y}=\frac{4}{3}\) 可设 \(x=4k\)，\(y=3k\)，代入 \(x-y=5\) 得 \(k=5\)，所以 \(x=20\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.domain == _ExerciseDomain.equationSystem) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'解方程组：\\begin{cases} x+y=7 \\ x-y=1 \\end{cases}，x 的值是多少？',
          options: const ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
          answer: 'C',
          explanation: r'两式相加得 2x=8，所以 x=4。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question:
              r'解方程组：\\begin{cases} 2x+y=8 \\ x+y=5 \\end{cases}，y 的值是多少？',
          options: const ['A. 1', 'B. 2', 'C. 3', 'D. 4'],
          answer: 'B',
          explanation: r'两式相减得 x=3，代入 x+y=5 得 y=2。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question:
              r'解方程组：\\begin{cases} x+2y=11 \\ 3x-y=4 \\end{cases}，x+y 的值是多少？',
          options: const ['A. 6', 'B. 7', 'C. 8', 'D. 9'],
          answer: 'C',
          explanation: r'由 3x-y=4 得 y=3x-4，代入 x+2y=11 得 x=3，y=5，所以 x+y=8。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.domain == _ExerciseDomain.solidGeometryVolume) {
      if (profile.variant == _ExerciseVariant.cylinderVolume) {
        return _defaultCylinderVolumeExercises(questionId, now);
      }
      return _defaultConeVolumeExercises(questionId, now);
    }

    if (profile.domain == _ExerciseDomain.organicChemistry) {
      return _defaultOrganicChemistryExercises(questionId, now);
    }

    if (profile.domain == _ExerciseDomain.physicsCircuit) {
      return const <GeneratedExercise>[];
    }

    if (profile.domain == _ExerciseDomain.functionEvaluation) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'已知函数 \(f(x)=2x+1\)，求 \(f(3)\) 的值。',
          options: const ['A. 5', 'B. 6', 'C. 7', 'D. 8'],
          answer: 'C',
          explanation: r'把 \(x=3\) 代入，得 \(f(3)=2\times3+1=7\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'已知函数 \(g(x)=x^2-2x\)，求 \(g(4)\) 的值。',
          options: const ['A. 6', 'B. 8', 'C. 10', 'D. 12'],
          answer: 'B',
          explanation: r'把 \(x=4\) 代入，得 \(g(4)=4^2-2\times4=16-8=8\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'已知函数 \(h(x)=-x^2+3x+2\)，求 \(h(2)\) 的值。',
          options: const ['A. 2', 'B. 4', 'C. 6', 'D. 8'],
          answer: 'B',
          explanation: r'把 \(x=2\) 代入，得 \(h(2)=-4+6+2=4\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    return const <GeneratedExercise>[];
  }

  bool _shouldSuppressGeneratedExercises(
    AnalysisResult? analysis, {
    String? sourceQuestionText,
  }) {
    if (analysis == null) return false;
    return _isUnrecognizedQuestionAnalysis(
          analysis,
          sourceQuestionText: sourceQuestionText,
        ) ||
        _isAdvancedProofNeedsReviewAnalysis(
          analysis,
          sourceQuestionText: sourceQuestionText,
        );
  }

  bool _isUnrecognizedQuestionAnalysis(
    AnalysisResult analysis, {
    String? sourceQuestionText,
  }) {
    final text = _exerciseDecisionText(analysis, sourceQuestionText)
        .replaceAll(RegExp(r'\s+'), '');
    final sourceLooksInstructionOnly = sourceQuestionText != null &&
        _isInstructionOnlyImagePrompt(sourceQuestionText);
    final hasMissingQuestionSignal = _hasAnySignal(text, <String>[
      '无法确定',
      '题干缺失',
      '缺少图片',
      '缺少原题',
      '缺少题目',
      '未提供可识别',
      '没有可识别',
      '无法还原完整题目',
      '无法整理完整题干',
      '无法准确识别',
      '无法推出题目最终答案',
      '重新识别图片',
    ]);
    if (!hasMissingQuestionSignal) return false;
    return sourceLooksInstructionOnly ||
        analysis.visualAssumptionStatus == VisualAssumptionStatus.needsReview;
  }

  bool _isAdvancedProofNeedsReviewAnalysis(
    AnalysisResult analysis, {
    String? sourceQuestionText,
  }) {
    final text = _exerciseDecisionText(analysis, sourceQuestionText)
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
    final needsReview = analysis.visualAssumptionStatus ==
            VisualAssumptionStatus.needsReview ||
        analysis.consistencyStatus == AnalysisConsistencyStatus.needsReview ||
        _hasAnySignal(text, <String>[
          '需要人工复核',
          '建议结合原题标准答案核对',
          '完整严谨性',
        ]);
    if (!needsReview) return false;

    return _hasAnySignal(text, <String>[
          '证明',
          '单调递增',
          '单调性证明',
          '集合包含',
          '抽象函数',
          '反证',
          r'd(x_0)',
          'd(x0)',
        ]) &&
        _hasAnySignal(text, <String>[
          '函数',
          r'\mathbb{r}',
          '定义域',
          '包含关系',
        ]);
  }

  String _exerciseDecisionText(
    AnalysisResult analysis,
    String? sourceQuestionText,
  ) {
    return <String>[
      sourceQuestionText ?? '',
      analysis.reconstructedQuestionText,
      analysis.finalAnswer,
      analysis.finalAnswerDerivation,
      ...analysis.steps,
      ...analysis.aiTags,
      ...analysis.knowledgePoints,
      analysis.mistakeReason,
      analysis.studyAdvice,
      analysis.consistencyNote,
      analysis.visualAssumptions?.targetObject ?? '',
      analysis.visualAssumptions?.targetQuestion ?? '',
      ...?analysis.visualAssumptions?.solutionBasis,
      ...?analysis.visualAssumptions?.uncertainItems,
      analysis.visualAssumptions?.reviewReason ?? '',
    ].join(' ');
  }

  List<GeneratedExercise> _defaultOrganicChemistryExercises(
    String questionId,
    DateTime now,
  ) {
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: '苯酚与乙酸酐反应生成有机物 X，X 经 Fries 重排可生成羟基苯乙酮。X 的结构简式最可能是',
        options: const [
          r'A. \(\mathrm{C_6H_5OCOCH_3}\)',
          r'B. \(\mathrm{C_6H_5COOCH_3}\)',
          r'C. \(\mathrm{C_6H_5CH_2OH}\)',
          r'D. \(\mathrm{C_6H_5CHO}\)',
        ],
        answer: 'A',
        explanation:
            r'苯酚与乙酸酐发生酯化生成乙酸苯酯，结构为 \(\mathrm{C_6H_5OCOCH_3}\)，其 Fries 重排可生成羟基苯乙酮。',
        createdAt: now,
        order: 0,
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question:
            r'某化合物 Y 的分子式为 \(\mathrm{C_8H_8O_2}\)，能发生银镜反应，且核磁共振氢谱有 4 组峰，峰面积比为 \(1:2:2:3\)。下列结构最符合的是',
        options: const [
          r'A. \(\mathrm{o{-}CH_3O{-}C_6H_4{-}CHO}\)',
          r'B. \(\mathrm{p{-}CH_3O{-}C_6H_4{-}CHO}\)',
          r'C. \(\mathrm{m{-}CH_3O{-}C_6H_4{-}CHO}\)',
          r'D. \(\mathrm{C_6H_5COOCH_3}\)',
        ],
        answer: 'B',
        explanation:
            '对甲氧基苯甲醛含醛基，能发生银镜反应；对位二取代使苯环氢有两组各 2H，加上醛基 H 和甲氧基 H，共 4 组峰。',
        createdAt: now,
        order: 1,
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question:
            r'苯乙酮 \(\mathrm{C_6H_5COCH_3}\) 与 \(\mathrm{NH_2OH}\) 反应，先加成后脱水。脱水后主要产物的官能团结构应为',
        options: const [
          r'A. \(\mathrm{C_6H_5C(=N{-}OH)CH_3}\)',
          r'B. \(\mathrm{C_6H_5CH(OH)CH_3}\)',
          r'C. \(\mathrm{C_6H_5COONH_4}\)',
          r'D. \(\mathrm{C_6H_5NHCOCH_3}\)',
        ],
        answer: 'A',
        explanation: r'羰基化合物与羟胺反应先生成加成产物，再脱水形成肟，结构特征为 \(\mathrm{C=N{-}OH}\)。',
        createdAt: now,
        order: 2,
      ),
    ];
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
    );
  }
}

class _ConsistencyCheck {
  const _ConsistencyCheck({
    required this.isSuspicious,
    required this.isUnverifiable,
    required this.note,
    this.forceManualReview = false,
  });

  final bool isSuspicious;
  final bool isUnverifiable;
  final String note;
  final bool forceManualReview;
}

class _ConsistencyVerification {
  const _ConsistencyVerification({
    required this.isConsistent,
    required this.correctFinalAnswer,
    required this.correctedFinalAnswerDerivation,
    required this.correctedSteps,
    required this.correctedMistakeReason,
    required this.confidence,
    required this.needsManualReview,
    required this.reason,
  });

  final bool isConsistent;
  final String correctFinalAnswer;
  final String correctedFinalAnswerDerivation;
  final List<String> correctedSteps;
  final String correctedMistakeReason;
  final String confidence;
  final bool needsManualReview;
  final String reason;
}

class ParsedAnalysisResult extends AnalysisResult {
  const ParsedAnalysisResult({
    required super.finalAnswer,
    required super.steps,
    required super.aiTags,
    required super.knowledgePoints,
    required super.mistakeReason,
    required super.studyAdvice,
    required this.rawContent,
    super.subject,
    super.finalAnswerDerivation,
    super.reconstructedQuestionText,
    super.visualAssumptions,
    super.visualAssumptionStatus,
    super.consistencyStatus,
    super.consistencyNote,
    super.wasVerifierUsed,
  });

  final String rawContent;

  @override
  AnalysisResult copyWith({
    Subject? subject,
    String? finalAnswer,
    String? finalAnswerDerivation,
    String? reconstructedQuestionText,
    VisualAssumptions? visualAssumptions,
    VisualAssumptionStatus? visualAssumptionStatus,
    List<String>? steps,
    List<String>? aiTags,
    List<String>? knowledgePoints,
    String? mistakeReason,
    String? studyAdvice,
    AnalysisConsistencyStatus? consistencyStatus,
    String? consistencyNote,
    bool? wasVerifierUsed,
  }) {
    return ParsedAnalysisResult(
      rawContent: rawContent,
      subject: subject ?? this.subject,
      finalAnswer: finalAnswer ?? this.finalAnswer,
      finalAnswerDerivation:
          finalAnswerDerivation ?? this.finalAnswerDerivation,
      reconstructedQuestionText:
          reconstructedQuestionText ?? this.reconstructedQuestionText,
      visualAssumptions: visualAssumptions ?? this.visualAssumptions,
      visualAssumptionStatus:
          visualAssumptionStatus ?? this.visualAssumptionStatus,
      steps: steps ?? this.steps,
      aiTags: aiTags ?? this.aiTags,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      mistakeReason: mistakeReason ?? this.mistakeReason,
      studyAdvice: studyAdvice ?? this.studyAdvice,
      consistencyStatus: consistencyStatus ?? this.consistencyStatus,
      consistencyNote: consistencyNote ?? this.consistencyNote,
      wasVerifierUsed: wasVerifierUsed ?? this.wasVerifierUsed,
    );
  }
}

class CandidateAnalysisPayload {
  const CandidateAnalysisPayload({
    required this.candidateId,
    required this.order,
    required this.questionText,
    required this.analysisResult,
    required this.savedExercises,
    this.subject,
    this.aiTags = const [],
    this.aiKnowledgePoints = const [],
    this.status = CandidateAnalysisStatus.success,
    this.errorMessage,
  });

  const CandidateAnalysisPayload.failed({
    required this.candidateId,
    required this.order,
    required this.questionText,
    required this.errorMessage,
  })  : analysisResult = null,
        savedExercises = const [],
        subject = null,
        aiTags = const [],
        aiKnowledgePoints = const [],
        status = CandidateAnalysisStatus.failed;

  final String candidateId;
  final int order;
  final String questionText;
  final AnalysisResult? analysisResult;
  final List<GeneratedExercise> savedExercises;
  final Subject? subject;
  final List<String> aiTags;
  final List<String> aiKnowledgePoints;
  final CandidateAnalysisStatus status;
  final String? errorMessage;

  bool get isSuccessful =>
      status == CandidateAnalysisStatus.success && analysisResult != null;
}

class _FakeAiAnalysisService extends AiAnalysisService {
  _FakeAiAnalysisService()
      : super(settingsRepository: InMemorySettingsRepository());

  @override
  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    final normalized = textHint.isNotEmpty ? textHint : '示例题目文本';
    final splitResult = await splitQuestionCandidates(
        text: normalized, subjectName: subjectName);
    return AiQuestionExtractionResult(
      extractedQuestionText: normalized,
      normalizedQuestionText: normalized,
      subject: _parseSubject(subjectName) ?? Subject.math,
      splitResult: splitResult,
    );
  }

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    return _fakeResult();
  }

  @override
  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    return _fakeResult();
  }

  @override
  Future<List<String>> fetchAvailableModels(AiProviderConfig config) async {
    return <String>['gpt-5.5'];
  }

  @override
  Future<void> testConnection(AiProviderConfig config) async {}

  @override
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) async {
    return userAnswer == correctAnswer;
  }

  @override
  Future<List<GeneratedExercise>> generateExercisesForQuestion(
    QuestionRecord question,
  ) async {
    return extractGeneratedExercises(
      question.analysisResult ?? _fakeResult(),
      questionId: question.id,
      sourceQuestionText: question.normalizedQuestionText,
    );
  }

  @override
  Future<String> answerQuestionFollowUp({
    required QuestionRecord question,
    required String userQuestion,
    List<AiFollowUpMessage> history = const <AiFollowUpMessage>[],
  }) async {
    return '可以。关键是先看清题干条件，再沿着已有步骤追问：$userQuestion';
  }
}

class TestAiAnalysisService extends AiAnalysisService {
  TestAiAnalysisService({
    required super.settingsRepository,
    required this.extractionResult,
    required this.analysisResultValue,
    this.candidateAnalysisResults,
  });

  final AiQuestionExtractionResult extractionResult;
  final AnalysisResult analysisResultValue;
  final List<AnalysisResult>? candidateAnalysisResults;
  int extractionCallCount = 0;
  int analysisCallCount = 0;
  int analysisImageCallCount = 0;

  @override
  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    extractionCallCount++;
    return extractionResult;
  }

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    analysisCallCount++;
    if (imagePath != null) analysisImageCallCount++;
    if (candidateAnalysisResults != null &&
        analysisCallCount <= candidateAnalysisResults!.length) {
      return candidateAnalysisResults![analysisCallCount - 1];
    }
    return analysisResultValue;
  }
}

class AiAnalysisException implements Exception {
  AiAnalysisException(this.message);
  final String message;
  @override
  String toString() => message;
}
