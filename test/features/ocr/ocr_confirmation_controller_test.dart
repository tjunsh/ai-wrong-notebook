import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/ocr_confirmation_controller.dart';

void main() {
  test('controller updates corrected text and subject', () {
    final controller = OcrConfirmationController(
      recognizedText: '1十1=?',
      subjectName: '数学',
    );

    controller.updateCorrectedText('1+1=?');
    controller.updateSubjectName('数学');

    expect(controller.correctedText, '1+1=?');
    expect(controller.subjectName, '数学');
  });
}
