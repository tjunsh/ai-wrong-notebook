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
  bool _testing = false;
  String? _testResult;

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
                hintText: 'https://api.openai.com/v1 或 https://openrouter.ai/api/v1',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: '模型',
                hintText: 'gpt-4o, gemini-2.0-flash-thinking-exp-121 等',
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
            const SizedBox(height: 16),
            if (_testResult != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _testResult!.contains('成功') ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _testResult!.contains('成功') ? const Color(0xFFBBF7D0) : const Color(0xFFFED7AA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      _testResult!.contains('成功') ? CupertinoIcons.checkmark_circle : CupertinoIcons.exclamationmark_triangle,
                      color: _testResult!.contains('成功') ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _testResult!.contains('成功') ? const Color(0xFF166534) : const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(CupertinoIcons.wifi, size: 18),
                    label: Text(_testing ? '测试中...' : '测试连接'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _testResult = null;
    });
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

  Future<void> _testConnection() async {
    final config = AiProviderConfig(
      id: 'default',
      displayName: '默认',
      baseUrl: _urlController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    if (config.baseUrl.isEmpty || config.model.isEmpty || config.apiKey.isEmpty) {
      setState(() => _testResult = '请填写完整的配置信息');
      return;
    }

    setState(() {
      _testing = true;
      _testResult = '正在保存配置...\nURL: ${config.baseUrl}\n模型: ${config.model}';
    });

    try {
      // 先保存到本地
      debugPrint('[ProviderConfig] Saving config...');
      await ref.read(settingsRepositoryProvider).saveAiProviderConfig(config);
      debugPrint('[ProviderConfig] Config saved successfully');

      // 立即读取验证
      final savedConfig = await ref.read(settingsRepositoryProvider).getAiProviderConfig();
      debugPrint('[ProviderConfig] Saved config: ${savedConfig?.baseUrl}, ${savedConfig?.model}');

      if (savedConfig == null) {
        setState(() => _testResult = '✗ 保存失败\n\n无法读取保存的配置，请重试');
        return;
      }

      setState(() => _testResult = '配置已保存，正在连接 AI...\nURL: ${savedConfig.baseUrl}\n模型: ${savedConfig.model}');

      // 调用 AI 服务测试
      final service = ref.read(aiAnalysisServiceProvider);
      await service.testConnection(savedConfig);

      if (mounted) {
        setState(() => _testResult = '✓ 成功！\n\nAPI 连接正常，配置已保存！\n\n现在可以拍照测试了。');
      }
    } catch (e) {
      debugPrint('[ProviderConfig] Test failed: $e');
      if (mounted) {
        setState(() => _testResult = '✗ 连接失败\n\n${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _testing = false);
      }
    }
  }
}
