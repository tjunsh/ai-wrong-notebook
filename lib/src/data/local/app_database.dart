import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'package:smart_wrong_notebook/src/data/local/tables/question_records.dart';
import 'package:smart_wrong_notebook/src/data/local/tables/generated_exercises.dart';
import 'package:smart_wrong_notebook/src/data/local/tables/review_logs.dart';
import 'package:smart_wrong_notebook/src/data/local/tables/settings_entries.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [QuestionRecords, GeneratedExercises, ReviewLogs, SettingsEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  factory AppDatabase() {
    _instance ??= AppDatabase._internal(_openConnection());
    return _instance!;
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory()
          .timeout(const Duration(seconds: 10));
      final file = File(p.join(dbFolder.path, 'smart_wrong_notebook.db'));
      return NativeDatabase.createInBackground(file);
    } catch (e) {
      return NativeDatabase.memory();
    }
  });
}