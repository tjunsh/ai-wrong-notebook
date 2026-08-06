import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

void main() {
  late HttpServer server;
  late AiAnalysisService service;
  late AiProviderConfig config;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    service =
        AiAnalysisService(settingsRepository: InMemorySettingsRepository());
    config = AiProviderConfig(
      id: 'local',
      displayName: 'Local',
      baseUrl: 'http://${server.address.address}:${server.port}/v1',
      model: 'gpt-5.5',
      apiKey: 'test-key',
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('fetches the model ids available to the configured API key', () async {
    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/v1/models');
      expect(request.headers.value('authorization'), 'Bearer test-key');
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<String, dynamic>{
        'data': <Map<String, String>>[
          <String, String>{'id': 'gpt-5.4-mini'},
          <String, String>{'id': 'gpt-5.5'},
          <String, String>{'id': 'gpt-5.6-terra'},
        ],
      }));
      await request.response.close();
    });

    expect(
      await service.fetchAvailableModels(config),
      <String>['gpt-5.4-mini', 'gpt-5.5', 'gpt-5.6-terra'],
    );
  });

  test('connection test sends a lightweight image request', () async {
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/chat/completions');
      final payload = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      final messages = payload['messages'] as List<dynamic>;
      final content =
          (messages.single as Map<String, dynamic>)['content'] as List<dynamic>;
      final imagePart = content
          .cast<Map<dynamic, dynamic>>()
          .singleWhere((part) => part['type'] == 'image_url');

      final imageUrl =
          (imagePart['image_url'] as Map<dynamic, dynamic>)['url'] as String;
      expect(imageUrl, startsWith('data:image/png;base64,'));
      _expectValidPng(base64Decode(imageUrl.split(',').last));
      expect(payload['max_tokens'], 8);

      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(<String, dynamic>{
        'choices': <Map<String, dynamic>>[
          <String, dynamic>{
            'message': <String, String>{'content': 'OK'},
          },
        ],
      }));
      await request.response.close();
    });

    await service.testConnection(config);
  });
}

void _expectValidPng(List<int> bytes) {
  const pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  expect(bytes.sublist(0, pngSignature.length), pngSignature);

  var offset = pngSignature.length;
  var sawImageData = false;
  while (offset < bytes.length) {
    final length = _readUint32(bytes, offset);
    final type = ascii.decode(bytes.sublist(offset + 4, offset + 8));
    final dataStart = offset + 8;
    final dataEnd = dataStart + length;
    final crcEnd = dataEnd + 4;
    expect(crcEnd, lessThanOrEqualTo(bytes.length));
    final typeAndData = bytes.sublist(offset + 4, dataEnd);
    final expectedCrc = _readUint32(bytes, dataEnd);
    expect(_crc32(typeAndData), expectedCrc);

    if (type == 'IDAT') {
      // A valid PNG must contain image data whose zlib stream can be decoded.
      ZLibDecoder().convert(bytes.sublist(dataStart, dataEnd));
      sawImageData = true;
    }
    offset = crcEnd;
    if (type == 'IEND') break;
  }
  expect(sawImageData, isTrue);
}

int _readUint32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
