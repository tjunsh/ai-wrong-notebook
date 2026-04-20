import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardPage(
      icon: CupertinoIcons.camera,
      title: '拍照录题',
      description: '快速拍照，智能识别',
      color: Color(0xFF6366F1),
      bg: Color(0xFFEEF2FF),
    ),
    _OnboardPage(
      icon: CupertinoIcons.smiley,
      title: 'AI 解析',
      description: '深入分析，精准诊断',
      color: Color(0xFFD97706),
      bg: Color(0xFFFFFBEB),
    ),
    _OnboardPage(
      icon: CupertinoIcons.pencil,
      title: '举一反三',
      description: '针对性练习，巩固知识点',
      color: Color(0xFF16A34A),
      bg: Color(0xFFF0FDF4),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setString('onboarding_done', 'true');
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text('跳过', style: TextStyle(color: Colors.grey.shade500)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentPage == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? const Color(0xFF6366F1) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: FilledButton(
                onPressed: _currentPage < _pages.length - 1
                    ? () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                    : _finish,
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                child: Text(_currentPage < _pages.length - 1 ? '下一步' : '开始使用'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bg,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(icon, size: 56, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            '智能错题本',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '拍照录题，AI 分析，举一反三',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 48),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
