import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';

class AnalysisFailureLogService {
  const AnalysisFailureLogService();

  List<AnalysisJob> failedJobs(Iterable<AnalysisJob> jobs) {
    return jobs.where((job) => job.status == AnalysisJobStatus.failed).toList()
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
  }

  Map<String, dynamic> buildExportPayload(
    Iterable<AnalysisJob> jobs, {
    required DateTime exportedAt,
  }) {
    final failures = failedJobs(jobs);
    return <String, dynamic>{
      'schemaVersion': 1,
      'exportedAt': exportedAt.toIso8601String(),
      'failureCount': failures.length,
      'failures': failures.map(_toJson).toList(growable: false),
    };
  }

  Map<String, dynamic> _toJson(AnalysisJob job) {
    return <String, dynamic>{
      'jobId': job.id,
      'parentQuestionId': job.taskSpec.parentQuestionId,
      'taskType': job.taskSpec.type.name,
      'status': job.status.name,
      'queuePriority': job.taskSpec.queuePriority.name,
      'workloadProfile': job.taskSpec.workloadProfile.name,
      'requestedModelClass': job.route.requestedModelClass.name,
      'requestedModelRole': job.route.requestedModelRole.name,
      'providerConfigId': job.route.providerConfigId,
      'modelName': job.route.modelName,
      'attemptCount': job.attemptCount,
      'maxAttempts': job.maxAttempts,
      'createdAt': job.createdAt.toIso8601String(),
      'updatedAt': job.updatedAt.toIso8601String(),
      'startedAt': job.startedAt?.toIso8601String(),
      'completedAt': job.completedAt?.toIso8601String(),
      'errorMessage': _sanitizeError(job.errorMessage),
      'progress': job.progress?.toJson(),
    };
  }

  String _sanitizeError(String? value) {
    final message = (value ?? '').trim();
    if (message.isEmpty) return '';

    final sanitized = message.replaceAll(
      RegExp(
        r'''(?:["']?(?:api[_ -]?key|authorization)["']?\s*[:=]\s*["']?(?:bearer\s+)?|\bbearer\s+)[^\s,;"'}]+''',
        caseSensitive: false,
      ),
      '[REDACTED]',
    );
    final withoutQueryKeys = sanitized.replaceAll(
      RegExp(
        r'''([?&](?:api[_ -]?key|access[_ -]?token|token)=)[^&\s]+''',
        caseSensitive: false,
      ),
      r'\1[REDACTED]',
    );
    if (withoutQueryKeys.length <= 2000) return withoutQueryKeys;
    return '${withoutQueryKeys.substring(0, 2000)}...';
  }
}
