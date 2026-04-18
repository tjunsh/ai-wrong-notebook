import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_controller.dart';

void main() {
  test('notebook controller filters by subject and mastery', () async {
    final controller = NotebookController.fake();
    final items = await controller.filter(subjectName: '数学', masteryName: 'reviewing');

    expect(items.length, 1);
    expect(items.single.subject.label, '数学');
  });
}
