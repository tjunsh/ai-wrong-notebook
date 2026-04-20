import 'package:drift/drift.dart';

class QuestionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  TextColumn get originalImagePath => text().nullable()();
  TextColumn get originalText => text()();
  TextColumn get correctedText => text()();
  TextColumn get masteryLevel => text()();
  TextColumn get contentStatus => text()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get aiAnalysisJson => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}