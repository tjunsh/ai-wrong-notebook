import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_review_log_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/ai_conversation_repository.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/capture_service.dart';
import 'package:smart_wrong_notebook/src/data/services/notification_service.dart';
import 'package:smart_wrong_notebook/src/data/services/ocr_service.dart';
import 'package:smart_wrong_notebook/src/data/services/question_split_service.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_pipeline.dart';
import 'package:smart_wrong_notebook/src/data/services/scan_task_lifecycle_service.dart';
import 'package:smart_wrong_notebook/src/data/services/ai_learning_task_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_session.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

// --- Repository providers (default implementations) ---

final Provider<QuestionRepository> questionRepositoryProvider =
    Provider<QuestionRepository>((ref) {
  return SharedPrefsQuestionRepository();
});

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) {
  return SharedPrefsSettingsRepository.instance;
});

// ReviewLogRepository - stored in SharedPreferences
final Provider<ReviewLogRepository> reviewLogRepositoryProvider =
    Provider<ReviewLogRepository>((ref) {
  return SharedPrefsReviewLogRepository();
});

final Provider<AiConversationRepository> aiConversationRepositoryProvider =
    Provider<AiConversationRepository>((ref) {
  return InMemoryAiConversationRepository();
});

final Provider<AnalysisJobRepository?> analysisJobRepositoryProvider =
    Provider<AnalysisJobRepository?>((ref) => null);

final Provider<ScanTaskLifecycleService> scanTaskLifecycleServiceProvider =
    Provider<ScanTaskLifecycleService>((ref) {
  return ScanTaskLifecycleService(
    analysisJobs: ref.watch(analysisJobRepositoryProvider),
    questions: ref.watch(questionRepositoryProvider),
  );
});

final AutoDisposeFutureProvider<int> scanTaskCountProvider =
    FutureProvider.autoDispose<int>((ref) {
  return ref.watch(scanTaskLifecycleServiceProvider).countTasks();
});

final AutoDisposeFutureProvider<int> failedAnalysisTaskCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(analysisJobRepositoryProvider);
  if (repository == null) {
    return 0;
  }
  final jobs = await repository.listAll();
  return jobs.where((job) => job.status == AnalysisJobStatus.failed).length;
});

// --- Service providers ---

final Provider<AiAnalysisService> aiAnalysisServiceProvider =
    Provider<AiAnalysisService>((ref) {
  return AiAnalysisService(
      settingsRepository: ref.read(settingsRepositoryProvider));
});

final Provider<QuestionAnalysisCoordinator>
    questionAnalysisCoordinatorProvider =
    Provider<QuestionAnalysisCoordinator>((ref) {
  return DirectQuestionAnalysisCoordinator(
    QuestionAnalysisPipeline(ref.read(aiAnalysisServiceProvider)),
  );
});

final Provider<AiLearningTaskCoordinator> aiLearningTaskCoordinatorProvider =
    Provider<AiLearningTaskCoordinator>((ref) {
  return DirectAiLearningTaskCoordinator(
    ref.read(aiAnalysisServiceProvider),
  );
});

final StreamProvider<List<QuestionAnalysisTaskSnapshot>>
    backgroundAnalysisTasksProvider =
    StreamProvider<List<QuestionAnalysisTaskSnapshot>>((ref) {
  final repository = ref.watch(analysisJobRepositoryProvider);
  final coordinator = ref.watch(questionAnalysisCoordinatorProvider);
  if (repository == null ||
      coordinator is! BackgroundQuestionAnalysisCoordinator) {
    return Stream<List<QuestionAnalysisTaskSnapshot>>.value(
      const <QuestionAnalysisTaskSnapshot>[],
    );
  }

  return repository.watchAll().map((jobs) {
    final jobsById = <String, AnalysisJob>{
      for (final job in jobs) job.id: job,
    };
    final latestByQuestion = <String, AnalysisJob>{};
    for (final job in jobs) {
      if (job.taskSpec.type != AiTaskType.firstPassAnalysis) continue;
      final questionId = job.taskSpec.parentQuestionId;
      final existing = latestByQuestion[questionId];
      if (existing == null || job.createdAt.isAfter(existing.createdAt)) {
        latestByQuestion[questionId] = job;
      }
    }

    final snapshots = <QuestionAnalysisTaskSnapshot>[];
    for (final job in latestByQuestion.values) {
      try {
        snapshots.add(coordinator.snapshotFromJob(
          job,
          dependencyJobs: job.taskSpec.dependencyJobIds
              .map((id) => jobsById[id])
              .whereType<AnalysisJob>(),
          relatedJobs: jobs.where(
            (item) =>
                item.taskSpec.parentQuestionId == job.taskSpec.parentQuestionId,
          ),
        ));
      } catch (_) {
        // A malformed legacy task must not break the whole home screen.
      }
    }
    snapshots.sort(_compareAnalysisTasks);
    return snapshots;
  });
});

