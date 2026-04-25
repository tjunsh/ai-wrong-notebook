import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum Subject {
  chinese('语文', CupertinoIcons.doc_text, Color(0xFF16A34A)),
  math('数学', CupertinoIcons.function, Color(0xFF6366F1)),
  english('英语', CupertinoIcons.textformat_abc, Color(0xFFD97706)),
  physics('物理', CupertinoIcons.bolt, Color(0xFFEA580C)),
  chemistry('化学', CupertinoIcons.flame, Color(0xFF7C3AED)),
  biology('生物', CupertinoIcons.leaf_arrow_circlepath, Color(0xFF16A34A)),
  history('历史', CupertinoIcons.book, Color(0xFFD97706)),
  geography('地理', CupertinoIcons.globe, Color(0xFF6366F1)),
  politics('政治', CupertinoIcons.building_2_fill, Color(0xFF7C3AED)),
  science('科学', CupertinoIcons.lightbulb, Color(0xFFEA580C)),
  custom('自定义', CupertinoIcons.question, Colors.grey);

  const Subject(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}