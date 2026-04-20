import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class QuestionCorrectionScreen extends ConsumerStatefulWidget {
  const QuestionCorrectionScreen({super.key});

  @override
  ConsumerState<QuestionCorrectionScreen> createState() => _QuestionCorrectionScreenState();
}

class _QuestionCorrectionScreenState extends ConsumerState<QuestionCorrectionScreen> {
  bool _ocrLoading = false;
  String? _ocrError;
  bool _showManualInput = false;
  late TextEditingController _manualController;

  @override
  void initState() {
    super.initState();
    _manualController = TextEditingController();
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);
    final imagePath = current?.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('校正与框选'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                if (imagePath != null && File(imagePath).existsSync())
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.file(File(imagePath), fit: BoxFit.contain),
                    ),
                  )
                else
                  const Center(child: Text('未选择图片', style: TextStyle(color: Colors.grey))),
                if (_ocrLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 12),
                          Text('正在识别文字...', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                if (_showManualInput)
                  Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text('手动输入题目', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _manualController,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: '请输入题目内容...',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  TextButton(
                                    onPressed: () => setState(() => _showManualInput = false),
                                    child: const Text('取消'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () {
                                      final text = _manualController.text.trim();
                                      if (text.isNotEmpty) {
                                        ref.read(currentQuestionProvider.notifier).state =
                                            current?.copyWith(correctedText: text);
                                        setState(() => _showManualInput = false);
                                        context.go('/capture/ocr-confirmation');
                                      }
                                    },
                                    child: const Text('确认'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_ocrError != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(CupertinoIcons.exclamationmark_triangle, size: 18, color: Color(0xFFEA580C)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_ocrError!, style: const TextStyle(fontSize: 13, color: Color(0xFF9A3412)))),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(currentQuestionProvider.notifier).state = current?.copyWith(
                      correctedText: '',
                    );
                    setState(() {
                      _showManualInput = true;
                      _ocrError = null;
                    });
                  },
                  child: const Text('手动输入'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _ocrLoading ? null : _runOcr,
                  child: _ocrLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('识别文字'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runOcr() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) return;

    setState(() {
      _ocrLoading = true;
      _ocrError = null;
    });

    try {
      final ocr = ref.read(ocrServiceProvider);
      final text = await ocr.recognizeImage(current.imagePath);

      if (mounted) setState(() => _ocrLoading = false);

      if (text.isEmpty) {
        if (mounted) setState(() => _ocrError = '未识别到文字，可以选择手动输入');
        return;
      }

      ref.read(currentQuestionProvider.notifier).state = current.copyWith(
        correctedText: text,
      );

      if (mounted) context.go('/capture/ocr-confirmation');
    } catch (e) {
      String errorMsg;
      if (e.toString().contains('PERMISSION_DENIED') || e.toString().contains('permission')) {
        errorMsg = '相机权限被拒绝，请在设置中开启相机权限';
      } else if (e.toString().contains('CANCEL')) {
        errorMsg = '操作已取消';
      } else {
        errorMsg = '识别失败，请重试或手动输入';
      }
      setState(() {
        _ocrLoading = false;
        _ocrError = errorMsg;
      });
    }
  }
}