int _compareAnalysisTasks(
  QuestionAnalysisTaskSnapshot left,
  QuestionAnalysisTaskSnapshot right,
) {
  final leftRank = _analysisTaskRank(left.job.status);
  final rightRank = _analysisTaskRank(right.job.status);
  if (leftRank != rightRank) return leftRank.compareTo(rightRank);
  if (left.job.status == AnalysisJobStatus.queued) {
    return left.job.createdAt.compareTo(right.job.createdAt);
  }
  return right.job.createdAt.compareTo(left.job.createdAt);
}

int _analysisTaskRank(AnalysisJobStatus status) => switch (status) {
      AnalysisJobStatus.running => 0,
      AnalysisJobStatus.queued => 1,
      AnalysisJobStatus.completed => 2,
      AnalysisJobStatus.failed => 3,
      AnalysisJobStatus.cancelled => 4,
    };

final Provider<ImageStorageService> imageStorageServiceProvider =
    Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

final Provider<OcrService> ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

final Provider<QuestionSplitService> questionSplitServiceProvider =
    Provider<QuestionSplitService>((ref) {
  return QuestionSplitService(
      aiAnalysisService: ref.read(aiAnalysisServiceProvider));
});

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((ref) {
  return NotificationService(
      questionRepository: ref.read(questionRepositoryProvider));
});

final Provider<CaptureService> captureServiceProvider =
    Provider<CaptureService>((ref) {
  return CaptureService(storage: ref.read(imageStorageServiceProvider));
});

// --- Current question flow ---

final StateProvider<QuestionRecord?> currentQuestionProvider =
    StateProvider<QuestionRecord?>((ref) => null);

enum PracticeContextSource { analysis, notebook }

class PracticeContext {
  const PracticeContext({
    required this.source,
    this.candidateId,
    this.candidateOrder,
    required this.returnRoute,
  });

  final PracticeContextSource source;
  final String? candidateId;
  final int? candidateOrder;
  final String returnRoute;
}

final StateProvider<PracticeContext?> currentPracticeContextProvider =
    StateProvider<PracticeContext?>((ref) => null);

final StateProvider<QuestionSplitSession?> currentQuestionSplitSessionProvider =
    StateProvider<QuestionSplitSession?>((ref) => null);

Future<QuestionSplitSession> buildQuestionSplitSession(
  QuestionRecord source, {
  QuestionSplitService splitter = const QuestionSplitService(),
}) async {
  final result = source.splitResult ??
      await _resolveSplitResult(source, splitter: splitter);

  final hasMultipleCandidates = result.hasMultipleCandidates;
  var failedCandidateCount = 0;
  var retryingCandidateCount = 0;
  final drafts = <QuestionSplitDraft>[];
  for (final candidate in result.candidates) {
    final snapshot = source.candidateAnalyses
        .where((analysis) => analysis.order == candidate.order)
        .cast<CandidateAnalysisSnapshot?>()
        .firstWhere((analysis) => analysis != null, orElse: () => null);
    final canSave = !hasMultipleCandidates || (snapshot?.isSuccessful ?? false);
    final isRetrying = snapshot?.status == CandidateAnalysisStatus.queued ||
        snapshot?.status == CandidateAnalysisStatus.running;
    if (isRetrying) {
      retryingCandidateCount++;
      continue;
    }
    if (!canSave) {
      failedCandidateCount++;
      continue;
    }
    drafts.add(QuestionSplitDraft(
      id: '${source.id}-${candidate.order - 1}',
      text: candidate.text,
      selected: true,
      originalOrder: candidate.order,
      contentFormat: source.contentFormat,
    ));
  }

  return QuestionSplitSession(
    source: source,
    strategy: result.strategy,
    drafts: drafts,
    failedCandidateCount: failedCandidateCount,
    retryingCandidateCount: retryingCandidateCount,
  );
}

Future<QuestionSplitResult> _resolveSplitResult(
  QuestionRecord source, {
  required QuestionSplitService splitter,
}) async {
  final normalized = source.normalizedQuestionText.trim();
  final extracted = source.extractedQuestionText.trim();
  final seedText = normalized.isNotEmpty ? normalized : extracted;
  return splitter.split(seedText, subject: source.subject);
}

