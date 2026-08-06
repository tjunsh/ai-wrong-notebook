import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class AiProviderPreset {
  const AiProviderPreset({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.signUpUrl,
    required this.isRecommended,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String signUpUrl;
  final bool isRecommended;

  static const List<AiProviderPreset> supported = <AiProviderPreset>[
    AiProviderPreset(
      id: 'vbcode',
      displayName: 'VBcode.io',
      baseUrl: 'https://www.vbcode.io/v1',
      signUpUrl: 'https://vbcode.io/sign-up?aff=lEmu',
      isRecommended: true,
    ),
    AiProviderPreset(
      id: 'dohoya',
      displayName: 'dohoya.com',
      baseUrl: 'https://www.dohoya.com/v1',
      signUpUrl: 'https://www.dohoya.com/sign-up?aff=hiUV',
      isRecommended: false,
    ),
  ];

  static AiProviderPreset? fromConfig(AiProviderConfig config) {
    final normalizedBaseUrl = _normalizeUrl(config.baseUrl);
    for (final preset in supported) {
      if (config.id == preset.id ||
          normalizedBaseUrl == _normalizeUrl(preset.baseUrl) ||
          (preset.id == 'vbcode' &&
              normalizedBaseUrl == 'https://vbcode.io/v1')) {
        return preset;
      }
    }
    return null;
  }

  static String _normalizeUrl(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '').toLowerCase();
  }
}
