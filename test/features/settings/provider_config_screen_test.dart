import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/provider_config_screen.dart';

class _RecordingSettingsRepository implements SettingsRepository {
  _RecordingSettingsRepository([this.config]);

  AiProviderConfig? config;
  final Map<String, String> _values = <String, String>{};

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => config;

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig next) async {
    config = next;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}

class _ProviderConfigTestService extends AiAnalysisService {
  _ProviderConfigTestService()
      : super(settingsRepository: InMemorySettingsRepository());

  final List<AiProviderConfig> testedConfigurations = <AiProviderConfig>[];
  Object? connectionFailure;

  @override
  Future<List<String>> fetchAvailableModels(AiProviderConfig config) async {
    return <String>['gpt-5.4-mini', 'gpt-5.5', 'gpt-5.6-terra'];
  }

  @override
  Future<void> testConnection(AiProviderConfig config) async {
    testedConfigurations.add(config);
    if (connectionFailure != null) throw connectionFailure!;
  }
}

void main() {
  Widget buildSubject({
    required _RecordingSettingsRepository settings,
    required _ProviderConfigTestService service,
  }) {
    return ProviderScope(
      overrides: <Override>[
        settingsRepositoryProvider.overrideWithValue(settings),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(home: ProviderConfigScreen()),
    );
  }

  testWidgets('preset selection clears an API key from another provider',
      (tester) async {
    final settings = _RecordingSettingsRepository(const AiProviderConfig(
      id: 'vbcode',
      displayName: 'VBcode.io',
      baseUrl: 'https://www.vbcode.io/v1',
      model: 'gpt-5.5',
      apiKey: 'vbcode-key',
    ));
    final service = _ProviderConfigTestService();

    await tester.pumpWidget(buildSubject(settings: settings, service: service));
    await tester.pumpAndSettle();

    expect(find.text('VBcode.io'), findsOneWidget);
    await tester.tap(find.byKey(const Key('provider-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dohoya.com'));
    await tester.pumpAndSettle();

    expect(find.text('dohoya.com'), findsOneWidget);
    final apiKeyField = tester.widget<TextFormField>(
      find.byKey(const Key('provider-api-key-field')),
    );
    expect(apiKeyField.controller!.text, isEmpty);
  });

  testWidgets('preset locks Base URL while custom service makes it editable',
      (tester) async {
    final settings = _RecordingSettingsRepository();
    final service = _ProviderConfigTestService();

    await tester.pumpWidget(buildSubject(settings: settings, service: service));
    await tester.pumpAndSettle();

    final baseUrlFinder = find.byKey(const Key('provider-base-url-field'));
    var baseUrlField = tester.widget<TextField>(
      find.descendant(of: baseUrlFinder, matching: find.byType(TextField)),
    );
    expect(baseUrlField.readOnly, isTrue);
    expect(baseUrlField.controller!.text, 'https://www.vbcode.io/v1');
    expect(find.text('高级设置'), findsNothing);

    await tester.tap(find.byKey(const Key('provider-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自定义服务'));
    await tester.pumpAndSettle();

    baseUrlField = tester.widget<TextField>(
      find.descendant(of: baseUrlFinder, matching: find.byType(TextField)),
    );
    expect(baseUrlField.readOnly, isFalse);
    await tester.enterText(
      find.byKey(const Key('provider-base-url-field')),
      'https://example.com/v1',
    );
    expect(baseUrlField.controller!.text, 'https://example.com/v1');
  });

  testWidgets('manual model ID returns to the main configuration flow',
      (tester) async {
    final settings = _RecordingSettingsRepository();
    final service = _ProviderConfigTestService();

    await tester.pumpWidget(buildSubject(settings: settings, service: service));
    await tester.pumpAndSettle();
    final manualModelButton = find.byKey(const Key('manual-model-id-button'));
    await tester.drag(
      find.byKey(const Key('provider-config-scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(manualModelButton);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('manual-model-id-field')),
      'vision-model-custom',
    );
    await tester.tap(find.byKey(const Key('confirm-manual-model-id-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('vision-model-custom'), findsOneWidget);
  });

  testWidgets('migrates the legacy VBcode endpoint to the canonical host',
      (tester) async {
    final settings = _RecordingSettingsRepository(const AiProviderConfig(
      id: 'vbcode',
      displayName: 'VBcode.io',
      baseUrl: 'https://vbcode.io/v1',
      model: 'gpt-5.5',
      apiKey: 'vbcode-key',
    ));
    final service = _ProviderConfigTestService();

    await tester.pumpWidget(buildSubject(settings: settings, service: service));
    await tester.pumpAndSettle();

    expect(settings.config?.baseUrl, 'https://www.vbcode.io/v1');
    final baseUrlField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('provider-base-url-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(baseUrlField.controller!.text, 'https://www.vbcode.io/v1');
  });

  testWidgets('loads models, selects a model, and saves after test',
      (tester) async {
    final settings = _RecordingSettingsRepository();
    final service = _ProviderConfigTestService();

    await tester.pumpWidget(buildSubject(settings: settings, service: service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('provider-api-key-field')),
      'vbcode-key',
    );
    await tester.tap(find.byKey(const Key('fetch-models-button')));
    await tester.pumpAndSettle();

    expect(find.text('选择模型'), findsOneWidget);
    expect(find.text('推荐用于图片识题'), findsNothing);
    expect(find.text('图片识题能力未验证'), findsNothing);
    await tester.tap(find.text('gpt-5.5'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('provider-config-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final saveButton = find.byKey(const Key('save-and-test-button'));
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(settings.config?.id, 'vbcode');
    expect(settings.config?.model, 'gpt-5.5');
    expect(settings.config?.apiKey, 'vbcode-key');
    expect(service.testedConfigurations, hasLength(1));
    expect(find.text('连接正常，配置已保存', skipOffstage: false), findsOneWidget);
  });

  testWidgets('keeps a configuration when connection verification fails',
      (tester) async {
    final settings = _RecordingSettingsRepository();
    final service = _ProviderConfigTestService()
      ..connectionFailure = Exception('HTTP 502');

    await tester.pumpWidget(buildSubject(settings: settings, service: service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('provider-api-key-field')),
      'vbcode-key',
    );
    await tester.drag(
      find.byKey(const Key('provider-config-scroll')),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manual-model-id-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('manual-model-id-field')),
      'gpt-5.5',
    );
    await tester.tap(find.byKey(const Key('confirm-manual-model-id-button')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('provider-config-scroll')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-and-test-button')));
    await tester.pumpAndSettle();

    expect(settings.config?.baseUrl, 'https://www.vbcode.io/v1');
    expect(settings.config?.apiKey, 'vbcode-key');
    expect(settings.config?.model, 'gpt-5.5');
    expect(service.testedConfigurations, hasLength(1));
    expect(
      find.textContaining('配置已保存，但连接失败', skipOffstage: false),
      findsOneWidget,
    );
  });
}
