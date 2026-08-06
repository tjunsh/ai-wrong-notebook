class AiProviderConfig {
  const AiProviderConfig({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String model;
  final String apiKey;

  /// Keeps previously saved VBcode configurations on the canonical API host.
  /// The non-www host worked for some calls, but has not been consistently
  /// routed to the same model gateway.
  String get effectiveBaseUrl {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.toLowerCase() == 'https://vbcode.io/v1') {
      return 'https://www.vbcode.io/v1';
    }
    return normalized;
  }

  AiProviderConfig copyWith({
    String? id,
    String? displayName,
    String? baseUrl,
    String? model,
    String? apiKey,
  }) {
    return AiProviderConfig(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }
}
