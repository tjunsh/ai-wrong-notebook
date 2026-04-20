import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class ProviderConfigScreen extends ConsumerStatefulWidget {
  const ProviderConfigScreen({super.key});

  @override
  ConsumerState<ProviderConfigScreen> createState() => _ProviderConfigScreenState();
}

class _ProviderConfigScreenState extends ConsumerState<ProviderConfigScreen> {
  late TextEditingController _urlController;
  late TextEditingController _modelController;
  late TextEditingController _apiKeyController;
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _modelController = TextEditingController();
    _apiKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    if (_loaded) return;
    final config = await ref.read(settingsRepositoryProvider).getAiProviderConfig();
    if (config != null && mounted) {
      _urlController.text = config.baseUrl;
      _modelController.text = config.model;
      _apiKeyController.text = config.apiKey;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    _loadConfig();
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 服务配置'),
        leading: IconButton(icon: const Icon(CupertinoIcons.chevron_left), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'API 地址',
                hintText: 'https://api.openai.com/v1',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '模型',
                hintText: 'gpt-4o',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apiKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final config = AiProviderConfig(
      id: 'default',
      displayName: '默认',
      baseUrl: _urlController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
    await ref.read(settingsRepositoryProvider).saveAiProviderConfig(config);
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('配置已保存')));
    }
  }
}
