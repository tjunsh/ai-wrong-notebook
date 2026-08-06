import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart' as db;
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart'
    as domain;
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'dart:convert';

class DriftQuestionRepository implements QuestionRepository {
  DriftQuestionRepository(this._db);
  final db.AppDatabase _db;

  @override
  Future<List<domain.QuestionRecord>> listAll() async {
    final rows = await _db.select(_db.questionRecords).get();
    final records = <domain.QuestionRecord>[];
    for (final row in rows) {
      records.add(await _toModel(row));
    }
    return records;
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
          db.QuestionRecordsCompanion(
            id: Value(record.id),
            subject: Value(record.subject.name),
            originalImagePath: Value(record.imagePath),
            originalText: Value(record.extractedQuestionText),
            correctedText: Value(record.normalizedQuestionText),
            masteryLevel: Value(record.masteryLevel.name),
            contentStatus: Value(record.contentStatus.name),
            reviewCount: Value(record.reviewCount),
            nextReviewAt: Value(record.lastReviewedAt),
            createdAt: Value(record.createdAt),
            updatedAt: Value(record.updatedAt),
            aiAnalysisJson: Value(record.analysisResult != null
                ? jsonEncode(record.analysisResult!.toJson())
                : null),
            tags: Value(record.tags.join(',')),
            aiTags: Value(record.aiTags.join(',')),
            aiKnowledgePoints: Value(record.aiKnowledgePoints.join(',')),
            customTags: Value(record.customTags.join(',')),
            parentQuestionId: Value(record.parentQuestionId),
            rootQuestionId: Value(record.rootQuestionId),
            splitOrder: Value(record.splitOrder),
          ),
        );

    await (_db.delete(_db.generatedExercises)
          ..where((t) => t.questionId.equals(record.id)))
        .go();
    if (record.savedExercises.isNotEmpty) {
      await _db.batch((batch) {
        batch.insertAll(
          _db.generatedExercises,
          record.savedExercises.map((exercise) {
            final roundIndex = exercise.roundIndex ?? 1;
            final normalized = exercise.copyWith(
              id: '${record.id}-round-$roundIndex-exercise-${(exercise.order ?? 0) + 1}',
              questionId: record.id,
            );
            return db.GeneratedExercisesCompanion.insert(
              id: normalized.id,
              questionId: normalized.questionId,
              generationMode: Value(normalized.generationMode.name),
              orderIndex: Value(normalized.order),
              difficulty: normalized.difficulty,
              question: normalized.question,
              answer: normalized.answer,
              explanation: Value(normalized.explanation),
              optionsJson: Value(normalized.options == null
                  ? null
                  : jsonEncode(normalized.options)),
              userAnswer: Value(normalized.userAnswer),
              isCorrect: Value(normalized.isCorrect),
              roundIndex: Value(normalized.roundIndex),
              roundTotal: Value(normalized.roundTotal),
              roundGroupId: Value(normalized.roundGroupId),
              sourceExerciseId: Value(normalized.sourceExerciseId),
              diagramDataJson: Value(normalized.diagramData == null
                  ? null
                  : jsonEncode(normalized.diagramData)),
              createdAt: normalized.createdAt,
            );
          }).toList(),
        );
      });
    }
  }

  @override
  Future<void> saveDrafts(List<domain.QuestionRecord> records) async {
    for (final record in records) {
      await saveDraft(record);
    }
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.aiConversationMessages)
          ..where((t) => t.questionId.equals(id)))
        .go();
    await (_db.delete(_db.generatedExercises)
          ..where((t) => t.questionId.equals(id)))
        .go();
    await (_db.delete(_db.questionRecords)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> update(domain.QuestionRecord record) => saveDraft(record);

  Future<domain.QuestionRecord> _toModel(db.QuestionRecord row) async {
    AnalysisResult? analysisResult;
    List<GeneratedExercise> legacyExercises = <GeneratedExercise>[];

    if (row.aiAnalysisJson != null && row.aiAnalysisJson!.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.aiAnalysisJson!) as Map<String, dynamic>;
        analysisResult = AnalysisResult.fromJson(decoded);
        legacyExercises = ((decoded['generatedExercises'] as List?) ?? const [])
            .map((e) => GeneratedExercise.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        analysisResult = null;
      }
    }

    final exerciseRows = await (_db.select(_db.generatedExercises)
          ..where((t) => t.questionId.equals(row.id))
          ..orderBy([
            (t) => OrderingTerm.asc(t.roundIndex),
            (t) => OrderingTerm.asc(t.orderIndex),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();

    final savedExercises = exerciseRows.isNotEmpty
        ? exerciseRows.map(_toExerciseModel).toList()
        : legacyExercises
            .asMap()
            .entries
            .map((entry) => entry.value.copyWith(
                  questionId: row.id,
                  order: entry.value.order ?? entry.key,
                ))
            .toList();

    return domain.QuestionRecord(
      id: row.id,
      imagePath: row.originalImagePath ?? '',
      subject: Subject.values.firstWhere((s) => s.name == row.subject,
          orElse: () => Subject.unknown),
      extractedQuestionText: row.originalText,
      normalizedQuestionText: row.correctedText,
      contentFormat: domain.QuestionContentFormat.plain,
      tags: row.tags.isNotEmpty ? row.tags.split(',') : <String>[],
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      lastReviewedAt: row.nextReviewAt,
      reviewCount: row.reviewCount,
      isFavorite: false,
      contentStatus: ContentStatus.values.firstWhere(
          (c) => c.name == row.contentStatus,
          orElse: () => ContentStatus.processing),
      masteryLevel: MasteryLevel.values.firstWhere(
          (m) => m.name == row.masteryLevel,
          orElse: () => MasteryLevel.newQuestion),
      analysisResult: analysisResult,
      savedExercises: savedExercises,
      aiTags: row.aiTags.isNotEmpty ? row.aiTags.split(',') : <String>[],
      aiKnowledgePoints: row.aiKnowledgePoints.isNotEmpty
          ? row.aiKnowledgePoints.split(',')
          : <String>[],
      customTags:
          row.customTags.isNotEmpty ? row.customTags.split(',') : <String>[],
      parentQuestionId: row.parentQuestionId,
      rootQuestionId: row.rootQuestionId,
      splitOrder: row.splitOrder,
    );
  }

  GeneratedExercise _toExerciseModel(db.GeneratedExercise row) {
    final options = row.optionsJson == null || row.optionsJson!.isEmpty
        ? null
        : List<String>.from(jsonDecode(row.optionsJson!) as List);

    Map<String, dynamic>? diagramData;
    if (row.diagramDataJson != null && row.diagramDataJson!.isNotEmpty) {
      try {
        diagramData = jsonDecode(row.diagramDataJson!) as Map<String, dynamic>;
      } catch (_) {
        diagramData = null;
      }
    }

    return GeneratedExercise(
      id: row.id,
      questionId: row.questionId,
      generationMode: ExerciseGenerationMode.values.firstWhere(
        (mode) => mode.name == row.generationMode,
        orElse: () => ExerciseGenerationMode.practice,
      ),
      difficulty: row.difficulty,
      question: row.question,
      answer: row.answer,
      explanation: row.explanation ?? '',
      createdAt: row.createdAt,
      order: row.orderIndex,
      isCorrect: row.isCorrect,
      options: options,
      userAnswer: row.userAnswer,
      roundIndex: row.roundIndex,
      roundTotal: row.roundTotal,
      roundGroupId: row.roundGroupId,
      sourceExerciseId: row.sourceExerciseId,
      diagramData: diagramData,
    );
  }
}
