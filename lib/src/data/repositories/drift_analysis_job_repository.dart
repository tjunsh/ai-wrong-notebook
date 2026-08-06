import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart' as db;
import 'package:smart_wrong_notebook/src/domain/models/ai_task_spec.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';
import 'package:smart_wrong_notebook/src/domain/services/ai_route_resolver.dart';

class DriftAnalysisJobRepository implements AnalysisJobRepository {
  DriftAnalysisJobRepository(this._db, {this.maxPendingJobs = 20});

  final db.AppDatabase _db;
  final int maxPendingJobs;

  @override
  Future<AnalysisJob> enqueue(AnalysisJob job) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.analysisJobs)
            ..where((table) => table.idempotencyKey.equals(job.idempotencyKey)))
          .getSingleOrNull();
      if (existing != null) return _toModel(existing);

      final pendingRows = await (_db.select(_db.analysisJobs)
            ..where((table) => table.status.isIn(<String>[
                  AnalysisJobStatus.queued.name,
                  AnalysisJobStatus.running.name,
                ])))
          .get();
      if (pendingRows.length >= maxPendingJobs) {
        throw AnalysisQueueCapacityException(maxPendingJobs);
      }

      await _db.into(_db.analysisJobs).insert(_toCompanion(job));
      return job;
    });
  }

  @override
  Future<AnalysisJob?> getById(String id) async {
    final row = await (_db.select(_db.analysisJobs)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  @override
  Future<List<AnalysisJob>> listAll() async {
    final rows = await (_db.select(_db.analysisJobs)
          ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
        .get();
    return rows.map(_toModel).toList(growable: false);
  }

  @override
  Stream<List<AnalysisJob>> watchAll() {
    final query = _db.select(_db.analysisJobs)
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    return query.watch().map(
          (rows) => rows.map(_toModel).toList(growable: false),
        );
  }

  @override
  Stream<List<AnalysisJob>> watchByParentQuestionId(String parentQuestionId) {
    final query = _db.select(_db.analysisJobs)
      ..where((table) => table.parentQuestionId.equals(parentQuestionId))
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    return query.watch().map(
          (rows) => rows.map(_toModel).toList(growable: false),
        );
  }

  @override
  Future<void> deleteByParentQuestionId(String parentQuestionId) async {
    await (_db.delete(_db.analysisJobs)
          ..where((table) => table.parentQuestionId.equals(parentQuestionId)))
        .go();
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.analysisJobs).go();
  }

  @override
  Future<int> deleteTerminalJobsBefore(DateTime cutoff) async {
    return _db.transaction(() async {
      final rows = await _db.select(_db.analysisJobs).get();
      final jobs = rows.map(_toModel).toList(growable: false);
      final protectedIds = jobs
          .where((job) =>
              job.status == AnalysisJobStatus.queued ||
              job.status == AnalysisJobStatus.running)
          .expand((job) => job.taskSpec.dependencyJobIds)
          .toSet();
      final removableIds = jobs
          .where((job) =>
              job.isTerminal &&
              job.updatedAt.isBefore(cutoff) &&
              !protectedIds.contains(job.id))
          .map((job) => job.id)
          .toList(growable: false);
      if (removableIds.isEmpty) return 0;

      return (_db.delete(_db.analysisJobs)
            ..where((table) => table.id.isIn(removableIds)))
          .go();
    });
  }

  @override
  Future<AnalysisJob?> claimNextRunnable() {
    return _db.transaction(() async {
      final rows = await _db.select(_db.analysisJobs).get();
      final jobs = rows.map(_toModel).toList();
      final jobsById = <String, AnalysisJob>{
        for (final job in jobs) job.id: job,
      };
      if (jobs.any((job) => job.status == AnalysisJobStatus.running)) {
        return null;
      }
      final queued = jobs
          .where((job) => job.status == AnalysisJobStatus.queued)
          .toList()
        ..sort(_compareQueueOrder);

      for (final job in queued) {
        final dependencies = job.taskSpec.dependencyJobIds
            .map((id) => jobsById[id])
            .toList(growable: false);
        final hasInvalidDependency = dependencies.any(
          (dependency) =>
              dependency == null ||
              dependency.status == AnalysisJobStatus.failed ||
              dependency.status == AnalysisJobStatus.cancelled,
        );
        if (hasInvalidDependency) {
          final now = DateTime.now();
          await (_db.update(_db.analysisJobs)
                ..where((table) =>
                    table.id.equals(job.id) &
                    table.status.equals(AnalysisJobStatus.queued.name)))
              .write(db.AnalysisJobsCompanion(
            status: Value(AnalysisJobStatus.failed.name),
            errorMessage: const Value('前置 AI 任务失败，当前任务已停止。'),
            updatedAt: Value(now),
            completedAt: Value(now),
          ));
          continue;
        }
        final dependenciesComplete = dependencies.every(
          (dependency) => dependency?.status == AnalysisJobStatus.completed,
        );
        if (!dependenciesComplete) continue;

        final now = DateTime.now();
        final updated = await (_db.update(_db.analysisJobs)
              ..where((table) =>
                  table.id.equals(job.id) &
                  table.status.equals(AnalysisJobStatus.queued.name)))
            .write(db.AnalysisJobsCompanion(
          status: Value(AnalysisJobStatus.running.name),
          attemptCount: Value(job.attemptCount + 1),
          updatedAt: Value(now),
          startedAt: Value(now),
        ));
        if (updated == 1) return getById(job.id);
      }
      return null;
    });
  }

  @override
  Future<bool> markCompleted(String id, {required String resultJson}) async {
    final now = DateTime.now();
    final updated = await (_db.update(_db.analysisJobs)
          ..where((table) =>
              table.id.equals(id) &
              table.status.equals(AnalysisJobStatus.running.name)))
        .write(db.AnalysisJobsCompanion(
      status: Value(AnalysisJobStatus.completed.name),
      resultJson: Value(resultJson),
      errorMessage: const Value(null),
      updatedAt: Value(now),
      completedAt: Value(now),
    ));
    return updated == 1;
  }

  @override
  Future<bool> replaceCompletedResult(
    String id, {
    required String resultJson,
  }) async {
    final updated = await (_db.update(_db.analysisJobs)
          ..where((table) =>
              table.id.equals(id) &
              table.status.equals(AnalysisJobStatus.completed.name)))
        .write(db.AnalysisJobsCompanion(
      resultJson: Value(resultJson),
      updatedAt: Value(DateTime.now()),
    ));
    return updated == 1;
  }

  @override
  Future<bool> updateProgress(
    String id, {
    required int attemptCount,
    required AnalysisJobProgress progress,
  }) async {
    final updated = await (_db.update(_db.analysisJobs)
          ..where((table) =>
              table.id.equals(id) &
              table.status.equals(AnalysisJobStatus.running.name) &
              table.attemptCount.equals(attemptCount)))
        .write(db.AnalysisJobsCompanion(
      progressJson: Value(jsonEncode(progress.toJson())),
      updatedAt: Value(DateTime.now()),
    ));
    return updated == 1;
  }

  @override
  Future<AnalysisJobStatus> recordFailure(
    String id, {
    required String errorMessage,
    required bool retryable,
  }) {
    return _db.transaction(() async {
      final current = await getById(id);
      if (current == null) {
        return AnalysisJobStatus.cancelled;
      }
      if (current.status != AnalysisJobStatus.running) {
        return current.status;
      }

      final shouldRetry =
          retryable && current.attemptCount < current.maxAttempts;
      final nextStatus =
          shouldRetry ? AnalysisJobStatus.queued : AnalysisJobStatus.failed;
      final now = DateTime.now();
      await (_db.update(_db.analysisJobs)
            ..where((table) =>
                table.id.equals(id) &
                table.status.equals(AnalysisJobStatus.running.name)))
          .write(db.AnalysisJobsCompanion(
        status: Value(nextStatus.name),
        errorMessage: Value(errorMessage),
        progressJson: shouldRetry ? const Value(null) : const Value.absent(),
        updatedAt: Value(now),
        startedAt: shouldRetry ? const Value(null) : const Value.absent(),
        completedAt: shouldRetry ? const Value(null) : Value(now),
      ));
      return nextStatus;
    });
  }

  @override
  Future<void> recoverInterruptedJobs() {
    return _db.transaction(() async {
      final rows = await (_db.select(_db.analysisJobs)
            ..where(
                (table) => table.status.equals(AnalysisJobStatus.running.name)))
          .get();
      final now = DateTime.now();
      for (final row in rows) {
        final canRetry = row.attemptCount < row.maxAttempts;
        await (_db.update(_db.analysisJobs)
              ..where((table) => table.id.equals(row.id)))
            .write(db.AnalysisJobsCompanion(
          status: Value(canRetry
              ? AnalysisJobStatus.queued.name
              : AnalysisJobStatus.failed.name),
          errorMessage:
              Value(canRetry ? '任务在应用退出时中断，已重新排队。' : '任务在应用退出时中断，已达到最大尝试次数。'),
          progressJson: const Value(null),
          updatedAt: Value(now),
          startedAt: const Value(null),
          completedAt: canRetry ? const Value(null) : Value(now),
        ));
      }
    });
  }

  int _compareQueueOrder(AnalysisJob left, AnalysisJob right) {
    final priority = left.taskSpec.queuePriority.index
        .compareTo(right.taskSpec.queuePriority.index);
    if (priority != 0) return priority;
    final created = left.createdAt.compareTo(right.createdAt);
    if (created != 0) return created;
    return left.id.compareTo(right.id);
  }

  db.AnalysisJobsCompanion _toCompanion(AnalysisJob job) {
    return db.AnalysisJobsCompanion.insert(
      id: job.id,
      idempotencyKey: job.idempotencyKey,
      parentQuestionId: job.taskSpec.parentQuestionId,
      taskType: job.taskSpec.type.name,
      workloadProfile: job.taskSpec.workloadProfile.name,
      requiredCapabilitiesJson: jsonEncode(
        job.taskSpec.requiredCapabilities.map((item) => item.name).toList(),
      ),
      qualityPolicy: job.taskSpec.qualityPolicy.name,
      queuePriority: job.taskSpec.queuePriority.name,
      dependencyJobIdsJson: jsonEncode(job.taskSpec.dependencyJobIds),
      modelRole: job.taskSpec.modelRole.name,
      requestedModelClass: job.route.requestedModelClass.name,
      requestedModelRole: job.route.requestedModelRole.name,
      resolvedRouteId: job.route.resolvedRouteId,
      providerConfigId: job.route.providerConfigId,
      modelName: job.route.modelName,
      promptVersion: job.route.promptVersion,
      verifierIsIndependent: Value(job.route.verifierIsIndependent),
      payloadJson: job.payloadJson,
      status: job.status.name,
      attemptCount: Value(job.attemptCount),
      maxAttempts: Value(job.maxAttempts),
      resultJson: Value(job.resultJson),
      errorMessage: Value(job.errorMessage),
      progressJson: Value(
        job.progress == null ? null : jsonEncode(job.progress!.toJson()),
      ),
      createdAt: job.createdAt,
      updatedAt: job.updatedAt,
      startedAt: Value(job.startedAt),
      completedAt: Value(job.completedAt),
    );
  }

  AnalysisJob _toModel(db.AnalysisJob row) {
    final taskSpec = AiTaskSpec(
      id: row.id,
      parentQuestionId: row.parentQuestionId,
      type: _enumByName(
        AiTaskType.values,
        row.taskType,
        AiTaskType.firstPassAnalysis,
      ),
      workloadProfile: _enumByName(
        AiWorkloadProfile.values,
        row.workloadProfile,
        AiWorkloadProfile.routine,
      ),
      requiredCapabilities: (jsonDecode(row.requiredCapabilitiesJson) as List)
          .map((name) => _enumByName(
                AiCapability.values,
                name,
                AiCapability.structuredOutput,
              ))
          .toSet(),
      qualityPolicy: _enumByName(
        AiQualityPolicy.values,
        row.qualityPolicy,
        AiQualityPolicy.reliableRequired,
      ),
      queuePriority: _enumByName(
        AiQueuePriority.values,
        row.queuePriority,
        AiQueuePriority.background,
      ),
      dependencyJobIds:
          List<String>.from(jsonDecode(row.dependencyJobIdsJson) as List),
      modelRole: _enumByName(
        AiModelRole.values,
        row.modelRole,
        AiModelRole.primary,
      ),
    );
    return AnalysisJob(
      id: row.id,
      idempotencyKey: row.idempotencyKey,
      taskSpec: taskSpec,
      route: AiResolvedRoute(
        requestedModelClass: _enumByName(
          AiModelClass.values,
          row.requestedModelClass,
          AiModelClass.balanced,
        ),
        requestedModelRole: _enumByName(
          AiModelRole.values,
          row.requestedModelRole,
          AiModelRole.primary,
        ),
        resolvedRouteId: row.resolvedRouteId,
        providerConfigId: row.providerConfigId,
        modelName: row.modelName,
        promptVersion: row.promptVersion,
        verifierIsIndependent: row.verifierIsIndependent,
      ),
      payloadJson: row.payloadJson,
      status: _enumByName(
        AnalysisJobStatus.values,
        row.status,
        AnalysisJobStatus.failed,
      ),
      attemptCount: row.attemptCount,
      maxAttempts: row.maxAttempts,
      resultJson: row.resultJson,
      errorMessage: row.errorMessage,
      progress: _decodeProgress(row.progressJson),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
    );
  }
}

AnalysisJobProgress? _decodeProgress(String? source) {
  if (source == null || source.isEmpty) return null;
  try {
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return AnalysisJobProgress.fromJson(decoded);
    }
    if (decoded is Map) {
      return AnalysisJobProgress.fromJson(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {
    // Invalid progress metadata must not hide the underlying task.
  }
  return null;
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
