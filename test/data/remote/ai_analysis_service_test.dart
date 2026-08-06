import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_controller.dart';
import 'package:smart_wrong_notebook/src/shared/utils/composite_worksheet_detector.dart';

class _Vector {
  const _Vector(this.x, this.y);

  final double x;
  final double y;
}

Map<String, _Vector> _diagramLabels(Map<String, dynamic> diagramData) {
  final labels = <String, _Vector>{};
  final elements = diagramData['elements'] as List;
  for (final element in elements.whereType<Map>()) {
    if (element['type'] == 'polygon') {
      final points = element['points'] as List;
      final rawLabels = element['labels'] as List? ?? const [];
      for (var i = 0; i < points.length && i < rawLabels.length; i++) {
        final point = points[i] as List;
        final label = rawLabels[i] as Map;
        labels[label['text'] as String] = _Vector(
          (point[0] as num).toDouble(),
          (point[1] as num).toDouble(),
        );
      }
    } else if (element['type'] == 'point') {
      labels[element['label'] as String] = _Vector(
        (element['x'] as num).toDouble(),
        (element['y'] as num).toDouble(),
      );
    }
  }
  return labels;
}

void _registerUnknownSubjectPromptTests() {
  test('extraction prompt omits unresolved subject but keeps explicit math',
      () {
    final service = AiAnalysisService(
      settingsRepository: InMemorySettingsRepository(),
    );

    final unknownPrompt = service.buildExtractionPromptForTest(
      subjectName: Subject.unknown.name,
      textHint: '',
    );
    final mathPrompt = service.buildExtractionPromptForTest(
      subjectName: Subject.math.name,
      textHint: '',
    );
    final unknownAnalysisPrompt = service.buildAnalysisPromptForTest(
      'Read the passage.',
      Subject.unknown.name,
    );

    expect(unknownPrompt, isNot(contains('用户当前选择的科目提示')));
    expect(unknownPrompt, isNot(contains('数学')));
    expect(mathPrompt, contains('用户当前选择的科目提示：math'));
    expect(unknownAnalysisPrompt, isNot(contains('unknown')));
    expect(unknownAnalysisPrompt, contains('请先根据题目内容判断科目'));
  });
}

