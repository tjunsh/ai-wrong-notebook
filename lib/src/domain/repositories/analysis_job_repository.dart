import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';

abstract interface class AnalysisJobRepository {
  Future<AnalysisJob> enqueue(AnalysisJob job);
  Future<AnalysisJob?> getById(String id);
  Future<List<AnalysisJob>> listAll();
  Stream<List<AnalysisJob>> watchAll();
  Stream<List<AnalysisJob>> watchByParentQuestionId(String parentQuestionId);
  Future<void> deleteByParentQuestionId(String parentQuestionId);
  Future<void> clearAll();
  Future<int> deleteTerminalJobsBefore(DateTime cutoff);
  Future<AnalysisJob?> claimNextRunnable();
  Future<bool> markCompleted(String id, {required String resultJson});

  /// Updates the durable result owned by an already-completed parent task.
  ///
  /// Candidate retries use this to fill one failed item without rerunning the
  /// original multi-question analysis.
  Future<bool> replaceCompletedResult(String id, {required String resultJson});
  Future<bool> updateProgress(
    String id, {
    required int attemptCount,
    required AnalysisJobProgress progress,
  });
  Future<AnalysisJobStatus> recordFailure(
    String id, {
    required String errorMessage,
    required bool retryable,
  });
  Future<void> recoverInterruptedJobs();
}
