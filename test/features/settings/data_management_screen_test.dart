import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    show AppDatabase;
import 'package:smart_wrong_notebook/src/data/repositories/drift_analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/data_management_screen.dart';

QuestionRecord _question(String id) {
  final now = DateTime(2026);
  return QuestionRecord(
    id: id,
    imagePath: '',
    subject: Subject.math,
    extractedQuestionText: '题目',
    normalizedQuestionText: '题目',
    contentFormat: QuestionContentFormat.plain,
    tags: const <String>[],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: null,
  );
}

ReviewLog _reviewLog(String questionId) {
  return ReviewLog(
    id: 'log-$questionId',
    questionRecordId: questionId,
    reviewedAt: DateTime(2026),
    result: 'reviewing',
    masteryAfter: MasteryLevel.reviewing,
  );
}

AnalysisJob _analysisJob(String id) {
  final spec = AiTaskSpec(
    id: id,
    parentQuestionId: 'scan-1',
    type: AiTaskType.firstPassAnalysis,
    workloadProfile: AiWorkloadProfile.routine,
    requiredCapabilities: const <AiCapability>{AiCapability.structuredOutput},
    qualityPolicy: AiQualityPolicy.reliableRequired,
    queuePriority: AiQueuePriority.firstPass,
  );
  const resolver = SingleProviderAiRouteResolver(
    routeId: 'test',
    providerConfigId: 'test',
    modelName: 'test',
  );
  return AnalysisJob.queued(
    id: id,
    idempotencyKey: id,
    taskSpec: spec,
    route: resolver.resolve(spec, promptVersion: 'analysis-v1'),
    payloadJson: '{}',
    createdAt: DateTime(2026),
  );
}

void main() {
  testWidgets('shows review log count and clears questions with logs',
      (tester) async {
    final questionRepository = InMemoryQuestionRepository();
    final reviewLogRepository = InMemoryReviewLogRepository();
    await questionRepository.saveDraft(_question('q-1'));
    await reviewLogRepository.insert(_reviewLog('q-1'));

    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(questionRepository),
        reviewLogRepositoryProvider.overrideWithValue(reviewLogRepository),
      ],
      child: const MaterialApp(home: DataManagementScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('题库总量'), findsOneWidget);
    expect(find.text('1 题'), findsOneWidget);
    expect(find.text('复习记录总量'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
    expect(find.text('AI 失败任务'), findsOneWidget);
    expect(find.text('删除错题、复习记录和扫题任务，不可恢复'), findsOneWidget);

    await tester.tap(find.text('清空所有数据'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除 1 道错题和 0 条扫题记录吗？此操作不可恢复。'), findsOneWidget);

    await tester.tap(find.text('清空'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(await questionRepository.listAll(), isEmpty);
    expect(await reviewLogRepository.listAll(), isEmpty);
    expect(find.text('0 题'), findsOneWidget);
    expect(find.text('0 条'), findsNWidgets(3));
  });

  testWidgets('clears scan tasks when the notebook is already empty',
      (tester) async {
    final database = AppDatabase.memory();
    addTearDown(database.close);
    final analysisJobs = DriftAnalysisJobRepository(database);
    await analysisJobs.enqueue(_analysisJob('scan-1-core'));

    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider
            .overrideWithValue(InMemoryQuestionRepository()),
        reviewLogRepositoryProvider
            .overrideWithValue(InMemoryReviewLogRepository()),
        analysisJobRepositoryProvider.overrideWithValue(analysisJobs),
      ],
      child: const MaterialApp(home: DataManagementScreen()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('清空所有数据'));
    await tester.pumpAndSettle();

    expect(
      find.text('确定要删除 0 道错题和 1 条扫题记录吗？此操作不可恢复。'),
      findsOneWidget,
    );

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    expect(await analysisJobs.listAll(), isEmpty);
  });
}
