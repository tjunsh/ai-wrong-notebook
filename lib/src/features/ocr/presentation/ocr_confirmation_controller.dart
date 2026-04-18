class OcrConfirmationController {
  OcrConfirmationController({
    required this.recognizedText,
    required this.subjectName,
  }) : correctedText = recognizedText;

  final String recognizedText;
  String correctedText;
  String subjectName;

  void updateCorrectedText(String value) {
    correctedText = value;
  }

  void updateSubjectName(String value) {
    subjectName = value;
  }
}
