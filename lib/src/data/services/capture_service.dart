import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:uuid/uuid.dart';

class CaptureService {
  CaptureService({ImageStorageService? storage})
      : _storage = storage ?? ImageStorageService();

  final ImageStorageService _storage;
  final ImagePicker _picker = ImagePicker();

  Future<QuestionRecord?> pickFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) return null;
    return _saveToDraft(file);
  }

  Future<QuestionRecord?> pickFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return null;
    return _saveToDraft(file);
  }

  Future<QuestionRecord> _saveToDraft(XFile file) async {
    final savedPath = await _storage.saveImage(File(file.path));
    return QuestionRecord.draft(
      id: const Uuid().v4(),
      imagePath: savedPath,
      subject: Subject.math,
      recognizedText: '',
    );
  }
}
