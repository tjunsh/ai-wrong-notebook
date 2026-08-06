import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_wrong_notebook/src/common/widgets/stats_chart.dart';

void main() {
  group('StatsGrid', () {
    testWidgets('forwards taps from all four statistic cards', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsGrid(
              total: 10,
              todayNew: 2,
              pending: 7,
              mastered: 3,
              onTotalTap: () => tapped.add('total'),
              onTodayNewTap: () => tapped.add('today'),
              onMasteredTap: () => tapped.add('mastered'),
              onPendingTap: () => tapped.add('pending'),
            ),
          ),
        ),
      );

      for (final label in <String>['题库总量', '今日新增', '已掌握', '待复习']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }

      expect(tapped, <String>['total', 'today', 'mastered', 'pending']);
    });

    testWidgets('displays all stat values correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsGrid(
              total: 10,
              todayNew: 2,
              pending: 7,
              mastered: 3,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget); // total
      expect(find.text('2'), findsOneWidget); // today new
      expect(find.text('7'), findsOneWidget); // pending
      expect(find.text('3'), findsOneWidget); // mastered
    });

    testWidgets('displays all stat labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsGrid(
              total: 0,
              todayNew: 0,
              pending: 0,
              mastered: 0,
            ),
          ),
        ),
      );

      expect(find.text('题库总量'), findsOneWidget);
      expect(find.text('今日新增'), findsOneWidget);
      expect(find.text('待复习'), findsOneWidget);
      expect(find.text('已掌握'), findsOneWidget);
    });
  });

  group('StatsBarChart', () {
    testWidgets('displays chart with data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsBarChart(
              total: 10,
              mastered: 3,
              reviewing: 4,
              newQ: 3,
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('displays legend items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsBarChart(
              total: 10,
              mastered: 3,
              reviewing: 4,
              newQ: 3,
            ),
          ),
        ),
      );

      expect(find.text('已掌握 (3)'), findsOneWidget);
      expect(find.text('复习中 (4)'), findsOneWidget);
      expect(find.text('新增 (3)'), findsOneWidget);
    });

    testWidgets('handles zero values gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsBarChart(
              total: 0,
              mastered: 0,
              reviewing: 0,
              newQ: 0,
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('已掌握 (0)'), findsOneWidget);
    });
  });
}
