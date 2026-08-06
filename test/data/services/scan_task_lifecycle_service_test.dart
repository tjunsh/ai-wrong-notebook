import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    show AppDatabase;
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/scan_task_lifecycle_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';

void main() {
  late AppDatabase database;
  late DriftAnalysisJobRepository jobs;
  late InMemoryQuestionRepository questions;
  late Directory tempDirectory;
  late ScanTaskLifecycleService lifecycle;

  setUp(() async {
    database = AppDatabase.memory();
    jobs = DriftAnalysisJobRepository(database);
    questions = InMemoryQuestionRepository();
    tempDirectory = await Directory.systemTemp.createTemp('scan-lifecycle-');
    lifecycle = ScanTaskLifecycleService(
      analysisJobs: jobs,
      questions: questions,
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  QuestionRecord source(String id, String imagePath) {
    return QuestionRecord.draft(
      id: id,
      imagePath: imagePath,
      subject: Subject.math,
      recognizedText: '题目',
    );
  }

  AnalysisJob job(QuestionRecord source) {
    final spec = AiTaskSpec(
      id: '${source.id}:core',
      parentQuestionId: source.id,
      type: AiTaskType.firstPassAnalysis,
      workloadProfile: AiWorkloadProfile.routine,
      requiredCapabilities: const <AiCapability>{
        AiCapability.structuredOutput,
      },
      qualityPolicy: AiQualityPolicy.reliableRequired,
      queuePriority: AiQueuePriority.firstPass,
    );
    const resolver = SingleProviderAiRouteResolver(
      routeId: 'test',
      providerConfigId: 'test',
      modelName: 'test',
    );
    return AnalysisJob.queued(
      id: spec.id,
      idempotencyKey: spec.id,
      taskSpec: spec,
      route: resolver.resolve(spec, promptVersion: 'analysis-v1'),
      payloadJson: '{"question":${_jsonFor(source)}}',
      createdAt: DateTime(2026),
    );
  }

  test('saving removes the scan jobs but preserves the notebook image',
      () async {
    final image = File('${tempDirectory.path}/saved.jpg');
    await image.writeAsString('image');
    final record = source('scan-saved', image.path);
    await jobs.enqueue(job(record));
    await questions.saveDraft(record);

    await lifecycle.completeSaved(record.id);

    expect(await jobs.listAll(), isEmpty);
    expect(await image.exists(), isTrue);
  });

  test('discarding removes jobs and an unreferenced temporary image', () async {
    final image = File('${tempDirectory.path}/discarded.jpg');
    await image.writeAsString('image');
    final record = source('scan-discarded', image.path);
    await jobs.enqueue(job(record));

    await lifecycle.discard(record);

    expect(await jobs.listAll(), isEmpty);
    expect(await image.exists(), isFalse);
  });

  test('discarding preserves an image referenced by another scan task',
      () async {
    final image = File('${tempDirectory.path}/shared.jpg');
    await image.writeAsString('image');
    final discarded = source('scan-discarded', image.path);
    final remaining = source('scan-remaining', image.path);
    await jobs.enqueue(job(discarded));
    await jobs.enqueue(job(remaining));

    await lifecycle.discard(discarded);

    expect(
      (await jobs.listAll()).map((item) => item.taskSpec.parentQuestionId),
      <String>[remaining.id],
    );
    expect(await image.exists(), isTrue);
  });

  test('retry removes the old job graph but keeps the source image', () async {
    final image = File('${tempDirectory.path}/retry.jpg');
    await image.writeAsString('image');
    final record = source('scan-retry', image.path);
    await jobs.enqueue(job(record));

    await lifecycle.prepareRetry(record);

    expect(await jobs.listAll(), isEmpty);
    expect(await image.exists(), isTrue);
  });
}

String _jsonFor(QuestionRecord question) {
  final escapedPath = question.imagePath.replaceAll(r'\', r'\\');
  return '{"id":"${question.id}","imagePath":"$escapedPath"}';
}
