import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class CaptureEntrySheet extends ConsumerWidget {
  const CaptureEntrySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () => _pickAndNavigate(context, ref, fromCamera: true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('相册'),
              onTap: () => _pickAndNavigate(context, ref, fromCamera: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndNavigate(BuildContext context, WidgetRef ref, {required bool fromCamera}) async {
    Navigator.pop(context);
    final capture = ref.read(captureServiceProvider);
    final record = fromCamera
        ? await capture.pickFromCamera()
        : await capture.pickFromGallery();

    if (record != null && context.mounted) {
      ref.read(currentQuestionProvider.notifier).state = record;
      context.go('/capture/correction');
    }
  }
}
