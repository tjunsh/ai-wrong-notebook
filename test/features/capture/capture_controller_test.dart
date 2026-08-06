import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_controller.dart';

void main() {
  test('capture controller creates a draft from imported image', () async {
    final controller = CaptureController.fake();
    final draft = await controller.createDraftFromFile(File('/tmp/raw.jpg'));

    expect(draft.imagePath, '/app/images/raw.jpg');
    expect(draft.contentStatus.name, 'processing');
    expect(draft.subject, Subject.unknown);
  });
}
