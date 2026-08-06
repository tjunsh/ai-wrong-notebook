enum AiConversationRole { user, assistant }

class AiConversationMessage {
  const AiConversationMessage({
    required this.id,
    required this.questionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final AiConversationRole role;
  final String content;
  final DateTime createdAt;
}
