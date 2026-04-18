import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OcrConfirmationScreen extends StatelessWidget {
  const OcrConfirmationScreen({super.key, required this.initialText});

  final String initialText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('识别确认')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: '数学',
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: '语文', child: Text('语文')),
                DropdownMenuItem(value: '数学', child: Text('数学')),
                DropdownMenuItem(value: '英语', child: Text('英语')),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: '学科'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextFormField(
                initialValue: initialText,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: '识别文本',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/analysis/loading'),
              child: const Text('开始 AI 解析'),
            ),
          ],
        ),
      ),
    );
  }
}
