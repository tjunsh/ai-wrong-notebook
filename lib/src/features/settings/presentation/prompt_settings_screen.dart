import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class PromptSettingsScreen extends ConsumerStatefulWidget {
  const PromptSettingsScreen({super.key});

  @override
  ConsumerState<PromptSettingsScreen> createState() => _PromptSettingsScreenState();
}

class _PromptSettingsScreenState extends ConsumerState<PromptSettingsScreen> {
  late TextEditingController _systemPromptController;
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _systemPromptController = TextEditingController();
  }

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final prompt = await ref.read(settingsRepositoryProvider).getString('system_prompt');
    if (mounted) {
      _systemPromptController.text = prompt ?? '';
      setState(() => _loaded = true);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await ref.read(settingsRepositoryProvider).setString('system_prompt', _systemPromptController.text);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提示词已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    _load();
    return Scaffold(
      appBar: AppBar(title: const Text('提示词设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            Text('自定义系统提示词', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '设置后 AI 将使用此提示词进行分析，为空则使用默认提示词',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _systemPromptController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '请根据学生的错题内容进行分析，并以 JSON 格式返回...',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存提示词'),
            ),
          ],
        ),
      ),
    );
  }
}
