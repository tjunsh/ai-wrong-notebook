import 'package:flutter/material.dart';

class PromptSettingsScreen extends StatelessWidget {
  const PromptSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提示词设置')),
      body: Center(child: const Text('分析题目 / 举一反三')),
    );
  }
}
