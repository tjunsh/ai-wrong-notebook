import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/shared_prefs_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';
import 'package:smart_wrong_notebook/src/data/services/capture_service.dart';
import 'package:smart_wrong_notebook/src/data/services/notification_service.dart';
import 'package:smart_wrong_notebook/src/data/services/ocr_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

// --- Repository providers (default implementations) ---

final Provider<QuestionRepository> questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return SharedPrefsQuestionRepository();
});

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SharedPrefsSettingsRepository();
});

// ReviewLogRepository - using SharedPrefsQuestionRepository as base for now
final Provider<ReviewLogRepository> reviewLogRepositoryProvider = Provider<ReviewLogRepository>((ref) {
  throw UnimplementedError('ReviewLogRepository not yet implemented with SharedPreferences');
});

// --- Service providers ---

final Provider<AiAnalysisService> aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisService(settingsRepository: ref.read(settingsRepositoryProvider));
});

final Provider<ImageStorageService> imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

final Provider<OcrService> ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService();
});

final Provider<NotificationService> notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(questionRepository: ref.read(questionRepositoryProvider));
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

// --- Notebook filter state ---

final StateProvider<Subject?> selectedSubjectFilterProvider = StateProvider<Subject?>((ref) => null);

final StateProvider<MasteryLevel?> selectedMasteryFilterProvider = StateProvider<MasteryLevel?>((ref) => null);

final StateProvider<String> searchQueryProvider = StateProvider<String>((ref) => '');

// --- Filtered notebook list ---

final FutureProvider<List<QuestionRecord>> filteredQuestionListProvider = FutureProvider<List<QuestionRecord>>((ref) async {
  ref.watch(_listVersionProvider);
  final all = await ref.read(questionRepositoryProvider).listAll();

  final subject = ref.watch(selectedSubjectFilterProvider);
  final mastery = ref.watch(selectedMasteryFilterProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return all.where((QuestionRecord q) {
    if (subject != null && q.subject != subject) return false;
    if (mastery != null && q.masteryLevel != mastery) return false;
    if (query.isNotEmpty && !q.correctedText.toLowerCase().contains(query)) return false;
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
