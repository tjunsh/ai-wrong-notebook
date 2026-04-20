import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class ImageCropScreen extends ConsumerStatefulWidget {
  const ImageCropScreen({super.key});

  @override
  ConsumerState<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends ConsumerState<ImageCropScreen> {
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCrop();
    });
  }

  Future<void> _startCrop() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) {
      if (mounted) context.go('/');
      return;
    }

    setState(() => _cropping = true);

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: current.imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '框选题目',
            toolbarColor: const Color(0xFF6366F1),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: '框选题目',
            cancelButtonTitle: '取消',
            doneButtonTitle: '完成',
          ),
        ],
      );

      if (!mounted) return;

      if (croppedFile != null) {
        // Save cropped image
        final storage = ref.read(imageStorageServiceProvider);
        final savedPath = await storage.saveImage(File(croppedFile.path));

        // Create new question with cropped image path
        final newRecord = QuestionRecord.draft(
          id: current.id,
          imagePath: savedPath,
          subject: current.subject,
          recognizedText: '',
        );
        ref.read(currentQuestionProvider.notifier).state = newRecord;
      }

      if (mounted) {
        // Go directly to AI analysis - AI will recognize the question from image
        context.go('/analysis/loading');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('裁剪失败: $e')),
        );
        context.go('/capture/ocr-confirmation');
      }
    } finally {
      if (mounted) setState(() => _cropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('框选题目'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: _cropping
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在打开裁剪工具...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('准备裁剪...'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _startCrop,
                    child: const Text('重新裁剪'),
                  ),
                ],
              ),
      ),
    );
  }
}
