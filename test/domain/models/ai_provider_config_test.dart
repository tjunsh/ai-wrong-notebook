import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

void main() {
  test('uses the canonical VBcode API endpoint for legacy configurations', () {
    const legacy = AiProviderConfig(
      id: 'vbcode',
      displayName: 'VBcode.io',
      baseUrl: 'https://vbcode.io/v1',
      model: 'gpt-5.5',
      apiKey: 'test-key',
    );

    expect(legacy.effectiveBaseUrl, 'https://www.vbcode.io/v1');
  });

  test('keeps custom provider endpoints unchanged apart from trailing slashes',
      () {
    const config = AiProviderConfig(
      id: 'custom',
      displayName: 'Custom',
      baseUrl: 'https://example.com/v1/',
      model: 'vision-model',
      apiKey: 'test-key',
    );

    expect(config.effectiveBaseUrl, 'https://example.com/v1');
  });
}
