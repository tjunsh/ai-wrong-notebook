import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('开始拍错题', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: null,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('拍照录题'),
        ),
        const SizedBox(height: 24),
        Text('最近新增', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
