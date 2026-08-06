import 'package:drift/drift.dart';
import 'question_records.dart';

class AiConversationMessages extends Table {
  TextColumn get id => text()();
  TextColumn get questionId => text().references(QuestionRecords, #id)();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
