import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen> {
  String? _errorMessage;
  int _step = 0;

  final _steps = const ['正在分析题目...', '正在生成解析...', '正在生成练习题...', '即将完成...'];

  @override
  void initState() {
    super.initState();
    _runAnalysis();
    _animateSteps();
  }

  void _animateSteps() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_step < _steps.length - 1) {
        setState(() => _step++);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _runAnalysis() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) {
      if (mounted) context.go('/');
      return;
    }

    try {
      final service = ref.read(aiAnalysisServiceProvider);
      final analysis = await service.analyzeQuestion(
        correctedText: current.correctedText,
        subjectName: current.subject.name,
      );

      final updated = current.copyWith(
        contentStatus: ContentStatus.ready,
        analysisResult: analysis,
      );
      ref.read(currentQuestionProvider.notifier).state = updated;

      if (mounted) context.go('/analysis/result');
    } on AiAnalysisException catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _errorMessage != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _step = 0;
                        });
                        _runAnalysis();
                        _animateSteps();
                      },
                      child: const Text('重试'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('返回首页'),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const _RotatingBrainIcon(),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(_steps[_step], style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    'AI 正在分析中，请稍候...',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RotatingBrainIcon extends StatefulWidget {
  const _RotatingBrainIcon();

  @override
  State<_RotatingBrainIcon> createState() => _RotatingBrainIconState();
}

class _RotatingBrainIconState extends State<_RotatingBrainIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.rotate(
        angle: _controller.value * 2 * 3.14159,
        child: const Icon(Icons.psychology_outlined, size: 64, color: Colors.indigo),
      ),
    );
  }
}
