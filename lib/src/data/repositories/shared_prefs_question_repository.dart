import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class SharedPrefsQuestionRepository implements QuestionRepository {
  SharedPreferences? _prefs;
  static const String _questionsKey = 'questions_list';

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<List<QuestionRecord>> listAll() async {
    final prefs = await _preferences;
    final json = prefs.getString(_questionsKey);
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => QuestionRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<QuestionRecord?> getById(String id) async {
    final all = await listAll();
    for (final q in all) {
      if (q.id == id) return q;
    }
    return null;
  }

  @override
  Future<void> saveDraft(QuestionRecord record) async {
    final all = await listAll();
    all.removeWhere((q) => q.id == record.id);
    all.add(record);
    await _saveAll(all);
  }

  @override
  Future<void> delete(String id) async {
    final all = await listAll();
    all.removeWhere((q) => q.id == id);
    await _saveAll(all);
  }

  @override
  Future<void> update(QuestionRecord record) async {
    await saveDraft(record);
  }

  Future<void> _saveAll(List<QuestionRecord> questions) async {
    final json = jsonEncode(questions.map((q) => q.toJson()).toList());
    await (await _preferences).setString(_questionsKey, json);
  }
}
