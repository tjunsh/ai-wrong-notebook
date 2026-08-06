import 'analysis_result.dart';
import 'content_status.dart';
import 'generated_exercise.dart';
import 'mastery_level.dart';
import 'question_split_result.dart';
import 'subject.dart';

enum QuestionContentFormat { plain, latexMixed }

enum CandidateAnalysisStatus { queued, running, success, failed }

class CandidateAnalysisSnapshot {
  const CandidateAnalysisSnapshot({
    required this.candidateId,
    required this.order,
    required this.questionText,
    this.analysisResult,
    this.savedExercises = const [],
    this.subject,
    this.aiTags = const [],
    this.aiKnowledgePoints = const [],
    this.status = CandidateAnalysisStatus.success,
    this.errorMessage,
  });

  factory CandidateAnalysisSnapshot.fromJson(Map<String, dynamic> json) {
    final analysisJson = json['analysisResult'] as Map<String, dynamic>?;
    final exercisesJson = json['savedExercises'] as List? ?? const <Object>[];
    final analysisResult =
        analysisJson != null ? AnalysisResult.fromJson(analysisJson) : null;
    return CandidateAnalysisSnapshot(
      candidateId: json['candidateId'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      questionText: json['questionText'] as String? ?? '',
      analysisResult: analysisResult,
      savedExercises: exercisesJson
          .map((item) =>
              GeneratedExercise.fromJson(item as Map<String, dynamic>))
          .toList(),
      subject: _parseSubjectFromJson(json['subject'] as String?),
      aiTags: List<String>.from(json['aiTags'] as List? ?? const <String>[]),
      aiKnowledgePoints: List<String>.from(
          json['aiKnowledgePoints'] as List? ?? const <String>[]),
      status: _parseCandidateAnalysisStatus(
        json['status'] as String?,
        analysisResult: analysisResult,
      ),
      errorMessage: _nullableString(json['errorMessage']),
    );
  }

  final String candidateId;
  final int order;
  final String questionText;
  final AnalysisResult? analysisResult;
  final List<GeneratedExercise> savedExercises;
  final Subject? subject;
  final List<String> aiTags;
  final List<String> aiKnowledgePoints;
  final CandidateAnalysisStatus status;
  final String? errorMessage;

  bool get isSuccessful =>
      status == CandidateAnalysisStatus.success && analysisResult != null;

  CandidateAnalysisSnapshot copyWith({
    String? candidateId,
    int? order,
    String? questionText,
    AnalysisResult? analysisResult,
    List<GeneratedExercise>? savedExercises,
    Subject? subject,
    List<String>? aiTags,
    List<String>? aiKnowledgePoints,
    CandidateAnalysisStatus? status,
    String? errorMessage,
  }) {
    return CandidateAnalysisSnapshot(
      candidateId: candidateId ?? this.candidateId,
      order: order ?? this.order,
      questionText: questionText ?? this.questionText,
      analysisResult: analysisResult ?? this.analysisResult,
      savedExercises: savedExercises ?? this.savedExercises,
      subject: subject ?? this.subject,
      aiTags: aiTags ?? this.aiTags,
      aiKnowledgePoints: aiKnowledgePoints ?? this.aiKnowledgePoints,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'candidateId': candidateId,
      'order': order,
      'questionText': questionText,
      'analysisResult': analysisResult?.toJson(),
      'savedExercises':
          savedExercises.map((exercise) => exercise.toJson()).toList(),
      'subject': subject?.name,
      'aiTags': aiTags,
      'aiKnowledgePoints': aiKnowledgePoints,
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }
}

CandidateAnalysisStatus _parseCandidateAnalysisStatus(
  String? value, {
  required AnalysisResult? analysisResult,
}) {
  for (final status in CandidateAnalysisStatus.values) {
    if (status.name == value) return status;
  }
  return analysisResult != null
      ? CandidateAnalysisStatus.success
      : CandidateAnalysisStatus.failed;
}

Subject? _parseSubjectFromJson(String? value) {
  if (value == null || value.isEmpty) return null;
  for (final subject in Subject.values) {
    if (subject.name == value || subject.label == value) return subject;
  }
  return null;
}

String? _nullableString(Object? value) {
  final text = value as String?;
  return text == null || text.isEmpty ? null : text;
}

int? _nullableInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

class QuestionRecord {
  const QuestionRecord({
    required this.id,
    required this.imagePath,
    required this.subject,
    required this.extractedQuestionText,
    required this.normalizedQuestionText,
    required this.contentFormat,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.lastReviewedAt,
    required this.reviewCount,
    required this.isFavorite,
    required this.contentStatus,
    required this.masteryLevel,
    required this.analysisResult,
    this.savedExercises = const [],
    this.aiTags = const [],
    this.aiKnowledgePoints = const [],
    this.customTags = const [],
    this.splitResult,
    this.candidateAnalyses = const [],
    this.parentQuestionId,
    this.rootQuestionId,
    this.splitOrder,
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
      extractedQuestionText: recognizedText,
      normalizedQuestionText: recognizedText,
      contentFormat: QuestionContentFormat.plain,
      tags: const <String>[],
      createdAt: now,
      updatedAt: now,
      lastReviewedAt: null,
      reviewCount: 0,
      isFavorite: false,
      contentStatus: ContentStatus.processing,
      masteryLevel: MasteryLevel.newQuestion,
      analysisResult: null,
      savedExercises: const [],
      aiTags: const [],
      aiKnowledgePoints: const [],
      customTags: const [],
      parentQuestionId: null,
      rootQuestionId: null,
      splitOrder: null,
    );
  }

  factory QuestionRecord.fromJson(Map<String, dynamic> json) {
    final analysisResult = json['analysisResult'] != null
        ? AnalysisResult.fromJson(
            json['analysisResult'] as Map<String, dynamic>)
        : null;

    final savedExercisesJson = json['savedExercises'] as List?;
    final legacyExercisesJson = (json['analysisResult']
        as Map<String, dynamic>?)?['generatedExercises'] as List?;
    final extractedQuestionText = json['extractedQuestionText'] as String? ??
        json['recognizedText'] as String? ??
        '';
    final normalizedQuestionText = json['normalizedQuestionText'] as String? ??
        json['correctedText'] as String? ??
        extractedQuestionText;
    final formatName = json['contentFormat'] as String?;
    final splitResultJson = json['splitResult'] as Map<String, dynamic>?;
    final candidateAnalysesJson =
        json['candidateAnalyses'] as List? ?? const <Object>[];

    final savedExercises =
        (savedExercisesJson ?? legacyExercisesJson ?? const [])
            .map((e) => GeneratedExercise.fromJson(e as Map<String, dynamic>))
            .toList();

    final id = json['id'] as String? ?? '';

    return QuestionRecord(
      id: id,
      imagePath: json['imagePath'] as String? ?? '',
      subject: Subject.values.firstWhere(
        (s) => s.name == json['subject'],
        orElse: () => Subject.unknown,
      ),
      extractedQuestionText: extractedQuestionText,
      normalizedQuestionText: normalizedQuestionText,
      contentFormat: QuestionContentFormat.values.firstWhere(
        (format) => format.name == formatName,
        orElse: () => QuestionContentFormat.plain,
      ),
      tags: List<String>.from(json['tags'] as List? ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
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
      analysisResult: analysisResult,
      savedExercises: savedExercises
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(
                questionId: entry.value.questionId.isEmpty
                    ? id
                    : entry.value.questionId,
                order: entry.value.order ?? entry.key,
              ))
          .toList(),
      aiTags: List<String>.from(json['aiTags'] as List? ?? []),
      aiKnowledgePoints:
          List<String>.from(json['aiKnowledgePoints'] as List? ?? []),
      customTags: List<String>.from(json['customTags'] as List? ?? []),
      splitResult: splitResultJson != null
          ? QuestionSplitResult.fromJson(splitResultJson)
          : null,
      candidateAnalyses: candidateAnalysesJson
          .map((item) =>
              CandidateAnalysisSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
      parentQuestionId: _nullableString(json['parentQuestionId']),
      rootQuestionId: _nullableString(json['rootQuestionId']),
      splitOrder: _nullableInt(json['splitOrder']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'subject': subject.name,
      'extractedQuestionText': extractedQuestionText,
      'normalizedQuestionText': normalizedQuestionText,
      'recognizedText': extractedQuestionText,
      'correctedText': normalizedQuestionText,
      'contentFormat': contentFormat.name,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'reviewCount': reviewCount,
      'isFavorite': isFavorite,
      'contentStatus': contentStatus.name,
      'masteryLevel': masteryLevel.name,
      'analysisResult': analysisResult?.toJson(),
      'savedExercises':
          savedExercises.map((exercise) => exercise.toJson()).toList(),
      'aiTags': aiTags,
      'aiKnowledgePoints': aiKnowledgePoints,
      'customTags': customTags,
      'splitResult': splitResult?.toJson(),
      'candidateAnalyses':
          candidateAnalyses.map((candidate) => candidate.toJson()).toList(),
      'parentQuestionId': parentQuestionId,
      'rootQuestionId': rootQuestionId,
      'splitOrder': splitOrder,
    };
  }

  final String id;
  final String imagePath;
  final Subject subject;
  final String extractedQuestionText;
  final String normalizedQuestionText;
  final QuestionContentFormat contentFormat;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final bool isFavorite;
  final ContentStatus contentStatus;
  final MasteryLevel masteryLevel;
  final AnalysisResult? analysisResult;
  final List<GeneratedExercise> savedExercises;
  final List<String> aiTags;
  final List<String> aiKnowledgePoints;
  final List<String> customTags;
  final QuestionSplitResult? splitResult;
  final List<CandidateAnalysisSnapshot> candidateAnalyses;
  final String? parentQuestionId;
  final String? rootQuestionId;
  final int? splitOrder;

  String get recognizedText => extractedQuestionText;
  String get correctedText => normalizedQuestionText;

  List<String> get allTags => [...aiTags, ...customTags];

  QuestionRecord createReanalysisDraft({required String correctedText}) {
    final text = correctedText.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(
        correctedText,
        'correctedText',
        'Corrected question text must not be empty.',
      );
    }

    return QuestionRecord(
      id: id,
      imagePath: imagePath,
      subject: subject,
      extractedQuestionText: text,
      normalizedQuestionText: text,
      contentFormat: contentFormat,
      tags: tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastReviewedAt: lastReviewedAt,
      reviewCount: reviewCount,
      isFavorite: isFavorite,
      contentStatus: ContentStatus.processing,
      masteryLevel: masteryLevel,
      analysisResult: null,
      savedExercises: const <GeneratedExercise>[],
      aiTags: const <String>[],
      aiKnowledgePoints: const <String>[],
      customTags: customTags,
      splitResult: null,
      candidateAnalyses: const <CandidateAnalysisSnapshot>[],
      parentQuestionId: parentQuestionId,
      rootQuestionId: rootQuestionId,
      splitOrder: splitOrder,
    );
  }

  QuestionRecord copyWith({
    String? extractedQuestionText,
    String? normalizedQuestionText,
    QuestionContentFormat? contentFormat,
    Subject? subject,
    ContentStatus? contentStatus,
    AnalysisResult? analysisResult,
    List<GeneratedExercise>? savedExercises,
    MasteryLevel? masteryLevel,
    int? reviewCount,
    DateTime? lastReviewedAt,
    List<String>? tags,
    bool? isFavorite,
    List<String>? aiTags,
    List<String>? aiKnowledgePoints,
    List<String>? customTags,
    QuestionSplitResult? splitResult,
    List<CandidateAnalysisSnapshot>? candidateAnalyses,
    String? parentQuestionId,
    String? rootQuestionId,
    int? splitOrder,
  }) {
    return QuestionRecord(
      id: id,
      imagePath: imagePath,
      subject: subject ?? this.subject,
      extractedQuestionText:
          extractedQuestionText ?? this.extractedQuestionText,
      normalizedQuestionText:
          normalizedQuestionText ?? this.normalizedQuestionText,
      contentFormat: contentFormat ?? this.contentFormat,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      isFavorite: isFavorite ?? this.isFavorite,
      contentStatus: contentStatus ?? this.contentStatus,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      analysisResult: analysisResult ?? this.analysisResult,
      savedExercises: savedExercises ?? this.savedExercises,
      aiTags: aiTags ?? this.aiTags,
      aiKnowledgePoints: aiKnowledgePoints ?? this.aiKnowledgePoints,
      customTags: customTags ?? this.customTags,
      splitResult: splitResult ?? this.splitResult,
      candidateAnalyses: candidateAnalyses ?? this.candidateAnalyses,
      parentQuestionId: parentQuestionId ?? this.parentQuestionId,
      rootQuestionId: rootQuestionId ?? this.rootQuestionId,
      splitOrder: splitOrder ?? this.splitOrder,
    );
  }
}
