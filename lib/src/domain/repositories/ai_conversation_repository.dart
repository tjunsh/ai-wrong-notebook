import 'package:smart_wrong_notebook/src/domain/models/ai_conversation_message.dart';

abstract class AiConversationRepository {
  Future<List<AiConversationMessage>> getByQuestionId(String questionId);
  Future<void> insert(AiConversationMessage message);
  Future<void> insertAll(List<AiConversationMessage> messages);
  Future<void> clearByQuestionId(String questionId);
}

class InMemoryAiConversationRepository implements AiConversationRepository {
  final List<AiConversationMessage> _items = <AiConversationMessage>[];

  @override
  Future<List<AiConversationMessage>> getByQuestionId(String questionId) async {
    final messages = _items
        .where((message) => message.questionId == questionId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List<AiConversationMessage>.unmodifiable(messages);
  }

  @override
  Future<void> insert(AiConversationMessage message) async {
    _items.removeWhere((item) => item.id == message.id);
    _items.add(message);
  }

  @override
  Future<void> insertAll(List<AiConversationMessage> messages) async {
    for (final message in messages) {
      await insert(message);
    }
  }

  @override
  Future<void> clearByQuestionId(String questionId) async {
    _items.removeWhere((message) => message.questionId == questionId);
  }
}
