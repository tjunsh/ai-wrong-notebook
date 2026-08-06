import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_controller.dart';

void main() {
  test('controller marks record ready after ai analysis', () async {
    final controller = AnalysisController.fake();
    final record = await controller.analyze(
      questionId: 'q-1',
      correctedText: 'x+2=5',
      subjectName: '数学',
    );

    expect(record.contentStatus.name, 'ready');
    expect(record.savedExercises, isEmpty);
  });
}
