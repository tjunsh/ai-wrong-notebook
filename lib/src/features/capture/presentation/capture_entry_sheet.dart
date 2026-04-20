import 'package:flutter/cupertino.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '添加错题',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _EntryOption(
              icon: CupertinoIcons.camera,
              iconColor: const Color(0xFF6366F1),
              iconBg: const Color(0xFFEEF2FF),
              label: '拍照',
              description: '使用相机拍摄错题',
              onTap: () => _pickAndNavigate(context, ref, fromCamera: true),
            ),
            const SizedBox(height: 10),
            _EntryOption(
              icon: CupertinoIcons.photo,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFFFBEB),
              label: '相册',
              description: '从相册选择图片',
              onTap: () => _pickAndNavigate(context, ref, fromCamera: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndNavigate(BuildContext context, WidgetRef ref, {required bool fromCamera}) async {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    final capture = ref.read(captureServiceProvider);
    final record = fromCamera
        ? await capture.pickFromCamera()
        : await capture.pickFromGallery();

    if (record != null) {
      ref.read(currentQuestionProvider.notifier).state = record;
      router.go('/capture/correction');
    }
  }
}

class _EntryOption extends StatelessWidget {
  const _EntryOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 22, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
