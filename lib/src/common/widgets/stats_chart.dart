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
    final maxY = [mastered, reviewing, newQ].reduce((a, b) => a > b ? a : b).toDouble();

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
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: <BarChartGroupData>[
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: mastered.toDouble(),
                      color: _colors[MasteryLevel.mastered],
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: reviewing.toDouble(),
                      color: _colors[MasteryLevel.reviewing],
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: newQ.toDouble(),
                      color: _colors[MasteryLevel.newQuestion],
                      width: 28,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
            _LegendDot(color: _colors[MasteryLevel.mastered]!, label: '已掌握 ($mastered)'),
            const SizedBox(width: 16),
            _LegendDot(color: _colors[MasteryLevel.reviewing]!, label: '复习中 ($reviewing)'),
            const SizedBox(width: 16),
            _LegendDot(color: _colors[MasteryLevel.newQuestion]!, label: '新增 ($newQ)'),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.total,
    required this.mastered,
    required this.reviewing,
    required this.newQ,
    required this.due,
  });

  final int total;
  final int mastered;
  final int reviewing;
  final int newQ;
  final int due;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _StatCard(label: '题库总量', value: '$total', bg: const Color(0xFFEFF6FF), border: const Color(0xFFBFDBFE), text: const Color(0xFF2563EB))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '待复习', value: '$due', bg: const Color(0xFFFFF7ED), border: const Color(0xFFFED7AA), text: const Color(0xFFEA580C))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _StatCard(label: '已掌握', value: '$mastered', bg: const Color(0xFFF0FDF4), border: const Color(0xFFBBF7D0), text: const Color(0xFF16A34A))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '复习中', value: '$reviewing', bg: const Color(0xFFFEF3C7), border: const Color(0xFFFDE68A), text: const Color(0xFFD97706))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '新增', value: '$newQ', bg: const Color(0xFFF9FAFB), border: const Color(0xFFE5E7EB), text: const Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.bg, required this.border, required this.text});

  final String label;
  final String value;
  final Color bg;
  final Color border;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: <Widget>[
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: text)),
        ],
      ),
    );
  }
}
