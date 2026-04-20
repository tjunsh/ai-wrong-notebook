import 'analysis_result.dart';
import 'content_status.dart';
import 'mastery_level.dart';
import 'subject.dart';

class QuestionRecord {
  const QuestionRecord({
    required this.id,
    required this.imagePath,
    required this.subject,
    required this.recognizedText,
    required this.correctedText,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.lastReviewedAt,
    required this.reviewCount,
    required this.isFavorite,
    required this.contentStatus,
    required this.masteryLevel,
    required this.analysisResult,
  });

  factory QuestionRecord.draft({
    required String id,
    required String imagePath,
    required Subject subject,
    required String recognizedText,
  }) {
    final now = DateTime.now();
    return QuestionRecord(
      id: id,
      imagePath: imagePath,
      subject: subject,
      recognizedText: recognizedText,
      correctedText: recognizedText,
      tags: const <String>[],
      createdAt: now,
      updatedAt: now,
      lastReviewedAt: null,
      reviewCount: 0,
      isFavorite: false,
      contentStatus: ContentStatus.processing,
      masteryLevel: MasteryLevel.newQuestion,
      analysisResult: null,
    );
  }

  factory QuestionRecord.fromJson(Map<String, dynamic> json) {
    return QuestionRecord(
      id: json['id'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      subject: Subject.values.firstWhere(
        (s) => s.name == json['subject'],
        orElse: () => Subject.math,
      ),
      recognizedText: json['recognizedText'] as String? ?? '',
      correctedText: json['correctedText'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.tryParse(json['lastReviewedAt'] as String)
          : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      contentStatus: ContentStatus.values.firstWhere(
        (s) => s.name == json['contentStatus'],
        orElse: () => ContentStatus.processing,
      ),
      masteryLevel: MasteryLevel.values.firstWhere(
        (m) => m.name == json['masteryLevel'],
        orElse: () => MasteryLevel.newQuestion,
      ),
      analysisResult: json['analysisResult'] != null
          ? AnalysisResult.fromJson(json['analysisResult'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'subject': subject.name,
      'recognizedText': recognizedText,
      'correctedText': correctedText,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'reviewCount': reviewCount,
      'isFavorite': isFavorite,
      'contentStatus': contentStatus.name,
      'masteryLevel': masteryLevel.name,
      'analysisResult': analysisResult?.toJson(),
    };
  }

  final String id;
  final String imagePath;
  final Subject subject;
  final String recognizedText;
  final String correctedText;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final bool isFavorite;
  final ContentStatus contentStatus;
  final MasteryLevel masteryLevel;
  final AnalysisResult? analysisResult;

  QuestionRecord copyWith({
    String? correctedText,
    Subject? subject,
    ContentStatus? contentStatus,
    AnalysisResult? analysisResult,
    MasteryLevel? masteryLevel,
    int? reviewCount,
    DateTime? lastReviewedAt,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return QuestionRecord(
      id: id,
      imagePath: imagePath,
      subject: subject ?? this.subject,
      recognizedText: recognizedText,
      correctedText: correctedText ?? this.correctedText,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      contentStatus: contentStatus ?? this.contentStatus,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }
}
