import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_controller.dart';

void main() {
  test('review controller records mastered result', () async {
    final controller = ReviewController.fake();
    final record = await controller.markMastered('q-1');

    expect(record.masteryLevel.name, 'mastered');
    expect(record.reviewCount, 1);
  });
}
