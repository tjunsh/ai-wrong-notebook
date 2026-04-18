import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/capture_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

// --- Repository providers ---

final Provider<QuestionRepository> questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return DriftQuestionRepository();
});

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return InMemorySettingsRepository();
});

// --- Service providers ---

final Provider<AiAnalysisService> aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisService(settingsRepository: ref.read(settingsRepositoryProvider));
});

final Provider<ImageStorageService> imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

final Provider<CaptureService> captureServiceProvider = Provider<CaptureService>((ref) {
  return CaptureService(storage: ref.read(imageStorageServiceProvider));
});

// --- Current question flow ---

final StateProvider<QuestionRecord?> currentQuestionProvider = StateProvider<QuestionRecord?>((ref) => null);

// --- Internal version counter for cache invalidation ---

final StateProvider<int> _listVersionProvider = StateProvider<int>((ref) => 0);

/// Call after any mutation (save, delete, review) to refresh list/review providers.
void invalidateQuestionList(WidgetRef ref) {
  ref.read(_listVersionProvider.notifier).state++;
}

// --- All questions list ---

final FutureProvider<List<QuestionRecord>> questionListProvider = FutureProvider<List<QuestionRecord>>((ref) async {
  ref.watch(_listVersionProvider);
  return ref.read(questionRepositoryProvider).listAll();
});

// --- Questions due for review ---

final FutureProvider<List<QuestionRecord>> dueReviewProvider = FutureProvider<List<QuestionRecord>>((ref) async {
  ref.watch(_listVersionProvider);
  final all = await ref.read(questionRepositoryProvider).listAll();
  return all.where((QuestionRecord q) =>
    q.contentStatus == ContentStatus.ready &&
    q.masteryLevel != MasteryLevel.mastered
  ).toList();
});
