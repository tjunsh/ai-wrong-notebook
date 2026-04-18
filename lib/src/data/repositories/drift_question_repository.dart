import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart' as db;
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class DriftQuestionRepository implements QuestionRepository {
  DriftQuestionRepository({db.AppDatabase? database}) : _db = database ?? db.AppDatabase();

  final db.AppDatabase _db;

  QuestionRecord _toDomain(db.QuestionRecord r) {
    return QuestionRecord(
      id: r.id,
      imagePath: r.imagePath,
      subject: Subject.values.firstWhere((s) => s.name == r.subject),
      recognizedText: r.recognizedText,
      correctedText: r.correctedText,
      tags: List<String>.from(jsonDecode(r.tagsJson) as List),
      contentStatus: ContentStatus.values.firstWhere((s) => s.name == r.contentStatus),
      masteryLevel: MasteryLevel.values.firstWhere((s) => s.name == r.masteryLevel),
      analysisResult: r.analysisJson != null ? _parseAnalysis(r.analysisJson!) : null,
      isFavorite: r.isFavorite,
      reviewCount: r.reviewCount,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      lastReviewedAt: r.lastReviewedAt,
    );
  }

  db.QuestionRecordsCompanion _toCompanion(QuestionRecord r) {
    return db.QuestionRecordsCompanion(
      id: Value(r.id),
      imagePath: Value(r.imagePath),
      subject: Value(r.subject.name),
      recognizedText: Value(r.recognizedText),
      correctedText: Value(r.correctedText),
      tagsJson: Value(jsonEncode(r.tags)),
      contentStatus: Value(r.contentStatus.name),
      masteryLevel: Value(r.masteryLevel.name),
      analysisJson: Value(r.analysisResult != null ? _encodeAnalysis(r.analysisResult!) : null),
      isFavorite: Value(r.isFavorite),
      reviewCount: Value(r.reviewCount),
      createdAt: Value(r.createdAt),
      updatedAt: Value(r.updatedAt),
      lastReviewedAt: Value(r.lastReviewedAt),
    );
  }

  String _encodeAnalysis(AnalysisResult result) {
    return jsonEncode({
      'finalAnswer': result.finalAnswer,
      'steps': result.steps,
      'knowledgePoints': result.knowledgePoints,
      'mistakeReason': result.mistakeReason,
      'studyAdvice': result.studyAdvice,
      'generatedExercises': result.generatedExercises.map((e) => {
        'id': e.id,
        'difficulty': e.difficulty,
        'question': e.question,
        'answer': e.answer,
        'explanation': e.explanation,
        'isCorrect': e.isCorrect,
      }).toList(),
    });
  }

  AnalysisResult _parseAnalysis(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final exercises = (map['generatedExercises'] as List).map((e) {
      final em = e as Map<String, dynamic>;
      return GeneratedExercise(
        id: em['id'] as String,
        difficulty: em['difficulty'] as String,
        question: em['question'] as String,
        answer: em['answer'] as String,
        explanation: em['explanation'] as String,
        isCorrect: em['isCorrect'] as bool?,
      );
    }).toList();
    return AnalysisResult(
      finalAnswer: map['finalAnswer'] as String,
      steps: List<String>.from(map['steps'] as List),
      knowledgePoints: List<String>.from(map['knowledgePoints'] as List),
      mistakeReason: map['mistakeReason'] as String,
      studyAdvice: map['studyAdvice'] as String,
      generatedExercises: exercises,
    );
  }

  @override
  Future<void> saveDraft(QuestionRecord record) async {
    await _db.into(_db.questionRecords).insertOnConflictUpdate(_toCompanion(record));
  }

  @override
  Future<List<QuestionRecord>> listAll() async {
    final rows = await _db.select(_db.questionRecords).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<QuestionRecord?> getById(String id) async {
    final query = _db.select(_db.questionRecords)
      ..where((t) => t.id.equals(id));
    final rows = await query.get();
    return rows.isEmpty ? null : _toDomain(rows.first);
  }

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.questionRecords)
      ..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> update(QuestionRecord record) async {
    await (_db.update(_db.questionRecords)
      ..where((t) => t.id.equals(record.id)))
        .replace(_toCompanion(record));
  }
}
