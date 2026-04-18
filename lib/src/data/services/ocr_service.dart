import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  Future<String> recognizeImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);

    try {
      final recognized = await recognizer.processImage(inputImage);
      final text = recognized.text.trim();
      return text;
    } finally {
      recognizer.close();
    }
  }
}
