import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class NotebookController {
  NotebookController(this._items);

  final List<QuestionRecord> _items;

  factory NotebookController.fake() {
    return NotebookController(<QuestionRecord>[
      QuestionRecord.draft(id: 'q-1', imagePath: '/tmp/1.jpg', subject: Subject.math, recognizedText: 'a')
          .copyWith(contentStatus: ContentStatus.ready, masteryLevel: MasteryLevel.reviewing),
      QuestionRecord.draft(id: 'q-2', imagePath: '/tmp/2.jpg', subject: Subject.english, recognizedText: 'b')
          .copyWith(contentStatus: ContentStatus.ready),
    ]);
  }

  Future<List<QuestionRecord>> filter({String? subjectName, String? masteryName}) async {
    return _items.where((QuestionRecord item) {
      final bool subjectOk = subjectName == null || item.subject.label == subjectName;
      final bool masteryOk = masteryName == null || item.masteryLevel.name == masteryName;
      return subjectOk && masteryOk;
    }).toList();
  }
}
