import 'package:drift/drift.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart' as db;
import 'package:smart_wrong_notebook/src/domain/models/ai_conversation_message.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/ai_conversation_repository.dart';

class DriftAiConversationRepository implements AiConversationRepository {
  DriftAiConversationRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<List<AiConversationMessage>> getByQuestionId(String questionId) async {
    final rows = await (_db.select(_db.aiConversationMessages)
          ..where((table) => table.questionId.equals(questionId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> insert(AiConversationMessage message) async {
    await _db.into(_db.aiConversationMessages).insertOnConflictUpdate(
          db.AiConversationMessagesCompanion.insert(
            id: message.id,
            questionId: message.questionId,
            role: message.role.name,
            content: message.content,
            createdAt: message.createdAt,
          ),
        );
  }

  @override
  Future<void> insertAll(List<AiConversationMessage> messages) async {
    if (messages.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.aiConversationMessages,
        messages
            .map((message) => db.AiConversationMessagesCompanion.insert(
                  id: message.id,
                  questionId: message.questionId,
                  role: message.role.name,
                  content: message.content,
                  createdAt: message.createdAt,
                ))
            .toList(),
      );
    });
  }

  @override
  Future<void> clearByQuestionId(String questionId) async {
    await (_db.delete(_db.aiConversationMessages)
          ..where((table) => table.questionId.equals(questionId)))
        .go();
  }

  AiConversationMessage _toModel(db.AiConversationMessage row) {
    return AiConversationMessage(
      id: row.id,
      questionId: row.questionId,
      role: AiConversationRole.values.firstWhere(
        (role) => role.name == row.role,
        orElse: () => AiConversationRole.user,
      ),
      content: row.content,
      createdAt: row.createdAt,
    );
  }
}
