import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/ai_provider_preset.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderConfigScreen extends ConsumerStatefulWidget {
  const ProviderConfigScreen({super.key});

  @override
  ConsumerState<ProviderConfigScreen> createState() =>
      _ProviderConfigScreenState();
}

class _ProviderConfigScreenState extends ConsumerState<ProviderConfigScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _modelController;
  late final TextEditingController _apiKeyController;
  AiProviderPreset? _selectedPreset = AiProviderPreset.supported.first;
  List<String> _availableModels = const <String>[];
  bool _loaded = false;
  bool _fetchingModels = false;
  bool _savingAndTesting = false;
  bool _showApiKey = false;
  _ConnectionStatus? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _selectedPreset!.baseUrl);
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
    var config =
        await ref.read(settingsRepositoryProvider).getAiProviderConfig();
    if (config != null && config.effectiveBaseUrl != config.baseUrl) {
      config = config.copyWith(baseUrl: config.effectiveBaseUrl);
      await ref.read(settingsRepositoryProvider).saveAiProviderConfig(config);
    }
    if (!mounted) return;

    setState(() {
      _loaded = true;
      if (config == null) return;
      _selectedPreset = AiProviderPreset.fromConfig(config);
      _urlController.text = config.baseUrl;
      _modelController.text = config.model;
      _apiKeyController.text = config.apiKey;
      if (config.model.trim().isNotEmpty) {
        _availableModels = <String>[config.model.trim()];
      }
    });
  }

  AiProviderConfig _buildConfig() {
    final preset = _selectedPreset;
    return AiProviderConfig(
      id: preset?.id ?? 'custom',
      displayName: preset?.displayName ?? '自定义服务',
      baseUrl: _urlController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );
  }

  String get _providerDisplayName => _selectedPreset?.displayName ?? '自定义服务';

  Future<void> _chooseProvider() async {
    final selected = await showModalBottomSheet<AiProviderPreset?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: RadioGroup<String>(
            groupValue: _selectedPreset?.id ?? 'custom',
            onChanged: (id) {
              final matches = AiProviderPreset.supported
                  .where((candidate) => candidate.id == id)
                  .toList();
              Navigator.pop(context, matches.isEmpty ? null : matches.first);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '选择服务商',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...AiProviderPreset.supported.map(
                  (preset) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(value: preset.id),
                    title: Text(preset.displayName),
                    subtitle: Text(
                      preset.isRecommended ? '推荐服务商' : '备用服务商，配置流程一致',
                    ),
                    trailing:
                        preset.isRecommended ? const _RecommendedLabel() : null,
                    onTap: () => Navigator.pop(context, preset),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Radio<String>(value: 'custom'),
                  title: const Text('自定义服务'),
                  subtitle: const Text('填写兼容 OpenAI 图片输入的服务地址'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;

    final previousId = _selectedPreset?.id ?? 'custom';
    final nextId = selected?.id ?? 'custom';
    if (previousId == nextId) return;

    setState(() {
      _selectedPreset = selected;
      _urlController.text = selected?.baseUrl ?? '';
      _apiKeyController.clear();
      _modelController.clear();
      _availableModels = const <String>[];
      _connectionStatus = null;
    });
  }

  void _onApiKeyChanged(String _) {
    if (_availableModels.isEmpty && _modelController.text.isEmpty) return;
    setState(() {
      _availableModels = const <String>[];
      _modelController.clear();
      _connectionStatus = null;
    });
  }

  Future<void> _fetchModels() async {
    final draft = _buildConfig();
    if (draft.apiKey.isEmpty || draft.baseUrl.isEmpty) {
      setState(() {
        _connectionStatus = const _ConnectionStatus.error(
          '请先选择服务商并填写 API Key',
        );
      });
      return;
    }

    setState(() {
      _fetchingModels = true;
      _connectionStatus = null;
    });
    try {
      final models =
          await ref.read(aiAnalysisServiceProvider).fetchAvailableModels(draft);
      if (!mounted) return;
      setState(() {
        _availableModels = _sortModels(models);
        _fetchingModels = false;
      });
      await _openModelPicker();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = _ConnectionStatus.error('获取模型失败：$error');
      });
    } finally {
      if (mounted && _fetchingModels) {
        setState(() => _fetchingModels = false);
      }
    }
  }

  List<String> _sortModels(List<String> models) {
    final unique = models.toSet().toList();
    unique.sort();
    return unique;
  }

  Future<void> _openModelPicker() async {
    if (_availableModels.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ModelPickerSheet(
        models: _availableModels,
        selectedModel: _modelController.text.trim(),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == _ModelPickerSheet.manualModelEntry) {
      await _openManualModelEntry();
      return;
    }
    setState(() {
      _modelController.text = selected;
      _connectionStatus = null;
    });
  }

  Future<void> _openManualModelEntry() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ManualModelIdSheet(
        initialModel: _modelController.text.trim(),
      ),
    );
    if (!mounted || selected == null || selected.trim().isEmpty) return;
    setState(() {
      _modelController.text = selected.trim();
      _connectionStatus = null;
    });
  }

  Future<void> _saveAndTest() async {
    final draft = _buildConfig();
    if (draft.baseUrl.isEmpty || draft.apiKey.isEmpty || draft.model.isEmpty) {
      setState(() {
        _connectionStatus = const _ConnectionStatus.error(
          '请先完成服务商、API Key 和模型配置',
        );
      });
      return;
    }

    setState(() {
      _savingAndTesting = true;
      _connectionStatus = const _ConnectionStatus.loading('正在验证图片识题能力...');
    });
    try {
      await ref.read(settingsRepositoryProvider).saveAiProviderConfig(draft);
      await ref.read(aiAnalysisServiceProvider).testConnection(draft);
      if (!mounted) return;
      setState(() {
        _connectionStatus = const _ConnectionStatus.success('连接正常，配置已保存');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = _ConnectionStatus.error('配置已保存，但连接失败：$error');
      });
    } finally {
      if (mounted) setState(() => _savingAndTesting = false);
    }
  }

  Future<void> _openRegistration() async {
    final preset = _selectedPreset ?? AiProviderPreset.supported.first;
    final opened = await launchUrl(
      Uri.parse(preset.signUpUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || opened) return;
    await Clipboard.setData(ClipboardData(text: preset.signUpUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('注册链接已复制，请在浏览器打开')),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loadConfig();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedModel = _modelController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 服务商配置'),
        leading: IconButton(
          tooltip: '返回',
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('provider-config-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: <Widget>[
            _ConfigurationSurface(
              child: InkWell(
                key: const Key('provider-selector'),
                onTap: _chooseProvider,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      const _LeadingIcon(
                        icon: CupertinoIcons.cloud,
                        color: Color(0xFF2563EB),
                        background: Color(0xFFEFF6FF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text('服务商',
                                      style: theme.textTheme.titleSmall),
                                ),
                                if (_selectedPreset?.isRecommended ??
                                    false) ...<Widget>[
                                  const SizedBox(width: 8),
                                  const _RecommendedLabel(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _selectedPreset == null
                                  ? '自定义服务'
                                  : _providerDisplayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPreset == null
                  ? '自定义服务需要支持 OpenAI 兼容的图片输入。'
                  : '创建 API Key 时请选择 codex 分组。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_selectedPreset != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openRegistration,
                  icon: const Icon(CupertinoIcons.arrow_up_right_square,
                      size: 16),
                  label: Text('前往 $_providerDisplayName 获取 API Key'),
                ),
              ),
            const SizedBox(height: 16),
            Text('连接信息', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('provider-base-url-field'),
              controller: _urlController,
              readOnly: _selectedPreset != null,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Base URL',
                hintText: 'https://example.com/v1',
                helperText: _selectedPreset == null
                    ? '填写服务商提供的 OpenAI 兼容 API 地址'
                    : '已根据 $_providerDisplayName 自动填入',
                prefixIcon: const Icon(CupertinoIcons.link),
                suffixIcon: _selectedPreset == null
                    ? null
                    : const Icon(CupertinoIcons.lock),
              ),
              onChanged: _selectedPreset == null
                  ? (_) => setState(() => _connectionStatus = null)
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('provider-api-key-field'),
              controller: _apiKeyController,
              obscureText: !_showApiKey,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: _onApiKeyChanged,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: '粘贴刚刚复制的 API Key',
                prefixIcon: const Icon(CupertinoIcons.lock),
                suffixIcon: IconButton(
                  tooltip: _showApiKey ? '隐藏 API Key' : '显示 API Key',
                  icon: Icon(
                    _showApiKey ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  ),
                  onPressed: () => setState(() => _showApiKey = !_showApiKey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Icon(
                  CupertinoIcons.lock_shield,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Key 仅用于直连所选服务商，不会发送到错题本服务。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ConfigurationSurface(
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const _LeadingIcon(
                      icon: CupertinoIcons.sparkles,
                      color: Color(0xFF7C3AED),
                      background: Color(0xFFF5F3FF),
                    ),
                    title: const Text('模型'),
                    subtitle: Text(
                      selectedModel.isEmpty ? '粘贴 Key 后获取可用模型' : selectedModel,
                    ),
                    trailing: _availableModels.isEmpty
                        ? null
                        : IconButton(
                            tooltip: '选择模型',
                            icon: const Icon(CupertinoIcons.chevron_right),
                            onPressed: _openModelPicker,
                          ),
                    onTap: _availableModels.isEmpty ? null : _openModelPicker,
                  ),
                  Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colorScheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const Key('fetch-models-button'),
                            onPressed: _fetchingModels ? null : _fetchModels,
                            icon: _fetchingModels
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(CupertinoIcons.arrow_clockwise,
                                    size: 18),
                            label:
                                Text(_fetchingModels ? '正在获取模型...' : '获取可用模型'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          key: const Key('manual-model-id-button'),
                          onPressed: _openManualModelEntry,
                          icon: const Icon(CupertinoIcons.add, size: 17),
                          label: const Text('手动填写模型 ID'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_connectionStatus != null) ...<Widget>[
              const SizedBox(height: 12),
              _StatusMessage(status: _connectionStatus!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('save-and-test-button'),
                onPressed: _savingAndTesting ? null : _saveAndTest,
                icon: _savingAndTesting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(CupertinoIcons.checkmark_shield),
                label: Text(_savingAndTesting ? '正在测试...' : '保存并测试'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '测试会发送一张极小的测试图片，确认当前模型支持图片识题。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualModelIdSheet extends StatefulWidget {
  const _ManualModelIdSheet({required this.initialModel});

  final String initialModel;

  @override
  State<_ManualModelIdSheet> createState() => _ManualModelIdSheetState();
}

class _ManualModelIdSheetState extends State<_ManualModelIdSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialModel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final model = _controller.text.trim();
    if (model.isNotEmpty) Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('手动填写模型 ID', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '仅在服务商未提供模型列表，或你明确知道模型 ID 时使用。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('manual-model-id-field'),
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: '模型 ID',
                hintText: '例如：gpt-5.5',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('confirm-manual-model-id-button'),
                onPressed: _submit,
                child: const Text('使用此模型'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelPickerSheet extends StatefulWidget {
  static const manualModelEntry = '__manual_model_entry__';

  const _ModelPickerSheet({
    required this.models,
    required this.selectedModel,
  });

  final List<String> models;
  final String selectedModel;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final models = widget.models
        .where((model) => model.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final theme = Theme.of(context);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('选择模型', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                autofocus: false,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: '搜索模型',
                  prefixIcon: Icon(CupertinoIcons.search),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: models.isEmpty
                    ? const Center(child: Text('没有匹配的模型'))
                    : RadioGroup<String>(
                        groupValue: widget.selectedModel,
                        onChanged: (model) {
                          if (model != null) Navigator.pop(context, model);
                        },
                        child: ListView.separated(
                          itemCount: models.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final model = models[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Radio<String>(value: model),
                              title: Text(model),
                              onTap: () => Navigator.pop(context, model),
                            );
                          },
                        ),
                      ),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(CupertinoIcons.add),
                title: const Text('手动填写模型 ID'),
                onTap: () =>
                    Navigator.pop(context, _ModelPickerSheet.manualModelEntry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigurationSurface extends StatelessWidget {
  const _ConfigurationSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.16) : background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _RecommendedLabel extends StatelessWidget {
  const _RecommendedLabel();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '推荐',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }
}

enum _ConnectionState { loading, success, error }

class _ConnectionStatus {
  const _ConnectionStatus.loading(this.message)
      : state = _ConnectionState.loading;
  const _ConnectionStatus.success(this.message)
      : state = _ConnectionState.success;
  const _ConnectionStatus.error(this.message) : state = _ConnectionState.error;
  final _ConnectionState state;
  final String message;
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.status});
  final _ConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (color, lightBackground, icon) = switch (status.state) {
      _ConnectionState.success => (
          const Color(0xFF16A34A),
          const Color(0xFFF0FDF4),
          CupertinoIcons.checkmark_circle_fill,
        ),
      _ConnectionState.error => (
          const Color(0xFFEA580C),
          const Color(0xFFFFF7ED),
          CupertinoIcons.exclamationmark_triangle_fill,
        ),
      _ConnectionState.loading => (
          colorScheme.primary,
          colorScheme.primaryContainer,
          CupertinoIcons.arrow_clockwise,
        ),
    };
    final background = isDark ? color.withValues(alpha: 0.14) : lightBackground;
    final borderColor = isDark ? color.withValues(alpha: 0.35) : background;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(status.message, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
