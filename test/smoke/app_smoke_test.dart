import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';

void main() {
  testWidgets('app boots to shell with Home tab label', (tester) async {
    await tester.pumpWidget(const SmartWrongNotebookApp());
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('错题本'), findsOneWidget);
    expect(find.text('复习'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
