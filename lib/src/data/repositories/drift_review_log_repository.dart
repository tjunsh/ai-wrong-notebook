import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart' as db;
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';

class DriftReviewLogRepository implements ReviewLogRepository {
  DriftReviewLogRepository({db.AppDatabase? database}) : _db = database ?? db.AppDatabase();
  final db.AppDatabase _db;

  @override
  Future<void> insert(domain.ReviewLog log) async {
    await _db.into(_db.reviewLogs).insert(_toCompanion(log));
  }

  @override
  Future<List<domain.ReviewLog>> getByQuestionId(String questionId) async {
    final rows = await (_db.select(_db.reviewLogs)
          ..where((t) => t.questionRecordId.equals(questionId))
          ..orderBy([(t) => OrderingTerm.desc(t.reviewedAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.ReviewLog>> listAll() async {
    final rows = await _db.select(_db.reviewLogs).get();
    return rows.map(_toDomain).toList();
  }

  domain.ReviewLog _toDomain(db.ReviewLog r) {
    return domain.ReviewLog(
      id: r.id,
      questionRecordId: r.questionRecordId,
      reviewedAt: r.reviewedAt,
      result: r.result,
      masteryAfter: MasteryLevel.values.firstWhere((m) => m.name == r.masteryAfter),
    );
  }

  db.ReviewLogsCompanion _toCompanion(domain.ReviewLog log) {
    return db.ReviewLogsCompanion(
      id: Value(log.id),
      questionRecordId: Value(log.questionRecordId),
      reviewedAt: Value(log.reviewedAt),
      result: Value(log.result),
      masteryAfter: Value(log.masteryAfter.name),
    );
  }
}
