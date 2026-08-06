import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart'
    hide AiConversationMessage, QuestionRecord;
import 'package:smart_wrong_notebook/src/data/repositories/drift_ai_conversation_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_conversation_message.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  late AppDatabase database;
  late DriftQuestionRepository questionRepository;
  late DriftAiConversationRepository conversationRepository;

  setUp(() {
    database = AppDatabase.memory();
    questionRepository = DriftQuestionRepository(database);
    conversationRepository = DriftAiConversationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('persists ai follow-up messages by question id', () async {
    final now = DateTime(2026, 7, 10, 19);
    await questionRepository.saveDraft(QuestionRecord.draft(
      id: 'q-follow-up',
      imagePath: '/tmp/q.jpg',
      subject: Subject.math,
      recognizedText: '已知 x+1=3，求 x',
    ));

    await conversationRepository.insertAll(<AiConversationMessage>[
      AiConversationMessage(
        id: 'm-2',
        questionId: 'q-follow-up',
        role: AiConversationRole.assistant,
        content: '因为等式两边同时减去 1。',
        createdAt: now.add(const Duration(seconds: 2)),
      ),
      AiConversationMessage(
        id: 'm-1',
        questionId: 'q-follow-up',
        role: AiConversationRole.user,
        content: '为什么要移项？',
        createdAt: now.add(const Duration(seconds: 1)),
      ),
    ]);

    final loaded = await conversationRepository.getByQuestionId('q-follow-up');

    expect(loaded, hasLength(2));
    expect(loaded.first.role, AiConversationRole.user);
    expect(loaded.first.content, '为什么要移项？');
    expect(loaded.last.role, AiConversationRole.assistant);
  });
}
