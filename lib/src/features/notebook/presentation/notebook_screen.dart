import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotebookScreen extends StatelessWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('错题本列表（按学科/掌握状态筛选）'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/capture/correction'),
              child: const Text('+ 添加错题'),
            ),
          ],
        ),
      ),
    );
  }
}