QuestionRecord buildSplitQuestionRecord({
  required QuestionRecord source,
  required QuestionSplitDraft draft,
  required int sortOrder,
}) {
  final trimmedText = draft.text.trim();
  final now = DateTime.now();
  final candidateSnapshot = source.candidateAnalyses
      .where((candidate) {
        return candidate.order == draft.originalOrder;
      })
      .cast<CandidateAnalysisSnapshot?>()
      .firstWhere(
        (candidate) => candidate != null,
        orElse: () => null,
      );
  final hasMultipleCandidates =
      source.splitResult?.hasMultipleCandidates ?? false;
  if (hasMultipleCandidates && !(candidateSnapshot?.isSuccessful ?? false)) {
    throw StateError('解析失败的子题不能保存到错题本。');
  }
  final analysisResult = candidateSnapshot?.analysisResult ??
      (hasMultipleCandidates ? null : source.analysisResult);
  final savedExercises = (candidateSnapshot?.savedExercises ??
          (hasMultipleCandidates
              ? const <GeneratedExercise>[]
              : source.savedExercises))
      .asMap()
      .entries
      .map((entry) {
    final order = entry.value.order ?? entry.key;
    final roundIndex = entry.value.roundIndex ?? 1;
    return entry.value.copyWith(
      id: '${source.id}-$sortOrder-round-$roundIndex-exercise-${order + 1}',
      questionId: '${source.id}-$sortOrder',
      order: order,
    );
  }).toList();
  final aiTags = candidateSnapshot?.aiTags ??
      (hasMultipleCandidates ? const <String>[] : source.aiTags);
  final aiKnowledgePoints = candidateSnapshot?.aiKnowledgePoints ??
      (hasMultipleCandidates ? const <String>[] : source.aiKnowledgePoints);
  final subject =
      candidateSnapshot?.subject ?? analysisResult?.subject ?? source.subject;

  return QuestionRecord(
    id: '${source.id}-$sortOrder',
    imagePath: source.imagePath,
    subject: subject,
    extractedQuestionText: trimmedText,
    normalizedQuestionText: trimmedText,
    contentFormat: draft.contentFormat ?? source.contentFormat,
    tags: source.tags,
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: source.contentStatus,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: analysisResult,
    savedExercises: savedExercises,
    aiTags: aiTags,
    aiKnowledgePoints: aiKnowledgePoints,
    customTags: source.customTags,
    parentQuestionId: source.id,
    rootQuestionId: source.rootQuestionId ?? source.id,
    splitOrder: sortOrder,
  );
}

// --- Internal version counter for cache invalidation ---

final StateProvider<int> _listVersionProvider = StateProvider<int>((ref) => 0);

/// Call after any mutation (save, delete, review) to refresh list/review providers.
void invalidateQuestionList(WidgetRef ref) {
  ref.read(_listVersionProvider.notifier).state++;
}

// --- All questions list ---

final FutureProvider<List<QuestionRecord>> questionListProvider =
    FutureProvider<List<QuestionRecord>>((ref) async {
  ref.watch(_listVersionProvider);
  return ref.read(questionRepositoryProvider).listAll();
});

final FutureProvider<List<ReviewLog>> reviewLogListProvider =
    FutureProvider<List<ReviewLog>>((ref) async {
  ref.watch(_listVersionProvider);
  return ref.read(reviewLogRepositoryProvider).listAll();
});

class QuestionBatchGroup {
  const QuestionBatchGroup({required this.rootId, required this.questions});

  final String rootId;
  final List<QuestionRecord> questions;
}

final FutureProvider<Map<String, QuestionBatchGroup>>
    questionBatchGroupsProvider =
    FutureProvider<Map<String, QuestionBatchGroup>>((ref) async {
  ref.watch(_listVersionProvider);
  final all = await ref.read(questionRepositoryProvider).listAll();
  return buildQuestionBatchGroups(all);
});

Map<String, QuestionBatchGroup> buildQuestionBatchGroups(
    List<QuestionRecord> questions) {
  final grouped = <String, List<QuestionRecord>>{};

  for (final question in questions) {
    final rootId = _questionBatchRootId(question);
    if (rootId == null) continue;
    grouped.putIfAbsent(rootId, () => <QuestionRecord>[]).add(question);
  }

  final result = <String, QuestionBatchGroup>{};
  for (final entry in grouped.entries) {
    if (entry.value.length < 2) continue;
    final sorted = [...entry.value]..sort(_compareBatchQuestions);
    result[entry.key] =
        QuestionBatchGroup(rootId: entry.key, questions: sorted);
  }
  return result;
}

String? questionBatchRootId(QuestionRecord question) =>
    _questionBatchRootId(question);

