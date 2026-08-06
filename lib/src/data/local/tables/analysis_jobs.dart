import 'package:drift/drift.dart';

class AnalysisJobs extends Table {
  TextColumn get id => text()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get parentQuestionId => text()();
  TextColumn get taskType => text()();
  TextColumn get workloadProfile => text()();
  TextColumn get requiredCapabilitiesJson => text()();
  TextColumn get qualityPolicy => text()();
  TextColumn get queuePriority => text()();
  TextColumn get dependencyJobIdsJson => text()();
  TextColumn get modelRole => text()();
  TextColumn get requestedModelClass => text()();
  TextColumn get requestedModelRole => text()();
  TextColumn get resolvedRouteId => text()();
  TextColumn get providerConfigId => text()();
  TextColumn get modelName => text()();
  TextColumn get promptVersion => text()();
  BoolColumn get verifierIsIndependent =>
      boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  IntColumn get maxAttempts => integer().withDefault(const Constant(2))();
  TextColumn get resultJson => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get progressJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
