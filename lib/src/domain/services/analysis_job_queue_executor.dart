import 'dart:async';

import 'package:smart_wrong_notebook/src/domain/models/analysis_job.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/analysis_job_repository.dart';

class AnalysisJobExecutionContext {
  const AnalysisJobExecutionContext({
    required this.job,
    required this.dependencyResults,
    this.progressReporter = _ignoreProgress,
  });

  final AnalysisJob job;
  final Map<String, String> dependencyResults;
  final Future<void> Function(AnalysisJobProgress progress) progressReporter;

  Future<void> reportProgress(AnalysisJobProgress progress) {
    return progressReporter(progress);
  }
}

Future<void> _ignoreProgress(AnalysisJobProgress progress) async {}

abstract interface class AnalysisJobRunner {
  Future<String> run(AnalysisJobExecutionContext context);
}

class AnalysisJobExecutionException implements Exception {
  const AnalysisJobExecutionException(
    this.message, {
    required this.retryable,
  });

  final String message;
  final bool retryable;

  @override
  String toString() => message;
}

class AnalysisJobQueueExecutor {
  AnalysisJobQueueExecutor({
    required AnalysisJobRepository repository,
    required AnalysisJobRunner runner,
    this.terminalJobRetention = const Duration(days: 30),
    this.maintenanceInterval = const Duration(days: 1),
    DateTime Function()? now,
  })  : _repository = repository,
        _runner = runner,
        _now = now ?? DateTime.now;

  final AnalysisJobRepository _repository;
  final AnalysisJobRunner _runner;
  final Duration terminalJobRetention;
  final Duration maintenanceInterval;
  final DateTime Function() _now;

  Future<void>? _initializeFuture;
  Future<void>? _drainFuture;
  Future<void>? _maintenanceFuture;
  DateTime? _lastMaintenanceAt;
  bool _drainRequested = false;

  Future<void> initialize() {
    return _initializeFuture ??= _recoverAndDrain();
  }

  Future<void> _recoverAndDrain() async {
    await _repository.recoverInterruptedJobs();
    await _runTerminalCleanup(force: true);
    await processUntilIdle();
  }

  Future<AnalysisJob> enqueue(AnalysisJob job) async {
    await _runTerminalCleanup();
    final persisted = await _repository.enqueue(job);
    unawaited(processUntilIdle());
    return persisted;
  }

  Future<void> _runTerminalCleanup({bool force = false}) {
    final now = _now();
    final lastRun = _lastMaintenanceAt;
    if (!force &&
        lastRun != null &&
        now.difference(lastRun) < maintenanceInterval) {
      return Future<void>.value();
    }

    final active = _maintenanceFuture;
    if (active != null) return active;

    late final Future<void> maintenance;
    maintenance = () async {
      await _repository.deleteTerminalJobsBefore(
        _now().subtract(terminalJobRetention),
      );
      _lastMaintenanceAt = _now();
    }()
        .whenComplete(() {
      if (identical(_maintenanceFuture, maintenance)) {
        _maintenanceFuture = null;
      }
    });
    _maintenanceFuture = maintenance;
    return maintenance;
  }

  Future<void> processUntilIdle() {
    _drainRequested = true;
    final activeDrain = _drainFuture;
    if (activeDrain != null) return activeDrain;

    late final Future<void> trackedDrain;
    trackedDrain = _drainLoop().whenComplete(() {
      if (identical(_drainFuture, trackedDrain)) {
        _drainFuture = null;
      }
    });
    _drainFuture = trackedDrain;
    return trackedDrain;
  }

  Future<void> _drainLoop() async {
    do {
      _drainRequested = false;
      while (true) {
        final job = await _repository.claimNextRunnable();
        if (job == null) break;
        await _execute(job);
      }
    } while (_drainRequested);
  }

  Future<void> _execute(AnalysisJob job) async {
    try {
      final dependencyResults = await _resolveDependencies(job);
      final result = await _runner.run(AnalysisJobExecutionContext(
        job: job,
        dependencyResults: dependencyResults,
        progressReporter: (progress) => _repository.updateProgress(
          job.id,
          attemptCount: job.attemptCount,
          progress: progress,
        ),
      ));
      await _repository.markCompleted(job.id, resultJson: result);
    } on AnalysisJobExecutionException catch (error) {
      await _repository.recordFailure(
        job.id,
        errorMessage: error.message,
        retryable: error.retryable,
      );
    } catch (error) {
      await _repository.recordFailure(
        job.id,
        errorMessage: error.toString(),
        retryable: false,
      );
    }
  }

  Future<Map<String, String>> _resolveDependencies(AnalysisJob job) async {
    final results = <String, String>{};
    for (final dependencyId in job.taskSpec.dependencyJobIds) {
      final dependency = await _repository.getById(dependencyId);
      final result = dependency?.resultJson;
      if (dependency?.status != AnalysisJobStatus.completed || result == null) {
        throw AnalysisJobExecutionException(
          '前置 AI 任务 $dependencyId 没有可用结果。',
          retryable: false,
        );
      }
      results[dependencyId] = result;
    }
    return Map<String, String>.unmodifiable(results);
  }
}