void main() {
  _registerUnknownSubjectPromptTests();

  test('service generates exercises from saved question without image or OCR',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"generatedExercises\":[{\"difficulty\":\"简单\",\"question\":\"已知 \\\\(x+2=5\\\\)，求 \\\\(x\\\\)\",\"options\":[\"A. 1\",\"B. 2\",\"C. 3\",\"D. 4\"],\"answer\":\"C\",\"explanation\":\"两边同时减去 \\\\(2\\\\)，得 \\\\(x=3\\\\)。\"},{\"difficulty\":\"同级\",\"question\":\"已知 \\\\(y+4=9\\\\)，求 \\\\(y\\\\)\",\"options\":[\"A. 3\",\"B. 4\",\"C. 5\",\"D. 6\"],\"answer\":\"C\",\"explanation\":\"两边同时减去 \\\\(4\\\\)，得 \\\\(y=5\\\\)。\"},{\"difficulty\":\"提高\",\"question\":\"已知 \\\\(2z+1=7\\\\)，求 \\\\(z\\\\)\",\"options\":[\"A. 2\",\"B. 3\",\"C. 4\",\"D. 5\"],\"answer\":\"B\",\"explanation\":\"先移项得 \\\\(2z=6\\\\)，所以 \\\\(z=3\\\\)。\"}]}"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final question = QuestionRecord(
      id: 'q-saved-1',
      imagePath: '/tmp/unused.jpg',
      subject: Subject.math,
      extractedQuestionText: '已知 \\(x+1=3\\)，求 \\(x\\)',
      normalizedQuestionText: '已知 \\(x+1=3\\)，求 \\(x\\)',
      contentFormat: QuestionContentFormat.plain,
      tags: const <String>[],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      lastReviewedAt: null,
      reviewCount: 0,
      isFavorite: false,
      contentStatus: ContentStatus.ready,
      masteryLevel: MasteryLevel.newQuestion,
      analysisResult: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '\\(x=2\\)',
        finalAnswerDerivation: '两边同时减去 1。',
        steps: <String>['两边同时减去 1，得到 \\(x=2\\)。'],
        aiTags: <String>['一次方程'],
        knowledgePoints: <String>['等式性质'],
        mistakeReason: '移项时容易忘记变号。',
        studyAdvice: '先把未知数单独留在一边。',
      ),
    );

    try {
      final exercises = await service.generateExercisesForQuestion(question);

      expect(exercises, hasLength(3));
      expect(exercises.first.questionId, 'q-saved-1');
      expect(exercises.first.question, contains('x+2=5'));
      expect(requests, hasLength(1));
      expect(requests.single, isNot(contains('image_url')));
      expect(requests.single, contains('只生成练习题'));
      expect(requests.single, contains('不重新识别图片'));
      expect(requests.single, contains('generatedExercises 最多 3 道'));
      expect(requests.single, contains('无法保证质量，可以少于 3 道'));
      expect(requests.single, isNot(contains('generatedExercises 必须恰好 3 道')));
      expect(requests.single, isNot(contains('请先做题目结构化提取')));
      expect(requests.single, isNot(contains('解析优先模式')));
    } finally {
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test('service avoids exercises that duplicate existing saved practice',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"generatedExercises\":[{\"difficulty\":\"简单\",\"question\":\"已知 \\\\(x^2=9\\\\)，求 \\\\(x\\\\) 的值。\",\"options\":[\"A. \\\\(x=3\\\\)\",\"B. \\\\(x=-3\\\\)\",\"C. \\\\(x=\\\\pm 3\\\\)\",\"D. \\\\(x=9\\\\)\"],\"answer\":\"C\",\"explanation\":\"平方等于 9 的数有 3 和 -3，所以 \\\\(x=\\\\pm3\\\\)。\"},{\"difficulty\":\"同级\",\"question\":\"已知 \\\\(y^2=16\\\\)，求 \\\\(y\\\\) 的值。\",\"options\":[\"A. \\\\(y=4\\\\)\",\"B. \\\\(y=-4\\\\)\",\"C. \\\\(y=\\\\pm4\\\\)\",\"D. \\\\(y=16\\\\)\"],\"answer\":\"C\",\"explanation\":\"平方等于 16 的数有 4 和 -4，所以 \\\\(y=\\\\pm4\\\\)。\"}]}"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final question = QuestionRecord(
      id: 'q-saved-repeat',
      imagePath: '/tmp/unused.jpg',
      subject: Subject.math,
      extractedQuestionText: '已知 \\(x^2+1=5\\)，求 \\(x\\)',
      normalizedQuestionText: '已知 \\(x^2+1=5\\)，求 \\(x\\)',
      contentFormat: QuestionContentFormat.plain,
      tags: const <String>[],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      lastReviewedAt: null,
      reviewCount: 0,
      isFavorite: false,
      contentStatus: ContentStatus.ready,
      masteryLevel: MasteryLevel.newQuestion,
      analysisResult: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '\\(x=\\pm2\\)',
        finalAnswerDerivation: '两边同时减去 1，再开平方。',
        steps: <String>['两边同时减去 1，得到 \\(x^2=4\\)。'],
        aiTags: <String>['平方方程'],
        knowledgePoints: <String>['开平方'],
        mistakeReason: '容易漏掉负根。',
        studyAdvice: '开平方时注意正负两个结果。',
      ),
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'old-1',
          questionId: 'q-saved-repeat',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: '已知 \\(x^2=9\\)，求 \\(x\\) 的值。',
          options: const <String>[
            'A. \\(x=3\\)',
            'B. \\(x=-3\\)',
            'C. \\(x=\\pm 3\\)',
            'D. \\(x=9\\)'
          ],
          answer: 'C',
          explanation: '平方等于 9 的数有 3 和 -3，所以 \\(x=\\pm3\\)。',
          createdAt: DateTime(2026),
          order: 0,
        ),
      ],
    );

    try {
      final exercises = await service.generateExercisesForQuestion(question);

      final exerciseQuestions =
          exercises.map((exercise) => exercise.question).toList();
      expect(exerciseQuestions, contains('已知 \\(y^2=16\\)，求 \\(y\\) 的值。'));
      expect(
          exerciseQuestions, isNot(contains('已知 \\(x^2=9\\)，求 \\(x\\) 的值。')));
      expect(requests, hasLength(1));
      expect(requests.single, contains('已有练习题'));
      expect(requests.single, contains('不要生成与已有练习题重复'));
      expect(requests.single, contains('x^2=9'));
    } finally {
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test('service answers follow-up from saved question without image or OCR',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "因为等式两边同时减去同一个数，等式仍然成立，所以可以先移项。"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final question = QuestionRecord(
      id: 'q-follow-up-1',
      imagePath: '/tmp/unused.jpg',
      subject: Subject.math,
      extractedQuestionText: '已知 \\(x+1=3\\)，求 \\(x\\)',
      normalizedQuestionText: '已知 \\(x+1=3\\)，求 \\(x\\)',
      contentFormat: QuestionContentFormat.plain,
      tags: const <String>[],
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      lastReviewedAt: null,
      reviewCount: 0,
      isFavorite: false,
      contentStatus: ContentStatus.ready,
      masteryLevel: MasteryLevel.newQuestion,
      analysisResult: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '\\(x=2\\)',
        finalAnswerDerivation: '两边同时减去 1。',
        steps: <String>['两边同时减去 1，得到 \\(x=2\\)。'],
        aiTags: <String>['一次方程'],
        knowledgePoints: <String>['等式性质'],
        mistakeReason: '移项时容易忘记变号。',
        studyAdvice: '先把未知数单独留在一边。',
      ),
    );

    try {
      final answer = await service.answerQuestionFollowUp(
        question: question,
        userQuestion: '为什么要先移项？',
      );

      expect(answer, contains('等式两边同时减去同一个数'));
      expect(requests, hasLength(1));
      expect(requests.single, isNot(contains('image_url')));
      expect(requests.single, contains('本任务只做答疑'));
      expect(requests.single, contains('为什么要先移项'));
      expect(requests.single, isNot(contains('请先做题目结构化提取')));
      expect(requests.single, isNot(contains('解析优先模式')));
      expect(requests.single, isNot(contains('generatedExercises 必须恰好 3 道')));
    } finally {
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test('service analyzes long chemistry text without resending image',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"化学\",\"finalAnswer\":\"取代反应\",\"finalAnswerDerivation\":\"由题干文字判断。\",\"reconstructedQuestionText\":\"有机合成路线题\",\"steps\":[\"根据结构化文本分析。\"],\"aiTags\":[\"有机合成\"],\"knowledgePoints\":[\"反应类型\"],\"mistakeReason\":\"图示复杂，需要核对。\",\"studyAdvice\":\"核对原图关键标注。\"}"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final imageFile = File(
      '${Directory.systemTemp.path}/swn-chem-text-only-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText:
            '某治疗胃溃疡的药物中间体 N，可通过图示合成路线制得。A 在 Cl2/FeCl3 条件下生成 B；B 经 NaOH、H+ 生成 D；D 与乙酸酐反应生成 E。请回答 A 到 B 的反应类型，并写出相关官能团变化。',
        subjectName: 'chemistry',
        imagePath: imageFile.path,
      );

      expect(analysis.finalAnswer, '取代反应');
      expect(requests, hasLength(1));
      expect(requests.single, isNot(contains('image_url')));
      expect(requests.single, contains('本次只做解析'));
      expect(requests.single, isNot(contains('生成举一反三的练习题')));
      expect(requests.single, isNot(contains('generatedExercises 必须恰好 3 道')));
    } finally {
      await imageFile.delete();
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test('service still sends image for graphical math analysis', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"数学\",\"finalAnswer\":\"70^\\circ\",\"finalAnswerDerivation\":\"由等腰三角形底角相等得到。\",\"reconstructedQuestionText\":\"如图，在三角形 ABC 中求角 B。\",\"steps\":[\"读图后根据等腰三角形性质计算。\"],\"aiTags\":[\"几何\"],\"knowledgePoints\":[\"等腰三角形\"],\"mistakeReason\":\"角度关系易看错。\",\"studyAdvice\":\"先读图确认条件。\"}"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final imageFile = File(
      '${Directory.systemTemp.path}/swn-math-image-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText: '如图，在三角形 ABC 中，AB=AC，角 A=40 度，求角 B。',
        subjectName: 'math',
        imagePath: imageFile.path,
      );

      expect(analysis.finalAnswer, r'70^\circ');
      expect(requests, hasLength(1));
      expect(requests.single, contains('image_url'));
    } finally {
      await imageFile.delete();
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test('service sends image for instruction-only language analysis', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"英语\",\"finalAnswer\":\"1.C\",\"finalAnswerDerivation\":\"根据图片题干判断。\",\"reconstructedQuestionText\":\"Saving for a Rainy Day 语法选择题。\",\"steps\":[\"直接读取图片中的英文短文和选项。\"],\"aiTags\":[\"英语\"],\"knowledgePoints\":[\"语法选择\"],\"mistakeReason\":\"忽略上下文。\",\"studyAdvice\":\"通读全文。\"}"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final imageFile = File(
      '${Directory.systemTemp.path}/swn-language-image-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText: '请识别图片中的英语题，整理完整题干并分析作答思路，生成同题型举一反三练习。',
        subjectName: 'english',
        imagePath: imageFile.path,
      );

      expect(analysis.finalAnswer, '1.C');
      expect(requests, hasLength(1));
      expect(requests.single, contains('image_url'));
      expect(requests.single, contains('请识别图片中的英语题'));
      expect(requests.single, contains('本次只做解析'));
      expect(requests.single, isNot(contains('generatedExercises 必须恰好 3 道')));
    } finally {
      await imageFile.delete();
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test(
      'service sends image and defers exercises for instruction-only Chinese analysis',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <String>[];
    final handler = server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"语文\",\"finalAnswer\":\"陶渊明\",\"finalAnswerDerivation\":\"根据图片题干判断。\",\"reconstructedQuestionText\":\"《桃花源记》文常题。\",\"steps\":[\"直接读取图片中的文言题。\"],\"aiTags\":[\"语文\"],\"knowledgePoints\":[\"文学常识\"],\"mistakeReason\":\"混淆作者。\",\"studyAdvice\":\"整理文常。\"}"
      }
    }
  ]
}
''');
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final imageFile = File(
      '${Directory.systemTemp.path}/swn-chinese-image-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText: '请识别图片中的语文题，整理完整题干并分析作答思路，生成同题型举一反三练习。',
        subjectName: 'chinese',
        imagePath: imageFile.path,
      );

      expect(analysis.finalAnswer, '陶渊明');
      expect(requests, hasLength(1));
      expect(requests.single, contains('image_url'));
      expect(requests.single, contains('请识别图片中的语文题'));
      expect(requests.single, contains('本次只做解析'));
      expect(requests.single, isNot(contains('generatedExercises 必须恰好 3 道')));
    } finally {
      await imageFile.delete();
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test(
      'service falls back to existing chemistry text when image analysis returns 524',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requestCount = 0;
    final requests = <String>[];
    final handler = server.listen((request) async {
      requestCount++;
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      if (requestCount == 1) {
        request.response.statusCode = 524;
        request.response.headers.contentType = ContentType.text;
        request.response.write('error code: 524');
      } else {
        request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"化学\",\"finalAnswer\":\"取代反应\",\"finalAnswerDerivation\":\"由已知文本判断。\",\"reconstructedQuestionText\":\"有机合成路线题\",\"steps\":[\"根据已有 OCR 文本分析。\"],\"aiTags\":[\"有机合成\"],\"knowledgePoints\":[\"反应类型\"],\"mistakeReason\":\"图示复杂，需要核对。\",\"studyAdvice\":\"核对原图关键标注。\"}"
      }
    }
  ]
}
''');
      }
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final imageFile = File(
      '${Directory.systemTemp.path}/swn-524-fallback-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText: '某治疗胃溃疡的药物中间体 N，可通过图示合成路线制得。请回答 A 到 B 的反应类型。',
        subjectName: 'chemistry',
        imagePath: imageFile.path,
      );

      expect(analysis.finalAnswer, '取代反应');
      expect(
          analysis.visualAssumptionStatus, VisualAssumptionStatus.needsReview);
      expect(requests, hasLength(2));
      expect(requests.first, contains('image_url'));
      expect(requests.last, isNot(contains('image_url')));
    } finally {
      await imageFile.delete();
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test(
      'service extracts image text for instruction-only chemistry fallback after 524',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requestCount = 0;
    final requests = <String>[];
    final handler = server.listen((request) async {
      requestCount++;
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      if (requestCount == 1) {
        request.response.statusCode = 524;
        request.response.headers.contentType = ContentType.text;
        request.response.write('error code: 524');
      } else if (requestCount == 2) {
        request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"化学\",\"extractedQuestionText\":\"9. 某治疗胃溃疡的药物中间体 N，可通过图示合成路线制得。A 在 Cl2/FeCl3 条件下生成 B。请回答 A 到 B 的反应类型。\",\"normalizedQuestionText\":\"9. 某治疗胃溃疡的药物中间体 N，可通过图示合成路线制得。A 在 Cl2/FeCl3 条件下生成 B。请回答 A 到 B 的反应类型。\"}"
      }
    }
  ]
}
''');
      } else {
        request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"化学\",\"finalAnswer\":\"取代反应\",\"finalAnswerDerivation\":\"由 Cl2/FeCl3 判断为苯环亲电取代。\",\"reconstructedQuestionText\":\"有机合成路线题\",\"steps\":[\"A 到 B 使用 Cl2/FeCl3。\",\"判断为取代反应。\"],\"aiTags\":[\"有机合成\"],\"knowledgePoints\":[\"苯环卤代\"],\"mistakeReason\":\"不要误判为加成。\",\"studyAdvice\":\"先看反应条件。\"}"
      }
    }
  ]
}
''');
      }
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);
    final imageFile = File(
      '${Directory.systemTemp.path}/swn-524-instruction-fallback-${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await imageFile.writeAsBytes(<int>[0xff, 0xd8, 0xff, 0xd9]);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText: '请识别图片中的高二化学有机合成综合题，保持为一道大题处理，不要把小问误拆成独立题；整理题干、分析作答思路。',
        subjectName: 'chemistry',
        imagePath: imageFile.path,
      );

      expect(analysis.finalAnswer, '取代反应');
      expect(requests, hasLength(3));
      expect(requests.first, contains('image_url'));
      expect(requests[1], contains('image_url'));
      expect(requests.last, isNot(contains('image_url')));
      expect(requests.last, contains('某治疗胃溃疡的药物中间体'));
      expect(requests.last, isNot(contains('请识别图片中的高二化学')));
    } finally {
      await imageFile.delete();
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test('service retries long math proof analysis with compact prompt after 524',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requestCount = 0;
    final requests = <String>[];
    final handler = server.listen((request) async {
      requestCount++;
      final body = await utf8.decoder.bind(request).join();
      requests.add(body);
      request.response.headers.contentType = ContentType.json;
      if (requestCount == 1) {
        request.response.statusCode = 524;
        request.response.headers.contentType = ContentType.text;
        request.response.write('error code: 524');
      } else {
        request.response.write(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"subject\":\"数学\",\"finalAnswer\":\"（1）D(-1)=(0,+\\\\infty)；（2）结论成立；（3）f(0)\\\\ge 1，且 f(x) 在 (0,+\\\\infty) 单调递增。\",\"finalAnswerDerivation\":\"根据 D(x) 的定义和题设包含关系得到。\",\"reconstructedQuestionText\":\"高考函数综合证明题\",\"steps\":[\"先由定义求 D(-1)。\",\"再用 D 集合包含关系证明单调性结论。\"],\"aiTags\":[\"函数\",\"证明\"],\"knowledgePoints\":[\"集合定义\",\"单调性\"],\"mistakeReason\":\"完整证明较长，需核对细节。\",\"studyAdvice\":\"先理解 D(x) 的含义。\"}"
      }
    }
  ]
}
''');
      }
      await request.response.close();
    });

    final settings = InMemorySettingsRepository();
    await settings.saveAiProviderConfig(
      AiProviderConfig(
        id: 'local',
        displayName: 'Local',
        baseUrl: 'http://${server.address.address}:${server.port}/v1',
        model: 'gpt-5.5',
        apiKey: 'test-key',
      ),
    );
    final service = AiAnalysisService(settingsRepository: settings);

    try {
      final analysis = await service.analyzeExtractedQuestion(
        correctedText:
            r'19.（17分）已知函数 \(f(x)\) 的定义域为 \(\mathbb{R}\)，且当 \(x<0\) 时，\(f(x)=2^x\)。对任意 \(x_0\in\mathbb{R}\)，定义集合 \(D(x_0)=\{d\in\mathbb{R}\mid f(x_0+d)>f(x_0)\}\)。（1）若当 \(x\geq 0\) 时，\(f(x)=1-x\)，求 \(D(-1)\)；（2）若 \(f(x)\) 是奇函数，且 \(f(x_1)\leq f(x_2)\)，\(x_1x_2\neq0\)，证明：\(D(x_2)\subseteq D(x_1)\)；（3）设 \(f(x)\) 满足：① 若 \(f(x_1)\leq f(x_2)\)，则 \(D(x_2)\subseteq D(x_1)\)；② 当 \(0<x<1\) 时，\(f(x)<f(0)\)。证明：（i）\(f(0)\geq1\)；（ii）\(f(x)\) 在区间 \((0,+\infty)\) 上单调递增。',
        subjectName: 'math',
      );

      expect(analysis.finalAnswer, contains('D(-1)'));
      expect(requests, hasLength(2));
      expect(requests.first, contains('解析优先模式'));
      expect(requests.last, contains('紧凑解析模式'));
      expect(requests.last, isNot(contains('generatedExercises 必须恰好 3 道')));
    } finally {
      await handler.cancel();
      await server.close(force: true);
    }
  });

  test(
      'fake analysis controller returns ready record without first-pass exercises',
      () async {
    final controller = AnalysisController.fake();
    final record = await controller.analyze(
      questionId: 'q-1',
      correctedText: '解方程 x+2=5',
      subjectName: '数学',
    );

    expect(record.analysisResult?.finalAnswer, 'x = 3');
    expect(record.savedExercises, isEmpty);
  });

  test('service parses final answer derivation and consistency metadata', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "25\pi/2",
  "finalAnswerDerivation": "由最后一步 \frac{1}{2}\times25\pi 得到 25\pi/2。",
  "reconstructedQuestionText": "如图，求半圆面积。",
  "steps": ["圆面积为 25\pi", "阴影面积为 25\pi/2"],
  "aiTags": ["几何"],
  "knowledgePoints": ["圆面积"],
  "mistakeReason": "漏乘二分之一",
  "studyAdvice": "注意目标区域"
}
''';

    final analysis = service.parseAnalysisResponseForTest(raw);

    expect(analysis.finalAnswer, r'25\pi/2');
    expect(analysis.finalAnswerDerivation, contains(r'\frac{1}{2}'));
    expect(analysis.reconstructedQuestionText, contains('半圆面积'));
    final restored = AnalysisResult.fromJson(
      analysis
          .copyWith(
            consistencyStatus: AnalysisConsistencyStatus.repaired,
            consistencyNote: 'AI 已复核并修正答案。',
            wasVerifierUsed: true,
          )
          .toJson(),
    );
    expect(restored.consistencyStatus, AnalysisConsistencyStatus.repaired);
    expect(restored.wasVerifierUsed, isTrue);
    expect(restored.finalAnswerDerivation, contains(r'\frac{1}{2}'));
  });

  test('service extracts content from SSE chat completion chunks', () {
    final service = AiAnalysisService.fake();
    const responseBody = '''
data: {"choices":[{"delta":{"role":"assistant"}}]}
data: {"choices":[{"delta":{"content":"{\\"subject\\":\\"数学\\","}}]}
data: {"choices":[{"delta":{"content":"\\"finalAnswer\\":\\"x=1\\"}"}}]}
data: [DONE]
''';

    final content = service.extractContentFromResponseForTest(
      Response<String>(
        requestOptions: RequestOptions(path: '/chat/completions'),
        data: responseBody,
      ),
    );

    expect(content, '{"subject":"数学","finalAnswer":"x=1"}');
  });

  test('service parses visual assumptions and marks low confidence for review',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "25\pi/2",
  "finalAnswerDerivation": "按半圆面积公式得到 25\pi/2。",
  "reconstructedQuestionText": "如图，求阴影半圆面积。",
  "visualAssumptions": {
    "targetObject": "阴影半圆",
    "targetQuestion": "求面积",
    "measurements": [
      {
        "label": "10",
        "meaning": "半圆直径",
        "usedInSolution": true,
        "evidence": "image",
        "confidence": "low"
      }
    ],
    "solutionBasis": ["半径为 5"],
    "uncertainItems": ["10 是否为直径"],
    "needsManualReview": true,
    "reviewReason": "需核对 10 的标注含义"
  },
  "steps": ["若 10 为直径，则半径为 5。", "面积为 25\pi/2。"],
  "aiTags": ["几何"],
  "knowledgePoints": ["半圆面积"],
  "mistakeReason": "未核对标注含义",
  "studyAdvice": "先确认图中关键长度"
}
''';

    final analysis = service.parseAnalysisResponseForTest(raw);
    final restored = AnalysisResult.fromJson(analysis.toJson());

    expect(restored.visualAssumptions?.targetObject, '阴影半圆');
    expect(restored.visualAssumptions?.measurements.single.label, '10');
    expect(restored.visualAssumptionStatus, VisualAssumptionStatus.needsReview);
  });

  test('service marks medium inferred solution measurement for review', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "50-\frac{29\pi}{2}",
  "finalAnswerDerivation": "外框面积减去半圆面积。",
  "reconstructedQuestionText": "如图，求外框内、半圆外区域面积。",
  "visualAssumptions": {
    "targetObject": "外框内、半圆外区域",
    "targetQuestion": "求面积",
    "measurements": [
      {
        "label": "左斜边",
        "meaning": "半圆直径",
        "usedInSolution": true,
        "evidence": "inferred",
        "confidence": "medium"
      }
    ],
    "solutionBasis": ["半圆直径为左斜边"],
    "uncertainItems": [],
    "needsManualReview": false,
    "reviewReason": ""
  },
  "steps": ["外框面积为 50。", "半圆面积为 29\pi/2。"],
  "aiTags": ["几何"],
  "knowledgePoints": ["半圆面积"],
  "mistakeReason": "需核对读图假设",
  "studyAdvice": "确认直径位置"
}
''';

    final analysis = service.parseAnalysisResponseForTest(raw);

    expect(analysis.visualAssumptionStatus, VisualAssumptionStatus.needsReview);
  });

  test(
      'visual assumption uncertainty keeps consistent verifier result in review',
      () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi/2',
      finalAnswerDerivation: r'按半圆面积公式得到 25\pi/2。',
      steps: <String>[r'若 10 为直径，则半径为 5。', r'面积为 25\pi/2。'],
      aiTags: <String>['几何'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: '图中标注含义可能不稳定。',
      studyAdvice: '先确认关键标注。',
      visualAssumptions: VisualAssumptions(
        targetObject: '阴影半圆',
        targetQuestion: '求面积',
        measurements: <VisualMeasurementAssumption>[
          VisualMeasurementAssumption(
            label: '10',
            meaning: '半圆直径',
            usedInSolution: true,
            confidence: 'low',
          ),
        ],
        uncertainItems: <String>['10 是否为直径'],
        needsManualReview: true,
        reviewReason: '需核对 10 的标注含义',
      ),
      visualAssumptionStatus: VisualAssumptionStatus.needsReview,
    );
    const verification = r'''
{
  "isConsistent": true,
  "correctFinalAnswer": "",
  "correctedFinalAnswerDerivation": "",
  "confidence": "high",
  "needsManualReview": false,
  "reason": "答案与步骤一致。"
}
''';

    final reviewed = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(reviewed.consistencyStatus, AnalysisConsistencyStatus.needsReview);
    expect(reviewed.consistencyNote, '需核对 10 的标注含义');
    expect(reviewed.wasVerifierUsed, isTrue);
  });

  test('service routes chemistry HTTP 524 image failure to text fallback', () {
    final service = AiAnalysisService.fake();
    final requestOptions = RequestOptions(path: '/chat/completions');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 524,
        data: 'error code: 524',
      ),
    );

    expect(
      service.shouldUseExtractedTextFallbackAfterImageFailureForTest(
        error,
        'chemistry',
      ),
      isTrue,
    );
    expect(
      service.shouldUseExtractedTextFallbackAfterImageFailureForTest(
        error,
        'math',
      ),
      isFalse,
    );
  });

  test('service routes only chemistry empty SSE image failure to text fallback',
      () {
    final service = AiAnalysisService.fake();
    const error = FormatException('Empty SSE chat completion content.');
    const otherError = FormatException('Unexpected character');

    expect(
      service.shouldUseExtractedTextFallbackAfterImageFormatFailureForTest(
        error,
        'chemistry',
      ),
      isTrue,
    );
    expect(
      service.shouldUseExtractedTextFallbackAfterImageFormatFailureForTest(
        error,
        'biology',
      ),
      isTrue,
    );
    expect(
      service.shouldUseExtractedTextFallbackAfterImageFormatFailureForTest(
        error,
        'math',
      ),
      isFalse,
    );
    expect(
      service.shouldUseExtractedTextFallbackAfterImageFormatFailureForTest(
        otherError,
        'chemistry',
      ),
      isFalse,
    );
  });

  test('service retries transient handshake failures from provider', () {
    final service = AiAnalysisService.fake();
    final error = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      type: DioExceptionType.unknown,
      error: const HandshakeException('Connection terminated during handshake'),
    );

    expect(service.shouldRetryPostForTest(error), isTrue);
  });

  test('service retries unknown provider failures without HTTP response', () {
    final service = AiAnalysisService.fake();
    final error = DioException(
      requestOptions: RequestOptions(path: '/chat/completions'),
      type: DioExceptionType.unknown,
    );

    expect(service.shouldRetryPostForTest(error), isTrue);
  });

  test('service retries HTTP status only when explicitly allowed', () {
    final service = AiAnalysisService.fake();
    final requestOptions = RequestOptions(path: '/chat/completions');
    final error = DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: 524,
        data: 'error code: 524',
      ),
    );

    expect(service.shouldRetryPostForTest(error), isFalse);
    expect(
      service.shouldRetryPostWithStatusCodesForTest(error, <int>{524}),
      isTrue,
    );
  });

  test('service limits extraction HTTP status retry to chemistry and biology',
      () {
    final service = AiAnalysisService.fake();

    expect(
      service.extractionRetryStatusCodesForSubjectForTest('chemistry'),
      contains(524),
    );
    expect(
      service.extractionRetryStatusCodesForSubjectForTest('化学'),
      contains(524),
    );
    expect(
      service.extractionRetryStatusCodesForSubjectForTest('biology'),
      contains(524),
    );
    expect(
      service.extractionRetryStatusCodesForSubjectForTest('math'),
      isEmpty,
    );
    expect(
      service.extractionRetryStatusCodesForSubjectForTest('physics'),
      isEmpty,
    );
    expect(
      service.extractionRetryStatusCodesForSubjectForTest('english'),
      isEmpty,
    );
  });

  test('service limits empty SSE extraction retry to chemistry and biology',
      () {
    final service = AiAnalysisService.fake();
    const error = FormatException('Empty SSE chat completion content.');
    const otherError = FormatException('Unexpected character');

    expect(
      service.shouldRetryEmptySseExtractionForTest(error, 'chemistry'),
      isTrue,
    );
    expect(
      service.shouldRetryEmptySseExtractionForTest(error, '化学'),
      isTrue,
    );
    expect(
      service.shouldRetryEmptySseExtractionForTest(error, 'biology'),
      isTrue,
    );
    expect(
      service.shouldRetryEmptySseExtractionForTest(error, 'math'),
      isFalse,
    );
    expect(
      service.shouldRetryEmptySseExtractionForTest(error, 'physics'),
      isFalse,
    );
    expect(
      service.shouldRetryEmptySseExtractionForTest(otherError, 'chemistry'),
      isFalse,
    );
  });

  test('service marks extraction fallback analysis as needs review', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: '答案',
      steps: <String>['步骤'],
      aiTags: <String>['有机'],
      knowledgePoints: <String>['合成路线'],
      mistakeReason: '读图标注复杂',
      studyAdvice: '核对结构式',
      consistencyStatus: AnalysisConsistencyStatus.consistent,
    );

    final reviewed = service.markExtractionFallbackForReviewForTest(
      analysis,
      extractedText: 'D 的分子式较模糊，疑为 C7H6O。',
    );

    expect(reviewed.visualAssumptionStatus, VisualAssumptionStatus.needsReview);
    expect(reviewed.consistencyStatus, AnalysisConsistencyStatus.needsReview);
    expect(reviewed.visualAssumptions?.needsManualReview, isTrue);
    expect(reviewed.consistencyNote, contains('核对原图'));
  });

  test('service does not let visual assumption review skip answer mismatch',
      () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi',
      finalAnswerDerivation: r'先得到 29\pi/2，但结合常见构型改成 25\pi。',
      steps: <String>[
        r'圆心为 (-5,5)，半径为 5。',
        r'半圆面积为 \frac{1}{2}\pi\times5^2=\frac{25\pi}{2}。最终答案是 \frac{25\pi}{2}。',
      ],
      aiTags: <String>['半圆', '面积'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: '读图假设不稳定。',
      studyAdvice: '核对关键标注。',
      visualAssumptions: VisualAssumptions(
        targetObject: '半圆',
        targetQuestion: '求面积',
        uncertainItems: <String>['3 与 7 的对应关系'],
        needsManualReview: true,
        reviewReason: '关键标注需核对',
      ),
      visualAssumptionStatus: VisualAssumptionStatus.needsReview,
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "25\\pi/2",
  "correctedFinalAnswerDerivation": "步骤最终得到 25\\pi/2。",
  "confidence": "low",
  "needsManualReview": true,
  "reason": "finalAnswer 与步骤最终结论不同。"
}
''';

    final reviewed = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(reviewed.finalAnswer, r'25\pi');
    expect(reviewed.consistencyStatus, AnalysisConsistencyStatus.needsReview);
    expect(reviewed.consistencyNote, 'finalAnswer 与步骤最终结论不同。');
    expect(reviewed.wasVerifierUsed, isTrue);
  });

  test('service keeps repaired visual assumptions in review state', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi',
      finalAnswerDerivation: r'误把半圆当整圆。',
      steps: <String>[r'半圆面积最终应为 25\pi/2。'],
      aiTags: <String>['半圆', '面积'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: '读图假设不稳定。',
      studyAdvice: '核对关键标注。',
      visualAssumptions: VisualAssumptions(
        targetObject: '半圆',
        targetQuestion: '求面积',
        uncertainItems: <String>['10 是否为直径'],
        needsManualReview: true,
        reviewReason: '需核对 10 的标注含义',
      ),
      visualAssumptionStatus: VisualAssumptionStatus.needsReview,
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "25\\pi/2",
  "correctedFinalAnswerDerivation": "步骤最终得到 25\\pi/2。",
  "correctedSteps": ["半圆面积最终应为 25\\pi/2。"],
  "confidence": "high",
  "needsManualReview": false,
  "reason": "finalAnswer 写成整圆面积。"
}
''';

    final reviewed = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(reviewed.finalAnswer, r'25\pi/2');
    expect(reviewed.consistencyStatus, AnalysisConsistencyStatus.needsReview);
    expect(reviewed.consistencyNote, contains('AI 已复核并修正答案'));
    expect(reviewed.consistencyNote, contains('需核对 10 的标注含义'));
    expect(reviewed.wasVerifierUsed, isTrue);
  });

  test('service applies high confidence verifier repair conservatively', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi',
      finalAnswerDerivation: r'误把整圆面积 25\pi 当作最终答案。',
      steps: <String>[
        r'圆面积为 25\pi',
        r'阴影面积为 \frac{1}{2}\times25\pi=25\pi/2，所以答案为 25\pi/2。',
      ],
      aiTags: <String>['几何'],
      knowledgePoints: <String>['圆面积'],
      mistakeReason: r'漏乘 \frac{1}{2}',
      studyAdvice: '区分整圆和半圆面积',
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "25\\pi/2",
  "correctedFinalAnswerDerivation": "最后一步得到 25\\pi/2，因此最终答案应为 25\\pi/2。",
  "confidence": "high",
  "needsManualReview": false,
  "reason": "finalAnswer 写成整圆面积，步骤最终结论是半圆面积。"
}
''';

    final repaired = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(repaired.finalAnswer, r'25\pi/2');
    expect(repaired.consistencyStatus, AnalysisConsistencyStatus.repaired);
    expect(repaired.wasVerifierUsed, isTrue);
  });

  test('service marks low confidence verifier result as needs review', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: 'C. 10',
      finalAnswerDerivation: '根据 finalAnswer 选择 C。',
      steps: <String>['设未知数', '解得 20，所以选 D。'],
      aiTags: <String>['应用题'],
      knowledgePoints: <String>['方程'],
      mistakeReason: '审题错误',
      studyAdvice: '列式后验算',
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "D. 20",
  "correctedFinalAnswerDerivation": "步骤结论为 D. 20。",
  "confidence": "low",
  "needsManualReview": true,
  "reason": "题干信息不足，无法确认。"
}
''';

    final reviewed = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(reviewed.finalAnswer, 'C. 10');
    expect(reviewed.consistencyStatus, AnalysisConsistencyStatus.needsReview);
    expect(reviewed.wasVerifierUsed, isTrue);
  });

  test('service does not let mistake reason mask final answer mismatch', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi',
      finalAnswerDerivation: r'最终答案写成 25\pi。',
      steps: <String>[
        r'由图形关系得到半圆半径为 \sqrt{29}。',
        r'半圆面积为 \frac{1}{2}\pi\times29=29\pi/2，所以答案为 29\pi/2。',
      ],
      aiTags: <String>['半圆', '面积'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: r'原答案 25\pi 可能来自把半圆误当整圆。',
      studyAdvice: '核对半径或直径关系。',
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "29\\pi/2",
  "correctedFinalAnswerDerivation": "步骤最终得到 29\\pi/2。",
  "confidence": "low",
  "needsManualReview": true,
  "reason": "finalAnswer 与步骤最终结论不同，需要人工核对图形关系。"
}
''';

    final reviewed = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(reviewed.finalAnswer, r'25\pi');
    expect(reviewed.consistencyStatus, AnalysisConsistencyStatus.needsReview);
    expect(reviewed.wasVerifierUsed, isTrue);
  });

  test('service detects semicircle area formula chain contradiction', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi',
      finalAnswerDerivation: r'最后得到 \(25\pi\)。',
      steps: <String>[
        r'解得半径 \(r=5\)。',
        r'半圆面积公式为 \(S=\frac{1}{2}\pi r^2\)，代入 \(r=5\)，得 \(S=\frac{25\pi}{2}\times2=25\pi\)。',
      ],
      aiTags: <String>['半圆', '面积'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: r'把 \(25\pi/2\) 又乘以 2。',
      studyAdvice: '确认求的是半圆还是整圆。',
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "25\\pi/2",
  "correctedFinalAnswerDerivation": "半圆面积为整圆面积的一半，因此最终答案是 25\\pi/2。",
  "confidence": "high",
  "needsManualReview": false,
  "reason": "步骤中半圆面积公式已给出 25π/2，后续多乘 2 得到 25π 是错误的。"
}
''';

    final repaired = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(repaired.finalAnswer, r'25\pi/2');
    expect(repaired.consistencyStatus, AnalysisConsistencyStatus.repaired);
  });

  test('service repairs semicircle formula chain steps from verifier', () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi',
      finalAnswerDerivation: r'最后得到 \(25\pi\)。',
      steps: <String>[
        r'解得半径 \(r=5\)。',
        r'半圆面积公式为 \(S=\frac{1}{2}\pi r^2\)，代入 \(r=5\)，得 \(S=\frac{25\pi}{2}\times2=25\pi\)。',
      ],
      aiTags: <String>['半圆', '面积'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: r'把 \(25\pi/2\) 又乘以 2。',
      studyAdvice: '确认求的是半圆还是整圆。',
    );
    const verification = r'''
{
  "isConsistent": false,
  "correctFinalAnswer": "25\\pi/2",
  "correctedFinalAnswerDerivation": "半圆面积为整圆面积的一半，因此最终答案是 25\\pi/2。",
  "correctedSteps": [
    "解得半径 \\(r=5\\)。",
    "半圆面积公式为 \\(S=\\frac{1}{2}\\pi r^2\\)，代入 \\(r=5\\)，得 \\(S=\\frac{1}{2}\\pi\\times5^2=\\frac{25\\pi}{2}\\)。"
  ],
  "correctedMistakeReason": "误把半圆面积又乘以 2，变成了整圆面积。",
  "confidence": "high",
  "needsManualReview": false,
  "reason": "原步骤中半圆面积已经是 25π/2，后续多乘 2 得到 25π 是错误的。"
}
''';

    final repaired = service.applyConsistencyVerificationForTest(
      analysis,
      verification,
    );

    expect(repaired.finalAnswer, r'25\pi/2');
    expect(repaired.steps.join(' '), isNot(contains(r'\times2=25\pi')));
    expect(repaired.steps.join(' '), contains(r'\frac{25\pi}{2}'));
    expect(repaired.mistakeReason, contains('又乘以 2'));
    expect(repaired.consistencyStatus, AnalysisConsistencyStatus.repaired);
  });

  test('service detects generic step internal contradiction', () {
    final service = AiAnalysisService.fake();
    // A single step has two separate conclusion statements pointing to
    // different numeric values — should be flagged.
    const analysis = AnalysisResult(
      finalAnswer: r'10\pi',
      finalAnswerDerivation: r'最终面积为 10\pi。',
      steps: <String>[
        r'设半径 r，则面积为 \pi r^2。',
        r'所以面积为 25\pi/2，因此最终答案为 10\pi。',
      ],
      aiTags: <String>['圆', '面积'],
      knowledgePoints: <String>['圆面积'],
      mistakeReason: '计算有误。',
      studyAdvice: '检查计算。',
    );

    final isSuspicious = service.detectConsistencyIssueForTest(analysis);
    expect(isSuspicious, isTrue);
  });

  test('service detects graphical target mismatch for composite area question',
      () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'\frac{29\pi}{2}',
      finalAnswerDerivation: r'由勾股定理求出半圆面积为 \frac{29\pi}{2}。',
      reconstructedQuestionText: '如图，求该半圆的面积。',
      visualAssumptions: VisualAssumptions(
        targetObject: '以左侧斜边为直径的半圆',
        targetQuestion: '求半圆面积',
        measurements: <VisualMeasurementAssumption>[
          VisualMeasurementAssumption(
            label: '10',
            meaning: '右侧竖直高度',
            usedInSolution: true,
            evidence: 'image',
            confidence: 'high',
          ),
        ],
      ),
      steps: <String>[
        r'直径平方为 (7-3)^2+10^2=116。',
        r'半圆面积为 \frac{29\pi}{2}。',
      ],
      aiTags: <String>['半圆面积'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: '误读目标区域',
      studyAdvice: '先确认题目求哪块区域',
    );

    final isSuspicious = service.detectConsistencyIssueForTest(
      analysis,
      questionText: '图中标注上边为3、底边为7、右边高为10，图内为半圆，求图中括号所示区域面积。',
    );
    final forceManualReview = service.consistencyIssueForcesManualReviewForTest(
      analysis,
      questionText: '图中标注上边为3、底边为7、右边高为10，图内为半圆，求图中括号所示区域面积。',
    );

    expect(isSuspicious, isTrue);
    expect(forceManualReview, isTrue);
  });

  test(
      'service does not flag steps as contradictory when conclusions are consistent',
      () {
    final service = AiAnalysisService.fake();
    const analysis = AnalysisResult(
      finalAnswer: r'25\pi/2',
      finalAnswerDerivation: r'半圆面积为 25\pi/2。',
      steps: <String>[
        r'半径为 5。',
        r'整圆面积为 25\pi。',
        r'半圆面积为 25\pi/2。',
      ],
      aiTags: <String>['半圆'],
      knowledgePoints: <String>['半圆面积'],
      mistakeReason: '无。',
      studyAdvice: '理解半圆公式。',
    );

    final isSuspicious = service.detectConsistencyIssueForTest(analysis);
    // Different steps in a derivation chain naturally have different values
    // (step 2: 整圆=25π, step 3: 半圆=25π/2). Only intra-step contradictions
    // are flagged, not inter-step intermediate calculations.
    expect(isSuspicious, isFalse);
  });

  test('service detects graphical math question conservatively', () {
    final service = AiAnalysisService.fake();

    expect(
      service.isGraphicalQuestion(
        '如图，大矩形长 175cm，高 95cm，右下角空白矩形宽 95cm，高 75cm，求其余部分面积。',
        '数学',
        imagePath: '/tmp/question.jpg',
      ),
      isTrue,
    );
    expect(
      service.isGraphicalQuestion(
        '小明去图书馆借书，第一次借了 3 本，第二次借了 2 本，一共借了几本？',
        '数学',
        imagePath: '/tmp/question.jpg',
      ),
      isFalse,
    );
    expect(
      service.isGraphicalQuestion(
        '如图所示，求阴影部分面积。',
        '语文',
        imagePath: '/tmp/question.jpg',
      ),
      isFalse,
    );
    expect(
      service.isGraphicalQuestion(
        '如图所示，求阴影部分面积。',
        '数学',
      ),
      isFalse,
    );
  });

  test('graphical analysis prompt asks model to read diagram first', () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      '如图，求阴影部分面积。',
      '数学',
      isGraphicalQuestion: true,
    );

    expect(prompt, contains('图形/示意图题分析要求'));
    expect(prompt, contains('图片题输入说明'));
    expect(prompt, contains('只能作为参考线索，不是已确认题干'));
    expect(prompt, contains('第一目标是直接根据原图理解题目并完成解题'));
    expect(prompt, contains('不要把人工确认作为解题前置条件'));
    expect(prompt, contains('不要因此跳过解题'));
    expect(prompt, contains('不要为了写完整题干而强行命名外部轮廓'));
    expect(prompt, contains('不能自动解释成上底、下底、高、半径或直径'));
    expect(
        prompt, contains('reconstructedQuestionText 只重构与求解目标直接相关且能从图片确认的条件'));
    expect(prompt, isNot(contains('已确认题目文本')));
    expect(prompt, isNot(contains('举一反三锚点')));
  });

  test('normal analysis prompt does not include graphical instructions', () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest('解方程 x+2=5', '数学');

    expect(prompt, isNot(contains('图形/示意图题分析要求')));
    expect(prompt, contains('请分析以下数学科目的错题'));
    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
  });

  test('service parses extracted question structure json', () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "物理",
  "extractedQuestionText": "如图所示，求电阻 R 两端电压。",
  "normalizedQuestionText": "如图所示，求电阻 R 两端的电压。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.physics);
    expect(extraction.extractedQuestionText, '如图所示，求电阻 R 两端电压。');
    expect(extraction.normalizedQuestionText, '如图所示，求电阻 R 两端的电压。');
  });

  test('service keeps physics choice question with table as one candidate', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "physics",
  "extractedQuestionText": "6. LED灯发光的颜色与电压的对应关系如表1所示，LED灯发光时通过它的电流始终为0.02安。把这样的LED灯接入图3所示电路，闭合开关，当滑动变阻器的滑片在图示位置，LED灯发出黄色的光。下列方案中可使LED灯发红色的光的是\n表1：\nLED灯两端的电压（伏） | LED灯发光的颜色\n1.8 | 红\n2.4 | 黄\n3.2 | 蓝\n图3：电路中有LED灯、滑动变阻器R（滑片P在靠右位置）、电源和开关S串联。\nA. 向右移动滑片P，电源电压一定变大\nB. 向右移动滑片P，电源电压可能变小\nC. 向左移动滑片P，电源电压可能不变\nD. 向左移动滑片P，电源电压一定变大",
  "normalizedQuestionText": "LED灯发光的颜色与其两端电压的对应关系如表1所示，LED灯发光时通过它的电流始终为 \(0.02\,\mathrm{A}\)。把这样的LED灯接入图3所示电路，闭合开关，当滑动变阻器的滑片在图示位置时，LED灯发出黄色的光。图3为由LED灯、滑动变阻器 \(R\)（滑片 \(P\) 在靠右位置）、电源和开关 \(S\) 组成的串联电路。下列方案中可使LED灯发红色的光的是（ ）\n\n表1：\n| LED灯两端的电压/\(\mathrm{V}\) | LED灯发光的颜色 |\n|---|---|\n| \(1.8\) | 红 |\n| \(2.4\) | 黄 |\n| \(3.2\) | 蓝 |\n\nA. 向右移动滑片 \(P\)，电源电压一定变大\nB. 向右移动滑片 \(P\)，电源电压可能变小\nC. 向左移动滑片 \(P\)，电源电压可能不变\nD. 向左移动滑片 \(P\)，电源电压一定变大"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.physics);
    expect(
      isSingleChoiceQuestionWithOptionBlock(
        extraction.normalizedQuestionText,
        subject: extraction.subject,
      ),
      isTrue,
    );
    expect(extraction.splitResult?.strategy, QuestionSplitStrategy.fallback);
    expect(extraction.splitResult?.candidates, hasLength(1));
    expect(extraction.splitResult?.candidates.single.text, contains('表1'));
    expect(
        extraction.splitResult?.candidates.single.text, contains('A. 向右移动滑片'));
  });

  test('service does not split decimal table rows as numbered questions', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "物理",
  "extractedQuestionText": "6. LED灯发光的颜色与电压的对应关系如表1所示。下列方案中可使LED灯发红色的光的是\nA. 向右移动滑片P，电源电压一定变大\nB. 向右移动滑片P，电源电压可能变小\nC. 向左移动滑片P，电源电压可能不变\nD. 向左移动滑片P，电源电压一定变大",
  "normalizedQuestionText": "LED灯发光的颜色与其两端电压的对应关系如表1所示，LED灯发光时通过它的电流始终为 \\(0.02\\,\\mathrm{A}\\)。下列方案中可使LED灯发红色的光的是（ ）\n\n\\[\n\\begin{array}{c|c}\n\\text{LED灯两端的电压/伏} & \\text{LED灯发光的颜色} \\\\\n1.8 & \\text{红} \\\\\n2.4 & \\text{黄} \\\\\n3.2 & \\text{蓝}\n\\end{array}\n\\]\n\nA. 向右移动滑片 \\(P\\)，电源电压一定变大\nB. 向右移动滑片 \\(P\\)，电源电压可能变小\nC. 向左移动滑片 \\(P\\)，电源电压可能不变\nD. 向左移动滑片 \\(P\\)，电源电压一定变大"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.physics);
    expect(extraction.splitResult?.strategy, QuestionSplitStrategy.fallback);
    expect(extraction.splitResult?.candidates, hasLength(1));
    expect(extraction.splitResult?.candidates.single.text, contains('1.8'));
    expect(
        extraction.splitResult?.candidates.single.text, contains('A. 向右移动滑片'));
  });

  test('service keeps a single physics data question with a supporting table',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "physics",
  "extractedQuestionText": "某同学利用图示电路测量小灯泡的电功率，实验中保持电源电压不变。表1记录了电压和电流的对应数据。根据表1中的数据，求小灯泡在电压为2.5伏时的电功率。",
  "normalizedQuestionText": "某同学利用图示电路测量小灯泡的电功率，实验中保持电源电压不变。\n\n表1：\n| 电压/\\(\\mathrm{V}\\) | 电流/\\(\\mathrm{A}\\) |\n|---|---|\n| \\(2.0\\) | \\(0.20\\) |\n| \\(2.5\\) | \\(0.24\\) |\n| \\(3.0\\) | \\(0.28\\) |\n\n根据表1中的数据，求小灯泡在电压为 \\(2.5\\,\\mathrm{V}\\) 时的电功率。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.physics);
    expect(extraction.splitResult?.strategy, QuestionSplitStrategy.fallback);
    expect(extraction.splitResult?.candidates, hasLength(1));
    expect(extraction.splitResult?.candidates.single.text, contains('表1'));
    expect(extraction.splitResult?.candidates.single.text, contains('电功率'));
  });

  test('service still splits extracted independent math questions', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^{2}+1=5\)，求 \(x\) 的值\n2. 若 \(\frac{a}{b}=2\) 且 \(a+b=9\)，求 \(a,b\)\n3. 函数 \(f(x)=x^{2}-2x+1\) 在 \(x=3\) 时的值是？\n4. 解方程组 \(\begin{cases} x+y=5 \\ x-y=1 \end{cases}\)\n5. 圆锥体积 \(V=\frac{1}{3}\pi r^{2}h\)，当 \(r=3,h=4\) 时求 \(V\)\n6. 在 \(\triangle ABC\) 中，若 \(AB=AC\)，且 \(\angle A=40^\circ\)，求 \(\angle B\)",
  "normalizedQuestionText": "1. 已知 \(x^{2}+1=5\)，求 \(x\) 的值。\n\n2. 若 \(\frac{a}{b}=2\)，且 \(a+b=9\)，求 \(a\) 和 \(b\) 的值。\n\n3. 函数 \(f(x)=x^{2}-2x+1\) 在 \(x=3\) 时的值是多少？\n\n4. 解方程组：\[\begin{cases} x+y=5 \\ x-y=1 \end{cases}\]\n\n5. 圆锥体积公式为 \(V=\frac{1}{3}\pi r^{2}h\)。当 \(r=3\)，\(h=4\) 时，求 \(V\)。\n\n6. 在 \(\triangle ABC\) 中，若 \(AB=AC\)，且 \(\angle A=40^\circ\)，求 \(\angle B\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(extraction.splitResult?.candidates, hasLength(6));
    expect(extraction.splitResult?.candidates.first.text, startsWith('1.'));
    expect(extraction.splitResult?.candidates.last.text, startsWith('6.'));
  });

  test('service restores double-escaped numbered question line breaks', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "math",
  "extractedQuestionText": "1. 已知 x+1=3，求 x。\\n2. 已知 y-2=0，求 y。\\n3. 已知 z=5，求 z+1。",
  "normalizedQuestionText": "1. 已知 x+1=3，求 x。\\n2. 已知 y-2=0，求 y。\\n3. 已知 z=5，求 z+1。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, isNot(contains(r'\n2.')));
    expect(extraction.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(extraction.splitResult?.candidates, hasLength(3));
    expect(extraction.splitResult?.candidates.last.text, startsWith('3.'));
  });

  test(
      'service preserves latex commands while restoring escaped question breaks',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "math",
  "extractedQuestionText": "1. 已知 \\(x\\neq 0\\)，求 x。\\n2. 已知 y=2，求 y+1。",
  "normalizedQuestionText": "1. 已知 \\(x\\neq 0\\)，求 x。\\n2. 已知 y=2，求 y+1。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.normalizedQuestionText, contains(r'\neq'));
    expect(extraction.normalizedQuestionText, isNot(contains(r'\n2.')));
    expect(extraction.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(extraction.splitResult?.candidates, hasLength(2));
  });

  test('service parses extraction json with raw latex backslashes', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。",
  "normalizedQuestionText": "已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText,
        r'已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。');
  });

  test('service parses extraction json with raw parenthesis latex delimiters',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。\n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "normalizedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。\n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, contains(r'\frac{a}{b}'));
    expect(extraction.normalizedQuestionText, contains('\n'));
  });
  test('service repairs mixed escaped delimiters and raw latex commands', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \\(x^2+1=5\\)，求 \\(x\\) 的值。\n2. 若 \\(\frac{a}{b}=2\\)，求 \\(a\\)。",
  "normalizedQuestionText": "1. 已知 \\(x^2+1=5\\)，求 \\(x\\) 的值。\n2. 若 \\(\frac{a}{b}=2\\)，求 \\(a\\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, isNot(contains(r'\\(')));
    expect(extraction.normalizedQuestionText, contains(r'\(\frac{a}{b}=2\)'));
    expect(extraction.normalizedQuestionText, contains('\n'));
  });
  test('service parses extraction json with literal newline in string', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。
2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "normalizedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。
2. 若 \(\frac{a}{b}=2\)，求 \(a\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, contains(r'\(\frac{a}{b}=2\)'));
  });
  test(
      'service recovers extraction json with doubled delimiters around raw frac',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。 \n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "normalizedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。 \n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "extra": "尾部字段"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, isNot(contains(r'\\(')));
    expect(extraction.normalizedQuestionText, contains(r'\(\frac{a}{b}=2\)'));
  });
  test('service preserves valid json escape sequences when repairing latex',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "第一行\n第二行，公式 \frac{1}{2}",
  "steps": ["先移项，使用公式 \times 2", "保留换行\n继续"],
  "aiTags": ["一元一次方程"],
  "knowledgePoints": ["解方程"],
  "mistakeReason": "漏看 \angle 标记",
  "studyAdvice": "规范书写"
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw,
        questionId: 'q-latex');

    expect(exercises, isEmpty);
  });

  test('service repairs raw latex without corrupting escaped delimiters', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\\(50-\frac{29\pi}{2}\\)",
  "finalAnswerDerivation": "外框面积 \\(50\\) 减去半圆面积 \\(\frac{29\pi}{2}\\)。",
  "visualAssumptions": {
    "targetObject": "半圆外剩余区域",
    "targetQuestion": "求面积",
    "measurements": [
      {"label": "10", "meaning": "高度", "usedInSolution": true, "evidence": "image", "confidence": "high"}
    ],
    "solutionBasis": ["外框面积减半圆面积"],
    "uncertainItems": [],
    "needsManualReview": false,
    "reviewReason": ""
  },
  "steps": ["半圆面积为 \\(\frac{29\pi}{2}\\)。"],
  "aiTags": ["几何"],
  "knowledgePoints": ["半圆面积"],
  "mistakeReason": "目标区域读错",
  "studyAdvice": "先确认目标区域"
}
''';

    final analysis = service.parseAnalysisResponseForTest(raw);

    expect(analysis.finalAnswer, r'\(50-\frac{29\pi}{2}\)');
    expect(analysis.visualAssumptions?.targetObject, '半圆外剩余区域');
    expect(analysis.visualAssumptions?.measurements.single.label, '10');
  });

  test('service parses analysis json after model preface text', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
我会基于已确认文本还原合成路线；图片细节缺失的地方会在 `visualAssumptions` 中标明依据与不确定性。
{
  "subject": "化学",
  "reconstructedQuestionText": "某治疗胃溃疡的药物中间体 N，可通过合成路线制得。",
  "visualAssumptions": {
    "targetObject": "有机合成路线",
    "targetQuestion": "回答反应类型、官能团分类、结构简式等",
    "measurements": [],
    "solutionBasis": ["根据题干文字和路线条件分析"],
    "uncertainItems": ["部分结构式需核对原图"],
    "needsManualReview": true,
    "reviewReason": "模型返回基于文本的可能解法"
  },
  "finalAnswer": "A→B 为取代反应。",
  "finalAnswerDerivation": "苯环在 Cl2/FeCl3 条件下发生亲电取代。",
  "steps": ["识别 A→B 条件为 Cl2/FeCl3。", "判断为芳香环取代反应。"],
  "aiTags": ["有机合成", "取代反应"],
  "knowledgePoints": ["苯环卤代反应属于亲电取代。"],
  "mistakeReason": "容易误判为加成反应。",
  "studyAdvice": "先按反应条件识别反应类型。"
}
''';

    final analysis = service.parseAnalysisResponseForTest(raw);

    expect(analysis.subject, Subject.chemistry);
    expect(analysis.finalAnswer, 'A→B 为取代反应。');
    expect(analysis.visualAssumptionStatus, VisualAssumptionStatus.needsReview);
  });

  test('service does not backfill linear equation when raw json has none', () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "数学",
  "finalAnswer": "x=3",
  "steps": ["移项", "求解"],
  "aiTags": ["方程"],
  "knowledgePoints": ["一元一次方程"],
  "mistakeReason": "计算粗心",
  "studyAdvice": "多练习"
}
''';

    final exercises =
        service.extractGeneratedExercisesFromContent(raw, questionId: 'q-2');

    expect(exercises, isEmpty);
  });

  test('service normalizes double backslashes in generated exercise content',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "答案为 \\(x=2\\)",
  "steps": ["使用 \\frac{1}{2}"],
  "aiTags": ["方程"],
  "knowledgePoints": ["一元一次方程"],
  "mistakeReason": "计算粗心",
  "studyAdvice": "多练习",
  "generatedExercises": [
    {
      "id": "g-latex",
      "difficulty": "同级",
      "question": "解方程：\\(x^2+1=5\\)",
      "options": ["A. \\(1\\)", "B. \\(2\\)", "C. \\(3\\)", "D. \\(4\\)"],
      "answer": "B",
      "explanation": "因为 \\frac{4}{2}=2"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw,
        questionId: 'q-latex-normalized');

    expect(exercises.single.question, r'解方程：\(x^2+1=5\)');
    expect(exercises.single.question, isNot(contains(r'\\(')));
    expect(exercises.single.explanation, r'因为 \frac{4}{2}=2');
    expect(exercises.single.options, <String>[
      r'A. \(1\)',
      r'B. \(2\)',
      r'C. \(3\)',
      r'D. \(4\)',
    ]);
  });

  test('service normalizes organic synthesis xrightarrow exercise content', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "化学",
  "finalAnswer": "D",
  "steps": ["识别反应条件"],
  "aiTags": ["有机合成"],
  "knowledgePoints": ["反应条件"],
  "mistakeReason": "箭头条件易漏读",
  "studyAdvice": "整理反应路线",
  "generatedExercises": [
    {
      "id": "chem-arrow",
      "difficulty": "同级",
      "question": "某合成路线为：对甲氧基乙酰苯胺 xrightarrowa, Δ X xrightarrowNaOH, Δ 4-甲氧基-2-硝基苯胺。",
      "options": ["A. a 为 NH_2OH/HCl", "B. a 为浓硝酸和浓硫酸", "C. a 为 Pd/HCl", "D. a 为 (CH_3CO)_2O"],
      "answer": "D",
      "explanation": "路线可写作 \\(A\\xrightarrow{NaOH,\\Delta}B\\)。"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw,
        questionId: 'q-chem-arrow');

    final exercise =
        exercises.firstWhere((exercise) => exercise.id == 'chem-arrow');
    expect(exercise.question, contains(r'\xrightarrow{a, \Delta}'));
    expect(exercise.question, contains(r'\xrightarrow{NaOH, \Delta}'));
    expect(exercise.question, isNot(contains('xrightarrowa')));
    expect(exercise.explanation, contains(r'\xrightarrow{NaOH,\Delta}'));
  });

  test('service extracts generated exercises from raw ai json', () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "数学",
  "finalAnswer": "x=2",
  "steps": ["移项", "求解"],
  "aiTags": ["方程"],
  "knowledgePoints": ["一元一次方程"],
  "mistakeReason": "计算粗心",
  "studyAdvice": "多练习",
  "generatedExercises": [
    {
      "id": "g1",
      "difficulty": "同级",
      "question": "2x+1=5，求 x 的值",
      "options": ["A. 1", "B. 2", "C. 3", "D. 4"],
      "answer": "B",
      "explanation": "2x=4，所以 x=2"
    }
  ]
}
''';

    final exercises =
        service.extractGeneratedExercisesFromContent(raw, questionId: 'q-1');

    expect(exercises.length, 1);
    expect(exercises.first.id, 'g1');
    expect(exercises.first.questionId, 'q-1');
    expect(exercises.first.question, '2x+1=5，求 x 的值');
    expect(exercises.first.options, ['A. 1', 'B. 2', 'C. 3', 'D. 4']);
  });

  test('service preserves organic chemistry generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "化学",
  "reconstructedQuestionText": "某有机合成路线中，苯酚与乙酸酐生成乙酸苯酯，乙酸苯酯经 Fries 重排生成对羟基苯乙酮；对羟基苯乙酮与 NH2OH 反应生成肟。题目还要求根据银镜反应和核磁氢谱筛选同分异构体。",
  "finalAnswer": "（1）取代反应；（2）酚类；（3）E 为乙酸苯酯。",
  "finalAnswerDerivation": "根据苯酚乙酰化、Fries 重排、羟胺成肟和同分异构体筛选规律作答。",
  "steps": [
    "苯酚与乙酸酐反应生成乙酸苯酯。",
    "乙酸苯酯经 Fries 重排可生成对羟基苯乙酮。",
    "羰基化合物与 NH2OH 加成后脱水形成肟。"
  ],
  "aiTags": ["有机合成", "同分异构", "官能团", "反应类型"],
  "knowledgePoints": ["Fries 重排", "银镜反应", "羟胺成肟", "酰胺水解"],
  "mistakeReason": "容易把结构式与分子式读错。",
  "studyAdvice": "按官能团转化梳理有机合成路线。",
  "generatedExercises": [
    {
      "id": "chem1",
      "difficulty": "简单",
      "question": "苯酚与乙酸酐反应生成有机物 X，X 经 Fries 重排可生成邻羟基苯乙酮和对羟基苯乙酮。X 的结构简式最可能是",
      "options": ["A. \\(\\mathrm{C_6H_5OCOCH_3}\\)", "B. \\(\\mathrm{C_6H_5COOCH_3}\\)", "C. \\(\\mathrm{C_6H_5CH_2OH}\\)", "D. \\(\\mathrm{C_6H_5CHO}\\)"],
      "answer": "A",
      "explanation": "苯酚与乙酸酐发生酯化生成乙酸苯酯，结构为 \\(\\mathrm{C_6H_5OCOCH_3}\\)，其 Fries 重排可生成羟基苯乙酮。"
    },
    {
      "id": "chem2",
      "difficulty": "同级",
      "question": "某化合物 Y 的分子式为 \\(\\mathrm{C_8H_8O_2}\\)，能发生银镜反应，且核磁共振氢谱有 4 组峰，峰面积比为 \\(1:2:2:3\\)。下列结构最符合的是",
      "options": ["A. \\(\\mathrm{o{-}CH_3O{-}C_6H_4{-}CHO}\\)", "B. \\(\\mathrm{p{-}CH_3O{-}C_6H_4{-}CHO}\\)", "C. \\(\\mathrm{m{-}CH_3O{-}C_6H_4{-}CHO}\\)", "D. \\(\\mathrm{C_6H_5COOCH_3}\\)"],
      "answer": "B",
      "explanation": "对甲氧基苯甲醛含醛基，能发生银镜反应；对位二取代使苯环氢有两组各 2H，加上醛基 H 和甲氧基 H，共 4 组峰。"
    },
    {
      "id": "chem3",
      "difficulty": "提高",
      "question": "苯乙酮 \\(\\mathrm{C_6H_5COCH_3}\\) 与 \\(\\mathrm{NH_2OH}\\) 反应，先加成后脱水。脱水后主要产物的官能团结构应为",
      "options": ["A. \\(\\mathrm{C_6H_5C(=N{-}OH)CH_3}\\)", "B. \\(\\mathrm{C_6H_5CH(OH)CH_3}\\)", "C. \\(\\mathrm{C_6H_5COONH_4}\\)", "D. \\(\\mathrm{C_6H_5NHCOCH_3}\\)"],
      "answer": "A",
      "explanation": "羰基化合物与羟胺反应先生成加成产物，再脱水形成肟，结构特征为 \\(\\mathrm{C=N{-}OH}\\)。"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'huaxue',
      sourceQuestionText: '请识别图片中的高二化学有机合成综合题，保持为一道大题处理，并生成同题型举一反三练习。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        <String>['chem1', 'chem2', 'chem3']);
    final exerciseText =
        exercises.map((exercise) => exercise.question).join(' ');
    expect(exerciseText, contains('Fries'));
    expect(exerciseText, contains('银镜'));
    expect(exerciseText, contains('NH_2OH'));
    expect(exerciseText, isNot(contains('x+1=4')));
  });

  test('analysis prompt analyzes organic chemistry without exercise anchors',
      () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      '高二化学有机合成综合题：苯酚与乙酸酐生成乙酸苯酯，乙酸苯酯经 Fries 重排生成对羟基苯乙酮；结合银镜反应和核磁氢谱判断同分异构体。',
      'chemistry',
    );

    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('举一反三锚点')));
    expect(prompt, isNot(contains('domain=chemistryOrganicSynthesis')));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
  });

  test('analysis prompt defers exercises for long organic chemistry text', () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      '某治疗胃溃疡的药物中间体 N，可通过图示有机合成路线制得。A 在 Cl2/FeCl3 条件下生成 B；B 经 NaOH、H+ 生成 D；D 与乙酸酐反应生成 E；E 经 HNO3/H2SO4 反应生成含酚羟基和乙酰基的芳香化合物 F。请回答反应类型、官能团分类、结构简式、同分异构体、P/Q 结构、试剂 a 和水解方程式。',
      'chemistry',
    );

    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('举一反三锚点')));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
    expect(prompt, isNot(contains('exerciseAnchor、generatedExercises 字段')));
  });

  test('analysis prompt defers exercises for long math proof text', () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      r'19.（17分）已知函数 \(f(x)\) 的定义域为 \(\mathbb{R}\)，且当 \(x<0\) 时，\(f(x)=2^x\)。对任意 \(x_0\in\mathbb{R}\)，定义集合 \(D(x_0)=\{d\in\mathbb{R}\mid f(x_0+d)>f(x_0)\}\)。（1）若当 \(x\geq 0\) 时，\(f(x)=1-x\)，求 \(D(-1)\)；（2）若 \(f(x)\) 是奇函数，且 \(f(x_1)\leq f(x_2)\)，\(x_1x_2\neq0\)，证明：\(D(x_2)\subseteq D(x_1)\)；（3）设 \(f(x)\) 满足：① 若 \(f(x_1)\leq f(x_2)\)，则 \(D(x_2)\subseteq D(x_1)\)；② 当 \(0<x<1\) 时，\(f(x)<f(0)\)。证明：（i）\(f(0)\geq1\)；（ii）\(f(x)\) 在区间 \((0,+\infty)\) 上单调递增。',
      'math',
    );

    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('举一反三锚点')));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
    expect(prompt, isNot(contains('exerciseAnchor、generatedExercises 字段')));
  });

  test('analysis prompt defers exercises for long Chinese worksheet text', () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      '《桃花源记》翻译卷：一、文常积累：本文作者____，名____，字____，自号____，____朝代文学家，有“田园诗人”之称。二、字词释义：根据原文解释“缘、鲜美、落英、缤纷、甚、异、欲穷其林、林尽水源、仿佛、才通人、豁然开朗、俨然、属、交通、阡陌、相闻、悉、黄发、垂髫、乃、具、要、咸、妻子、绝境、遂、间隔、无论、为、叹惋、延、语云、不足、扶、向、志、及、诣、规、未果、寻、问津”等。',
      'chinese',
    );

    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('举一反三锚点')));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
    expect(prompt, isNot(contains('exerciseAnchor、generatedExercises 字段')));
  });

  test('analysis prompt defers exercises for long English cloze worksheet text',
      () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      '阅读短文《Saving for a Rainy Day》，根据上下文和语法从每题 A/B/C 选项中选择最佳答案。In China, saving money has always been considered a traditional virtue. For thousands of years, Chinese people ____1____ the habit of putting money aside. She told me that the money ____2____ for rainy days. They are ____3____ in buying financial products online. While some save 50% of their income, ____4____ spend most of it on travel and hobbies. It is important ____5____ a balance. We should ask ourselves ____6____ money means to us. A recent survey shows that 70% of Chinese families still ____7____ high savings. The habit, ____8____ was passed down from ancestors, is still valuable. No matter ____9____ rich you are, never waste a penny. After all, ____10____ thrifty is part of our culture.',
      'english',
    );

    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('举一反三锚点')));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
    expect(prompt, isNot(contains('exerciseAnchor、generatedExercises 字段')));
  });

  test('analysis prompt defers exercises for short English text', () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      'Choose the best answer: For many years, my parents ____ the habit of reading before bed. A. keep B. kept C. have kept D. are keeping',
      'english',
    );

    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('举一反三锚点')));
    expect(prompt, isNot(contains('generatedExercises 必须恰好 3 道')));
    expect(prompt, isNot(contains('exerciseAnchor、generatedExercises 字段')));
  });

  test('service falls back to organic chemistry exercises for organic source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "化学",
  "reconstructedQuestionText": "有机合成路线：苯酚与乙酸酐反应，经 Fries 重排生成对羟基苯乙酮。",
  "finalAnswer": "E 为乙酸苯酯。",
  "steps": ["苯酚与乙酸酐生成乙酸苯酯。", "乙酸苯酯经 Fries 重排生成羟基苯乙酮。"],
  "aiTags": ["有机合成", "官能团"],
  "knowledgePoints": ["Fries 重排", "酯化反应"],
  "mistakeReason": "易混淆酯的连接方式。",
  "studyAdvice": "按官能团转化整理路线。",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'chem-fallback',
      sourceQuestionText: '化学有机合成题：苯酚与乙酸酐反应，经 Fries 重排生成羟基苯乙酮。',
    );

    expect(exercises.length, 3);
    final exerciseText =
        exercises.map((exercise) => exercise.question).join(' ');
    expect(exerciseText, contains('Fries'));
    expect(exerciseText, contains('银镜'));
    expect(exerciseText, isNot(contains('x+1=4')));
    expect(exerciseText, isNot(contains('求 x 的值')));
  });

  test(
      'graphical analysis prompt stays analysis-only for right triangle length',
      () {
    final service = AiAnalysisService.fake();

    final prompt = service.buildAnalysisPromptForTest(
      r'如图，\(\angle ABC=90^\circ\)，\(\angle ADC=90^\circ\)，\(BD=BC\)，\(AD=6\)，\(DC=8\)，求 \(BC\) 的长度。',
      'math',
      isGraphicalQuestion: true,
    );

    expect(prompt, contains('图形/示意图题分析要求'));
    expect(prompt, contains('解析优先模式'));
    expect(prompt, contains('本次只做解析'));
    expect(prompt, isNot(contains('domain=planeGeometryLength')));
    expect(prompt, isNot(contains('简单、同级、提高')));
  });

  test('service preserves square perpendicular bisector length exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(DF=\frac{1}{4}\)",
  "steps": ["设 \(F(2,y)\)", "由垂直平分线性质得 \(FA=FE\)", "解得 \(DF=\frac{1}{4}\)"],
  "aiTags": ["正方形", "垂直平分线", "坐标法", "线段长度"],
  "knowledgePoints": ["垂直平分线性质", "坐标法", "两点距离公式"],
  "mistakeReason": "忽略垂直平分线性质",
  "studyAdvice": "先设点坐标，再用距离相等列方程",
  "generatedExercises": [
    {"id": "sq1", "difficulty": "简单", "question": "如图，在边长为 \(4\) 的正方形 \(ABCD\) 中，点 \(E\) 是 \(BC\) 的中点，点 \(F\) 在 \(DC\) 上，且 \(F\) 在线段 \(AE\) 的垂直平分线上。求 \(DF\) 的长。", "options": ["A. \(\frac{1}{2}\)", "B. \(1\)", "C. \(\frac{3}{2}\)", "D. \(2\)"], "answer": "A", "explanation": "设 \(F(4,y)\)，由 \(FA=FE\) 得 \(4^2+(y-4)^2=2^2+y^2\)，解得 \(DF=\frac{1}{2}\)。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.2,0.2],[0.2,0.8],[0.8,0.8],[0.8,0.2]]}]}},
    {"id": "sq2", "difficulty": "同级", "question": "如图，在边长为 \(8\) 的正方形 \(ABCD\) 中，点 \(E\) 是 \(BC\) 的中点，点 \(F\) 在 \(DC\) 上，直线 \(FH\) 垂直平分线段 \(AE\)。求 \(DF\) 的长。", "options": ["A. \(\frac{1}{2}\)", "B. \(1\)", "C. \(2\)", "D. \(4\)"], "answer": "B", "explanation": "设 \(F(8,y)\)，由 \(FA=FE\) 得 \(8^2+(y-8)^2=4^2+y^2\)，解得 \(y=7\)，所以 \(DF=1\)。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.2,0.2],[0.2,0.8],[0.8,0.8],[0.8,0.2]]}]}},
    {"id": "sq3", "difficulty": "提升", "question": "如图，在边长为 \(6\) 的正方形 \(ABCD\) 中，点 \(E\) 是 \(BC\) 的中点，点 \(F\) 在 \(DC\) 上，且 \(F\) 在线段 \(AE\) 的垂直平分线上。求 \(DF\) 的长。", "options": ["A. \(\frac{1}{2}\)", "B. \(\frac{2}{3}\)", "C. \(\frac{3}{4}\)", "D. \(\frac{5}{4}\)"], "answer": "C", "explanation": "设 \(F(6,y)\)，由 \(FA=FE\) 得 \(6^2+(y-6)^2=3^2+y^2\)，解得 \(DF=\frac{3}{4}\)。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.2,0.2],[0.2,0.8],[0.8,0.8],[0.8,0.2]]}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-square-bisector',
      sourceQuestionText:
          r'如图，在边长为 \(2\) 的正方形 \(ABCD\) 中，点 \(E\) 是边 \(BC\) 的中点，点 \(F\) 在边 \(DC\) 上，直线 \(FH\) 是线段 \(AE\) 的垂直平分线，求 \(DF\) 的长。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        <String>['sq1', 'sq2', 'sq3']);
    expect(exercises.map((exercise) => exercise.difficulty),
        <String>['简单', '同级', '提高']);
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('正方形'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('垂直平分'));
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
  });

  test(
      'service limits generic generated exercises to one practice set of three',
      () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "英语",
  "finalAnswer": "1.C 2.B 3.C",
  "steps": ["语法选择"],
  "aiTags": ["语法选择"],
  "knowledgePoints": ["时态", "语态", "固定搭配"],
  "mistakeReason": "忽略语境",
  "studyAdvice": "圈出语法标志",
  "generatedExercises": [
    {"id": "g1", "difficulty": "简单", "question": "For years, they ______ here.", "options": ["A. live", "B. lived", "C. have lived", "D. living"], "answer": "C", "explanation": "For years 用现在完成时。"},
    {"id": "g2", "difficulty": "简单", "question": "The room ______ yesterday.", "options": ["A. cleans", "B. cleaned", "C. was cleaned", "D. has cleaned"], "answer": "C", "explanation": "room 与 clean 是被动关系。"},
    {"id": "g3", "difficulty": "同级", "question": "She is ______ in music.", "options": ["A. interest", "B. interesting", "C. interested", "D. to interest"], "answer": "C", "explanation": "be interested in。"},
    {"id": "g4", "difficulty": "提高", "question": "The habit, ______ is useful, remains.", "options": ["A. who", "B. which", "C. that", "D. what"], "answer": "B", "explanation": "非限制性定语从句用 which。"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw,
        questionId: 'q-english');

    expect(exercises.length, 3);
    expect(
        exercises.map((exercise) => exercise.id), <String>['g1', 'g3', 'g4']);
    expect(exercises.map((exercise) => exercise.difficulty),
        <String>['简单', '同级', '提高']);
  });

  test('service does not backfill unrecognized language analysis with algebra',
      () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "英语",
  "reconstructedQuestionText": "题目要求识别图片中的英语题并分析作答思路，但当前未提供可识别的图片内容或具体英语题干，因此无法整理完整题干。",
  "visualAssumptions": {
    "targetObject": "未知英语题目",
    "targetQuestion": "识别图片中的英语题并解答",
    "measurements": [],
    "solutionBasis": ["用户文字说明中仅包含任务要求，未包含具体英语题干、选项、图片内容或学生作答信息。"],
    "uncertainItems": ["图片中的题干内容", "题目题型", "选项内容"],
    "needsManualReview": true,
    "reviewReason": "缺少图片或具体题目文本，无法准确识别题目并判断答案。"
  },
  "finalAnswer": "无法确定",
  "finalAnswerDerivation": "由于未提供图片内容或具体英语题干，无法推出题目最终答案。",
  "steps": ["没有具体英语题目内容。", "最终结论：无法确定。"],
  "aiTags": ["英语", "题干缺失"],
  "knowledgePoints": ["英语错题分析需要至少包含题干、选项或图片内容。"],
  "mistakeReason": "当前无法分析学生错误原因，因为缺少原题内容和学生作答信息。",
  "studyAdvice": "请补充上传题目图片，或直接输入完整英文题干、选项和你的原答案。",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-unrecognized-english',
      sourceQuestionText: '请识别图片中的英语题，整理完整题干并分析作答思路，生成同题型举一反三练习。',
    );

    expect(exercises, isEmpty);
  });

  test('service does not backfill physics circuit analysis with algebra', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "物理",
  "reconstructedQuestionText": "如图所示电路中，电源电压保持不变，电阻 R1、R2 串联或并联接入电路。根据电流表示数、电压表示数和电阻变化判断电路规律。",
  "finalAnswer": "根据欧姆定律和串并联电路规律判断。",
  "finalAnswerDerivation": "先识别电路连接方式，再用 \(I=\frac{U}{R}\) 与串并联规律分析电表变化。",
  "steps": [
    "判断电路中电阻的连接方式。",
    "结合欧姆定律 \(I=\frac{U}{R}\) 分析电流和电压变化。",
    "排除与电路规律矛盾的选项。"
  ],
  "aiTags": ["电路", "欧姆定律", "串并联电路", "电表示数"],
  "knowledgePoints": ["欧姆定律", "串联电路电压规律", "并联电路电流规律"],
  "mistakeReason": "容易把电压表和电流表测量对象判断错，或把串联、并联规律混用。",
  "studyAdvice": "先标出电流路径和电表测量对象，再列出对应的欧姆定律关系。",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-physics-circuit',
      sourceQuestionText: '物理电学选择题：根据电路图、电阻、电压表和电流表示数变化判断正确选项。',
    );

    expect(exercises, isEmpty);
  });

  test('service rejects generated algebra drift for physics circuit source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "物理",
  "reconstructedQuestionText": "如图所示电路中，电源电压保持不变，闭合开关后根据电压表、电流表示数变化判断正确选项。",
  "finalAnswer": "根据欧姆定律和串并联电路规律判断。",
  "finalAnswerDerivation": "先识别电路连接方式，再用 \(I=\frac{U}{R}\) 与串并联规律分析电表变化。",
  "steps": [
    "判断电路中电阻的连接方式。",
    "结合欧姆定律分析电流和电压变化。",
    "排除与电路规律矛盾的选项。"
  ],
  "aiTags": ["电路", "欧姆定律", "串并联电路", "电表示数"],
  "knowledgePoints": ["欧姆定律", "串联电路电压规律", "并联电路电流规律"],
  "mistakeReason": "容易把电压表和电流表测量对象判断错。",
  "studyAdvice": "先标出电流路径和电表测量对象。",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "x+1=4，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项得 x=4-1=3"},
    {"id": "bad2", "difficulty": "同级", "question": "2x=8，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 6"], "answer": "C", "explanation": "两边同时除以 2 得 x=4"},
    {"id": "bad3", "difficulty": "提高", "question": "3x+2=11，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "先减 2 再除以 3 得 x=3"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-physics-circuit-drift',
      sourceQuestionText: '物理电学选择题：根据电路图、电阻、电压表和电流表示数变化判断正确选项。',
    );

    expect(exercises, isEmpty);
  });

  test('service preserves valid physics circuit generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "物理",
  "reconstructedQuestionText": "如图所示电路中，电源电压保持不变，闭合开关后根据电压表、电流表示数变化判断正确选项。",
  "finalAnswer": "根据欧姆定律和串并联电路规律判断。",
  "finalAnswerDerivation": "先识别电路连接方式，再用 \(I=\frac{U}{R}\) 与串并联规律分析电表变化。",
  "steps": ["判断电表测量对象。", "根据欧姆定律分析。"],
  "aiTags": ["电路", "欧姆定律", "串并联电路"],
  "knowledgePoints": ["欧姆定律", "串联电路", "并联电路"],
  "mistakeReason": "容易看错电表测量对象。",
  "studyAdvice": "先画出电流路径。",
  "generatedExercises": [
    {"id": "p1", "difficulty": "简单", "question": "某电阻两端电压为 6V，通过电流为 0.3A，根据欧姆定律求电阻大小。", "options": ["A. 20Ω", "B. 18Ω", "C. 2Ω", "D. 0.05Ω"], "answer": "A", "explanation": "由 \(R=\frac{U}{I}\)，得 \(R=\frac{6}{0.3}=20Ω\)。"},
    {"id": "p2", "difficulty": "同级", "question": "两个电阻串联接入电路，总电压为 12V，电流为 0.5A，总电阻为多少？", "options": ["A. 6Ω", "B. 12Ω", "C. 24Ω", "D. 36Ω"], "answer": "C", "explanation": "串联电路电流处处相等，由 \(R=\frac{U}{I}\)，得总电阻为 24Ω。"},
    {"id": "p3", "difficulty": "提高", "question": "并联电路中，支路电阻变小且电源电压不变，下列关于干路电流的判断正确的是", "options": ["A. 变大", "B. 变小", "C. 不变", "D. 先变大后变小"], "answer": "A", "explanation": "并联总电阻变小，电源电压不变，由 \(I=\frac{U}{R}\) 可知干路电流变大。"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-physics-circuit-valid',
      sourceQuestionText: '物理电学选择题：根据电路图、电阻、电压表和电流表示数变化判断正确选项。',
    );

    expect(exercises.length, 3);
    expect(
        exercises.map((exercise) => exercise.id), <String>['p1', 'p2', 'p3']);
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('电路'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('x+1=4')));
  });

  test('service drops placeholder exercises for unrecognized language source',
      () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "英语",
  "reconstructedQuestionText": "当前未提供可识别的图片内容或具体英语题干，因此无法还原完整题目。",
  "finalAnswer": "无法确定",
  "finalAnswerDerivation": "由于未提供图片或具体英语题干，无法确定题目的最终答案。",
  "steps": ["没有可识别的英语题目图片或文本。", "因此本题最终答案为：无法确定。"],
  "aiTags": ["英语"],
  "knowledgePoints": ["题干识别"],
  "mistakeReason": "缺少原题内容。",
  "studyAdvice": "需要重新识别图片。",
  "generatedExercises": [
    {
      "id": "placeholder",
      "difficulty": "简单",
      "question": "因原题图片或文本缺失，以下为占位练习：Choose the correct sentence.",
      "options": ["A. She go to school.", "B. She goes to school.", "C. She going to school.", "D. She gone to school."],
      "answer": "B",
      "explanation": "主语 She 是第三人称单数。"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-placeholder-english',
      sourceQuestionText: '请识别图片中的英语题，整理完整题干并分析作答思路，生成同题型举一反三练习。',
    );

    expect(exercises, isEmpty);
  });

  test('service rejects linear drift for quadratic root source and falls back',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "由 \(x^2+1=5\) 可得 \(x=\pm 2\)。",
  "steps": ["先得到 \(x^2=4\)", "再开平方，得到 \(x=\pm 2\)"],
  "aiTags": ["一元二次", "平方根", "解方程"],
  "knowledgePoints": ["解含平方项的简单方程", "由 \(x^2=a\) 得 \(x=\pm \sqrt{a}\)"],
  "mistakeReason": "容易漏掉负根",
  "studyAdvice": "整理成 \(x^2=a\) 后再开平方",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "x+1=4，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项得 x=4-1=3"},
    {"id": "bad2", "difficulty": "同级", "question": "2x=8，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 6"], "answer": "C", "explanation": "两边同时除以 2 得 x=4"},
    {"id": "bad3", "difficulty": "提高", "question": "3x+2=11，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "先减 2 再除以 3 得 x=3"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-quadratic',
      sourceQuestionText: r'已知 \(x^2+1=5\)，求 \(x\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), isNot(contains('bad1')));
    expect(exercises.first.question, contains('x^2'));
    expect(exercises.any((exercise) => exercise.explanation.contains(r'\pm')),
        isTrue);
  });

  test(
      'service falls back to function evaluation exercises for function source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "把 x=3 代入 f(x)=x^2-2x+1，得 f(3)=4。",
  "steps": ["代入 x=3", "计算 3^2-2\\times3+1=4"],
  "aiTags": ["函数"],
  "knowledgePoints": ["函数值", "代入求值"],
  "mistakeReason": "代入计算错误",
  "studyAdvice": "按运算顺序计算",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x^2=9，求 x", "options": ["A. 3", "B. -3", "C. \\pm3", "D. 9"], "answer": "C", "explanation": "开平方得 x=\\pm3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 (x-1)^2=16", "options": ["A. 5", "B. -3", "C. 5或-3", "D. 16"], "answer": "C", "explanation": "开平方"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 x^2+4=20", "options": ["A. 4", "B. \\pm4", "C. 8", "D. \\pm8"], "answer": "B", "explanation": "开平方"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-function',
      sourceQuestionText: r'已知函数 \(f(x)=x^2-2x+1\)，求 \(f(3)\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('函数'));
    expect(exercises.first.question, contains(r'f('));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('x^2=9')));
  });

  test(
      'service does not backfill advanced proof needs-review result with function value exercises',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "reconstructedQuestionText": "已知函数 \(f(x)\) 的定义域为 \(\mathbb{R}\)，定义 \(D(x_0)=\{d\in\mathbb{R}\mid f(x_0+d)>f(x_0)\}\)。证明 \(D(x_2)\subseteq D(x_1)\)，并证明 \(f(x)\) 在 \((0,+\infty)\) 单调递增。",
  "visualAssumptions": {
    "needsManualReview": true,
    "reviewReason": "第（3）（ii）为抽象函数证明，紧凑输出只保留关键思路，完整严谨性建议结合原题标准答案核对。"
  },
  "finalAnswer": "（1）\(D(-1)=(0,\frac{3}{2})\)；（2）\(D(x_2)\subseteq D(x_1)\)；（3）\(f(0)\geq1\)，且 \(f(x)\) 在 \((0,+\infty)\) 单调递增。",
  "finalAnswerDerivation": "由分段函数直接比较得（1），由奇函数确定正负半轴表达式并分类比较得（2），由条件①的集合包含关系结合条件②反证推出（3）的两个结论。",
  "steps": [
    "（1）令 \(y=-1+d\)，分段比较得到 \(0<d<\frac32\)。",
    "（2）利用奇函数确定正半轴表达式后分类证明集合包含。",
    "（3）抽象函数证明只保留关键思路，需要人工复核严谨性。"
  ],
  "aiTags": ["函数", "集合包含", "单调性", "反证法"],
  "knowledgePoints": ["集合 \(D(x_0)\)", "抽象函数", "单调性证明"],
  "mistakeReason": "容易把 \(D(x_0)\) 误解为函数值域或定义域。",
  "studyAdvice": "遇到抽象函数证明时，先明确集合定义，再构造增量。",
  "consistencyStatus": "needsReview",
  "consistencyNote": "第（3）（ii）为抽象函数证明，紧凑输出只保留关键思路，完整严谨性建议结合原题标准答案核对。",
  "generatedExercises": []
}
''';

    final analysis = service.parseAnalysisResponseForTest(raw);
    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-advanced-proof',
      analysis: analysis,
      sourceQuestionText:
          r'已知函数 \(f(x)\) 的定义域为 \(\mathbb{R}\)，定义 \(D(x_0)=\{d\in\mathbb{R}\mid f(x_0+d)>f(x_0)\}\)。证明 \(D(x_2)\subseteq D(x_1)\)，并证明 \(f(x)\) 在区间 \((0,+\infty)\) 单调递增。',
    );

    expect(exercises, isEmpty);
  });

  test('service falls back to volume exercises for cone volume source', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "V=12\\pi",
  "steps": ["V=\\frac{1}{3}\\pi r^2h", "代入 r=3，h=4"],
  "aiTags": ["立体几何"],
  "knowledgePoints": ["圆锥体积", "公式代入"],
  "mistakeReason": "公式记错",
  "studyAdvice": "记住圆锥体积是圆柱的三分之一",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x^2=49，则 x 的值是", "options": ["A. 7", "B. -7", "C. \\pm7", "D. 49"], "answer": "C", "explanation": "开平方"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 (x-1)^2=16", "options": ["A. 5", "B. -3", "C. 5或-3", "D. 16"], "answer": "C", "explanation": "开平方"},
    {"id": "bad3", "difficulty": "提高", "question": "x^2+1=50，求 x", "options": ["A. 7", "B. \\pm7", "C. 49", "D. 50"], "answer": "B", "explanation": "先移项再开平方"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-volume',
      sourceQuestionText: r'圆锥底面半径 r=3，高 h=4，求体积 V=\frac{1}{3}\pi r^2h。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('圆锥'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('解方程')));
  });

  test('service rejects equation system drift to linear equation', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "x=4,y=3",
  "steps": ["两式相加消元", "代入求 y"],
  "aiTags": ["方程组"],
  "knowledgePoints": ["加减消元"],
  "mistakeReason": "消元错误",
  "studyAdvice": "先观察系数",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x+1=4", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 2x=8", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "C", "explanation": "除以 2"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 3x+2=11", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-system',
      sourceQuestionText: r'解方程组：\begin{cases} x+y=7 \\ x-y=1 \end{cases}',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('方程组'));
    expect(exercises.first.question, contains('cases'));
  });

  test('service rejects triangle angle drift to algebra equation', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "70°",
  "steps": ["三角形内角和为 180°", "180-50-60=70"],
  "aiTags": ["三角形"],
  "knowledgePoints": ["内角和"],
  "mistakeReason": "角度关系不清",
  "studyAdvice": "先标出已知角",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x+1=4", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 2x=8", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "C", "explanation": "除以 2"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 3x+2=11", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-triangle',
      sourceQuestionText:
          r'在 \triangle ABC 中，\angle A=50^\circ，\angle B=60^\circ，求 \angle C。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains(r'\triangle'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('解方程 x+1')));
  });

  test('service preserves valid function evaluation generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "4",
  "steps": ["代入 x=3"],
  "aiTags": ["函数"],
  "knowledgePoints": ["函数值"],
  "mistakeReason": "代入错误",
  "studyAdvice": "先代入再计算",
  "generatedExercises": [
    {"id": "good-f", "difficulty": "同级", "question": "已知函数 f(x)=x^2+1，求 f(2)", "options": ["A. 3", "B. 4", "C. 5", "D. 6"], "answer": "C", "explanation": "代入 x=2，f(2)=4+1=5"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-function-valid',
      sourceQuestionText: r'已知函数 \(f(x)=x^2-2x+1\)，求 \(f(3)\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good-f'));
    expect(exercises[1].id, 'good-f');
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('函数'));
  });

  test('service preserves valid volume generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "12\\pi",
  "steps": ["代入体积公式"],
  "aiTags": ["立体几何"],
  "knowledgePoints": ["圆锥体积"],
  "mistakeReason": "公式错误",
  "studyAdvice": "区分圆锥和圆柱公式",
  "generatedExercises": [
    {"id": "good-v", "difficulty": "同级", "question": "圆锥底面半径为 2，高为 6，求体积", "options": ["A. 6π", "B. 8π", "C. 10π", "D. 12π"], "answer": "B", "explanation": "体积 V=1/3πr^2h=1/3π×4×6=8π"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-volume-valid',
      sourceQuestionText: r'圆锥底面半径 r=3，高 h=4，求体积 V=\frac{1}{3}\pi r^2h。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good-v'));
    expect(exercises[1].id, 'good-v');
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('圆锥'));
  });

  test(
      'service falls back to proportional relation exercises for fraction source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "a=6,b=3",
  "steps": ["由 \\(\\frac{a}{b}=2\\) 得 \\(a=2b\\)", "代入 \\(a+b=9\\)"],
  "aiTags": ["分式关系", "代入法", "二元关系"],
  "knowledgePoints": ["比值关系", "和式条件"],
  "mistakeReason": "比例关系转化错误",
  "studyAdvice": "先把比值转成倍数关系",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 \\(x^2=9\\)，求 \\(x\\)", "options": ["A. \\(3\\)", "B. \\(-3\\)", "C. \\(\\pm3\\)", "D. \\(9\\)"], "answer": "C", "explanation": "开平方"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程组：\\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "加减消元"},
    {"id": "bad3", "difficulty": "提高", "question": "已知函数 f(x)=x^2，求 f(3)", "options": ["A. 3", "B. 6", "C. 9", "D. 12"], "answer": "C", "explanation": "代入"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-proportion',
      sourceQuestionText: r'若 \(\frac{a}{b}=2\)，且 \(a+b=9\)，求 \(a,b\)。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains(r'\frac'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('方程组')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('x^2')));
  });

  test(
      'service preserves valid slots and fills invalid slots for strong source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "4",
  "steps": ["代入 x=3"],
  "aiTags": ["函数"],
  "knowledgePoints": ["函数值"],
  "mistakeReason": "代入错误",
  "studyAdvice": "先代入再计算",
  "generatedExercises": [
    {"id": "good-f", "difficulty": "同级", "question": "已知函数 f(x)=x^2+1，求 f(2)", "options": ["A. 3", "B. 4", "C. 5", "D. 6"], "answer": "C", "explanation": "代入 x=2，f(2)=4+1=5"},
    {"id": "bad-q", "difficulty": "简单", "question": "解方程 x+1=4", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项"},
    {"id": "bad-geo", "difficulty": "提高", "question": "一个圆半径为 5，求面积", "options": ["A. 5π", "B. 10π", "C. 25π", "D. 50π"], "answer": "C", "explanation": "圆面积"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-partial-strong',
      sourceQuestionText: r'已知函数 \(f(x)=x^2-2x+1\)，求 \(f(3)\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good-f'));
    expect(exercises.map((exercise) => exercise.id), isNot(contains('bad-q')));
    expect(
        exercises.map((exercise) => exercise.id), isNot(contains('bad-geo')));
    expect(exercises.map((exercise) => exercise.difficulty),
        <String>['简单', '同级', '提高']);
    expect(exercises[1].id, 'good-f');
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('函数'));
  });

  test('service preserves valid proportional relation generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "a=6,b=3",
  "steps": ["由 \\(\\frac{a}{b}=2\\) 得 \\(a=2b\\)"],
  "aiTags": ["分式关系", "代入法"],
  "knowledgePoints": ["比值关系", "和式条件"],
  "mistakeReason": "比例关系转化错误",
  "studyAdvice": "先转化再代入",
  "generatedExercises": [
    {"id": "good-ratio", "difficulty": "同级", "question": "若 \\(\\frac{x}{y}=3\\)，且 \\(x+y=16\\)，求 \\(x\\) 的值。", "options": ["A. \\(4\\)", "B. \\(8\\)", "C. \\(12\\)", "D. \\(16\\)"], "answer": "C", "explanation": "由 \\(\\frac{x}{y}=3\\) 得 \\(x=3y\\)，代入 \\(x+y=16\\) 得 \\(4y=16\\)，所以 \\(x=12\\)。"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-proportion-valid',
      sourceQuestionText: r'若 \(\frac{a}{b}=2\)，且 \(a+b=9\)，求 \(a,b\)。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good-ratio'));
    expect(exercises[1].id, 'good-ratio');
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains(r'\frac'));
  });

  test('service triangle fallback wraps angle latex in inline math', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "70°",
  "steps": ["三角形内角和为 180°"],
  "aiTags": ["三角形"],
  "knowledgePoints": ["内角和"],
  "mistakeReason": "角度关系不清",
  "studyAdvice": "先标出已知角",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-triangle-fallback-format',
      sourceQuestionText:
          r'在 \(\triangle ABC\) 中，若 \(AB=AC\)，且 \(\angle A=40^\circ\)，求 \(\angle B\)。',
    );

    expect(exercises.first.question, contains(r'\(\angle A=50^\circ\)'));
    expect(exercises.first.question, isNot(contains(r'\\angle')));
    expect(exercises.first.explanation, contains(r'\(180^\circ\)'));
  });

  test('service rejects exterior angle diagram when D is not on AB extension',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "70°",
  "steps": ["等腰三角形底角相等"],
  "aiTags": ["等腰三角形", "外角"],
  "knowledgePoints": ["三角形外角"],
  "mistakeReason": "外角位置不清",
  "studyAdvice": "先画延长线",
  "generatedExercises": [
    {
      "id": "bad-exterior",
      "difficulty": "提高",
      "question": "在 \\(\\triangle ABC\\) 中，若 \\(AB=AC\\)，点 \\(D\\) 在 \\(AB\\) 的延长线上，且外角 \\(\\angle DAC=120^\\circ\\)，求 \\(\\angle B\\)。",
      "options": ["A. \\(50^\\circ\\)", "B. \\(55^\\circ\\)", "C. \\(60^\\circ\\)", "D. \\(65^\\circ\\)"],
      "answer": "C",
      "explanation": "外角 120°，所以顶角 60°，底角 60°。",
      "diagramData": {
        "elements": [
          {"type": "polygon", "points": [[0.5,0.22],[0.2,0.82],[0.82,0.82]], "labels": [{"text":"A","x":0.5,"y":0.14},{"text":"B","x":0.15,"y":0.87},{"text":"C","x":0.87,"y":0.87}]},
          {"type": "line", "x1":0.5,"y1":0.22,"x2":0.36,"y2":0.02,"style":"solid","role":"known"},
          {"type":"point","x":0.36,"y":0.02,"label":"D","role":"label"},
          {"type":"tickMark","x1":0.5,"y1":0.22,"x2":0.2,"y2":0.82,"ticks":1},
          {"type":"tickMark","x1":0.5,"y1":0.22,"x2":0.82,"y2":0.82,"ticks":1},
          {"type":"angleArc","vx":0.5,"vy":0.22,"startAngle":20,"sweepAngle":120,"r":0.1,"label":"120°"},
          {"type":"angleArc","vx":0.2,"vy":0.82,"startAngle":0,"sweepAngle":60,"r":0.08,"label":"?"}
        ],
        "auxiliaryLines": []
      }
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-exterior-diagram',
      sourceQuestionText:
          r'在 \(\triangle ABC\) 中，若 \(AB=AC\)，且 \(\angle A=40^\circ\)，求 \(\angle B\)。',
    );

    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('bad-exterior')));
    final hard =
        exercises.singleWhere((exercise) => exercise.difficulty == '提高');
    expect(hard.question, contains('外角'));
    expect(hard.question, contains(r'\(\angle DAC=120^\circ\)'));

    final labels = _diagramLabels(hard.diagramData!);
    final a = labels['A']!;
    final b = labels['B']!;
    final d = labels['D']!;
    final ab = _Vector(b.x - a.x, b.y - a.y);
    final ad = _Vector(d.x - a.x, d.y - a.y);
    final cross = (ab.x * ad.y - ab.y * ad.x).abs();
    final dot = ab.x * ad.x + ab.y * ad.y;

    expect(cross, lessThan(0.001));
    expect(dot, lessThan(0));
    final externalArc = (hard.diagramData!['elements'] as List)
        .whereType<Map>()
        .where((element) => element['type'] == 'angleArc')
        .singleWhere((element) => element['label'] == '120°');
    expect(externalArc['role'], 'external');
  });
  test('service preserves valid quadratic root generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(x=\pm2\)",
  "steps": ["\(x^2=4\)", "\(x=\pm2\)"],
  "aiTags": ["一元二次", "平方根"],
  "knowledgePoints": ["由 \(x^2=a\) 求正负根"],
  "mistakeReason": "漏负根",
  "studyAdvice": "注意正负根",
  "generatedExercises": [
    {"id": "good1", "difficulty": "同级", "question": "已知 \(x^2=16\)，求 \(x\) 的值。", "options": ["A. \(4\)", "B. \(-4\)", "C. \(\pm4\)", "D. \(16\)"], "answer": "C", "explanation": "由 \(x^2=16\) 得 \(x=\pm4\)。"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-valid-quadratic',
      sourceQuestionText: r'已知 \(x^2+1=5\)，求 \(x\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good1'));
    expect(exercises[1].id, 'good1');
    expect(exercises.first.question, contains('x^2'));
  });

  test(
      'service falls back to right triangle length exercises for pythagorean source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "5",
  "steps": ["先用勾股定理求 AC", "再结合等长关系求 BC"],
  "aiTags": ["直角三角形", "勾股定理"],
  "knowledgePoints": ["勾股定理", "线段长度"],
  "mistakeReason": "容易把中间量当答案",
  "studyAdvice": "先找直角三角形",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x+1=4，求 x 的值", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3"},
    {"id": "bad2", "difficulty": "同级", "question": "一个圆的半径为 5，求面积", "options": ["A. 10π", "B. 25π", "C. 50π", "D. 100π"], "answer": "B", "explanation": "圆面积公式"},
    {"id": "bad3", "difficulty": "提高", "question": "函数 f(x)=x^2，求 f(3)", "options": ["A. 3", "B. 6", "C. 9", "D. 12"], "answer": "C", "explanation": "代入"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-right-triangle',
      sourceQuestionText:
          r'如图，\(\angle ABC=90^\circ\)，\(\angle ADC=90^\circ\)，\(BD=BC\)，\(AD=6\)，\(DC=8\)，求 \(BC\) 的长度。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), isNot(contains('bad1')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('直角'));
    expect(exercises.map((exercise) => exercise.explanation).join(' '),
        contains('勾股'));
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
  });

  test('service rejects diagramData exercise when it drifts from source topic',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(\frac{25\pi}{2}\)",
  "steps": ["半圆面积"],
  "aiTags": ["半圆", "面积"],
  "knowledgePoints": ["半圆面积"],
  "mistakeReason": "漏乘二分之一",
  "studyAdvice": "先判断目标区域",
  "generatedExercises": [
    {"id": "bad-diagram", "difficulty": "简单", "question": "解方程 x+1=4，求 x 的值", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-diagram-quality-gate',
      sourceQuestionText: r'如图，一个半径为 5 cm 的圆，求阴影半圆面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('bad-diagram')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('半圆'));
  });

  test('service rejects equation drift for circle area source and falls back',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(\frac{25\pi}{2}\)",
  "steps": ["整圆面积是 \(25\pi\)", "半圆面积是 \(\frac{25\pi}{2}\)"],
  "aiTags": ["圆", "面积", "半圆"],
  "knowledgePoints": ["圆面积", "半圆面积"],
  "mistakeReason": "漏乘二分之一",
  "studyAdvice": "先判断目标区域是整圆还是部分圆",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x+1=4，求 x 的值", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 2x=8", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "C", "explanation": "除以 2"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 3x+2=11", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-circle-area',
      sourceQuestionText: r'如图，一个半径为 5 cm 的圆，求阴影半圆面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), isNot(contains('bad1')));
    expect(exercises.first.question, contains('半圆'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('解方程')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('圆环')));
  });

  test('service preserves valid circle area generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(\frac{25\pi}{2}\)",
  "steps": ["整圆面积是 \(25\pi\)", "半圆面积是 \(\frac{25\pi}{2}\)"],
  "aiTags": ["圆", "面积", "半圆"],
  "knowledgePoints": ["圆面积", "半圆面积"],
  "mistakeReason": "漏乘二分之一",
  "studyAdvice": "先判断目标区域是整圆还是部分圆",
  "generatedExercises": [
    {"id": "good-circle", "difficulty": "同级", "question": "一个半圆的半径为 6 cm，求半圆面积。", "options": ["A. \(12\pi\)", "B. \(18\pi\)", "C. \(36\pi\)", "D. \(72\pi\)"], "answer": "B", "explanation": "整圆面积为 \(36\pi\)，半圆面积是一半，所以是 \(18\pi\)。", "diagramData": {"elements": [{"type": "arc", "cx": 0.5, "cy": 0.6, "r": 0.3, "startAngle": 180, "sweepAngle": 180}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-circle-valid',
      sourceQuestionText: r'如图，一个半径为 5 cm 的圆，求阴影半圆面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good-circle'));
    expect(exercises[1].id, 'good-circle');
    expect(exercises.map((exercise) => exercise.question).join(' '),
        contains('半圆'));
  });

  test('service does not treat framed semicircle-only source as composite area',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(25\pi/2\)",
  "steps": ["左斜边是半圆直径", "半圆面积为 \(25\pi/2\)"],
  "aiTags": ["半圆面积", "勾股定理"],
  "knowledgePoints": ["半圆面积"],
  "mistakeReason": "直径读错",
  "studyAdvice": "先确认半圆直径",
  "generatedExercises": [
    {"id": "semi-only", "difficulty": "同级", "question": "如图，外框上边长为 4，下边长为 10，右边高为 8，左侧斜边为半圆直径。求该半圆的面积。", "options": ["A. \(25\pi/2\)", "B. \(25\pi\)", "C. \(50\pi\)", "D. \(10\pi\)"], "answer": "A", "explanation": "水平差为 6，高为 8，直径为 10，半圆面积为 \(25\pi/2\)。", "diagramData": {"elements": [{"type": "arc", "cx": 0.5, "cy": 0.5, "r": 0.3, "startAngle": 180, "sweepAngle": 180}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-framed-semicircle-only',
      sourceQuestionText: '如图，外框上边长为 3，下边长为 7，右边高为 10，左侧斜边为半圆直径，求该半圆的面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('semi-only'));
    expect(exercises[1].id, 'semi-only');
    expect(exercises[1].question, contains('求该半圆的面积'));
  });

  test(
      'service falls back to pythagorean semicircle exercises for framed semicircle source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(\frac{29\pi}{2}\)",
  "steps": ["左斜边是半圆直径", "由勾股定理求出直径平方", "半圆面积为 \(\frac{29\pi}{2}\)"],
  "aiTags": ["半圆面积", "勾股定理"],
  "knowledgePoints": ["半圆面积", "勾股定理"],
  "mistakeReason": "直径读错",
  "studyAdvice": "先由水平差和高求直径",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-framed-semicircle-fallback',
      sourceQuestionText: '如图，外框上边长为 3，下边长为 7，右边高为 10，左侧斜边为半圆直径，求该半圆的面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('上边长'));
    expect(exercises.first.question, contains('左侧斜边为半圆直径'));
    expect(exercises.map((exercise) => exercise.explanation).join(' '),
        contains('勾股'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('半径为 4')));
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
    final diagramTexts = (exercises.first.diagramData!['elements'] as List)
        .whereType<Map>()
        .where((element) => element['type'] == 'text')
        .map((element) => element['text'])
        .join(' ');
    expect(diagramTexts, contains('求半圆面积'));
    expect(diagramTexts, isNot(contains('求此区域')));
  });

  test('service parameterizes framed semicircle fallback from source numbers',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(\frac{25\pi}{2}\)",
  "steps": ["左侧斜边是半圆直径", "由水平差和高求直径", "求半圆面积"],
  "aiTags": ["半圆面积", "勾股定理"],
  "knowledgePoints": ["半圆面积", "勾股定理"],
  "mistakeReason": "直径读错",
  "studyAdvice": "先确认上下边和高",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-param-framed-semicircle',
      sourceQuestionText: '如图，外框上边长为 6，下边长为 14，右边高为 15，左侧斜边为半圆直径，求该半圆的面积。',
    );

    expect(exercises.length, 3);
    expect(exercises[1].question, contains('上边长为 6'));
    expect(exercises[1].question, contains('下边长为 14'));
    expect(exercises[1].question, contains('右边高为 15'));
    expect(exercises[1].options?[1], contains('289π/8'));
    expect(exercises[1].answer, 'B');
    expect(exercises[1].explanation, contains('水平差为 8'));
    expect(exercises[1].explanation, contains('直径平方为 289'));
    final diagramTexts = (exercises[1].diagramData!['elements'] as List)
        .whereType<Map>()
        .where((element) => element['type'] == 'text')
        .map((element) => element['text'])
        .join(' ');
    expect(diagramTexts, contains('6'));
    expect(diagramTexts, contains('14'));
    expect(diagramTexts, contains('15'));
    expect(diagramTexts, contains('求半圆面积'));
  });

  test('service rejects solid geometry drift for composite semicircle area',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(25\pi\)",
  "steps": ["半圆面积公式为 \(S=\frac{1}{2}\pi r^2\)", "代入 \(r=5\)，得 \(S=\frac{25\pi}{2}\times2=25\pi\)"],
  "aiTags": ["半圆", "面积", "梯形"],
  "knowledgePoints": ["半圆面积", "切线关系"],
  "mistakeReason": "混淆半圆和整圆面积",
  "studyAdvice": "先确认目标区域",
  "generatedExercises": [
    {"id": "bad-solid", "difficulty": "简单", "question": "圆锥底面半径为 r=2，高为 h=3，则体积 V 为", "options": ["A. \(4\pi\)", "B. \(8\pi\)", "C. \(12\pi\)", "D. \(6\pi\)"], "answer": "A", "explanation": "\(V=\frac{1}{3}\pi r^2h=4\pi\)"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-semicircle-no-solid',
      sourceQuestionText: '如图，上边长为3，下边长为7，右边高为10，半圆以左侧斜边为直径，求外边界与半圆弧之间区域的面积。',
    );

    expect(exercises.length, 3);
    expect(
        exercises.map((exercise) => exercise.id), isNot(contains('bad-solid')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('圆锥')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('体积')));
    expect(exercises.first.question, contains('上边'));
    expect(exercises.first.question, contains('半圆'));
  });

  test('service replaces invalid composite semicircle exercise by slot', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "13\pi",
  "steps": ["直径为 2\sqrt{26}", "半圆面积为 13\pi"],
  "aiTags": ["半圆", "面积", "勾股定理"],
  "knowledgePoints": ["半圆面积", "勾股定理"],
  "mistakeReason": "读图假设需核对",
  "studyAdvice": "先确认直径",
  "generatedExercises": [
    {"id": "good-simple", "difficulty": "简单", "question": "如图，上边长为 2，下边长为 5，右边高为 4，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。", "options": ["A. 14-25π/8", "B. 14-25π/4", "C. 20-25π/8", "D. 14-5π/2"], "answer": "A", "explanation": "外边界面积为 14，半圆面积为 25π/8，目标面积为 14-25π/8。", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}},
    {"id": "good-same", "difficulty": "同级", "question": "如图，上边长为 3，下边长为 7，右边高为 10，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。", "options": ["A. 50-29π", "B. 50-29π/2", "C. 40-29π/2", "D. 50-58π"], "answer": "B", "explanation": "外边界面积为 50，半圆面积为 29π/2，目标面积为 50-29π/2。", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}},
    {"id": "bad-conflict", "difficulty": "提高", "question": "如图，上边长为 4，下边长为 10，右边高为 8，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。", "options": ["A. 56-50π", "B. 48-25π", "C. 56-25π", "D. 56-25π/2"], "answer": "C", "explanation": "外边界面积为 56，半圆面积为 25π/2。注意这里目标面积应为 56-25π/2，因此答案为 D。", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-self-invalidating',
      sourceQuestionText: '如图，上边长为3，下边长为7，右边高为10，半圆以左侧斜边为直径，求外边界与半圆弧之间区域的面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), contains('good-simple'));
    expect(exercises.map((exercise) => exercise.id), contains('good-same'));
    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('bad-conflict')));
    expect(exercises[2].question, contains('上边长为 4'));
    expect(
      exercises.map((exercise) => exercise.explanation).join(' '),
      isNot(contains('选项中没有')),
    );
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
  });

  test(
      'service rejects generated exercise when explanation states different correct option',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "50-\frac{29\pi}{2}",
  "steps": ["外框面积为 50。", "半圆面积为 29\pi/2。"],
  "aiTags": ["半圆面积", "组合图形"],
  "knowledgePoints": ["整体减部分"],
  "mistakeReason": "目标区域读错",
  "studyAdvice": "先确认目标区域",
  "generatedExercises": [
    {"id": "bad-correct-option", "difficulty": "同级", "question": "如图，上边长为 5，下边长为 11，右边高为 8，半圆以左侧斜边为直径。求外框内、半圆外的区域面积。", "options": ["A. 64-25π", "B. 64-50π", "C. 128-25π", "D. 64-25π/2"], "answer": "A", "explanation": "外框面积为 64，半圆面积为 25π/2，因此剩余面积为 64-25π/2，正确选项为 D。", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-correct-option-conflict',
      sourceQuestionText:
          '图中外框由上水平边、右竖边、下水平边和左斜边围成，上水平边长为 3，下水平边长为 7，右竖边高为 10；左斜边作为半圆的直径，半圆位于外框内。求外框内、半圆外的括号状区域面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('bad-correct-option')));
    expect(exercises[1].answer, 'B');
    expect(exercises[1].question, contains('上边长为 3'));
  });

  test(
      'service rejects generated exercise when answer option value conflicts with explanation conclusion',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "50-\frac{29\pi}{2}",
  "steps": ["外框面积为 50。", "半圆面积为 29\pi/2。"],
  "aiTags": ["半圆面积", "组合图形"],
  "knowledgePoints": ["整体减部分"],
  "mistakeReason": "目标区域读错",
  "studyAdvice": "先确认目标区域",
  "generatedExercises": [
    {"id": "bad-value-conflict", "difficulty": "同级", "question": "如图，上边长为 5，下边长为 11，右边高为 8，半圆以左侧斜边为直径。求外框内、半圆外的区域面积。", "options": ["A. 64-25π", "B. 64-50π", "C. 128-25π", "D. 64-25π/2"], "answer": "A", "explanation": "外框面积为 64，半圆面积为 25π/2，因此剩余面积为 64-25π/2。", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-option-value-conflict',
      sourceQuestionText:
          '图中外框由上水平边、右竖边、下水平边和左斜边围成，上水平边长为 3，下水平边长为 7，右竖边高为 10；左斜边作为半圆的直径，半圆位于外框内。求外框内、半圆外的括号状区域面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('bad-value-conflict')));
    expect(exercises[1].answer, 'B');
    expect(exercises[1].options?[1], contains(r'50-\frac{29\pi}{2}'));
  });

  test('service rejects semicircle-only target for composite area source', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "50-\frac{29\pi}{2}",
  "steps": ["外框面积为 50。", "半圆面积为 29\pi/2。"],
  "aiTags": ["半圆面积", "勾股定理", "组合图形", "面积差"],
  "knowledgePoints": ["半圆面积", "整体减部分"],
  "mistakeReason": "需先确认目标区域",
  "studyAdvice": "先求外框面积，再减半圆面积",
  "generatedExercises": [
    {"id": "bad-target", "difficulty": "简单", "question": "如图，外框上水平边长为 4，下水平边长为 10，右侧竖直边高为 8，左斜边为半圆直径。求该半圆的面积。", "options": ["A. 25π/2", "B. 25π", "C. 50π", "D. 10π"], "answer": "A", "explanation": "水平差为 6，高为 8，半圆直径为 10，半圆面积为 25π/2。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.3,0.2],[0.8,0.2],[0.8,0.8],[0.1,0.8]]}]}},
    {"id": "good-same", "difficulty": "同级", "question": "如图，外框上水平边长为 5，下水平边长为 11，右侧竖直边高为 8，左斜边为半圆直径。求外框内、半圆外的括号状区域面积。", "options": ["A. 64-25π", "B. 64-25π/2", "C. 88-25π/2", "D. 64-50π/2"], "answer": "B", "explanation": "外框面积为 64。由勾股定理得半圆直径为 10，半径为 5，半圆面积为 25π/2，目标面积为 64-25π/2。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.3,0.2],[0.8,0.2],[0.8,0.8],[0.1,0.8]]}]}},
    {"id": "good-hard", "difficulty": "提高", "question": "如图，外框上水平边长为 5，下水平边长为 13，右侧竖直边高为 15，左斜边为半圆直径。求外框内、半圆外的括号状区域面积。", "options": ["A. 135-289π/4", "B. 135-289π/8", "C. 90-289π/8", "D. 135-17π/2"], "answer": "B", "explanation": "外框面积为 135。斜边直径为 17，半径为 17/2，半圆面积为 289π/8，所以目标面积为 135-289π/8。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.3,0.2],[0.8,0.2],[0.8,0.8],[0.1,0.8]]}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-target-consistency',
      sourceQuestionText:
          '图中外框由上水平边、右竖边、下水平边和左斜边围成，上水平边长为 3，下水平边长为 7，右竖边高为 10；左斜边作为半圆的直径，半圆位于外框内。求外框内、半圆外的括号状区域面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('bad-target')));
    expect(exercises.map((exercise) => exercise.id), contains('good-same'));
    expect(exercises.map((exercise) => exercise.id), contains('good-hard'));
    expect(exercises.first.question, contains('半圆弧之间区域'));
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
  });

  test('service replaces composite semicircle exercise missing diagramData',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "50-\frac{29\pi}{2}",
  "steps": ["外框面积为 50。", "半圆面积为 29\pi/2。"],
  "aiTags": ["半圆面积", "组合图形"],
  "knowledgePoints": ["整体减部分"],
  "mistakeReason": "目标区域读错",
  "studyAdvice": "先确认目标区域",
  "generatedExercises": [
    {"id": "missing-diagram", "difficulty": "简单", "question": "如图，上边长为 2，下边长为 5，右边高为 4，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。", "options": ["A. 14-25π/8", "B. 14-25π/4", "C. 20-25π/8", "D. 14-5π/2"], "answer": "A", "explanation": "外边界面积为 14，半圆面积为 25π/8，目标面积为 14-25π/8。"},
    {"id": "valid-same", "difficulty": "同级", "question": "如图，上边长为 3，下边长为 7，右边高为 10，半圆以左侧斜边为直径。求右侧外边界与半圆弧之间区域的面积。", "options": ["A. 50-29π", "B. 50-29π/2", "C. 40-29π/2", "D. 50-58π"], "answer": "B", "explanation": "外边界面积为 50，半圆面积为 29π/2，目标面积为 50-29π/2。", "diagramData": {"elements": [{"type": "line", "x1": 0.1, "y1": 0.2, "x2": 0.8, "y2": 0.2}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-composite-missing-diagram',
      sourceQuestionText:
          '图中外框由上水平边、右竖边、下水平边和左斜边围成，上水平边长为 3，下水平边长为 7，右竖边高为 10；左斜边作为半圆的直径，半圆位于外框内。求外框内、半圆外的括号状区域面积。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id),
        isNot(contains('missing-diagram')));
    expect(exercises.map((exercise) => exercise.id), contains('valid-same'));
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
  });

  test(
      'service preserves composite semicircle exercises with outer frame wording',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "50-\frac{29\pi}{2}",
  "steps": ["外框面积为 50。", "半圆面积为 29\pi/2。"],
  "aiTags": ["半圆面积", "勾股定理", "组合图形", "面积差"],
  "knowledgePoints": ["半圆面积", "整体减部分"],
  "mistakeReason": "需先确认半圆直径",
  "studyAdvice": "先求外框面积，再减半圆面积",
  "generatedExercises": [
    {"id": "ai-simple", "difficulty": "简单", "question": "如图，外框上水平边长为 4，下水平边长为 10，右侧竖直边高为 8，左斜边为半圆直径。求外框内、半圆外的括号状区域面积。", "options": ["A. 56-25π/2", "B. 56-25π", "C. 80-25π/2", "D. 40-25π/2"], "answer": "A", "explanation": "外框面积为 56。半圆直径由水平差和竖直差用勾股定理求得为 10，半圆面积为 25π/2，所以剩余面积为 56-25π/2。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.3,0.2],[0.8,0.2],[0.8,0.8],[0.1,0.8]]}]}},
    {"id": "ai-same", "difficulty": "同级", "question": "如图，外框上水平边长为 5，下水平边长为 11，右侧竖直边高为 8，左斜边为半圆直径。求外框内、半圆外的括号状区域面积。", "options": ["A. 64-25π", "B. 64-25π/2", "C. 88-25π/2", "D. 64-50π/2"], "answer": "B", "explanation": "外框面积为 64。由勾股定理得半圆直径为 10，半径为 5，半圆面积为 25π/2，目标面积为 64-25π/2。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.3,0.2],[0.8,0.2],[0.8,0.8],[0.1,0.8]]}]}},
    {"id": "ai-hard", "difficulty": "提高", "question": "如图，外框上水平边长为 5，下水平边长为 13，右侧竖直边高为 15，左斜边为半圆直径。求外框内、半圆外的括号状区域面积。", "options": ["A. 135-289π/4", "B. 135-289π/8", "C. 90-289π/8", "D. 135-17π/2"], "answer": "B", "explanation": "外框面积为 135。斜边直径为 17，半径为 17/2，半圆面积为 289π/8，所以目标面积为 135-289π/8。", "diagramData": {"elements": [{"type": "polygon", "points": [[0.3,0.2],[0.8,0.2],[0.8,0.8],[0.1,0.8]]}]}}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-outer-frame-wording',
      sourceQuestionText:
          '图中外框由上水平边、右竖边、下水平边和左斜边围成，上水平边长为 3，下水平边长为 7，右竖边高为 10；左斜边作为半圆的直径，半圆位于外框内。求外框内、半圆外的括号状区域面积。',
    );

    expect(exercises.map((exercise) => exercise.id),
        <String>['ai-simple', 'ai-same', 'ai-hard']);
    expect(exercises.every((exercise) => exercise.diagramData != null), isTrue);
  });
}