String? _questionBatchRootId(QuestionRecord question) {
  final rootId = question.rootQuestionId ?? question.parentQuestionId;
  return rootId == null || rootId.isEmpty ? null : rootId;
}

int _compareBatchQuestions(QuestionRecord a, QuestionRecord b) {
  final orderA = a.splitOrder;
  final orderB = b.splitOrder;
  if (orderA != null && orderB != null && orderA != orderB) {
    return orderA.compareTo(orderB);
  }
  if (orderA != null && orderB == null) return -1;
  if (orderA == null && orderB != null) return 1;
  final created = a.createdAt.compareTo(b.createdAt);
  if (created != 0) return created;
  return a.id.compareTo(b.id);
}

// --- Questions due for review ---

final FutureProvider<List<QuestionRecord>> dueReviewProvider =
    FutureProvider<List<QuestionRecord>>((ref) async {
  ref.watch(_listVersionProvider);
  final all = await ref.read(questionRepositoryProvider).listAll();
  return all
      .where((QuestionRecord q) =>
          q.contentStatus == ContentStatus.ready &&
          q.masteryLevel != MasteryLevel.mastered)
      .toList();
});

// --- Notebook filter state ---

final StateProvider<Subject?> selectedSubjectFilterProvider =
    StateProvider<Subject?>((ref) => null);

final StateProvider<MasteryLevel?> selectedMasteryFilterProvider =
    StateProvider<MasteryLevel?>((ref) => null);

final StateProvider<bool> selectedCreatedTodayFilterProvider =
    StateProvider<bool>((ref) => false);

final StateProvider<String> searchQueryProvider =
    StateProvider<String>((ref) => '');

final StateProvider<String?> selectedKnowledgePointFilterProvider =
    StateProvider<String?>((ref) => null);

// 多选标签过滤
final StateProvider<List<String>> selectedTagsFilterProvider =
    StateProvider<List<String>>((ref) => []);

// --- All tags provider ---
final FutureProvider<List<String>> allTagsProvider =
    FutureProvider<List<String>>((ref) async {
  ref.watch(_listVersionProvider);
  final all = await ref.read(questionRepositoryProvider).listAll();
  final tags = <String>{};
  for (final q in all) {
    // 添加 AI 短标签
    tags.addAll(q.aiTags);
    // 添加 AI 知识点
    tags.addAll(q.aiKnowledgePoints);
    // 添加自定义标签
    tags.addAll(q.customTags);
  }
  return tags.toList()..sort();
});

// --- Filtered notebook list ---

final FutureProvider<List<QuestionRecord>> filteredQuestionListProvider =
    FutureProvider<List<QuestionRecord>>((ref) async {
  ref.watch(_listVersionProvider);
  final all = await ref.read(questionRepositoryProvider).listAll();

  final subject = ref.watch(selectedSubjectFilterProvider);
  final mastery = ref.watch(selectedMasteryFilterProvider);
  final createdToday = ref.watch(selectedCreatedTodayFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final knowledgePoint = ref.watch(selectedKnowledgePointFilterProvider);
  final selectedTags = ref.watch(selectedTagsFilterProvider);

  final now = DateTime.now();
  return all.where((QuestionRecord q) {
    if (subject != null && q.subject != subject) return false;
    if (mastery != null && q.masteryLevel != mastery) return false;
    if (createdToday &&
        (q.createdAt.year != now.year ||
            q.createdAt.month != now.month ||
            q.createdAt.day != now.day)) {
      return false;
    }
    if (query.isNotEmpty &&
        !q.normalizedQuestionText.toLowerCase().contains(query)) {
      return false;
    }
    // AI 知识点过滤：匹配任意一个知识点
    if (knowledgePoint != null && knowledgePoint.isNotEmpty) {
      final kps = q.aiKnowledgePoints;
      if (!kps.any((kp) => kp.contains(knowledgePoint))) return false;
    }
    // 多选标签过滤：必须包含所有选中的标签
    if (selectedTags.isNotEmpty) {
      final allQTags = [...q.aiKnowledgePoints, ...q.customTags];
      for (final tag in selectedTags) {
        if (!allQTags.any((t) => t.contains(tag))) return false;
      }
    }
    return true;
  }).toList();
});

// --- Theme mode ---

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(settingsRepositoryProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._settingsRepo) : super(ThemeMode.system) {
    _load();
  }

  final SettingsRepository _settingsRepo;

  Future<void> _load() async {
    final value = await _settingsRepo.getString('theme_mode');
    final mode = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    state = mode;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settingsRepo.setString('theme_mode', value);
  }
}
