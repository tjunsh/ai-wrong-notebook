import 'ai_task_spec.dart';
import '../services/ai_route_resolver.dart';

enum AnalysisJobStatus {
  queued,
  running,
  completed,
  failed,
  cancelled,
}

enum AnalysisJobProgressStage {
  recognizing,
  analyzing,
  analyzingCandidates,
  finalizing,
}

class AnalysisJobProgress {
  const AnalysisJobProgress({
    required this.stage,
    this.completedUnits = 0,
    this.totalUnits = 0,
    this.failedUnits = 0,
  });

  factory AnalysisJobProgress.fromJson(Map<String, dynamic> json) {
    return AnalysisJobProgress(
      stage: AnalysisJobProgressStage.values.firstWhere(
        (stage) => stage.name == json['stage'],
        orElse: () => AnalysisJobProgressStage.analyzing,
      ),
      completedUnits: _nonNegativeInt(json['completedUnits']),
      totalUnits: _nonNegativeInt(json['totalUnits']),
      failedUnits: _nonNegativeInt(json['failedUnits']),
    );
  }

  final AnalysisJobProgressStage stage;
  final int completedUnits;
  final int totalUnits;
  final int failedUnits;

  bool get hasUnitProgress => totalUnits > 1;

  double get fraction {
    if (!hasUnitProgress) return 0;
    return (completedUnits / totalUnits).clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'stage': stage.name,
        'completedUnits': completedUnits,
        'totalUnits': totalUnits,
        'failedUnits': failedUnits,
      };

  @override
  bool operator ==(Object other) {
    return other is AnalysisJobProgress &&
        other.stage == stage &&
        other.completedUnits == completedUnits &&
        other.totalUnits == totalUnits &&
        other.failedUnits == failedUnits;
  }

  @override
  int get hashCode => Object.hash(
        stage,
        completedUnits,
        totalUnits,
        failedUnits,
      );
}

int _nonNegativeInt(Object? value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return parsed == null || parsed < 0 ? 0 : parsed;
}

class AnalysisJob {
  const AnalysisJob({
    required this.id,
    required this.idempotencyKey,
    required this.taskSpec,
    required this.route,
    required this.payloadJson,
    required this.status,
    required this.attemptCount,
    required this.maxAttempts,
    required this.createdAt,
    required this.updatedAt,
    this.resultJson,
    this.errorMessage,
    this.progress,
    this.startedAt,
    this.completedAt,
  });

  factory AnalysisJob.queued({
    required String id,
    required String idempotencyKey,
    required AiTaskSpec taskSpec,
    required AiResolvedRoute route,
    required String payloadJson,
    required DateTime createdAt,
    int maxAttempts = 2,
  }) {
    return AnalysisJob(
      id: id,
      idempotencyKey: idempotencyKey,
      taskSpec: taskSpec,
      route: route,
      payloadJson: payloadJson,
      status: AnalysisJobStatus.queued,
      attemptCount: 0,
      maxAttempts: maxAttempts,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final String id;
  final String idempotencyKey;
  final AiTaskSpec taskSpec;
  final AiResolvedRoute route;
  final String payloadJson;
  final AnalysisJobStatus status;
  final int attemptCount;
  final int maxAttempts;
  final String? resultJson;
  final String? errorMessage;
  final AnalysisJobProgress? progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isTerminal =>
      status == AnalysisJobStatus.completed ||
      status == AnalysisJobStatus.failed ||
      status == AnalysisJobStatus.cancelled;

  AnalysisJob copyWith({
    String? id,
    String? idempotencyKey,
    AiTaskSpec? taskSpec,
    AiResolvedRoute? route,
    String? payloadJson,
    AnalysisJobStatus? status,
    int? attemptCount,
    int? maxAttempts,
    String? resultJson,
    String? errorMessage,
    AnalysisJobProgress? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return AnalysisJob(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      taskSpec: taskSpec ?? this.taskSpec,
      route: route ?? this.route,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      resultJson: resultJson ?? this.resultJson,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class AnalysisQueueCapacityException implements Exception {
  const AnalysisQueueCapacityException(this.limit);

  final int limit;

  @override
  String toString() => 'AI queue already contains $limit pending jobs.';
}
