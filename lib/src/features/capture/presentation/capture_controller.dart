import 'dart:io';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class CaptureController {
  CaptureController({required this.copyIntoAppDir});

  final Future<String> Function(File file) copyIntoAppDir;

  factory CaptureController.fake() {
    return CaptureController(
      copyIntoAppDir: (File file) async =>
          '/app/images/${file.uri.pathSegments.last}',
    );
  }

  Future<QuestionRecord> createDraftFromFile(File file) async {
    final String imagePath = await copyIntoAppDir(file);
    return QuestionRecord.draft(
      id: 'draft-${file.uri.pathSegments.last}',
      imagePath: imagePath,
      subject: Subject.unknown,
      recognizedText: '',
    );
  }
}
