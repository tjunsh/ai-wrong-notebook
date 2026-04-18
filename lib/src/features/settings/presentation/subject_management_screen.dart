import 'package:flutter/material.dart';

class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('科目管理')),
      body: Center(child: const Text('内置科目 + 自定义科目')),
    );
  }
}
