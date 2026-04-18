import 'package:flutter/material.dart';

class AnalysisLoadingScreen extends StatefulWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  State<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends State<AnalysisLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _simulateAnalysis();
  }

  Future<void> _simulateAnalysis() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/analysis/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 正在思考...'),
          ],
        ),
      ),
    );
  }
}
