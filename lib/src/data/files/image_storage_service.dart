import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  ImageStorageService();

  Future<String> saveImage(File source) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagesDir = '${appDir.path}/wrong_question_images';
    await Directory(imagesDir).create(recursive: true);
    final String id = const Uuid().v4();
    final String newPath = '$imagesDir/$id.jpg';
    await source.copy(newPath);
    return newPath;
  }

  Future<void> deleteImage(String imagePath) async {
    final File file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
