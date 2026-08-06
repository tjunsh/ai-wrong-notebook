import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/services/question_analysis_coordinator.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() =>
      _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen> {
  String? _errorMessage;
  String? _debugInfo;
  int _step = 0;
  String? _progressText;
  bool _canContinueInBackground = false;
  Timer? _stepTimer;

  final _steps = const ['正在识别题目...', '正在理解题意...', '正在生成解析...', '即将完成...'];

  @override
  void initState() {
    super.initState();
    _runAnalysis();
    _animateSteps();
  }

  void _animateSteps() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
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

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) {
      if (mounted) context.go('/');
      return;
    }

    // 检查配置并显示调试信息
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final config = await settingsRepo.getAiProviderConfig();

    String debugInfo = '配置状态:\n';
    debugInfo += '- 配置对象: ${config != null ? "存在" : "为空"}\n';
    if (config != null) {
      debugInfo +=
          '- baseUrl: ${config.baseUrl.isNotEmpty ? config.baseUrl : "(空)"}\n';
      debugInfo +=
          '- model: ${config.model.isNotEmpty ? config.model : "(空)"}\n';
      debugInfo +=
          '- apiKey: ${config.apiKey.isNotEmpty ? "[已设置(${config.apiKey.length}字符)]" : "(空)"}\n';
    } else {
      debugInfo += '\n请到设置中配置 AI 服务';
    }

    if (!mounted) return;
    setState(() => _debugInfo = debugInfo);

    try {
      final coordinator = ref.read(questionAnalysisCoordinatorProvider);
      final QuestionRecord updated;
      if (coordinator is BackgroundQuestionAnalysisCoordinator) {
        final handle = await coordinator.enqueue(current);
        if (mounted) {
          setState(() => _canContinueInBackground = true);
        }
        updated = await coordinator.waitForResult(handle);
      } else {
        updated = await coordinator.analyze(
          current,
          onProgress: (completed, total, {int failed = 0}) {
            if (!mounted) return;
            setState(() {
              _stepTimer?.cancel();
              if (completed == 0) {
                _progressText = '正在依次分析 $total 道题...';
                return;
              }
              final suffix = failed > 0 ? '（$failed题失败）' : '';
              _progressText = '已完成 $completed/$total题分析$suffix';
            });
          },
        );
      }
      if (!mounted) return;
      final activeQuestion = ref.read(currentQuestionProvider);
      if (activeQuestion?.id != current.id) return;
      ref.read(currentQuestionProvider.notifier).state = updated;

      _stepTimer?.cancel();
      context.go('/analysis/result');
    } on AiAnalysisException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _debugInfo = debugInfo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 解析'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/capture/correction'),
        ),
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : _LoadingView(
              step: _step,
              steps: _steps,
              progressText: _progressText,
              onContinueInBackground:
                  _canContinueInBackground ? () => context.go('/') : null,
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFEA580C).withValues(alpha: 0.16)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Color(0xFFEA580C),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9A3412)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('调试信息:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(_debugInfo ?? '',
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _progressText = null;
                  _step = 0;
                  _canContinueInBackground = false;
                });
                _runAnalysis();
                _animateSteps();
              },
              style: FilledButton.styleFrom(minimumSize: const Size(120, 40)),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView({
    required this.step,
    required this.steps,
    this.progressText,
    this.onContinueInBackground,
  });

  final int step;
  final List<String> steps;
  final String? progressText;
  final VoidCallback? onContinueInBackground;

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(44),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Transform.rotate(
                  angle: _controller.value * 2 * 3.14159,
                  child: const Icon(CupertinoIcons.smiley,
                      size: 44, color: Color(0xFF6366F1)),
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
              widget.progressText ?? widget.steps[widget.step],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (widget.onContinueInBackground != null) ...<Widget>[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: widget.onContinueInBackground,
                icon: const Icon(CupertinoIcons.camera, size: 18),
                label: const Text('继续录题'),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              widget.progressText != null
                  ? '多题依次分析中，请稍候...'
                  : 'AI 正在生成学习分析，请稍候...',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
