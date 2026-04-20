import 'package:drift/drift.dart';
import 'question_records.dart';

class GeneratedExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text().references(QuestionRecords, #id)();
  TextColumn get difficulty => text()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get explanation => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}