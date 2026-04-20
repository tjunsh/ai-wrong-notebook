import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart' as domain;
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'dart:convert';

class DriftQuestionRepository implements QuestionRepository {
  DriftQuestionRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<domain.QuestionRecord>> listAll() async {
    final rows = await _db.select(_db.questionRecords).get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<domain.QuestionRecord?> getById(String id) async {
    final row = await (_db.select(_db.questionRecords)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toModel(row) : null;
  }

  @override
  Future<void> saveDraft(domain.QuestionRecord record) async {
    await _db.into(_db.questionRecords).insertOnConflictUpdate(
          QuestionRecordsCompanion(
            id: Value(record.id),
            subject: Value(record.subject.name),
            originalImagePath: Value(record.imagePath),
            originalText: Value(record.recognizedText),
            correctedText: Value(record.correctedText),
            masteryLevel: Value(record.masteryLevel.name),
            contentStatus: Value(record.contentStatus.name),
            reviewCount: Value(record.reviewCount),
            nextReviewAt: Value(record.lastReviewedAt),
            createdAt: Value(record.createdAt),
            updatedAt: Value(record.updatedAt),
            aiAnalysisJson: Value(record.analysisResult != null ? jsonEncode(record.analysisResult!.toJson()) : null),
            tags: Value(record.tags.join(',')),
          ),
        );
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.questionRecords)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> update(domain.QuestionRecord record) => saveDraft(record);

  domain.QuestionRecord _toModel(QuestionRecord row) {
    return domain.QuestionRecord(
      id: row.id,
      imagePath: row.originalImagePath ?? '',
      subject: Subject.values.firstWhere((s) => s.name == row.subject, orElse: () => Subject.math),
      recognizedText: row.originalText,
      correctedText: row.correctedText,
      tags: row.tags.isNotEmpty ? row.tags.split(',') : <String>[],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastReviewedAt: row.nextReviewAt,
      reviewCount: row.reviewCount,
      isFavorite: false,
      contentStatus: ContentStatus.values.firstWhere((c) => c.name == row.contentStatus, orElse: () => ContentStatus.processing),
      masteryLevel: MasteryLevel.values.firstWhere((m) => m.name == row.masteryLevel, orElse: () => MasteryLevel.newQuestion),
      analysisResult: row.aiAnalysisJson != null ? null : null,
    );
  }
}