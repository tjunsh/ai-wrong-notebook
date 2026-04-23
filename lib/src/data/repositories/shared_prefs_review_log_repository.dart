import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';

class SharedPrefsReviewLogRepository implements ReviewLogRepository {
  static const _key = 'review_logs';

  Future<List<ReviewLog>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ReviewLog(
      id: e['id'] as String,
      questionRecordId: e['questionRecordId'] as String,
      reviewedAt: DateTime.parse(e['reviewedAt'] as String),
      result: e['result'] as String,
      masteryAfter: MasteryLevel.values.firstWhere(
        (m) => m.name == e['masteryAfter'],
        orElse: () => MasteryLevel.reviewing,
      ),
    )).toList();
  }

  Future<void> _saveAll(List<ReviewLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(logs.map((l) => {
      'id': l.id,
      'questionRecordId': l.questionRecordId,
      'reviewedAt': l.reviewedAt.toIso8601String(),
      'result': l.result,
      'masteryAfter': l.masteryAfter.name,
    }).toList());
    await prefs.setString(_key, raw);
  }

  @override
  Future<void> insert(ReviewLog log) async {
    final logs = await _loadAll();
    logs.add(log);
    await _saveAll(logs);
  }

  @override
  Future<List<ReviewLog>> getByQuestionId(String questionId) async {
    final logs = await _loadAll();
    return logs.where((l) => l.questionRecordId == questionId).toList();
  }

  @override
  Future<List<ReviewLog>> listAll() async => _loadAll();
}
