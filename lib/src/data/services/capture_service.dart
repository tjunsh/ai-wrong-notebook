import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:uuid/uuid.dart';

class CaptureResult {
  final QuestionRecord? record;
  final String? errorMessage;
  final bool isCancelled;

  CaptureResult.success(this.record)
      : errorMessage = null,
        isCancelled = false;

  CaptureResult.cancel()
      : record = null,
        errorMessage = null,
        isCancelled = true;

  CaptureResult.error(this.errorMessage)
      : record = null,
        isCancelled = false;
}

class CaptureService {
  CaptureService({ImageStorageService? storage})
      : _storage = storage ?? ImageStorageService();

  final ImageStorageService _storage;
  final ImagePicker _picker = ImagePicker();

  Future<CaptureResult> pickFromCamera() async {
    try {
      debugPrint('[CaptureService] Opening camera...');
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      debugPrint(
          '[CaptureService] Camera result: ${file?.path ?? "cancelled"}');

      if (file == null) {
        return CaptureResult.cancel();
      }

      final record = await _saveToDraft(file);
      debugPrint('[CaptureService] Image saved: ${record.imagePath}');
      return CaptureResult.success(record);
    } catch (e) {
      debugPrint('[CaptureService] Camera error: $e');
      return CaptureResult.error(e.toString());
    }
  }

  Future<CaptureResult> pickFromGallery() async {
    try {
      debugPrint('[CaptureService] Opening gallery...');
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      debugPrint(
          '[CaptureService] Gallery result: ${file?.path ?? "cancelled"}');

      if (file == null) {
        return CaptureResult.cancel();
      }

      final record = await _saveToDraft(file);
      debugPrint('[CaptureService] Image saved: ${record.imagePath}');
      return CaptureResult.success(record);
    } catch (e) {
      debugPrint('[CaptureService] Gallery error: $e');
      return CaptureResult.error(e.toString());
    }
  }

  Future<QuestionRecord> _saveToDraft(XFile file) async {
    final savedPath = await _storage.saveImage(File(file.path));
    return QuestionRecord.draft(
      id: const Uuid().v4(),
      imagePath: savedPath,
      subject: Subject.unknown,
      recognizedText: '',
    );
  }
}
