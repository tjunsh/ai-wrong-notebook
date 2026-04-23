// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $QuestionRecordsTable extends QuestionRecords
    with TableInfo<$QuestionRecordsTable, QuestionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subjectMeta =
      const VerificationMeta('subject');
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
      'subject', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalImagePathMeta =
      const VerificationMeta('originalImagePath');
  @override
  late final GeneratedColumn<String> originalImagePath =
      GeneratedColumn<String>('original_image_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _originalTextMeta =
      const VerificationMeta('originalText');
  @override
  late final GeneratedColumn<String> originalText = GeneratedColumn<String>(
      'original_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _correctedTextMeta =
      const VerificationMeta('correctedText');
  @override
  late final GeneratedColumn<String> correctedText = GeneratedColumn<String>(
      'corrected_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _masteryLevelMeta =
      const VerificationMeta('masteryLevel');
  @override
  late final GeneratedColumn<String> masteryLevel = GeneratedColumn<String>(
      'mastery_level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentStatusMeta =
      const VerificationMeta('contentStatus');
  @override
  late final GeneratedColumn<String> contentStatus = GeneratedColumn<String>(
      'content_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _reviewCountMeta =
      const VerificationMeta('reviewCount');
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
      'review_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextReviewAtMeta =
      const VerificationMeta('nextReviewAt');
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
      'next_review_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _aiAnalysisJsonMeta =
      const VerificationMeta('aiAnalysisJson');
  @override
  late final GeneratedColumn<String> aiAnalysisJson = GeneratedColumn<String>(
      'ai_analysis_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _aiTagsMeta = const VerificationMeta('aiTags');
  @override
  late final GeneratedColumn<String> aiTags = GeneratedColumn<String>(
      'ai_tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _aiKnowledgePointsMeta =
      const VerificationMeta('aiKnowledgePoints');
  @override
  late final GeneratedColumn<String> aiKnowledgePoints =
      GeneratedColumn<String>('ai_knowledge_points', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _customTagsMeta =
      const VerificationMeta('customTags');
  @override
  late final GeneratedColumn<String> customTags =
      GeneratedColumn<String>('custom_tags', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        subject,
        originalImagePath,
        originalText,
        correctedText,
        masteryLevel,
        contentStatus,
        reviewCount,
        nextReviewAt,
        createdAt,
        updatedAt,
        aiAnalysisJson,
        tags,
        aiTags,
        aiKnowledgePoints,
        customTags
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_records';
  @override
  VerificationContext validateIntegrity(Insertable<QuestionRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(_subjectMeta,
          subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta));
    } else if (isInserting) {
      context.missing(_subjectMeta);
    }
    if (data.containsKey('original_image_path')) {
      context.handle(
          _originalImagePathMeta,
          originalImagePath.isAcceptableOrUnknown(
              data['original_image_path']!, _originalImagePathMeta));
    }
    if (data.containsKey('original_text')) {
      context.handle(
          _originalTextMeta,
          originalText.isAcceptableOrUnknown(
              data['original_text']!, _originalTextMeta));
    } else if (isInserting) {
      context.missing(_originalTextMeta);
    }
    if (data.containsKey('corrected_text')) {
      context.handle(
          _correctedTextMeta,
          correctedText.isAcceptableOrUnknown(
              data['corrected_text']!, _correctedTextMeta));
    } else if (isInserting) {
      context.missing(_correctedTextMeta);
    }
    if (data.containsKey('mastery_level')) {
      context.handle(
          _masteryLevelMeta,
          masteryLevel.isAcceptableOrUnknown(
              data['mastery_level']!, _masteryLevelMeta));
    } else if (isInserting) {
      context.missing(_masteryLevelMeta);
    }
    if (data.containsKey('content_status')) {
      context.handle(
          _contentStatusMeta,
          contentStatus.isAcceptableOrUnknown(
              data['content_status']!, _contentStatusMeta));
    } else if (isInserting) {
      context.missing(_contentStatusMeta);
    }
    if (data.containsKey('review_count')) {
      context.handle(
          _reviewCountMeta,
          reviewCount.isAcceptableOrUnknown(
              data['review_count']!, _reviewCountMeta));
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
          _nextReviewAtMeta,
          nextReviewAt.isAcceptableOrUnknown(
              data['next_review_at']!, _nextReviewAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('ai_analysis_json')) {
      context.handle(
          _aiAnalysisJsonMeta,
          aiAnalysisJson.isAcceptableOrUnknown(
              data['ai_analysis_json']!, _aiAnalysisJsonMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      subject: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject'])!,
      originalImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}original_image_path']),
      originalText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_text'])!,
      correctedText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}corrected_text'])!,
      masteryLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mastery_level'])!,
      contentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_status'])!,
      reviewCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}review_count'])!,
      nextReviewAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_review_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      aiAnalysisJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ai_analysis_json']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      aiTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_tags'])!,
    );
  }

  @override
  $QuestionRecordsTable createAlias(String alias) {
    return $QuestionRecordsTable(attachedDatabase, alias);
  }
}

class QuestionRecord extends DataClass implements Insertable<QuestionRecord> {
  final String id;
  final String subject;
  final String? originalImagePath;
  final String originalText;
  final String correctedText;
  final String masteryLevel;
  final String contentStatus;
  final int reviewCount;
  final DateTime? nextReviewAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? aiAnalysisJson;
  final String tags;
  final String aiTags;
  final String aiKnowledgePoints;
  final String customTags;
  const QuestionRecord(
      {required this.id,
      required this.subject,
      this.originalImagePath,
      required this.originalText,
      required this.correctedText,
      required this.masteryLevel,
      required this.contentStatus,
      required this.reviewCount,
      this.nextReviewAt,
      required this.createdAt,
      required this.updatedAt,
      this.aiAnalysisJson,
      required this.tags,
      this.aiTags = '',
      this.aiKnowledgePoints = '',
      this.customTags = ''});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject'] = Variable<String>(subject);
    if (!nullToAbsent || originalImagePath != null) {
      map['original_image_path'] = Variable<String>(originalImagePath);
    }
    map['original_text'] = Variable<String>(originalText);
    map['corrected_text'] = Variable<String>(correctedText);
    map['mastery_level'] = Variable<String>(masteryLevel);
    map['content_status'] = Variable<String>(contentStatus);
    map['review_count'] = Variable<int>(reviewCount);
    if (!nullToAbsent || nextReviewAt != null) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || aiAnalysisJson != null) {
      map['ai_analysis_json'] = Variable<String>(aiAnalysisJson);
    }
    map['tags'] = Variable<String>(tags);
    map['ai_tags'] = Variable<String>(aiTags);
    map['ai_knowledge_points'] = Variable<String>(aiKnowledgePoints);
    map['custom_tags'] = Variable<String>(customTags);
    return map;
  }

  QuestionRecordsCompanion toCompanion(bool nullToAbsent) {
    return QuestionRecordsCompanion(
      id: Value(id),
      subject: Value(subject),
      originalImagePath: originalImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalImagePath),
      originalText: Value(originalText),
      correctedText: Value(correctedText),
      masteryLevel: Value(masteryLevel),
      contentStatus: Value(contentStatus),
      reviewCount: Value(reviewCount),
      nextReviewAt: nextReviewAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextReviewAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      aiAnalysisJson: aiAnalysisJson == null && nullToAbsent
          ? const Value.absent()
          : Value(aiAnalysisJson),
      tags: Value(tags),
      aiTags: Value(aiTags),
    );
  }

  factory QuestionRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRecord(
      id: serializer.fromJson<String>(json['id']),
      subject: serializer.fromJson<String>(json['subject']),
      originalImagePath:
          serializer.fromJson<String?>(json['originalImagePath']),
      originalText: serializer.fromJson<String>(json['originalText']),
      correctedText: serializer.fromJson<String>(json['correctedText']),
      masteryLevel: serializer.fromJson<String>(json['masteryLevel']),
      contentStatus: serializer.fromJson<String>(json['contentStatus']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      nextReviewAt: serializer.fromJson<DateTime?>(json['nextReviewAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      aiAnalysisJson: serializer.fromJson<String?>(json['aiAnalysisJson']),
      tags: serializer.fromJson<String>(json['tags']),
      aiTags: serializer.fromJson<String>(json['aiTags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subject': serializer.toJson<String>(subject),
      'originalImagePath': serializer.toJson<String?>(originalImagePath),
      'originalText': serializer.toJson<String>(originalText),
      'correctedText': serializer.toJson<String>(correctedText),
      'masteryLevel': serializer.toJson<String>(masteryLevel),
      'contentStatus': serializer.toJson<String>(contentStatus),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'nextReviewAt': serializer.toJson<DateTime?>(nextReviewAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'aiAnalysisJson': serializer.toJson<String?>(aiAnalysisJson),
      'tags': serializer.toJson<String>(tags),
      'aiTags': serializer.toJson<String>(aiTags),
    };
  }

  QuestionRecord copyWith(
          {String? id,
          String? subject,
          Value<String?> originalImagePath = const Value.absent(),
          String? originalText,
          String? correctedText,
          String? masteryLevel,
          String? contentStatus,
          int? reviewCount,
          Value<DateTime?> nextReviewAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<String?> aiAnalysisJson = const Value.absent(),
          String? tags,
          String? aiTags}) =>
      QuestionRecord(
        id: id ?? this.id,
        subject: subject ?? this.subject,
        originalImagePath: originalImagePath.present
            ? originalImagePath.value
            : this.originalImagePath,
        originalText: originalText ?? this.originalText,
        correctedText: correctedText ?? this.correctedText,
        masteryLevel: masteryLevel ?? this.masteryLevel,
        contentStatus: contentStatus ?? this.contentStatus,
        reviewCount: reviewCount ?? this.reviewCount,
        nextReviewAt:
            nextReviewAt.present ? nextReviewAt.value : this.nextReviewAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        aiAnalysisJson:
            aiAnalysisJson.present ? aiAnalysisJson.value : this.aiAnalysisJson,
        tags: tags ?? this.tags,
        aiTags: aiTags ?? this.aiTags,
      );
  QuestionRecord copyWithCompanion(QuestionRecordsCompanion data) {
    return QuestionRecord(
      id: data.id.present ? data.id.value : this.id,
      subject: data.subject.present ? data.subject.value : this.subject,
      originalImagePath: data.originalImagePath.present
          ? data.originalImagePath.value
          : this.originalImagePath,
      originalText: data.originalText.present
          ? data.originalText.value
          : this.originalText,
      correctedText: data.correctedText.present
          ? data.correctedText.value
          : this.correctedText,
      masteryLevel: data.masteryLevel.present
          ? data.masteryLevel.value
          : this.masteryLevel,
      contentStatus: data.contentStatus.present
          ? data.contentStatus.value
          : this.contentStatus,
      reviewCount:
          data.reviewCount.present ? data.reviewCount.value : this.reviewCount,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      aiAnalysisJson: data.aiAnalysisJson.present
          ? data.aiAnalysisJson.value
          : this.aiAnalysisJson,
      tags: data.tags.present ? data.tags.value : this.tags,
      aiTags: data.aiTags.present ? data.aiTags.value : this.aiTags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRecord(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('originalText: $originalText, ')
          ..write('correctedText: $correctedText, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('contentStatus: $contentStatus, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('aiAnalysisJson: $aiAnalysisJson, ')
          ..write('tags: $tags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      subject,
      originalImagePath,
      originalText,
      correctedText,
      masteryLevel,
      contentStatus,
      reviewCount,
      nextReviewAt,
      createdAt,
      updatedAt,
      aiAnalysisJson,
      tags,
      aiTags,
      aiKnowledgePoints,
      customTags);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRecord &&
          other.id == this.id &&
          other.subject == this.subject &&
          other.originalImagePath == this.originalImagePath &&
          other.originalText == this.originalText &&
          other.correctedText == this.correctedText &&
          other.masteryLevel == this.masteryLevel &&
          other.contentStatus == this.contentStatus &&
          other.reviewCount == this.reviewCount &&
          other.nextReviewAt == this.nextReviewAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.aiAnalysisJson == this.aiAnalysisJson &&
          other.tags == this.tags &&
          other.aiTags == this.aiTags &&
          other.aiKnowledgePoints == this.aiKnowledgePoints &&
          other.customTags == this.customTags);
}

class QuestionRecordsCompanion extends UpdateCompanion<QuestionRecord> {
  final Value<String> id;
  final Value<String> subject;
  final Value<String?> originalImagePath;
  final Value<String> originalText;
  final Value<String> correctedText;
  final Value<String> masteryLevel;
  final Value<String> contentStatus;
  final Value<int> reviewCount;
  final Value<DateTime?> nextReviewAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> aiAnalysisJson;
  final Value<String> tags;
  final Value<String> aiTags;
  final Value<String> aiKnowledgePoints;
  final Value<String> customTags;
  final Value<int> rowid;
  const QuestionRecordsCompanion({
    this.id = const Value.absent(),
    this.subject = const Value.absent(),
    this.originalImagePath = const Value.absent(),
    this.originalText = const Value.absent(),
    this.correctedText = const Value.absent(),
    this.masteryLevel = const Value.absent(),
    this.contentStatus = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.aiAnalysisJson = const Value.absent(),
    this.tags = const Value.absent(),
    this.aiTags = const Value.absent(),
    this.aiKnowledgePoints = const Value.absent(),
    this.customTags = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuestionRecordsCompanion.insert({
    required String id,
    required String subject,
    this.originalImagePath = const Value.absent(),
    required String originalText,
    required String correctedText,
    required String masteryLevel,
    required String contentStatus,
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.aiAnalysisJson = const Value.absent(),
    this.tags = const Value.absent(),
    this.aiTags = const Value.absent(),
    this.aiKnowledgePoints = const Value.absent(),
    this.customTags = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        subject = Value(subject),
        originalText = Value(originalText),
        correctedText = Value(correctedText),
        masteryLevel = Value(masteryLevel),
        contentStatus = Value(contentStatus),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<QuestionRecord> custom({
    Expression<String>? id,
    Expression<String>? subject,
    Expression<String>? originalImagePath,
    Expression<String>? originalText,
    Expression<String>? correctedText,
    Expression<String>? masteryLevel,
    Expression<String>? contentStatus,
    Expression<int>? reviewCount,
    Expression<DateTime>? nextReviewAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? aiAnalysisJson,
    Expression<String>? tags,
    Expression<String>? aiTags,
    Expression<String>? aiKnowledgePoints,
    Expression<String>? customTags,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subject != null) 'subject': subject,
      if (originalImagePath != null) 'original_image_path': originalImagePath,
      if (originalText != null) 'original_text': originalText,
      if (correctedText != null) 'corrected_text': correctedText,
      if (masteryLevel != null) 'mastery_level': masteryLevel,
      if (contentStatus != null) 'content_status': contentStatus,
      if (reviewCount != null) 'review_count': reviewCount,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (aiAnalysisJson != null) 'ai_analysis_json': aiAnalysisJson,
      if (tags != null) 'tags': tags,
      if (aiTags != null) 'ai_tags': aiTags,
      if (aiKnowledgePoints != null) 'ai_knowledge_points': aiKnowledgePoints,
      if (customTags != null) 'custom_tags': customTags,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuestionRecordsCompanion copyWith(
      {Value<String>? id,
      Value<String>? subject,
      Value<String?>? originalImagePath,
      Value<String>? originalText,
      Value<String>? correctedText,
      Value<String>? masteryLevel,
      Value<String>? contentStatus,
      Value<int>? reviewCount,
      Value<DateTime?>? nextReviewAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String?>? aiAnalysisJson,
      Value<String>? tags,
      Value<String>? aiTags,
      Value<String>? aiKnowledgePoints,
      Value<String>? customTags,
      Value<int>? rowid}) {
    return QuestionRecordsCompanion(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      originalText: originalText ?? this.originalText,
      correctedText: correctedText ?? this.correctedText,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      contentStatus: contentStatus ?? this.contentStatus,
      reviewCount: reviewCount ?? this.reviewCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiAnalysisJson: aiAnalysisJson ?? this.aiAnalysisJson,
      tags: tags ?? this.tags,
      aiTags: aiTags ?? this.aiTags,
      aiKnowledgePoints: aiKnowledgePoints ?? this.aiKnowledgePoints,
      customTags: customTags ?? this.customTags,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (originalImagePath.present) {
      map['original_image_path'] = Variable<String>(originalImagePath.value);
    }
    if (originalText.present) {
      map['original_text'] = Variable<String>(originalText.value);
    }
    if (correctedText.present) {
      map['corrected_text'] = Variable<String>(correctedText.value);
    }
    if (masteryLevel.present) {
      map['mastery_level'] = Variable<String>(masteryLevel.value);
    }
    if (contentStatus.present) {
      map['content_status'] = Variable<String>(contentStatus.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (aiAnalysisJson.present) {
      map['ai_analysis_json'] = Variable<String>(aiAnalysisJson.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (aiTags.present) {
      map['ai_tags'] = Variable<String>(aiTags.value);
    }
    if (aiKnowledgePoints.present) {
      map['ai_knowledge_points'] = Variable<String>(aiKnowledgePoints.value);
    }
    if (customTags.present) {
      map['custom_tags'] = Variable<String>(customTags.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRecordsCompanion(')
          ..write('id: $id, ')
          ..write('subject: $subject, ')
          ..write('originalImagePath: $originalImagePath, ')
          ..write('originalText: $originalText, ')
          ..write('correctedText: $correctedText, ')
          ..write('masteryLevel: $masteryLevel, ')
          ..write('contentStatus: $contentStatus, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('aiAnalysisJson: $aiAnalysisJson, ')
          ..write('tags: $tags, ')
          ..write('aiTags: $aiTags, ')
          ..write('aiKnowledgePoints: $aiKnowledgePoints, ')
          ..write('customTags: $customTags, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeneratedExercisesTable extends GeneratedExercises
    with TableInfo<$GeneratedExercisesTable, GeneratedExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneratedExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES question_records (id)'));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionMeta =
      const VerificationMeta('question');
  @override
  late final GeneratedColumn<String> question = GeneratedColumn<String>(
      'question', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
      'answer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionId, difficulty, question, answer, explanation, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generated_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<GeneratedExercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('question')) {
      context.handle(_questionMeta,
          question.isAcceptableOrUnknown(data['question']!, _questionMeta));
    } else if (isInserting) {
      context.missing(_questionMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(_answerMeta,
          answer.isAcceptableOrUnknown(data['answer']!, _answerMeta));
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneratedExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneratedExercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      question: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GeneratedExercisesTable createAlias(String alias) {
    return $GeneratedExercisesTable(attachedDatabase, alias);
  }
}

class GeneratedExercise extends DataClass
    implements Insertable<GeneratedExercise> {
  final int id;
  final String questionId;
  final String difficulty;
  final String question;
  final String answer;
  final String? explanation;
  final DateTime createdAt;
  const GeneratedExercise(
      {required this.id,
      required this.questionId,
      required this.difficulty,
      required this.question,
      required this.answer,
      this.explanation,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['difficulty'] = Variable<String>(difficulty);
    map['question'] = Variable<String>(question);
    map['answer'] = Variable<String>(answer);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GeneratedExercisesCompanion toCompanion(bool nullToAbsent) {
    return GeneratedExercisesCompanion(
      id: Value(id),
      questionId: Value(questionId),
      difficulty: Value(difficulty),
      question: Value(question),
      answer: Value(answer),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      createdAt: Value(createdAt),
    );
  }

  factory GeneratedExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneratedExercise(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      question: serializer.fromJson<String>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'difficulty': serializer.toJson<String>(difficulty),
      'question': serializer.toJson<String>(question),
      'answer': serializer.toJson<String>(answer),
      'explanation': serializer.toJson<String?>(explanation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GeneratedExercise copyWith(
          {int? id,
          String? questionId,
          String? difficulty,
          String? question,
          String? answer,
          Value<String?> explanation = const Value.absent(),
          DateTime? createdAt}) =>
      GeneratedExercise(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        difficulty: difficulty ?? this.difficulty,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        explanation: explanation.present ? explanation.value : this.explanation,
        createdAt: createdAt ?? this.createdAt,
      );
  GeneratedExercise copyWithCompanion(GeneratedExercisesCompanion data) {
    return GeneratedExercise(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercise(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('difficulty: $difficulty, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('explanation: $explanation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, questionId, difficulty, question, answer, explanation, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedExercise &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.difficulty == this.difficulty &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.explanation == this.explanation &&
          other.createdAt == this.createdAt);
}

class GeneratedExercisesCompanion extends UpdateCompanion<GeneratedExercise> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<String> difficulty;
  final Value<String> question;
  final Value<String> answer;
  final Value<String?> explanation;
  final Value<DateTime> createdAt;
  const GeneratedExercisesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GeneratedExercisesCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required String difficulty,
    required String question,
    required String answer,
    this.explanation = const Value.absent(),
    required DateTime createdAt,
  })  : questionId = Value(questionId),
        difficulty = Value(difficulty),
        question = Value(question),
        answer = Value(answer),
        createdAt = Value(createdAt);
  static Insertable<GeneratedExercise> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<String>? difficulty,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<String>? explanation,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (difficulty != null) 'difficulty': difficulty,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (explanation != null) 'explanation': explanation,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GeneratedExercisesCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionId,
      Value<String>? difficulty,
      Value<String>? question,
      Value<String>? answer,
      Value<String?>? explanation,
      Value<DateTime>? createdAt}) {
    return GeneratedExercisesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      difficulty: difficulty ?? this.difficulty,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (question.present) {
      map['question'] = Variable<String>(question.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('difficulty: $difficulty, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('explanation: $explanation, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES question_records (id)'));
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _wasCorrectMeta =
      const VerificationMeta('wasCorrect');
  @override
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
      'was_correct', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_correct" IN (0, 1))'));
  static const VerificationMeta _responseTimeMsMeta =
      const VerificationMeta('responseTimeMs');
  @override
  late final GeneratedColumn<int> responseTimeMs = GeneratedColumn<int>(
      'response_time_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionId, reviewedAt, wasCorrect, responseTimeMs, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('was_correct')) {
      context.handle(
          _wasCorrectMeta,
          wasCorrect.isAcceptableOrUnknown(
              data['was_correct']!, _wasCorrectMeta));
    } else if (isInserting) {
      context.missing(_wasCorrectMeta);
    }
    if (data.containsKey('response_time_ms')) {
      context.handle(
          _responseTimeMsMeta,
          responseTimeMs.isAcceptableOrUnknown(
              data['response_time_ms']!, _responseTimeMsMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}reviewed_at'])!,
      wasCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_correct'])!,
      responseTimeMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}response_time_ms']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final int id;
  final String questionId;
  final DateTime reviewedAt;
  final bool wasCorrect;
  final int? responseTimeMs;
  final String? notes;
  const ReviewLog(
      {required this.id,
      required this.questionId,
      required this.reviewedAt,
      required this.wasCorrect,
      this.responseTimeMs,
      this.notes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_id'] = Variable<String>(questionId);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['was_correct'] = Variable<bool>(wasCorrect);
    if (!nullToAbsent || responseTimeMs != null) {
      map['response_time_ms'] = Variable<int>(responseTimeMs);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      questionId: Value(questionId),
      reviewedAt: Value(reviewedAt),
      wasCorrect: Value(wasCorrect),
      responseTimeMs: responseTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(responseTimeMs),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
    );
  }

  factory ReviewLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<int>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      wasCorrect: serializer.fromJson<bool>(json['wasCorrect']),
      responseTimeMs: serializer.fromJson<int?>(json['responseTimeMs']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionId': serializer.toJson<String>(questionId),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'wasCorrect': serializer.toJson<bool>(wasCorrect),
      'responseTimeMs': serializer.toJson<int?>(responseTimeMs),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  ReviewLog copyWith(
          {int? id,
          String? questionId,
          DateTime? reviewedAt,
          bool? wasCorrect,
          Value<int?> responseTimeMs = const Value.absent(),
          Value<String?> notes = const Value.absent()}) =>
      ReviewLog(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        wasCorrect: wasCorrect ?? this.wasCorrect,
        responseTimeMs:
            responseTimeMs.present ? responseTimeMs.value : this.responseTimeMs,
        notes: notes.present ? notes.value : this.notes,
      );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      wasCorrect:
          data.wasCorrect.present ? data.wasCorrect.value : this.wasCorrect,
      responseTimeMs: data.responseTimeMs.present
          ? data.responseTimeMs.value
          : this.responseTimeMs,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, questionId, reviewedAt, wasCorrect, responseTimeMs, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.reviewedAt == this.reviewedAt &&
          other.wasCorrect == this.wasCorrect &&
          other.responseTimeMs == this.responseTimeMs &&
          other.notes == this.notes);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<int> id;
  final Value<String> questionId;
  final Value<DateTime> reviewedAt;
  final Value<bool> wasCorrect;
  final Value<int?> responseTimeMs;
  final Value<String?> notes;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.responseTimeMs = const Value.absent(),
    this.notes = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required String questionId,
    required DateTime reviewedAt,
    required bool wasCorrect,
    this.responseTimeMs = const Value.absent(),
    this.notes = const Value.absent(),
  })  : questionId = Value(questionId),
        reviewedAt = Value(reviewedAt),
        wasCorrect = Value(wasCorrect);
  static Insertable<ReviewLog> custom({
    Expression<int>? id,
    Expression<String>? questionId,
    Expression<DateTime>? reviewedAt,
    Expression<bool>? wasCorrect,
    Expression<int>? responseTimeMs,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
      if (notes != null) 'notes': notes,
    });
  }

  ReviewLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionId,
      Value<DateTime>? reviewedAt,
      Value<bool>? wasCorrect,
      Value<int?>? responseTimeMs,
      Value<String?>? notes}) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (responseTimeMs.present) {
      map['response_time_ms'] = Variable<int>(responseTimeMs.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('responseTimeMs: $responseTimeMs, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SettingsEntry(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingsEntry copyWith({String? key, String? value, DateTime? updatedAt}) =>
      SettingsEntry(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $QuestionRecordsTable questionRecords =
      $QuestionRecordsTable(this);
  late final $GeneratedExercisesTable generatedExercises =
      $GeneratedExercisesTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $SettingsEntriesTable settingsEntries =
      $SettingsEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [questionRecords, generatedExercises, reviewLogs, settingsEntries];
}

typedef $$QuestionRecordsTableCreateCompanionBuilder = QuestionRecordsCompanion
    Function({
  required String id,
  required String subject,
  Value<String?> originalImagePath,
  required String originalText,
  required String correctedText,
  required String masteryLevel,
  required String contentStatus,
  Value<int> reviewCount,
  Value<DateTime?> nextReviewAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> aiAnalysisJson,
  Value<String> tags,
  Value<int> rowid,
});
typedef $$QuestionRecordsTableUpdateCompanionBuilder = QuestionRecordsCompanion
    Function({
  Value<String> id,
  Value<String> subject,
  Value<String?> originalImagePath,
  Value<String> originalText,
  Value<String> correctedText,
  Value<String> masteryLevel,
  Value<String> contentStatus,
  Value<int> reviewCount,
  Value<DateTime?> nextReviewAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> aiAnalysisJson,
  Value<String> tags,
  Value<int> rowid,
});

final class $$QuestionRecordsTableReferences extends BaseReferences<
    _$AppDatabase, $QuestionRecordsTable, QuestionRecord> {
  $$QuestionRecordsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GeneratedExercisesTable, List<GeneratedExercise>>
      _generatedExercisesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.generatedExercises,
              aliasName: $_aliasNameGenerator(
                  db.questionRecords.id, db.generatedExercises.questionId));

  $$GeneratedExercisesTableProcessedTableManager get generatedExercisesRefs {
    final manager = $$GeneratedExercisesTableTableManager(
            $_db, $_db.generatedExercises)
        .filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_generatedExercisesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReviewLogsTable, List<ReviewLog>>
      _reviewLogsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.reviewLogs,
              aliasName: $_aliasNameGenerator(
                  db.questionRecords.id, db.reviewLogs.questionId));

  $$ReviewLogsTableProcessedTableManager get reviewLogsRefs {
    final manager = $$ReviewLogsTableTableManager($_db, $_db.reviewLogs)
        .filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$QuestionRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalImagePath => $composableBuilder(
      column: $table.originalImagePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalText => $composableBuilder(
      column: $table.originalText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get correctedText => $composableBuilder(
      column: $table.correctedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiAnalysisJson => $composableBuilder(
      column: $table.aiAnalysisJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  Expression<bool> generatedExercisesRefs(
      Expression<bool> Function($$GeneratedExercisesTableFilterComposer f) f) {
    final $$GeneratedExercisesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.generatedExercises,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GeneratedExercisesTableFilterComposer(
              $db: $db,
              $table: $db.generatedExercises,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reviewLogsRefs(
      Expression<bool> Function($$ReviewLogsTableFilterComposer f) f) {
    final $$ReviewLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableFilterComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subject => $composableBuilder(
      column: $table.subject, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalImagePath => $composableBuilder(
      column: $table.originalImagePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalText => $composableBuilder(
      column: $table.originalText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get correctedText => $composableBuilder(
      column: $table.correctedText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiAnalysisJson => $composableBuilder(
      column: $table.aiAnalysisJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));
}

class $$QuestionRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionRecordsTable> {
  $$QuestionRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get originalImagePath => $composableBuilder(
      column: $table.originalImagePath, builder: (column) => column);

  GeneratedColumn<String> get originalText => $composableBuilder(
      column: $table.originalText, builder: (column) => column);

  GeneratedColumn<String> get correctedText => $composableBuilder(
      column: $table.correctedText, builder: (column) => column);

  GeneratedColumn<String> get masteryLevel => $composableBuilder(
      column: $table.masteryLevel, builder: (column) => column);

  GeneratedColumn<String> get contentStatus => $composableBuilder(
      column: $table.contentStatus, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
      column: $table.reviewCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
      column: $table.nextReviewAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get aiAnalysisJson => $composableBuilder(
      column: $table.aiAnalysisJson, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  Expression<T> generatedExercisesRefs<T extends Object>(
      Expression<T> Function($$GeneratedExercisesTableAnnotationComposer a) f) {
    final $$GeneratedExercisesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.generatedExercises,
            getReferencedColumn: (t) => t.questionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$GeneratedExercisesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.generatedExercises,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> reviewLogsRefs<T extends Object>(
      Expression<T> Function($$ReviewLogsTableAnnotationComposer a) f) {
    final $$ReviewLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewLogs,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.reviewLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionRecordsTable,
    QuestionRecord,
    $$QuestionRecordsTableFilterComposer,
    $$QuestionRecordsTableOrderingComposer,
    $$QuestionRecordsTableAnnotationComposer,
    $$QuestionRecordsTableCreateCompanionBuilder,
    $$QuestionRecordsTableUpdateCompanionBuilder,
    (QuestionRecord, $$QuestionRecordsTableReferences),
    QuestionRecord,
    PrefetchHooks Function(
        {bool generatedExercisesRefs, bool reviewLogsRefs})> {
  $$QuestionRecordsTableTableManager(
      _$AppDatabase db, $QuestionRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> subject = const Value.absent(),
            Value<String?> originalImagePath = const Value.absent(),
            Value<String> originalText = const Value.absent(),
            Value<String> correctedText = const Value.absent(),
            Value<String> masteryLevel = const Value.absent(),
            Value<String> contentStatus = const Value.absent(),
            Value<int> reviewCount = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String?> aiAnalysisJson = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionRecordsCompanion(
            id: id,
            subject: subject,
            originalImagePath: originalImagePath,
            originalText: originalText,
            correctedText: correctedText,
            masteryLevel: masteryLevel,
            contentStatus: contentStatus,
            reviewCount: reviewCount,
            nextReviewAt: nextReviewAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            aiAnalysisJson: aiAnalysisJson,
            tags: tags,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String subject,
            Value<String?> originalImagePath = const Value.absent(),
            required String originalText,
            required String correctedText,
            required String masteryLevel,
            required String contentStatus,
            Value<int> reviewCount = const Value.absent(),
            Value<DateTime?> nextReviewAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String?> aiAnalysisJson = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuestionRecordsCompanion.insert(
            id: id,
            subject: subject,
            originalImagePath: originalImagePath,
            originalText: originalText,
            correctedText: correctedText,
            masteryLevel: masteryLevel,
            contentStatus: contentStatus,
            reviewCount: reviewCount,
            nextReviewAt: nextReviewAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            aiAnalysisJson: aiAnalysisJson,
            tags: tags,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuestionRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {generatedExercisesRefs = false, reviewLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (generatedExercisesRefs) db.generatedExercises,
                if (reviewLogsRefs) db.reviewLogs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (generatedExercisesRefs)
                    await $_getPrefetchedData<QuestionRecord,
                            $QuestionRecordsTable, GeneratedExercise>(
                        currentTable: table,
                        referencedTable: $$QuestionRecordsTableReferences
                            ._generatedExercisesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionRecordsTableReferences(db, table, p0)
                                .generatedExercisesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.questionId == item.id),
                        typedResults: items),
                  if (reviewLogsRefs)
                    await $_getPrefetchedData<QuestionRecord,
                            $QuestionRecordsTable, ReviewLog>(
                        currentTable: table,
                        referencedTable: $$QuestionRecordsTableReferences
                            ._reviewLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionRecordsTableReferences(db, table, p0)
                                .reviewLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.questionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$QuestionRecordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionRecordsTable,
    QuestionRecord,
    $$QuestionRecordsTableFilterComposer,
    $$QuestionRecordsTableOrderingComposer,
    $$QuestionRecordsTableAnnotationComposer,
    $$QuestionRecordsTableCreateCompanionBuilder,
    $$QuestionRecordsTableUpdateCompanionBuilder,
    (QuestionRecord, $$QuestionRecordsTableReferences),
    QuestionRecord,
    PrefetchHooks Function({bool generatedExercisesRefs, bool reviewLogsRefs})>;
typedef $$GeneratedExercisesTableCreateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  Value<int> id,
  required String questionId,
  required String difficulty,
  required String question,
  required String answer,
  Value<String?> explanation,
  required DateTime createdAt,
});
typedef $$GeneratedExercisesTableUpdateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  Value<int> id,
  Value<String> questionId,
  Value<String> difficulty,
  Value<String> question,
  Value<String> answer,
  Value<String?> explanation,
  Value<DateTime> createdAt,
});

final class $$GeneratedExercisesTableReferences extends BaseReferences<
    _$AppDatabase, $GeneratedExercisesTable, GeneratedExercise> {
  $$GeneratedExercisesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $QuestionRecordsTable _questionIdTable(_$AppDatabase db) =>
      db.questionRecords.createAlias($_aliasNameGenerator(
          db.generatedExercises.questionId, db.questionRecords.id));

  $$QuestionRecordsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<String>('question_id')!;

    final manager =
        $$QuestionRecordsTableTableManager($_db, $_db.questionRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GeneratedExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$QuestionRecordsTableFilterComposer get questionId {
    final $$QuestionRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableFilterComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GeneratedExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$QuestionRecordsTableOrderingComposer get questionId {
    final $$QuestionRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GeneratedExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeneratedExercisesTable> {
  $$GeneratedExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$QuestionRecordsTableAnnotationComposer get questionId {
    final $$QuestionRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GeneratedExercisesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GeneratedExercisesTable,
    GeneratedExercise,
    $$GeneratedExercisesTableFilterComposer,
    $$GeneratedExercisesTableOrderingComposer,
    $$GeneratedExercisesTableAnnotationComposer,
    $$GeneratedExercisesTableCreateCompanionBuilder,
    $$GeneratedExercisesTableUpdateCompanionBuilder,
    (GeneratedExercise, $$GeneratedExercisesTableReferences),
    GeneratedExercise,
    PrefetchHooks Function({bool questionId})> {
  $$GeneratedExercisesTableTableManager(
      _$AppDatabase db, $GeneratedExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneratedExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneratedExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneratedExercisesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<String> question = const Value.absent(),
            Value<String> answer = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion(
            id: id,
            questionId: questionId,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionId,
            required String difficulty,
            required String question,
            required String answer,
            Value<String?> explanation = const Value.absent(),
            required DateTime createdAt,
          }) =>
              GeneratedExercisesCompanion.insert(
            id: id,
            questionId: questionId,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GeneratedExercisesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({questionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (questionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.questionId,
                    referencedTable: $$GeneratedExercisesTableReferences
                        ._questionIdTable(db),
                    referencedColumn: $$GeneratedExercisesTableReferences
                        ._questionIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GeneratedExercisesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GeneratedExercisesTable,
    GeneratedExercise,
    $$GeneratedExercisesTableFilterComposer,
    $$GeneratedExercisesTableOrderingComposer,
    $$GeneratedExercisesTableAnnotationComposer,
    $$GeneratedExercisesTableCreateCompanionBuilder,
    $$GeneratedExercisesTableUpdateCompanionBuilder,
    (GeneratedExercise, $$GeneratedExercisesTableReferences),
    GeneratedExercise,
    PrefetchHooks Function({bool questionId})>;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required String questionId,
  required DateTime reviewedAt,
  required bool wasCorrect,
  Value<int?> responseTimeMs,
  Value<String?> notes,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<String> questionId,
  Value<DateTime> reviewedAt,
  Value<bool> wasCorrect,
  Value<int?> responseTimeMs,
  Value<String?> notes,
});

final class $$ReviewLogsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLog> {
  $$ReviewLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $QuestionRecordsTable _questionIdTable(_$AppDatabase db) =>
      db.questionRecords.createAlias($_aliasNameGenerator(
          db.reviewLogs.questionId, db.questionRecords.id));

  $$QuestionRecordsTableProcessedTableManager get questionId {
    final $_column = $_itemColumn<String>('question_id')!;

    final manager =
        $$QuestionRecordsTableTableManager($_db, $_db.questionRecords)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get responseTimeMs => $composableBuilder(
      column: $table.responseTimeMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  $$QuestionRecordsTableFilterComposer get questionId {
    final $$QuestionRecordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableFilterComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get responseTimeMs => $composableBuilder(
      column: $table.responseTimeMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$QuestionRecordsTableOrderingComposer get questionId {
    final $$QuestionRecordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableOrderingComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => column);

  GeneratedColumn<int> get responseTimeMs => $composableBuilder(
      column: $table.responseTimeMs, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$QuestionRecordsTableAnnotationComposer get questionId {
    final $$QuestionRecordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questionRecords,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionRecordsTableAnnotationComposer(
              $db: $db,
              $table: $db.questionRecords,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, $$ReviewLogsTableReferences),
    ReviewLog,
    PrefetchHooks Function({bool questionId})> {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<DateTime> reviewedAt = const Value.absent(),
            Value<bool> wasCorrect = const Value.absent(),
            Value<int?> responseTimeMs = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              ReviewLogsCompanion(
            id: id,
            questionId: questionId,
            reviewedAt: reviewedAt,
            wasCorrect: wasCorrect,
            responseTimeMs: responseTimeMs,
            notes: notes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionId,
            required DateTime reviewedAt,
            required bool wasCorrect,
            Value<int?> responseTimeMs = const Value.absent(),
            Value<String?> notes = const Value.absent(),
          }) =>
              ReviewLogsCompanion.insert(
            id: id,
            questionId: questionId,
            reviewedAt: reviewedAt,
            wasCorrect: wasCorrect,
            responseTimeMs: responseTimeMs,
            notes: notes,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReviewLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({questionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (questionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.questionId,
                    referencedTable:
                        $$ReviewLogsTableReferences._questionIdTable(db),
                    referencedColumn:
                        $$ReviewLogsTableReferences._questionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReviewLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewLogsTable,
    ReviewLog,
    $$ReviewLogsTableFilterComposer,
    $$ReviewLogsTableOrderingComposer,
    $$ReviewLogsTableAnnotationComposer,
    $$ReviewLogsTableCreateCompanionBuilder,
    $$ReviewLogsTableUpdateCompanionBuilder,
    (ReviewLog, $$ReviewLogsTableReferences),
    ReviewLog,
    PrefetchHooks Function({bool questionId})>;
typedef $$SettingsEntriesTableCreateCompanionBuilder = SettingsEntriesCompanion
    Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SettingsEntriesTableUpdateCompanionBuilder = SettingsEntriesCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()> {
  $$SettingsEntriesTableTableManager(
      _$AppDatabase db, $SettingsEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsEntriesCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsEntriesTable,
    SettingsEntry,
    $$SettingsEntriesTableFilterComposer,
    $$SettingsEntriesTableOrderingComposer,
    $$SettingsEntriesTableAnnotationComposer,
    $$SettingsEntriesTableCreateCompanionBuilder,
    $$SettingsEntriesTableUpdateCompanionBuilder,
    (
      SettingsEntry,
      BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>
    ),
    SettingsEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$QuestionRecordsTableTableManager get questionRecords =>
      $$QuestionRecordsTableTableManager(_db, _db.questionRecords);
  $$GeneratedExercisesTableTableManager get generatedExercises =>
      $$GeneratedExercisesTableTableManager(_db, _db.generatedExercises);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
}
