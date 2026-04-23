import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class OcrConfirmationScreen extends ConsumerWidget {
  const OcrConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentQuestionProvider);
    final hasImage = current?.imagePath != null && File(current!.imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('分析确认'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/capture/correction'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              if (hasImage)
                GestureDetector(
                  onTap: () => _showFullImage(context, current.imagePath),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(current.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(child: Text('暂无图片', style: TextStyle(color: Colors.grey))),
                ),
              if (current?.subject != null) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(CupertinoIcons.book, size: 14, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 4),
                          Text(
                            current!.subject.label,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => context.go('/capture/crop'),
                icon: const Icon(CupertinoIcons.crop, size: 18),
                label: const Text('重新框选'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => context.go('/analysis/loading'),
                icon: const Icon(CupertinoIcons.arrow_2_circlepath, size: 18),
                label: const Text('重新分析'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('原图'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }
}
