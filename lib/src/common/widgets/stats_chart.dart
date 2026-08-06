import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';

class StatsBarChart extends StatelessWidget {
  const StatsBarChart({
    super.key,
    required this.total,
    required this.mastered,
    required this.reviewing,
    required this.newQ,
  });

  final int total;
  final int mastered;
  final int reviewing;
  final int newQ;

  static const _colors = {
    MasteryLevel.mastered: Color(0xFF16A34A),
    MasteryLevel.reviewing: Color(0xFFD97706),
    MasteryLevel.newQuestion: Color(0xFF6B7280),
  };

  static const _labels = {
    MasteryLevel.mastered: '已掌握',
    MasteryLevel.reviewing: '复习中',
    MasteryLevel.newQuestion: '新增',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxY =
        [mastered, reviewing, newQ].reduce((a, b) => a > b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY < 1 ? 5 : maxY * 1.3,
              barTouchData: BarTouchData(
                enabled: total > 0,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1E293B),
                  tooltipRoundedRadius: 6,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final level = MasteryLevel.values[group.x.toInt()];
                    return BarTooltipItem(
                      '${_labels[level]}\n${rod.toY.toInt()} 题',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final level = MasteryLevel.values[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _labels[level]!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: <BarChartGroupData>[
                BarChartGroupData(
                  x: MasteryLevel.newQuestion.index,
                  barRods: [
                    BarChartRodData(
                      toY: newQ.toDouble(),
                      color: _colors[MasteryLevel.newQuestion],
                      width: 28,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: MasteryLevel.reviewing.index,
                  barRods: [
                    BarChartRodData(
                      toY: reviewing.toDouble(),
                      color: _colors[MasteryLevel.reviewing],
                      width: 28,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: MasteryLevel.mastered.index,
                  barRods: [
                    BarChartRodData(
                      toY: mastered.toDouble(),
                      color: _colors[MasteryLevel.mastered],
                      width: 28,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            _LegendDot(
                color: _colors[MasteryLevel.newQuestion]!, label: '新增 ($newQ)'),
            const SizedBox(width: 16),
            _LegendDot(
                color: _colors[MasteryLevel.reviewing]!,
                label: '复习中 ($reviewing)'),
            const SizedBox(width: 16),
            _LegendDot(
                color: _colors[MasteryLevel.mastered]!,
                label: '已掌握 ($mastered)'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.total,
    required this.todayNew,
    required this.pending,
    required this.mastered,
    this.onTotalTap,
    this.onTodayNewTap,
    this.onPendingTap,
    this.onMasteredTap,
  });

  final int total;
  final int todayNew;
  final int pending;
  final int mastered;
  final VoidCallback? onTotalTap;
  final VoidCallback? onTodayNewTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onMasteredTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: '题库总量',
                value: '$total',
                bg: const Color(0xFFEFF6FF),
                darkBg: const Color(0xFF2563EB).withValues(alpha: 0.14),
                border: const Color(0xFFBFDBFE),
                darkBorder: const Color(0xFF2563EB).withValues(alpha: 0.35),
                text: const Color(0xFF2563EB),
                onTap: onTotalTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: '今日新增',
                value: '$todayNew',
                bg: const Color(0xFFF9FAFB),
                darkBg: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
                border: const Color(0xFFE5E7EB),
                darkBorder:
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.28),
                text: isDark
                    ? colorScheme.onSurfaceVariant
                    : const Color(0xFF6B7280),
                onTap: onTodayNewTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: '已掌握',
                value: '$mastered',
                bg: const Color(0xFFF0FDF4),
                darkBg: const Color(0xFF16A34A).withValues(alpha: 0.14),
                border: const Color(0xFFBBF7D0),
                darkBorder: const Color(0xFF16A34A).withValues(alpha: 0.35),
                text: const Color(0xFF16A34A),
                onTap: onMasteredTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: '待复习',
                value: '$pending',
                bg: const Color(0xFFFFF7ED),
                darkBg: const Color(0xFFEA580C).withValues(alpha: 0.14),
                border: const Color(0xFFFED7AA),
                darkBorder: const Color(0xFFEA580C).withValues(alpha: 0.35),
                text: const Color(0xFFEA580C),
                onTap: onPendingTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.bg,
    required this.darkBg,
    required this.border,
    required this.darkBorder,
    required this.text,
    this.onTap,
  });

  final String label;
  final String value;
  final Color bg;
  final Color darkBg;
  final Color border;
  final Color darkBorder;
  final Color text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? darkBg : bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? darkBorder : border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: text,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(label, style: TextStyle(fontSize: 11, color: text)),
                  if (onTap != null) ...<Widget>[
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 14, color: text),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
