import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/common/widgets/state_views.dart';
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
      appBar: AppBar(
        title: const Text('AI 解析'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/capture/ocr-confirmation'),
        ),
      ),
      body: _errorMessage != null
          ? ErrorView(
              message: _errorMessage!,
              icon: CupertinoIcons.cloud,
              onRetry: _retry,
            )
          : _LoadingView(step: _step, steps: _steps),
    );
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _step = 0;
    });
    _runAnalysis();
    _animateSteps();
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView({required this.step, required this.steps});

  final int step;
  final List<String> steps;

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> with SingleTickerProviderStateMixin {
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(44),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Transform.rotate(
                  angle: _controller.value * 2 * 3.14159,
                  child: const Icon(CupertinoIcons.smiley, size: 44, color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 28),
            Text(
              widget.steps[widget.step],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
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
