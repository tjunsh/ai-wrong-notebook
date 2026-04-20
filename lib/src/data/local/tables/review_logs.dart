import 'package:drift/drift.dart';
import 'question_records.dart';

class ReviewLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text().references(QuestionRecords, #id)();
  DateTimeColumn get reviewedAt => dateTime()();
  BoolColumn get wasCorrect => boolean()();
  IntColumn get responseTimeMs => integer().nullable()();
  TextColumn get notes => text().nullable()();
}