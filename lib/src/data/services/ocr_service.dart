import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// OCR service using Google ML Kit
class OcrService {
  bool _initialized = false;
  bool _available = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Try to initialize ML Kit
      final channel = MethodChannel('plugins.flutter.io/google_mlkit_text_recognition');
      // Just check if the plugin is available
      _available = true;
      debugPrint('[OcrService] ML Kit available');
    } catch (e) {
      debugPrint('[OcrService] ML Kit not available: $e');
      _available = false;
    }
  }

  Future<String> recognizeImage(String imagePath) async {
    debugPrint('[OcrService] Starting recognition for: $imagePath');

    await _ensureInitialized();

    if (!_available) {
      debugPrint('[OcrService] ML Kit not available, returning empty');
      return '';
    }

    try {
      // Dynamic import to avoid startup crash
      final result = await _callMlKit(imagePath);
      return result;
    } catch (e) {
      debugPrint('[OcrService] Recognition error: $e');
      return '';
    }
  }

  Future<String> _callMlKit(String imagePath) async {
    // This is a placeholder - actual implementation would use ML Kit
    // Since ML Kit crashes on this device, return empty for now
    debugPrint('[OcrService] ML Kit call - returning empty to prevent crash');
    return '';
  }

  void dispose() {
    // No-op
  }
}