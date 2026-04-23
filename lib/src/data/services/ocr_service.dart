import 'package:flutter/foundation.dart';

/// OCR service - disabled since ML Kit causes crashes
/// Now using AI vision to recognize text from images directly
class OcrService {
  Future<String> recognizeImage(String imagePath) async {
    debugPrint('[OcrService] OCR disabled - AI will recognize text from image directly');
    return '';
  }

  void dispose() {}
}
