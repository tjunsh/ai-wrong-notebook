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
  late final GeneratedColumn<String> customTags = GeneratedColumn<String>(
      'custom_tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _parentQuestionIdMeta =
      const VerificationMeta('parentQuestionId');
  @override
  late final GeneratedColumn<String> parentQuestionId = GeneratedColumn<String>(
      'parent_question_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _rootQuestionIdMeta =
      const VerificationMeta('rootQuestionId');
  @override
  late final GeneratedColumn<String> rootQuestionId = GeneratedColumn<String>(
      'root_question_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _splitOrderMeta =
      const VerificationMeta('splitOrder');
  @override
  late final GeneratedColumn<int> splitOrder = GeneratedColumn<int>(
      'split_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
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
        customTags,
        parentQuestionId,
        rootQuestionId,
        splitOrder
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
    if (data.containsKey('ai_tags')) {
      context.handle(_aiTagsMeta,
          aiTags.isAcceptableOrUnknown(data['ai_tags']!, _aiTagsMeta));
    }
    if (data.containsKey('ai_knowledge_points')) {
      context.handle(
          _aiKnowledgePointsMeta,
          aiKnowledgePoints.isAcceptableOrUnknown(
              data['ai_knowledge_points']!, _aiKnowledgePointsMeta));
    }
    if (data.containsKey('custom_tags')) {
      context.handle(
          _customTagsMeta,
          customTags.isAcceptableOrUnknown(
              data['custom_tags']!, _customTagsMeta));
    }
    if (data.containsKey('parent_question_id')) {
      context.handle(
          _parentQuestionIdMeta,
          parentQuestionId.isAcceptableOrUnknown(
              data['parent_question_id']!, _parentQuestionIdMeta));
    }
    if (data.containsKey('root_question_id')) {
      context.handle(
          _rootQuestionIdMeta,
          rootQuestionId.isAcceptableOrUnknown(
              data['root_question_id']!, _rootQuestionIdMeta));
    }
    if (data.containsKey('split_order')) {
      context.handle(
          _splitOrderMeta,
          splitOrder.isAcceptableOrUnknown(
              data['split_order']!, _splitOrderMeta));
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
      aiKnowledgePoints: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ai_knowledge_points'])!,
      customTags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_tags'])!,
      parentQuestionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parent_question_id']),
      rootQuestionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}root_question_id']),
      splitOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}split_order']),
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
  final String? parentQuestionId;
  final String? rootQuestionId;
  final int? splitOrder;
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
      required this.aiTags,
      required this.aiKnowledgePoints,
      required this.customTags,
      this.parentQuestionId,
      this.rootQuestionId,
      this.splitOrder});
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
    if (!nullToAbsent || parentQuestionId != null) {
      map['parent_question_id'] = Variable<String>(parentQuestionId);
    }
    if (!nullToAbsent || rootQuestionId != null) {
      map['root_question_id'] = Variable<String>(rootQuestionId);
    }
    if (!nullToAbsent || splitOrder != null) {
      map['split_order'] = Variable<int>(splitOrder);
    }
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
      aiKnowledgePoints: Value(aiKnowledgePoints),
      customTags: Value(customTags),
      parentQuestionId: parentQuestionId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentQuestionId),
      rootQuestionId: rootQuestionId == null && nullToAbsent
          ? const Value.absent()
          : Value(rootQuestionId),
      splitOrder: splitOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(splitOrder),
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
      aiKnowledgePoints: serializer.fromJson<String>(json['aiKnowledgePoints']),
      customTags: serializer.fromJson<String>(json['customTags']),
      parentQuestionId: serializer.fromJson<String?>(json['parentQuestionId']),
      rootQuestionId: serializer.fromJson<String?>(json['rootQuestionId']),
      splitOrder: serializer.fromJson<int?>(json['splitOrder']),
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
      'aiKnowledgePoints': serializer.toJson<String>(aiKnowledgePoints),
      'customTags': serializer.toJson<String>(customTags),
      'parentQuestionId': serializer.toJson<String?>(parentQuestionId),
      'rootQuestionId': serializer.toJson<String?>(rootQuestionId),
      'splitOrder': serializer.toJson<int?>(splitOrder),
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
          String? aiTags,
          String? aiKnowledgePoints,
          String? customTags,
          Value<String?> parentQuestionId = const Value.absent(),
          Value<String?> rootQuestionId = const Value.absent(),
          Value<int?> splitOrder = const Value.absent()}) =>
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
        aiKnowledgePoints: aiKnowledgePoints ?? this.aiKnowledgePoints,
        customTags: customTags ?? this.customTags,
        parentQuestionId: parentQuestionId.present
            ? parentQuestionId.value
            : this.parentQuestionId,
        rootQuestionId:
            rootQuestionId.present ? rootQuestionId.value : this.rootQuestionId,
        splitOrder: splitOrder.present ? splitOrder.value : this.splitOrder,
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
      aiKnowledgePoints: data.aiKnowledgePoints.present
          ? data.aiKnowledgePoints.value
          : this.aiKnowledgePoints,
      customTags:
          data.customTags.present ? data.customTags.value : this.customTags,
      parentQuestionId: data.parentQuestionId.present
          ? data.parentQuestionId.value
          : this.parentQuestionId,
      rootQuestionId: data.rootQuestionId.present
          ? data.rootQuestionId.value
          : this.rootQuestionId,
      splitOrder:
          data.splitOrder.present ? data.splitOrder.value : this.splitOrder,
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
          ..write('tags: $tags, ')
          ..write('aiTags: $aiTags, ')
          ..write('aiKnowledgePoints: $aiKnowledgePoints, ')
          ..write('customTags: $customTags, ')
          ..write('parentQuestionId: $parentQuestionId, ')
          ..write('rootQuestionId: $rootQuestionId, ')
          ..write('splitOrder: $splitOrder')
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
      customTags,
      parentQuestionId,
      rootQuestionId,
      splitOrder);
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
          other.customTags == this.customTags &&
          other.parentQuestionId == this.parentQuestionId &&
          other.rootQuestionId == this.rootQuestionId &&
          other.splitOrder == this.splitOrder);
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
  final Value<String?> parentQuestionId;
  final Value<String?> rootQuestionId;
  final Value<int?> splitOrder;
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
    this.parentQuestionId = const Value.absent(),
    this.rootQuestionId = const Value.absent(),
    this.splitOrder = const Value.absent(),
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
    this.parentQuestionId = const Value.absent(),
    this.rootQuestionId = const Value.absent(),
    this.splitOrder = const Value.absent(),
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
    Expression<String>? parentQuestionId,
    Expression<String>? rootQuestionId,
    Expression<int>? splitOrder,
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
      if (parentQuestionId != null) 'parent_question_id': parentQuestionId,
      if (rootQuestionId != null) 'root_question_id': rootQuestionId,
      if (splitOrder != null) 'split_order': splitOrder,
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
      Value<String?>? parentQuestionId,
      Value<String?>? rootQuestionId,
      Value<int?>? splitOrder,
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
      parentQuestionId: parentQuestionId ?? this.parentQuestionId,
      rootQuestionId: rootQuestionId ?? this.rootQuestionId,
      splitOrder: splitOrder ?? this.splitOrder,
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
    if (parentQuestionId.present) {
      map['parent_question_id'] = Variable<String>(parentQuestionId.value);
    }
    if (rootQuestionId.present) {
      map['root_question_id'] = Variable<String>(rootQuestionId.value);
    }
    if (splitOrder.present) {
      map['split_order'] = Variable<int>(splitOrder.value);
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
          ..write('parentQuestionId: $parentQuestionId, ')
          ..write('rootQuestionId: $rootQuestionId, ')
          ..write('splitOrder: $splitOrder, ')
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
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES question_records (id)'));
  static const VerificationMeta _generationModeMeta =
      const VerificationMeta('generationMode');
  @override
  late final GeneratedColumn<String> generationMode = GeneratedColumn<String>(
      'generation_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('practice'));
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
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
  static const VerificationMeta _optionsJsonMeta =
      const VerificationMeta('optionsJson');
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
      'options_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userAnswerMeta =
      const VerificationMeta('userAnswer');
  @override
  late final GeneratedColumn<String> userAnswer = GeneratedColumn<String>(
      'user_answer', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isCorrectMeta =
      const VerificationMeta('isCorrect');
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
      'is_correct', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_correct" IN (0, 1))'));
  static const VerificationMeta _roundIndexMeta =
      const VerificationMeta('roundIndex');
  @override
  late final GeneratedColumn<int> roundIndex = GeneratedColumn<int>(
      'round_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _roundTotalMeta =
      const VerificationMeta('roundTotal');
  @override
  late final GeneratedColumn<int> roundTotal = GeneratedColumn<int>(
      'round_total', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _roundGroupIdMeta =
      const VerificationMeta('roundGroupId');
  @override
  late final GeneratedColumn<String> roundGroupId = GeneratedColumn<String>(
      'round_group_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sourceExerciseIdMeta =
      const VerificationMeta('sourceExerciseId');
  @override
  late final GeneratedColumn<String> sourceExerciseId = GeneratedColumn<String>(
      'source_exercise_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _diagramDataJsonMeta =
      const VerificationMeta('diagramDataJson');
  @override
  late final GeneratedColumn<String> diagramDataJson = GeneratedColumn<String>(
      'diagram_data_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionId,
        generationMode,
        orderIndex,
        difficulty,
        question,
        answer,
        explanation,
        optionsJson,
        userAnswer,
        isCorrect,
        roundIndex,
        roundTotal,
        roundGroupId,
        sourceExerciseId,
        diagramDataJson,
        createdAt
      ];
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
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('generation_mode')) {
      context.handle(
          _generationModeMeta,
          generationMode.isAcceptableOrUnknown(
              data['generation_mode']!, _generationModeMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
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
    if (data.containsKey('options_json')) {
      context.handle(
          _optionsJsonMeta,
          optionsJson.isAcceptableOrUnknown(
              data['options_json']!, _optionsJsonMeta));
    }
    if (data.containsKey('user_answer')) {
      context.handle(
          _userAnswerMeta,
          userAnswer.isAcceptableOrUnknown(
              data['user_answer']!, _userAnswerMeta));
    }
    if (data.containsKey('is_correct')) {
      context.handle(_isCorrectMeta,
          isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta));
    }
    if (data.containsKey('round_index')) {
      context.handle(
          _roundIndexMeta,
          roundIndex.isAcceptableOrUnknown(
              data['round_index']!, _roundIndexMeta));
    }
    if (data.containsKey('round_total')) {
      context.handle(
          _roundTotalMeta,
          roundTotal.isAcceptableOrUnknown(
              data['round_total']!, _roundTotalMeta));
    }
    if (data.containsKey('round_group_id')) {
      context.handle(
          _roundGroupIdMeta,
          roundGroupId.isAcceptableOrUnknown(
              data['round_group_id']!, _roundGroupIdMeta));
    }
    if (data.containsKey('source_exercise_id')) {
      context.handle(
          _sourceExerciseIdMeta,
          sourceExerciseId.isAcceptableOrUnknown(
              data['source_exercise_id']!, _sourceExerciseIdMeta));
    }
    if (data.containsKey('diagram_data_json')) {
      context.handle(
          _diagramDataJsonMeta,
          diagramDataJson.isAcceptableOrUnknown(
              data['diagram_data_json']!, _diagramDataJsonMeta));
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
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      generationMode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}generation_mode'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index']),
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      question: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation']),
      optionsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}options_json']),
      userAnswer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_answer']),
      isCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_correct']),
      roundIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round_index']),
      roundTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}round_total']),
      roundGroupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}round_group_id']),
      sourceExerciseId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_exercise_id']),
      diagramDataJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}diagram_data_json']),
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
  final String id;
  final String questionId;
  final String generationMode;
  final int? orderIndex;
  final String difficulty;
  final String question;
  final String answer;
  final String? explanation;
  final String? optionsJson;
  final String? userAnswer;
  final bool? isCorrect;
  final int? roundIndex;
  final int? roundTotal;
  final String? roundGroupId;
  final String? sourceExerciseId;
  final String? diagramDataJson;
  final DateTime createdAt;
  const GeneratedExercise(
      {required this.id,
      required this.questionId,
      required this.generationMode,
      this.orderIndex,
      required this.difficulty,
      required this.question,
      required this.answer,
      this.explanation,
      this.optionsJson,
      this.userAnswer,
      this.isCorrect,
      this.roundIndex,
      this.roundTotal,
      this.roundGroupId,
      this.sourceExerciseId,
      this.diagramDataJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_id'] = Variable<String>(questionId);
    map['generation_mode'] = Variable<String>(generationMode);
    if (!nullToAbsent || orderIndex != null) {
      map['order_index'] = Variable<int>(orderIndex);
    }
    map['difficulty'] = Variable<String>(difficulty);
    map['question'] = Variable<String>(question);
    map['answer'] = Variable<String>(answer);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || optionsJson != null) {
      map['options_json'] = Variable<String>(optionsJson);
    }
    if (!nullToAbsent || userAnswer != null) {
      map['user_answer'] = Variable<String>(userAnswer);
    }
    if (!nullToAbsent || isCorrect != null) {
      map['is_correct'] = Variable<bool>(isCorrect);
    }
    if (!nullToAbsent || roundIndex != null) {
      map['round_index'] = Variable<int>(roundIndex);
    }
    if (!nullToAbsent || roundTotal != null) {
      map['round_total'] = Variable<int>(roundTotal);
    }
    if (!nullToAbsent || roundGroupId != null) {
      map['round_group_id'] = Variable<String>(roundGroupId);
    }
    if (!nullToAbsent || sourceExerciseId != null) {
      map['source_exercise_id'] = Variable<String>(sourceExerciseId);
    }
    if (!nullToAbsent || diagramDataJson != null) {
      map['diagram_data_json'] = Variable<String>(diagramDataJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GeneratedExercisesCompanion toCompanion(bool nullToAbsent) {
    return GeneratedExercisesCompanion(
      id: Value(id),
      questionId: Value(questionId),
      generationMode: Value(generationMode),
      orderIndex: orderIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(orderIndex),
      difficulty: Value(difficulty),
      question: Value(question),
      answer: Value(answer),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      optionsJson: optionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(optionsJson),
      userAnswer: userAnswer == null && nullToAbsent
          ? const Value.absent()
          : Value(userAnswer),
      isCorrect: isCorrect == null && nullToAbsent
          ? const Value.absent()
          : Value(isCorrect),
      roundIndex: roundIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(roundIndex),
      roundTotal: roundTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(roundTotal),
      roundGroupId: roundGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(roundGroupId),
      sourceExerciseId: sourceExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceExerciseId),
      diagramDataJson: diagramDataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(diagramDataJson),
      createdAt: Value(createdAt),
    );
  }

  factory GeneratedExercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneratedExercise(
      id: serializer.fromJson<String>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      generationMode: serializer.fromJson<String>(json['generationMode']),
      orderIndex: serializer.fromJson<int?>(json['orderIndex']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      question: serializer.fromJson<String>(json['question']),
      answer: serializer.fromJson<String>(json['answer']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      optionsJson: serializer.fromJson<String?>(json['optionsJson']),
      userAnswer: serializer.fromJson<String?>(json['userAnswer']),
      isCorrect: serializer.fromJson<bool?>(json['isCorrect']),
      roundIndex: serializer.fromJson<int?>(json['roundIndex']),
      roundTotal: serializer.fromJson<int?>(json['roundTotal']),
      roundGroupId: serializer.fromJson<String?>(json['roundGroupId']),
      sourceExerciseId: serializer.fromJson<String?>(json['sourceExerciseId']),
      diagramDataJson: serializer.fromJson<String?>(json['diagramDataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionId': serializer.toJson<String>(questionId),
      'generationMode': serializer.toJson<String>(generationMode),
      'orderIndex': serializer.toJson<int?>(orderIndex),
      'difficulty': serializer.toJson<String>(difficulty),
      'question': serializer.toJson<String>(question),
      'answer': serializer.toJson<String>(answer),
      'explanation': serializer.toJson<String?>(explanation),
      'optionsJson': serializer.toJson<String?>(optionsJson),
      'userAnswer': serializer.toJson<String?>(userAnswer),
      'isCorrect': serializer.toJson<bool?>(isCorrect),
      'roundIndex': serializer.toJson<int?>(roundIndex),
      'roundTotal': serializer.toJson<int?>(roundTotal),
      'roundGroupId': serializer.toJson<String?>(roundGroupId),
      'sourceExerciseId': serializer.toJson<String?>(sourceExerciseId),
      'diagramDataJson': serializer.toJson<String?>(diagramDataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GeneratedExercise copyWith(
          {String? id,
          String? questionId,
          String? generationMode,
          Value<int?> orderIndex = const Value.absent(),
          String? difficulty,
          String? question,
          String? answer,
          Value<String?> explanation = const Value.absent(),
          Value<String?> optionsJson = const Value.absent(),
          Value<String?> userAnswer = const Value.absent(),
          Value<bool?> isCorrect = const Value.absent(),
          Value<int?> roundIndex = const Value.absent(),
          Value<int?> roundTotal = const Value.absent(),
          Value<String?> roundGroupId = const Value.absent(),
          Value<String?> sourceExerciseId = const Value.absent(),
          Value<String?> diagramDataJson = const Value.absent(),
          DateTime? createdAt}) =>
      GeneratedExercise(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        generationMode: generationMode ?? this.generationMode,
        orderIndex: orderIndex.present ? orderIndex.value : this.orderIndex,
        difficulty: difficulty ?? this.difficulty,
        question: question ?? this.question,
        answer: answer ?? this.answer,
        explanation: explanation.present ? explanation.value : this.explanation,
        optionsJson: optionsJson.present ? optionsJson.value : this.optionsJson,
        userAnswer: userAnswer.present ? userAnswer.value : this.userAnswer,
        isCorrect: isCorrect.present ? isCorrect.value : this.isCorrect,
        roundIndex: roundIndex.present ? roundIndex.value : this.roundIndex,
        roundTotal: roundTotal.present ? roundTotal.value : this.roundTotal,
        roundGroupId:
            roundGroupId.present ? roundGroupId.value : this.roundGroupId,
        sourceExerciseId: sourceExerciseId.present
            ? sourceExerciseId.value
            : this.sourceExerciseId,
        diagramDataJson: diagramDataJson.present
            ? diagramDataJson.value
            : this.diagramDataJson,
        createdAt: createdAt ?? this.createdAt,
      );
  GeneratedExercise copyWithCompanion(GeneratedExercisesCompanion data) {
    return GeneratedExercise(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      generationMode: data.generationMode.present
          ? data.generationMode.value
          : this.generationMode,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      question: data.question.present ? data.question.value : this.question,
      answer: data.answer.present ? data.answer.value : this.answer,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      optionsJson:
          data.optionsJson.present ? data.optionsJson.value : this.optionsJson,
      userAnswer:
          data.userAnswer.present ? data.userAnswer.value : this.userAnswer,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      roundIndex:
          data.roundIndex.present ? data.roundIndex.value : this.roundIndex,
      roundTotal:
          data.roundTotal.present ? data.roundTotal.value : this.roundTotal,
      roundGroupId: data.roundGroupId.present
          ? data.roundGroupId.value
          : this.roundGroupId,
      sourceExerciseId: data.sourceExerciseId.present
          ? data.sourceExerciseId.value
          : this.sourceExerciseId,
      diagramDataJson: data.diagramDataJson.present
          ? data.diagramDataJson.value
          : this.diagramDataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercise(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('generationMode: $generationMode, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('difficulty: $difficulty, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('explanation: $explanation, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('roundIndex: $roundIndex, ')
          ..write('roundTotal: $roundTotal, ')
          ..write('roundGroupId: $roundGroupId, ')
          ..write('sourceExerciseId: $sourceExerciseId, ')
          ..write('diagramDataJson: $diagramDataJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      questionId,
      generationMode,
      orderIndex,
      difficulty,
      question,
      answer,
      explanation,
      optionsJson,
      userAnswer,
      isCorrect,
      roundIndex,
      roundTotal,
      roundGroupId,
      sourceExerciseId,
      diagramDataJson,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedExercise &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.generationMode == this.generationMode &&
          other.orderIndex == this.orderIndex &&
          other.difficulty == this.difficulty &&
          other.question == this.question &&
          other.answer == this.answer &&
          other.explanation == this.explanation &&
          other.optionsJson == this.optionsJson &&
          other.userAnswer == this.userAnswer &&
          other.isCorrect == this.isCorrect &&
          other.roundIndex == this.roundIndex &&
          other.roundTotal == this.roundTotal &&
          other.roundGroupId == this.roundGroupId &&
          other.sourceExerciseId == this.sourceExerciseId &&
          other.diagramDataJson == this.diagramDataJson &&
          other.createdAt == this.createdAt);
}

class GeneratedExercisesCompanion extends UpdateCompanion<GeneratedExercise> {
  final Value<String> id;
  final Value<String> questionId;
  final Value<String> generationMode;
  final Value<int?> orderIndex;
  final Value<String> difficulty;
  final Value<String> question;
  final Value<String> answer;
  final Value<String?> explanation;
  final Value<String?> optionsJson;
  final Value<String?> userAnswer;
  final Value<bool?> isCorrect;
  final Value<int?> roundIndex;
  final Value<int?> roundTotal;
  final Value<String?> roundGroupId;
  final Value<String?> sourceExerciseId;
  final Value<String?> diagramDataJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GeneratedExercisesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.generationMode = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.question = const Value.absent(),
    this.answer = const Value.absent(),
    this.explanation = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.roundIndex = const Value.absent(),
    this.roundTotal = const Value.absent(),
    this.roundGroupId = const Value.absent(),
    this.sourceExerciseId = const Value.absent(),
    this.diagramDataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneratedExercisesCompanion.insert({
    required String id,
    required String questionId,
    this.generationMode = const Value.absent(),
    this.orderIndex = const Value.absent(),
    required String difficulty,
    required String question,
    required String answer,
    this.explanation = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.userAnswer = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.roundIndex = const Value.absent(),
    this.roundTotal = const Value.absent(),
    this.roundGroupId = const Value.absent(),
    this.sourceExerciseId = const Value.absent(),
    this.diagramDataJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionId = Value(questionId),
        difficulty = Value(difficulty),
        question = Value(question),
        answer = Value(answer),
        createdAt = Value(createdAt);
  static Insertable<GeneratedExercise> custom({
    Expression<String>? id,
    Expression<String>? questionId,
    Expression<String>? generationMode,
    Expression<int>? orderIndex,
    Expression<String>? difficulty,
    Expression<String>? question,
    Expression<String>? answer,
    Expression<String>? explanation,
    Expression<String>? optionsJson,
    Expression<String>? userAnswer,
    Expression<bool>? isCorrect,
    Expression<int>? roundIndex,
    Expression<int>? roundTotal,
    Expression<String>? roundGroupId,
    Expression<String>? sourceExerciseId,
    Expression<String>? diagramDataJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (generationMode != null) 'generation_mode': generationMode,
      if (orderIndex != null) 'order_index': orderIndex,
      if (difficulty != null) 'difficulty': difficulty,
      if (question != null) 'question': question,
      if (answer != null) 'answer': answer,
      if (explanation != null) 'explanation': explanation,
      if (optionsJson != null) 'options_json': optionsJson,
      if (userAnswer != null) 'user_answer': userAnswer,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (roundIndex != null) 'round_index': roundIndex,
      if (roundTotal != null) 'round_total': roundTotal,
      if (roundGroupId != null) 'round_group_id': roundGroupId,
      if (sourceExerciseId != null) 'source_exercise_id': sourceExerciseId,
      if (diagramDataJson != null) 'diagram_data_json': diagramDataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneratedExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionId,
      Value<String>? generationMode,
      Value<int?>? orderIndex,
      Value<String>? difficulty,
      Value<String>? question,
      Value<String>? answer,
      Value<String?>? explanation,
      Value<String?>? optionsJson,
      Value<String?>? userAnswer,
      Value<bool?>? isCorrect,
      Value<int?>? roundIndex,
      Value<int?>? roundTotal,
      Value<String?>? roundGroupId,
      Value<String?>? sourceExerciseId,
      Value<String?>? diagramDataJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return GeneratedExercisesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      generationMode: generationMode ?? this.generationMode,
      orderIndex: orderIndex ?? this.orderIndex,
      difficulty: difficulty ?? this.difficulty,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      optionsJson: optionsJson ?? this.optionsJson,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      roundIndex: roundIndex ?? this.roundIndex,
      roundTotal: roundTotal ?? this.roundTotal,
      roundGroupId: roundGroupId ?? this.roundGroupId,
      sourceExerciseId: sourceExerciseId ?? this.sourceExerciseId,
      diagramDataJson: diagramDataJson ?? this.diagramDataJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (generationMode.present) {
      map['generation_mode'] = Variable<String>(generationMode.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
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
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (userAnswer.present) {
      map['user_answer'] = Variable<String>(userAnswer.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (roundIndex.present) {
      map['round_index'] = Variable<int>(roundIndex.value);
    }
    if (roundTotal.present) {
      map['round_total'] = Variable<int>(roundTotal.value);
    }
    if (roundGroupId.present) {
      map['round_group_id'] = Variable<String>(roundGroupId.value);
    }
    if (sourceExerciseId.present) {
      map['source_exercise_id'] = Variable<String>(sourceExerciseId.value);
    }
    if (diagramDataJson.present) {
      map['diagram_data_json'] = Variable<String>(diagramDataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedExercisesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('generationMode: $generationMode, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('difficulty: $difficulty, ')
          ..write('question: $question, ')
          ..write('answer: $answer, ')
          ..write('explanation: $explanation, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('userAnswer: $userAnswer, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('roundIndex: $roundIndex, ')
          ..write('roundTotal: $roundTotal, ')
          ..write('roundGroupId: $roundGroupId, ')
          ..write('sourceExerciseId: $sourceExerciseId, ')
          ..write('diagramDataJson: $diagramDataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
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

class $AiConversationMessagesTable extends AiConversationMessages
    with TableInfo<$AiConversationMessagesTable, AiConversationMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiConversationMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
      'question_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES question_records (id)'));
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, questionId, role, content, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_conversation_messages';
  @override
  VerificationContext validateIntegrity(
      Insertable<AiConversationMessage> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
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
  AiConversationMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiConversationMessage(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_id'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AiConversationMessagesTable createAlias(String alias) {
    return $AiConversationMessagesTable(attachedDatabase, alias);
  }
}

class AiConversationMessage extends DataClass
    implements Insertable<AiConversationMessage> {
  final String id;
  final String questionId;
  final String role;
  final String content;
  final DateTime createdAt;
  const AiConversationMessage(
      {required this.id,
      required this.questionId,
      required this.role,
      required this.content,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['question_id'] = Variable<String>(questionId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiConversationMessagesCompanion toCompanion(bool nullToAbsent) {
    return AiConversationMessagesCompanion(
      id: Value(id),
      questionId: Value(questionId),
      role: Value(role),
      content: Value(content),
      createdAt: Value(createdAt),
    );
  }

  factory AiConversationMessage.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiConversationMessage(
      id: serializer.fromJson<String>(json['id']),
      questionId: serializer.fromJson<String>(json['questionId']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'questionId': serializer.toJson<String>(questionId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiConversationMessage copyWith(
          {String? id,
          String? questionId,
          String? role,
          String? content,
          DateTime? createdAt}) =>
      AiConversationMessage(
        id: id ?? this.id,
        questionId: questionId ?? this.questionId,
        role: role ?? this.role,
        content: content ?? this.content,
        createdAt: createdAt ?? this.createdAt,
      );
  AiConversationMessage copyWithCompanion(
      AiConversationMessagesCompanion data) {
    return AiConversationMessage(
      id: data.id.present ? data.id.value : this.id,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationMessage(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionId, role, content, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiConversationMessage &&
          other.id == this.id &&
          other.questionId == this.questionId &&
          other.role == this.role &&
          other.content == this.content &&
          other.createdAt == this.createdAt);
}

class AiConversationMessagesCompanion
    extends UpdateCompanion<AiConversationMessage> {
  final Value<String> id;
  final Value<String> questionId;
  final Value<String> role;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AiConversationMessagesCompanion({
    this.id = const Value.absent(),
    this.questionId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiConversationMessagesCompanion.insert({
    required String id,
    required String questionId,
    required String role,
    required String content,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        questionId = Value(questionId),
        role = Value(role),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<AiConversationMessage> custom({
    Expression<String>? id,
    Expression<String>? questionId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionId != null) 'question_id': questionId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiConversationMessagesCompanion copyWith(
      {Value<String>? id,
      Value<String>? questionId,
      Value<String>? role,
      Value<String>? content,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AiConversationMessagesCompanion(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationMessagesCompanion(')
          ..write('id: $id, ')
          ..write('questionId: $questionId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalysisJobsTable extends AnalysisJobs
    with TableInfo<$AnalysisJobsTable, AnalysisJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalysisJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idempotencyKeyMeta =
      const VerificationMeta('idempotencyKey');
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
      'idempotency_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _parentQuestionIdMeta =
      const VerificationMeta('parentQuestionId');
  @override
  late final GeneratedColumn<String> parentQuestionId = GeneratedColumn<String>(
      'parent_question_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskTypeMeta =
      const VerificationMeta('taskType');
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
      'task_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workloadProfileMeta =
      const VerificationMeta('workloadProfile');
  @override
  late final GeneratedColumn<String> workloadProfile = GeneratedColumn<String>(
      'workload_profile', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requiredCapabilitiesJsonMeta =
      const VerificationMeta('requiredCapabilitiesJson');
  @override
  late final GeneratedColumn<String> requiredCapabilitiesJson =
      GeneratedColumn<String>('required_capabilities_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qualityPolicyMeta =
      const VerificationMeta('qualityPolicy');
  @override
  late final GeneratedColumn<String> qualityPolicy = GeneratedColumn<String>(
      'quality_policy', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _queuePriorityMeta =
      const VerificationMeta('queuePriority');
  @override
  late final GeneratedColumn<String> queuePriority = GeneratedColumn<String>(
      'queue_priority', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dependencyJobIdsJsonMeta =
      const VerificationMeta('dependencyJobIdsJson');
  @override
  late final GeneratedColumn<String> dependencyJobIdsJson =
      GeneratedColumn<String>('dependency_job_ids_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelRoleMeta =
      const VerificationMeta('modelRole');
  @override
  late final GeneratedColumn<String> modelRole = GeneratedColumn<String>(
      'model_role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestedModelClassMeta =
      const VerificationMeta('requestedModelClass');
  @override
  late final GeneratedColumn<String> requestedModelClass =
      GeneratedColumn<String>('requested_model_class', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _requestedModelRoleMeta =
      const VerificationMeta('requestedModelRole');
  @override
  late final GeneratedColumn<String> requestedModelRole =
      GeneratedColumn<String>('requested_model_role', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _resolvedRouteIdMeta =
      const VerificationMeta('resolvedRouteId');
  @override
  late final GeneratedColumn<String> resolvedRouteId = GeneratedColumn<String>(
      'resolved_route_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerConfigIdMeta =
      const VerificationMeta('providerConfigId');
  @override
  late final GeneratedColumn<String> providerConfigId = GeneratedColumn<String>(
      'provider_config_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modelNameMeta =
      const VerificationMeta('modelName');
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
      'model_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _promptVersionMeta =
      const VerificationMeta('promptVersion');
  @override
  late final GeneratedColumn<String> promptVersion = GeneratedColumn<String>(
      'prompt_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _verifierIsIndependentMeta =
      const VerificationMeta('verifierIsIndependent');
  @override
  late final GeneratedColumn<bool> verifierIsIndependent =
      GeneratedColumn<bool>('verifier_is_independent', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("verifier_is_independent" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _attemptCountMeta =
      const VerificationMeta('attemptCount');
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
      'attempt_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _maxAttemptsMeta =
      const VerificationMeta('maxAttempts');
  @override
  late final GeneratedColumn<int> maxAttempts = GeneratedColumn<int>(
      'max_attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(2));
  static const VerificationMeta _resultJsonMeta =
      const VerificationMeta('resultJson');
  @override
  late final GeneratedColumn<String> resultJson = GeneratedColumn<String>(
      'result_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _progressJsonMeta =
      const VerificationMeta('progressJson');
  @override
  late final GeneratedColumn<String> progressJson = GeneratedColumn<String>(
      'progress_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        idempotencyKey,
        parentQuestionId,
        taskType,
        workloadProfile,
        requiredCapabilitiesJson,
        qualityPolicy,
        queuePriority,
        dependencyJobIdsJson,
        modelRole,
        requestedModelClass,
        requestedModelRole,
        resolvedRouteId,
        providerConfigId,
        modelName,
        promptVersion,
        verifierIsIndependent,
        payloadJson,
        status,
        attemptCount,
        maxAttempts,
        resultJson,
        errorMessage,
        progressJson,
        createdAt,
        updatedAt,
        startedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analysis_jobs';
  @override
  VerificationContext validateIntegrity(Insertable<AnalysisJob> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
          _idempotencyKeyMeta,
          idempotencyKey.isAcceptableOrUnknown(
              data['idempotency_key']!, _idempotencyKeyMeta));
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('parent_question_id')) {
      context.handle(
          _parentQuestionIdMeta,
          parentQuestionId.isAcceptableOrUnknown(
              data['parent_question_id']!, _parentQuestionIdMeta));
    } else if (isInserting) {
      context.missing(_parentQuestionIdMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(_taskTypeMeta,
          taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta));
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('workload_profile')) {
      context.handle(
          _workloadProfileMeta,
          workloadProfile.isAcceptableOrUnknown(
              data['workload_profile']!, _workloadProfileMeta));
    } else if (isInserting) {
      context.missing(_workloadProfileMeta);
    }
    if (data.containsKey('required_capabilities_json')) {
      context.handle(
          _requiredCapabilitiesJsonMeta,
          requiredCapabilitiesJson.isAcceptableOrUnknown(
              data['required_capabilities_json']!,
              _requiredCapabilitiesJsonMeta));
    } else if (isInserting) {
      context.missing(_requiredCapabilitiesJsonMeta);
    }
    if (data.containsKey('quality_policy')) {
      context.handle(
          _qualityPolicyMeta,
          qualityPolicy.isAcceptableOrUnknown(
              data['quality_policy']!, _qualityPolicyMeta));
    } else if (isInserting) {
      context.missing(_qualityPolicyMeta);
    }
    if (data.containsKey('queue_priority')) {
      context.handle(
          _queuePriorityMeta,
          queuePriority.isAcceptableOrUnknown(
              data['queue_priority']!, _queuePriorityMeta));
    } else if (isInserting) {
      context.missing(_queuePriorityMeta);
    }
    if (data.containsKey('dependency_job_ids_json')) {
      context.handle(
          _dependencyJobIdsJsonMeta,
          dependencyJobIdsJson.isAcceptableOrUnknown(
              data['dependency_job_ids_json']!, _dependencyJobIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_dependencyJobIdsJsonMeta);
    }
    if (data.containsKey('model_role')) {
      context.handle(_modelRoleMeta,
          modelRole.isAcceptableOrUnknown(data['model_role']!, _modelRoleMeta));
    } else if (isInserting) {
      context.missing(_modelRoleMeta);
    }
    if (data.containsKey('requested_model_class')) {
      context.handle(
          _requestedModelClassMeta,
          requestedModelClass.isAcceptableOrUnknown(
              data['requested_model_class']!, _requestedModelClassMeta));
    } else if (isInserting) {
      context.missing(_requestedModelClassMeta);
    }
    if (data.containsKey('requested_model_role')) {
      context.handle(
          _requestedModelRoleMeta,
          requestedModelRole.isAcceptableOrUnknown(
              data['requested_model_role']!, _requestedModelRoleMeta));
    } else if (isInserting) {
      context.missing(_requestedModelRoleMeta);
    }
    if (data.containsKey('resolved_route_id')) {
      context.handle(
          _resolvedRouteIdMeta,
          resolvedRouteId.isAcceptableOrUnknown(
              data['resolved_route_id']!, _resolvedRouteIdMeta));
    } else if (isInserting) {
      context.missing(_resolvedRouteIdMeta);
    }
    if (data.containsKey('provider_config_id')) {
      context.handle(
          _providerConfigIdMeta,
          providerConfigId.isAcceptableOrUnknown(
              data['provider_config_id']!, _providerConfigIdMeta));
    } else if (isInserting) {
      context.missing(_providerConfigIdMeta);
    }
    if (data.containsKey('model_name')) {
      context.handle(_modelNameMeta,
          modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta));
    } else if (isInserting) {
      context.missing(_modelNameMeta);
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
          _promptVersionMeta,
          promptVersion.isAcceptableOrUnknown(
              data['prompt_version']!, _promptVersionMeta));
    } else if (isInserting) {
      context.missing(_promptVersionMeta);
    }
    if (data.containsKey('verifier_is_independent')) {
      context.handle(
          _verifierIsIndependentMeta,
          verifierIsIndependent.isAcceptableOrUnknown(
              data['verifier_is_independent']!, _verifierIsIndependentMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
          _attemptCountMeta,
          attemptCount.isAcceptableOrUnknown(
              data['attempt_count']!, _attemptCountMeta));
    }
    if (data.containsKey('max_attempts')) {
      context.handle(
          _maxAttemptsMeta,
          maxAttempts.isAcceptableOrUnknown(
              data['max_attempts']!, _maxAttemptsMeta));
    }
    if (data.containsKey('result_json')) {
      context.handle(
          _resultJsonMeta,
          resultJson.isAcceptableOrUnknown(
              data['result_json']!, _resultJsonMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('progress_json')) {
      context.handle(
          _progressJsonMeta,
          progressJson.isAcceptableOrUnknown(
              data['progress_json']!, _progressJsonMeta));
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
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalysisJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalysisJob(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      idempotencyKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}idempotency_key'])!,
      parentQuestionId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parent_question_id'])!,
      taskType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_type'])!,
      workloadProfile: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}workload_profile'])!,
      requiredCapabilitiesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}required_capabilities_json'])!,
      qualityPolicy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quality_policy'])!,
      queuePriority: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}queue_priority'])!,
      dependencyJobIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}dependency_job_ids_json'])!,
      modelRole: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_role'])!,
      requestedModelClass: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}requested_model_class'])!,
      requestedModelRole: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}requested_model_role'])!,
      resolvedRouteId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}resolved_route_id'])!,
      providerConfigId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}provider_config_id'])!,
      modelName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}model_name'])!,
      promptVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_version'])!,
      verifierIsIndependent: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}verifier_is_independent'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      attemptCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempt_count'])!,
      maxAttempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_attempts'])!,
      resultJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}result_json']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      progressJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}progress_json']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $AnalysisJobsTable createAlias(String alias) {
    return $AnalysisJobsTable(attachedDatabase, alias);
  }
}

class AnalysisJob extends DataClass implements Insertable<AnalysisJob> {
  final String id;
  final String idempotencyKey;
  final String parentQuestionId;
  final String taskType;
  final String workloadProfile;
  final String requiredCapabilitiesJson;
  final String qualityPolicy;
  final String queuePriority;
  final String dependencyJobIdsJson;
  final String modelRole;
  final String requestedModelClass;
  final String requestedModelRole;
  final String resolvedRouteId;
  final String providerConfigId;
  final String modelName;
  final String promptVersion;
  final bool verifierIsIndependent;
  final String payloadJson;
  final String status;
  final int attemptCount;
  final int maxAttempts;
  final String? resultJson;
  final String? errorMessage;
  final String? progressJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  const AnalysisJob(
      {required this.id,
      required this.idempotencyKey,
      required this.parentQuestionId,
      required this.taskType,
      required this.workloadProfile,
      required this.requiredCapabilitiesJson,
      required this.qualityPolicy,
      required this.queuePriority,
      required this.dependencyJobIdsJson,
      required this.modelRole,
      required this.requestedModelClass,
      required this.requestedModelRole,
      required this.resolvedRouteId,
      required this.providerConfigId,
      required this.modelName,
      required this.promptVersion,
      required this.verifierIsIndependent,
      required this.payloadJson,
      required this.status,
      required this.attemptCount,
      required this.maxAttempts,
      this.resultJson,
      this.errorMessage,
      this.progressJson,
      required this.createdAt,
      required this.updatedAt,
      this.startedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['parent_question_id'] = Variable<String>(parentQuestionId);
    map['task_type'] = Variable<String>(taskType);
    map['workload_profile'] = Variable<String>(workloadProfile);
    map['required_capabilities_json'] =
        Variable<String>(requiredCapabilitiesJson);
    map['quality_policy'] = Variable<String>(qualityPolicy);
    map['queue_priority'] = Variable<String>(queuePriority);
    map['dependency_job_ids_json'] = Variable<String>(dependencyJobIdsJson);
    map['model_role'] = Variable<String>(modelRole);
    map['requested_model_class'] = Variable<String>(requestedModelClass);
    map['requested_model_role'] = Variable<String>(requestedModelRole);
    map['resolved_route_id'] = Variable<String>(resolvedRouteId);
    map['provider_config_id'] = Variable<String>(providerConfigId);
    map['model_name'] = Variable<String>(modelName);
    map['prompt_version'] = Variable<String>(promptVersion);
    map['verifier_is_independent'] = Variable<bool>(verifierIsIndependent);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['max_attempts'] = Variable<int>(maxAttempts);
    if (!nullToAbsent || resultJson != null) {
      map['result_json'] = Variable<String>(resultJson);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || progressJson != null) {
      map['progress_json'] = Variable<String>(progressJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  AnalysisJobsCompanion toCompanion(bool nullToAbsent) {
    return AnalysisJobsCompanion(
      id: Value(id),
      idempotencyKey: Value(idempotencyKey),
      parentQuestionId: Value(parentQuestionId),
      taskType: Value(taskType),
      workloadProfile: Value(workloadProfile),
      requiredCapabilitiesJson: Value(requiredCapabilitiesJson),
      qualityPolicy: Value(qualityPolicy),
      queuePriority: Value(queuePriority),
      dependencyJobIdsJson: Value(dependencyJobIdsJson),
      modelRole: Value(modelRole),
      requestedModelClass: Value(requestedModelClass),
      requestedModelRole: Value(requestedModelRole),
      resolvedRouteId: Value(resolvedRouteId),
      providerConfigId: Value(providerConfigId),
      modelName: Value(modelName),
      promptVersion: Value(promptVersion),
      verifierIsIndependent: Value(verifierIsIndependent),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attemptCount: Value(attemptCount),
      maxAttempts: Value(maxAttempts),
      resultJson: resultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(resultJson),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      progressJson: progressJson == null && nullToAbsent
          ? const Value.absent()
          : Value(progressJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory AnalysisJob.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalysisJob(
      id: serializer.fromJson<String>(json['id']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      parentQuestionId: serializer.fromJson<String>(json['parentQuestionId']),
      taskType: serializer.fromJson<String>(json['taskType']),
      workloadProfile: serializer.fromJson<String>(json['workloadProfile']),
      requiredCapabilitiesJson:
          serializer.fromJson<String>(json['requiredCapabilitiesJson']),
      qualityPolicy: serializer.fromJson<String>(json['qualityPolicy']),
      queuePriority: serializer.fromJson<String>(json['queuePriority']),
      dependencyJobIdsJson:
          serializer.fromJson<String>(json['dependencyJobIdsJson']),
      modelRole: serializer.fromJson<String>(json['modelRole']),
      requestedModelClass:
          serializer.fromJson<String>(json['requestedModelClass']),
      requestedModelRole:
          serializer.fromJson<String>(json['requestedModelRole']),
      resolvedRouteId: serializer.fromJson<String>(json['resolvedRouteId']),
      providerConfigId: serializer.fromJson<String>(json['providerConfigId']),
      modelName: serializer.fromJson<String>(json['modelName']),
      promptVersion: serializer.fromJson<String>(json['promptVersion']),
      verifierIsIndependent:
          serializer.fromJson<bool>(json['verifierIsIndependent']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      maxAttempts: serializer.fromJson<int>(json['maxAttempts']),
      resultJson: serializer.fromJson<String?>(json['resultJson']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      progressJson: serializer.fromJson<String?>(json['progressJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'parentQuestionId': serializer.toJson<String>(parentQuestionId),
      'taskType': serializer.toJson<String>(taskType),
      'workloadProfile': serializer.toJson<String>(workloadProfile),
      'requiredCapabilitiesJson':
          serializer.toJson<String>(requiredCapabilitiesJson),
      'qualityPolicy': serializer.toJson<String>(qualityPolicy),
      'queuePriority': serializer.toJson<String>(queuePriority),
      'dependencyJobIdsJson': serializer.toJson<String>(dependencyJobIdsJson),
      'modelRole': serializer.toJson<String>(modelRole),
      'requestedModelClass': serializer.toJson<String>(requestedModelClass),
      'requestedModelRole': serializer.toJson<String>(requestedModelRole),
      'resolvedRouteId': serializer.toJson<String>(resolvedRouteId),
      'providerConfigId': serializer.toJson<String>(providerConfigId),
      'modelName': serializer.toJson<String>(modelName),
      'promptVersion': serializer.toJson<String>(promptVersion),
      'verifierIsIndependent': serializer.toJson<bool>(verifierIsIndependent),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'maxAttempts': serializer.toJson<int>(maxAttempts),
      'resultJson': serializer.toJson<String?>(resultJson),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'progressJson': serializer.toJson<String?>(progressJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  AnalysisJob copyWith(
          {String? id,
          String? idempotencyKey,
          String? parentQuestionId,
          String? taskType,
          String? workloadProfile,
          String? requiredCapabilitiesJson,
          String? qualityPolicy,
          String? queuePriority,
          String? dependencyJobIdsJson,
          String? modelRole,
          String? requestedModelClass,
          String? requestedModelRole,
          String? resolvedRouteId,
          String? providerConfigId,
          String? modelName,
          String? promptVersion,
          bool? verifierIsIndependent,
          String? payloadJson,
          String? status,
          int? attemptCount,
          int? maxAttempts,
          Value<String?> resultJson = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          Value<String?> progressJson = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent()}) =>
      AnalysisJob(
        id: id ?? this.id,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        parentQuestionId: parentQuestionId ?? this.parentQuestionId,
        taskType: taskType ?? this.taskType,
        workloadProfile: workloadProfile ?? this.workloadProfile,
        requiredCapabilitiesJson:
            requiredCapabilitiesJson ?? this.requiredCapabilitiesJson,
        qualityPolicy: qualityPolicy ?? this.qualityPolicy,
        queuePriority: queuePriority ?? this.queuePriority,
        dependencyJobIdsJson: dependencyJobIdsJson ?? this.dependencyJobIdsJson,
        modelRole: modelRole ?? this.modelRole,
        requestedModelClass: requestedModelClass ?? this.requestedModelClass,
        requestedModelRole: requestedModelRole ?? this.requestedModelRole,
        resolvedRouteId: resolvedRouteId ?? this.resolvedRouteId,
        providerConfigId: providerConfigId ?? this.providerConfigId,
        modelName: modelName ?? this.modelName,
        promptVersion: promptVersion ?? this.promptVersion,
        verifierIsIndependent:
            verifierIsIndependent ?? this.verifierIsIndependent,
        payloadJson: payloadJson ?? this.payloadJson,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        resultJson: resultJson.present ? resultJson.value : this.resultJson,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        progressJson:
            progressJson.present ? progressJson.value : this.progressJson,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  AnalysisJob copyWithCompanion(AnalysisJobsCompanion data) {
    return AnalysisJob(
      id: data.id.present ? data.id.value : this.id,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      parentQuestionId: data.parentQuestionId.present
          ? data.parentQuestionId.value
          : this.parentQuestionId,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      workloadProfile: data.workloadProfile.present
          ? data.workloadProfile.value
          : this.workloadProfile,
      requiredCapabilitiesJson: data.requiredCapabilitiesJson.present
          ? data.requiredCapabilitiesJson.value
          : this.requiredCapabilitiesJson,
      qualityPolicy: data.qualityPolicy.present
          ? data.qualityPolicy.value
          : this.qualityPolicy,
      queuePriority: data.queuePriority.present
          ? data.queuePriority.value
          : this.queuePriority,
      dependencyJobIdsJson: data.dependencyJobIdsJson.present
          ? data.dependencyJobIdsJson.value
          : this.dependencyJobIdsJson,
      modelRole: data.modelRole.present ? data.modelRole.value : this.modelRole,
      requestedModelClass: data.requestedModelClass.present
          ? data.requestedModelClass.value
          : this.requestedModelClass,
      requestedModelRole: data.requestedModelRole.present
          ? data.requestedModelRole.value
          : this.requestedModelRole,
      resolvedRouteId: data.resolvedRouteId.present
          ? data.resolvedRouteId.value
          : this.resolvedRouteId,
      providerConfigId: data.providerConfigId.present
          ? data.providerConfigId.value
          : this.providerConfigId,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      verifierIsIndependent: data.verifierIsIndependent.present
          ? data.verifierIsIndependent.value
          : this.verifierIsIndependent,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      maxAttempts:
          data.maxAttempts.present ? data.maxAttempts.value : this.maxAttempts,
      resultJson:
          data.resultJson.present ? data.resultJson.value : this.resultJson,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      progressJson: data.progressJson.present
          ? data.progressJson.value
          : this.progressJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisJob(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('parentQuestionId: $parentQuestionId, ')
          ..write('taskType: $taskType, ')
          ..write('workloadProfile: $workloadProfile, ')
          ..write('requiredCapabilitiesJson: $requiredCapabilitiesJson, ')
          ..write('qualityPolicy: $qualityPolicy, ')
          ..write('queuePriority: $queuePriority, ')
          ..write('dependencyJobIdsJson: $dependencyJobIdsJson, ')
          ..write('modelRole: $modelRole, ')
          ..write('requestedModelClass: $requestedModelClass, ')
          ..write('requestedModelRole: $requestedModelRole, ')
          ..write('resolvedRouteId: $resolvedRouteId, ')
          ..write('providerConfigId: $providerConfigId, ')
          ..write('modelName: $modelName, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('verifierIsIndependent: $verifierIsIndependent, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('resultJson: $resultJson, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('progressJson: $progressJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        idempotencyKey,
        parentQuestionId,
        taskType,
        workloadProfile,
        requiredCapabilitiesJson,
        qualityPolicy,
        queuePriority,
        dependencyJobIdsJson,
        modelRole,
        requestedModelClass,
        requestedModelRole,
        resolvedRouteId,
        providerConfigId,
        modelName,
        promptVersion,
        verifierIsIndependent,
        payloadJson,
        status,
        attemptCount,
        maxAttempts,
        resultJson,
        errorMessage,
        progressJson,
        createdAt,
        updatedAt,
        startedAt,
        completedAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalysisJob &&
          other.id == this.id &&
          other.idempotencyKey == this.idempotencyKey &&
          other.parentQuestionId == this.parentQuestionId &&
          other.taskType == this.taskType &&
          other.workloadProfile == this.workloadProfile &&
          other.requiredCapabilitiesJson == this.requiredCapabilitiesJson &&
          other.qualityPolicy == this.qualityPolicy &&
          other.queuePriority == this.queuePriority &&
          other.dependencyJobIdsJson == this.dependencyJobIdsJson &&
          other.modelRole == this.modelRole &&
          other.requestedModelClass == this.requestedModelClass &&
          other.requestedModelRole == this.requestedModelRole &&
          other.resolvedRouteId == this.resolvedRouteId &&
          other.providerConfigId == this.providerConfigId &&
          other.modelName == this.modelName &&
          other.promptVersion == this.promptVersion &&
          other.verifierIsIndependent == this.verifierIsIndependent &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.maxAttempts == this.maxAttempts &&
          other.resultJson == this.resultJson &&
          other.errorMessage == this.errorMessage &&
          other.progressJson == this.progressJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class AnalysisJobsCompanion extends UpdateCompanion<AnalysisJob> {
  final Value<String> id;
  final Value<String> idempotencyKey;
  final Value<String> parentQuestionId;
  final Value<String> taskType;
  final Value<String> workloadProfile;
  final Value<String> requiredCapabilitiesJson;
  final Value<String> qualityPolicy;
  final Value<String> queuePriority;
  final Value<String> dependencyJobIdsJson;
  final Value<String> modelRole;
  final Value<String> requestedModelClass;
  final Value<String> requestedModelRole;
  final Value<String> resolvedRouteId;
  final Value<String> providerConfigId;
  final Value<String> modelName;
  final Value<String> promptVersion;
  final Value<bool> verifierIsIndependent;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<int> maxAttempts;
  final Value<String?> resultJson;
  final Value<String?> errorMessage;
  final Value<String?> progressJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const AnalysisJobsCompanion({
    this.id = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.parentQuestionId = const Value.absent(),
    this.taskType = const Value.absent(),
    this.workloadProfile = const Value.absent(),
    this.requiredCapabilitiesJson = const Value.absent(),
    this.qualityPolicy = const Value.absent(),
    this.queuePriority = const Value.absent(),
    this.dependencyJobIdsJson = const Value.absent(),
    this.modelRole = const Value.absent(),
    this.requestedModelClass = const Value.absent(),
    this.requestedModelRole = const Value.absent(),
    this.resolvedRouteId = const Value.absent(),
    this.providerConfigId = const Value.absent(),
    this.modelName = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.verifierIsIndependent = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.progressJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalysisJobsCompanion.insert({
    required String id,
    required String idempotencyKey,
    required String parentQuestionId,
    required String taskType,
    required String workloadProfile,
    required String requiredCapabilitiesJson,
    required String qualityPolicy,
    required String queuePriority,
    required String dependencyJobIdsJson,
    required String modelRole,
    required String requestedModelClass,
    required String requestedModelRole,
    required String resolvedRouteId,
    required String providerConfigId,
    required String modelName,
    required String promptVersion,
    this.verifierIsIndependent = const Value.absent(),
    required String payloadJson,
    required String status,
    this.attemptCount = const Value.absent(),
    this.maxAttempts = const Value.absent(),
    this.resultJson = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.progressJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        idempotencyKey = Value(idempotencyKey),
        parentQuestionId = Value(parentQuestionId),
        taskType = Value(taskType),
        workloadProfile = Value(workloadProfile),
        requiredCapabilitiesJson = Value(requiredCapabilitiesJson),
        qualityPolicy = Value(qualityPolicy),
        queuePriority = Value(queuePriority),
        dependencyJobIdsJson = Value(dependencyJobIdsJson),
        modelRole = Value(modelRole),
        requestedModelClass = Value(requestedModelClass),
        requestedModelRole = Value(requestedModelRole),
        resolvedRouteId = Value(resolvedRouteId),
        providerConfigId = Value(providerConfigId),
        modelName = Value(modelName),
        promptVersion = Value(promptVersion),
        payloadJson = Value(payloadJson),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<AnalysisJob> custom({
    Expression<String>? id,
    Expression<String>? idempotencyKey,
    Expression<String>? parentQuestionId,
    Expression<String>? taskType,
    Expression<String>? workloadProfile,
    Expression<String>? requiredCapabilitiesJson,
    Expression<String>? qualityPolicy,
    Expression<String>? queuePriority,
    Expression<String>? dependencyJobIdsJson,
    Expression<String>? modelRole,
    Expression<String>? requestedModelClass,
    Expression<String>? requestedModelRole,
    Expression<String>? resolvedRouteId,
    Expression<String>? providerConfigId,
    Expression<String>? modelName,
    Expression<String>? promptVersion,
    Expression<bool>? verifierIsIndependent,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<int>? maxAttempts,
    Expression<String>? resultJson,
    Expression<String>? errorMessage,
    Expression<String>? progressJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (parentQuestionId != null) 'parent_question_id': parentQuestionId,
      if (taskType != null) 'task_type': taskType,
      if (workloadProfile != null) 'workload_profile': workloadProfile,
      if (requiredCapabilitiesJson != null)
        'required_capabilities_json': requiredCapabilitiesJson,
      if (qualityPolicy != null) 'quality_policy': qualityPolicy,
      if (queuePriority != null) 'queue_priority': queuePriority,
      if (dependencyJobIdsJson != null)
        'dependency_job_ids_json': dependencyJobIdsJson,
      if (modelRole != null) 'model_role': modelRole,
      if (requestedModelClass != null)
        'requested_model_class': requestedModelClass,
      if (requestedModelRole != null)
        'requested_model_role': requestedModelRole,
      if (resolvedRouteId != null) 'resolved_route_id': resolvedRouteId,
      if (providerConfigId != null) 'provider_config_id': providerConfigId,
      if (modelName != null) 'model_name': modelName,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (verifierIsIndependent != null)
        'verifier_is_independent': verifierIsIndependent,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (maxAttempts != null) 'max_attempts': maxAttempts,
      if (resultJson != null) 'result_json': resultJson,
      if (errorMessage != null) 'error_message': errorMessage,
      if (progressJson != null) 'progress_json': progressJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalysisJobsCompanion copyWith(
      {Value<String>? id,
      Value<String>? idempotencyKey,
      Value<String>? parentQuestionId,
      Value<String>? taskType,
      Value<String>? workloadProfile,
      Value<String>? requiredCapabilitiesJson,
      Value<String>? qualityPolicy,
      Value<String>? queuePriority,
      Value<String>? dependencyJobIdsJson,
      Value<String>? modelRole,
      Value<String>? requestedModelClass,
      Value<String>? requestedModelRole,
      Value<String>? resolvedRouteId,
      Value<String>? providerConfigId,
      Value<String>? modelName,
      Value<String>? promptVersion,
      Value<bool>? verifierIsIndependent,
      Value<String>? payloadJson,
      Value<String>? status,
      Value<int>? attemptCount,
      Value<int>? maxAttempts,
      Value<String?>? resultJson,
      Value<String?>? errorMessage,
      Value<String?>? progressJson,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? completedAt,
      Value<int>? rowid}) {
    return AnalysisJobsCompanion(
      id: id ?? this.id,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      parentQuestionId: parentQuestionId ?? this.parentQuestionId,
      taskType: taskType ?? this.taskType,
      workloadProfile: workloadProfile ?? this.workloadProfile,
      requiredCapabilitiesJson:
          requiredCapabilitiesJson ?? this.requiredCapabilitiesJson,
      qualityPolicy: qualityPolicy ?? this.qualityPolicy,
      queuePriority: queuePriority ?? this.queuePriority,
      dependencyJobIdsJson: dependencyJobIdsJson ?? this.dependencyJobIdsJson,
      modelRole: modelRole ?? this.modelRole,
      requestedModelClass: requestedModelClass ?? this.requestedModelClass,
      requestedModelRole: requestedModelRole ?? this.requestedModelRole,
      resolvedRouteId: resolvedRouteId ?? this.resolvedRouteId,
      providerConfigId: providerConfigId ?? this.providerConfigId,
      modelName: modelName ?? this.modelName,
      promptVersion: promptVersion ?? this.promptVersion,
      verifierIsIndependent:
          verifierIsIndependent ?? this.verifierIsIndependent,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      resultJson: resultJson ?? this.resultJson,
      errorMessage: errorMessage ?? this.errorMessage,
      progressJson: progressJson ?? this.progressJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (parentQuestionId.present) {
      map['parent_question_id'] = Variable<String>(parentQuestionId.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (workloadProfile.present) {
      map['workload_profile'] = Variable<String>(workloadProfile.value);
    }
    if (requiredCapabilitiesJson.present) {
      map['required_capabilities_json'] =
          Variable<String>(requiredCapabilitiesJson.value);
    }
    if (qualityPolicy.present) {
      map['quality_policy'] = Variable<String>(qualityPolicy.value);
    }
    if (queuePriority.present) {
      map['queue_priority'] = Variable<String>(queuePriority.value);
    }
    if (dependencyJobIdsJson.present) {
      map['dependency_job_ids_json'] =
          Variable<String>(dependencyJobIdsJson.value);
    }
    if (modelRole.present) {
      map['model_role'] = Variable<String>(modelRole.value);
    }
    if (requestedModelClass.present) {
      map['requested_model_class'] =
          Variable<String>(requestedModelClass.value);
    }
    if (requestedModelRole.present) {
      map['requested_model_role'] = Variable<String>(requestedModelRole.value);
    }
    if (resolvedRouteId.present) {
      map['resolved_route_id'] = Variable<String>(resolvedRouteId.value);
    }
    if (providerConfigId.present) {
      map['provider_config_id'] = Variable<String>(providerConfigId.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<String>(promptVersion.value);
    }
    if (verifierIsIndependent.present) {
      map['verifier_is_independent'] =
          Variable<bool>(verifierIsIndependent.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (maxAttempts.present) {
      map['max_attempts'] = Variable<int>(maxAttempts.value);
    }
    if (resultJson.present) {
      map['result_json'] = Variable<String>(resultJson.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (progressJson.present) {
      map['progress_json'] = Variable<String>(progressJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalysisJobsCompanion(')
          ..write('id: $id, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('parentQuestionId: $parentQuestionId, ')
          ..write('taskType: $taskType, ')
          ..write('workloadProfile: $workloadProfile, ')
          ..write('requiredCapabilitiesJson: $requiredCapabilitiesJson, ')
          ..write('qualityPolicy: $qualityPolicy, ')
          ..write('queuePriority: $queuePriority, ')
          ..write('dependencyJobIdsJson: $dependencyJobIdsJson, ')
          ..write('modelRole: $modelRole, ')
          ..write('requestedModelClass: $requestedModelClass, ')
          ..write('requestedModelRole: $requestedModelRole, ')
          ..write('resolvedRouteId: $resolvedRouteId, ')
          ..write('providerConfigId: $providerConfigId, ')
          ..write('modelName: $modelName, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('verifierIsIndependent: $verifierIsIndependent, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('maxAttempts: $maxAttempts, ')
          ..write('resultJson: $resultJson, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('progressJson: $progressJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
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
  late final $AiConversationMessagesTable aiConversationMessages =
      $AiConversationMessagesTable(this);
  late final $AnalysisJobsTable analysisJobs = $AnalysisJobsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        questionRecords,
        generatedExercises,
        reviewLogs,
        settingsEntries,
        aiConversationMessages,
        analysisJobs
      ];
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
  Value<String> aiTags,
  Value<String> aiKnowledgePoints,
  Value<String> customTags,
  Value<String?> parentQuestionId,
  Value<String?> rootQuestionId,
  Value<int?> splitOrder,
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
  Value<String> aiTags,
  Value<String> aiKnowledgePoints,
  Value<String> customTags,
  Value<String?> parentQuestionId,
  Value<String?> rootQuestionId,
  Value<int?> splitOrder,
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

  static MultiTypedResultKey<$AiConversationMessagesTable,
      List<AiConversationMessage>> _aiConversationMessagesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.aiConversationMessages,
          aliasName: $_aliasNameGenerator(
              db.questionRecords.id, db.aiConversationMessages.questionId));

  $$AiConversationMessagesTableProcessedTableManager
      get aiConversationMessagesRefs {
    final manager = $$AiConversationMessagesTableTableManager(
            $_db, $_db.aiConversationMessages)
        .filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_aiConversationMessagesRefsTable($_db));
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

  ColumnFilters<String> get aiTags => $composableBuilder(
      column: $table.aiTags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiKnowledgePoints => $composableBuilder(
      column: $table.aiKnowledgePoints,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customTags => $composableBuilder(
      column: $table.customTags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentQuestionId => $composableBuilder(
      column: $table.parentQuestionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootQuestionId => $composableBuilder(
      column: $table.rootQuestionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get splitOrder => $composableBuilder(
      column: $table.splitOrder, builder: (column) => ColumnFilters(column));

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

  Expression<bool> aiConversationMessagesRefs(
      Expression<bool> Function($$AiConversationMessagesTableFilterComposer f)
          f) {
    final $$AiConversationMessagesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aiConversationMessages,
            getReferencedColumn: (t) => t.questionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AiConversationMessagesTableFilterComposer(
                  $db: $db,
                  $table: $db.aiConversationMessages,
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

  ColumnOrderings<String> get aiTags => $composableBuilder(
      column: $table.aiTags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiKnowledgePoints => $composableBuilder(
      column: $table.aiKnowledgePoints,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customTags => $composableBuilder(
      column: $table.customTags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentQuestionId => $composableBuilder(
      column: $table.parentQuestionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootQuestionId => $composableBuilder(
      column: $table.rootQuestionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get splitOrder => $composableBuilder(
      column: $table.splitOrder, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get aiTags =>
      $composableBuilder(column: $table.aiTags, builder: (column) => column);

  GeneratedColumn<String> get aiKnowledgePoints => $composableBuilder(
      column: $table.aiKnowledgePoints, builder: (column) => column);

  GeneratedColumn<String> get customTags => $composableBuilder(
      column: $table.customTags, builder: (column) => column);

  GeneratedColumn<String> get parentQuestionId => $composableBuilder(
      column: $table.parentQuestionId, builder: (column) => column);

  GeneratedColumn<String> get rootQuestionId => $composableBuilder(
      column: $table.rootQuestionId, builder: (column) => column);

  GeneratedColumn<int> get splitOrder => $composableBuilder(
      column: $table.splitOrder, builder: (column) => column);

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

  Expression<T> aiConversationMessagesRefs<T extends Object>(
      Expression<T> Function($$AiConversationMessagesTableAnnotationComposer a)
          f) {
    final $$AiConversationMessagesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.aiConversationMessages,
            getReferencedColumn: (t) => t.questionId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AiConversationMessagesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.aiConversationMessages,
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
        {bool generatedExercisesRefs,
        bool reviewLogsRefs,
        bool aiConversationMessagesRefs})> {
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
            Value<String> aiTags = const Value.absent(),
            Value<String> aiKnowledgePoints = const Value.absent(),
            Value<String> customTags = const Value.absent(),
            Value<String?> parentQuestionId = const Value.absent(),
            Value<String?> rootQuestionId = const Value.absent(),
            Value<int?> splitOrder = const Value.absent(),
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
            aiTags: aiTags,
            aiKnowledgePoints: aiKnowledgePoints,
            customTags: customTags,
            parentQuestionId: parentQuestionId,
            rootQuestionId: rootQuestionId,
            splitOrder: splitOrder,
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
            Value<String> aiTags = const Value.absent(),
            Value<String> aiKnowledgePoints = const Value.absent(),
            Value<String> customTags = const Value.absent(),
            Value<String?> parentQuestionId = const Value.absent(),
            Value<String?> rootQuestionId = const Value.absent(),
            Value<int?> splitOrder = const Value.absent(),
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
            aiTags: aiTags,
            aiKnowledgePoints: aiKnowledgePoints,
            customTags: customTags,
            parentQuestionId: parentQuestionId,
            rootQuestionId: rootQuestionId,
            splitOrder: splitOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuestionRecordsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {generatedExercisesRefs = false,
              reviewLogsRefs = false,
              aiConversationMessagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (generatedExercisesRefs) db.generatedExercises,
                if (reviewLogsRefs) db.reviewLogs,
                if (aiConversationMessagesRefs) db.aiConversationMessages
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
                        typedResults: items),
                  if (aiConversationMessagesRefs)
                    await $_getPrefetchedData<QuestionRecord,
                            $QuestionRecordsTable, AiConversationMessage>(
                        currentTable: table,
                        referencedTable: $$QuestionRecordsTableReferences
                            ._aiConversationMessagesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionRecordsTableReferences(db, table, p0)
                                .aiConversationMessagesRefs,
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
    PrefetchHooks Function(
        {bool generatedExercisesRefs,
        bool reviewLogsRefs,
        bool aiConversationMessagesRefs})>;
typedef $$GeneratedExercisesTableCreateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  required String id,
  required String questionId,
  Value<String> generationMode,
  Value<int?> orderIndex,
  required String difficulty,
  required String question,
  required String answer,
  Value<String?> explanation,
  Value<String?> optionsJson,
  Value<String?> userAnswer,
  Value<bool?> isCorrect,
  Value<int?> roundIndex,
  Value<int?> roundTotal,
  Value<String?> roundGroupId,
  Value<String?> sourceExerciseId,
  Value<String?> diagramDataJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$GeneratedExercisesTableUpdateCompanionBuilder
    = GeneratedExercisesCompanion Function({
  Value<String> id,
  Value<String> questionId,
  Value<String> generationMode,
  Value<int?> orderIndex,
  Value<String> difficulty,
  Value<String> question,
  Value<String> answer,
  Value<String?> explanation,
  Value<String?> optionsJson,
  Value<String?> userAnswer,
  Value<bool?> isCorrect,
  Value<int?> roundIndex,
  Value<int?> roundTotal,
  Value<String?> roundGroupId,
  Value<String?> sourceExerciseId,
  Value<String?> diagramDataJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
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
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get generationMode => $composableBuilder(
      column: $table.generationMode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userAnswer => $composableBuilder(
      column: $table.userAnswer, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get roundIndex => $composableBuilder(
      column: $table.roundIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get roundTotal => $composableBuilder(
      column: $table.roundTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get roundGroupId => $composableBuilder(
      column: $table.roundGroupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceExerciseId => $composableBuilder(
      column: $table.sourceExerciseId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get diagramDataJson => $composableBuilder(
      column: $table.diagramDataJson,
      builder: (column) => ColumnFilters(column));

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
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get generationMode => $composableBuilder(
      column: $table.generationMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get question => $composableBuilder(
      column: $table.question, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userAnswer => $composableBuilder(
      column: $table.userAnswer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
      column: $table.isCorrect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get roundIndex => $composableBuilder(
      column: $table.roundIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get roundTotal => $composableBuilder(
      column: $table.roundTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get roundGroupId => $composableBuilder(
      column: $table.roundGroupId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceExerciseId => $composableBuilder(
      column: $table.sourceExerciseId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get diagramDataJson => $composableBuilder(
      column: $table.diagramDataJson,
      builder: (column) => ColumnOrderings(column));

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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get generationMode => $composableBuilder(
      column: $table.generationMode, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get question =>
      $composableBuilder(column: $table.question, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
      column: $table.optionsJson, builder: (column) => column);

  GeneratedColumn<String> get userAnswer => $composableBuilder(
      column: $table.userAnswer, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<int> get roundIndex => $composableBuilder(
      column: $table.roundIndex, builder: (column) => column);

  GeneratedColumn<int> get roundTotal => $composableBuilder(
      column: $table.roundTotal, builder: (column) => column);

  GeneratedColumn<String> get roundGroupId => $composableBuilder(
      column: $table.roundGroupId, builder: (column) => column);

  GeneratedColumn<String> get sourceExerciseId => $composableBuilder(
      column: $table.sourceExerciseId, builder: (column) => column);

  GeneratedColumn<String> get diagramDataJson => $composableBuilder(
      column: $table.diagramDataJson, builder: (column) => column);

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
            Value<String> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> generationMode = const Value.absent(),
            Value<int?> orderIndex = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<String> question = const Value.absent(),
            Value<String> answer = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<String?> optionsJson = const Value.absent(),
            Value<String?> userAnswer = const Value.absent(),
            Value<bool?> isCorrect = const Value.absent(),
            Value<int?> roundIndex = const Value.absent(),
            Value<int?> roundTotal = const Value.absent(),
            Value<String?> roundGroupId = const Value.absent(),
            Value<String?> sourceExerciseId = const Value.absent(),
            Value<String?> diagramDataJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion(
            id: id,
            questionId: questionId,
            generationMode: generationMode,
            orderIndex: orderIndex,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation,
            optionsJson: optionsJson,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            roundIndex: roundIndex,
            roundTotal: roundTotal,
            roundGroupId: roundGroupId,
            sourceExerciseId: sourceExerciseId,
            diagramDataJson: diagramDataJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionId,
            Value<String> generationMode = const Value.absent(),
            Value<int?> orderIndex = const Value.absent(),
            required String difficulty,
            required String question,
            required String answer,
            Value<String?> explanation = const Value.absent(),
            Value<String?> optionsJson = const Value.absent(),
            Value<String?> userAnswer = const Value.absent(),
            Value<bool?> isCorrect = const Value.absent(),
            Value<int?> roundIndex = const Value.absent(),
            Value<int?> roundTotal = const Value.absent(),
            Value<String?> roundGroupId = const Value.absent(),
            Value<String?> sourceExerciseId = const Value.absent(),
            Value<String?> diagramDataJson = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedExercisesCompanion.insert(
            id: id,
            questionId: questionId,
            generationMode: generationMode,
            orderIndex: orderIndex,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation,
            optionsJson: optionsJson,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            roundIndex: roundIndex,
            roundTotal: roundTotal,
            roundGroupId: roundGroupId,
            sourceExerciseId: sourceExerciseId,
            diagramDataJson: diagramDataJson,
            createdAt: createdAt,
            rowid: rowid,
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
typedef $$AiConversationMessagesTableCreateCompanionBuilder
    = AiConversationMessagesCompanion Function({
  required String id,
  required String questionId,
  required String role,
  required String content,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AiConversationMessagesTableUpdateCompanionBuilder
    = AiConversationMessagesCompanion Function({
  Value<String> id,
  Value<String> questionId,
  Value<String> role,
  Value<String> content,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$AiConversationMessagesTableReferences extends BaseReferences<
    _$AppDatabase, $AiConversationMessagesTable, AiConversationMessage> {
  $$AiConversationMessagesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $QuestionRecordsTable _questionIdTable(_$AppDatabase db) =>
      db.questionRecords.createAlias($_aliasNameGenerator(
          db.aiConversationMessages.questionId, db.questionRecords.id));

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

class $$AiConversationMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $AiConversationMessagesTable> {
  $$AiConversationMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

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

class $$AiConversationMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $AiConversationMessagesTable> {
  $$AiConversationMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

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

class $$AiConversationMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiConversationMessagesTable> {
  $$AiConversationMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

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

class $$AiConversationMessagesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiConversationMessagesTable,
    AiConversationMessage,
    $$AiConversationMessagesTableFilterComposer,
    $$AiConversationMessagesTableOrderingComposer,
    $$AiConversationMessagesTableAnnotationComposer,
    $$AiConversationMessagesTableCreateCompanionBuilder,
    $$AiConversationMessagesTableUpdateCompanionBuilder,
    (AiConversationMessage, $$AiConversationMessagesTableReferences),
    AiConversationMessage,
    PrefetchHooks Function({bool questionId})> {
  $$AiConversationMessagesTableTableManager(
      _$AppDatabase db, $AiConversationMessagesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiConversationMessagesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$AiConversationMessagesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiConversationMessagesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> questionId = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiConversationMessagesCompanion(
            id: id,
            questionId: questionId,
            role: role,
            content: content,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String questionId,
            required String role,
            required String content,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiConversationMessagesCompanion.insert(
            id: id,
            questionId: questionId,
            role: role,
            content: content,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AiConversationMessagesTableReferences(db, table, e)
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
                    referencedTable: $$AiConversationMessagesTableReferences
                        ._questionIdTable(db),
                    referencedColumn: $$AiConversationMessagesTableReferences
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

typedef $$AiConversationMessagesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AiConversationMessagesTable,
        AiConversationMessage,
        $$AiConversationMessagesTableFilterComposer,
        $$AiConversationMessagesTableOrderingComposer,
        $$AiConversationMessagesTableAnnotationComposer,
        $$AiConversationMessagesTableCreateCompanionBuilder,
        $$AiConversationMessagesTableUpdateCompanionBuilder,
        (AiConversationMessage, $$AiConversationMessagesTableReferences),
        AiConversationMessage,
        PrefetchHooks Function({bool questionId})>;
typedef $$AnalysisJobsTableCreateCompanionBuilder = AnalysisJobsCompanion
    Function({
  required String id,
  required String idempotencyKey,
  required String parentQuestionId,
  required String taskType,
  required String workloadProfile,
  required String requiredCapabilitiesJson,
  required String qualityPolicy,
  required String queuePriority,
  required String dependencyJobIdsJson,
  required String modelRole,
  required String requestedModelClass,
  required String requestedModelRole,
  required String resolvedRouteId,
  required String providerConfigId,
  required String modelName,
  required String promptVersion,
  Value<bool> verifierIsIndependent,
  required String payloadJson,
  required String status,
  Value<int> attemptCount,
  Value<int> maxAttempts,
  Value<String?> resultJson,
  Value<String?> errorMessage,
  Value<String?> progressJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$AnalysisJobsTableUpdateCompanionBuilder = AnalysisJobsCompanion
    Function({
  Value<String> id,
  Value<String> idempotencyKey,
  Value<String> parentQuestionId,
  Value<String> taskType,
  Value<String> workloadProfile,
  Value<String> requiredCapabilitiesJson,
  Value<String> qualityPolicy,
  Value<String> queuePriority,
  Value<String> dependencyJobIdsJson,
  Value<String> modelRole,
  Value<String> requestedModelClass,
  Value<String> requestedModelRole,
  Value<String> resolvedRouteId,
  Value<String> providerConfigId,
  Value<String> modelName,
  Value<String> promptVersion,
  Value<bool> verifierIsIndependent,
  Value<String> payloadJson,
  Value<String> status,
  Value<int> attemptCount,
  Value<int> maxAttempts,
  Value<String?> resultJson,
  Value<String?> errorMessage,
  Value<String?> progressJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

class $$AnalysisJobsTableFilterComposer
    extends Composer<_$AppDatabase, $AnalysisJobsTable> {
  $$AnalysisJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentQuestionId => $composableBuilder(
      column: $table.parentQuestionId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workloadProfile => $composableBuilder(
      column: $table.workloadProfile,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requiredCapabilitiesJson => $composableBuilder(
      column: $table.requiredCapabilitiesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qualityPolicy => $composableBuilder(
      column: $table.qualityPolicy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queuePriority => $composableBuilder(
      column: $table.queuePriority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dependencyJobIdsJson => $composableBuilder(
      column: $table.dependencyJobIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelRole => $composableBuilder(
      column: $table.modelRole, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestedModelClass => $composableBuilder(
      column: $table.requestedModelClass,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get requestedModelRole => $composableBuilder(
      column: $table.requestedModelRole,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resolvedRouteId => $composableBuilder(
      column: $table.resolvedRouteId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerConfigId => $composableBuilder(
      column: $table.providerConfigId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modelName => $composableBuilder(
      column: $table.modelName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptVersion => $composableBuilder(
      column: $table.promptVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get verifierIsIndependent => $composableBuilder(
      column: $table.verifierIsIndependent,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxAttempts => $composableBuilder(
      column: $table.maxAttempts, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resultJson => $composableBuilder(
      column: $table.resultJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get progressJson => $composableBuilder(
      column: $table.progressJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$AnalysisJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalysisJobsTable> {
  $$AnalysisJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentQuestionId => $composableBuilder(
      column: $table.parentQuestionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get taskType => $composableBuilder(
      column: $table.taskType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workloadProfile => $composableBuilder(
      column: $table.workloadProfile,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requiredCapabilitiesJson => $composableBuilder(
      column: $table.requiredCapabilitiesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qualityPolicy => $composableBuilder(
      column: $table.qualityPolicy,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queuePriority => $composableBuilder(
      column: $table.queuePriority,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dependencyJobIdsJson => $composableBuilder(
      column: $table.dependencyJobIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelRole => $composableBuilder(
      column: $table.modelRole, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestedModelClass => $composableBuilder(
      column: $table.requestedModelClass,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get requestedModelRole => $composableBuilder(
      column: $table.requestedModelRole,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resolvedRouteId => $composableBuilder(
      column: $table.resolvedRouteId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerConfigId => $composableBuilder(
      column: $table.providerConfigId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modelName => $composableBuilder(
      column: $table.modelName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptVersion => $composableBuilder(
      column: $table.promptVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get verifierIsIndependent => $composableBuilder(
      column: $table.verifierIsIndependent,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxAttempts => $composableBuilder(
      column: $table.maxAttempts, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resultJson => $composableBuilder(
      column: $table.resultJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get progressJson => $composableBuilder(
      column: $table.progressJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$AnalysisJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalysisJobsTable> {
  $$AnalysisJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
      column: $table.idempotencyKey, builder: (column) => column);

  GeneratedColumn<String> get parentQuestionId => $composableBuilder(
      column: $table.parentQuestionId, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get workloadProfile => $composableBuilder(
      column: $table.workloadProfile, builder: (column) => column);

  GeneratedColumn<String> get requiredCapabilitiesJson => $composableBuilder(
      column: $table.requiredCapabilitiesJson, builder: (column) => column);

  GeneratedColumn<String> get qualityPolicy => $composableBuilder(
      column: $table.qualityPolicy, builder: (column) => column);

  GeneratedColumn<String> get queuePriority => $composableBuilder(
      column: $table.queuePriority, builder: (column) => column);

  GeneratedColumn<String> get dependencyJobIdsJson => $composableBuilder(
      column: $table.dependencyJobIdsJson, builder: (column) => column);

  GeneratedColumn<String> get modelRole =>
      $composableBuilder(column: $table.modelRole, builder: (column) => column);

  GeneratedColumn<String> get requestedModelClass => $composableBuilder(
      column: $table.requestedModelClass, builder: (column) => column);

  GeneratedColumn<String> get requestedModelRole => $composableBuilder(
      column: $table.requestedModelRole, builder: (column) => column);

  GeneratedColumn<String> get resolvedRouteId => $composableBuilder(
      column: $table.resolvedRouteId, builder: (column) => column);

  GeneratedColumn<String> get providerConfigId => $composableBuilder(
      column: $table.providerConfigId, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get promptVersion => $composableBuilder(
      column: $table.promptVersion, builder: (column) => column);

  GeneratedColumn<bool> get verifierIsIndependent => $composableBuilder(
      column: $table.verifierIsIndependent, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
      column: $table.attemptCount, builder: (column) => column);

  GeneratedColumn<int> get maxAttempts => $composableBuilder(
      column: $table.maxAttempts, builder: (column) => column);

  GeneratedColumn<String> get resultJson => $composableBuilder(
      column: $table.resultJson, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<String> get progressJson => $composableBuilder(
      column: $table.progressJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$AnalysisJobsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnalysisJobsTable,
    AnalysisJob,
    $$AnalysisJobsTableFilterComposer,
    $$AnalysisJobsTableOrderingComposer,
    $$AnalysisJobsTableAnnotationComposer,
    $$AnalysisJobsTableCreateCompanionBuilder,
    $$AnalysisJobsTableUpdateCompanionBuilder,
    (
      AnalysisJob,
      BaseReferences<_$AppDatabase, $AnalysisJobsTable, AnalysisJob>
    ),
    AnalysisJob,
    PrefetchHooks Function()> {
  $$AnalysisJobsTableTableManager(_$AppDatabase db, $AnalysisJobsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalysisJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalysisJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalysisJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> idempotencyKey = const Value.absent(),
            Value<String> parentQuestionId = const Value.absent(),
            Value<String> taskType = const Value.absent(),
            Value<String> workloadProfile = const Value.absent(),
            Value<String> requiredCapabilitiesJson = const Value.absent(),
            Value<String> qualityPolicy = const Value.absent(),
            Value<String> queuePriority = const Value.absent(),
            Value<String> dependencyJobIdsJson = const Value.absent(),
            Value<String> modelRole = const Value.absent(),
            Value<String> requestedModelClass = const Value.absent(),
            Value<String> requestedModelRole = const Value.absent(),
            Value<String> resolvedRouteId = const Value.absent(),
            Value<String> providerConfigId = const Value.absent(),
            Value<String> modelName = const Value.absent(),
            Value<String> promptVersion = const Value.absent(),
            Value<bool> verifierIsIndependent = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> attemptCount = const Value.absent(),
            Value<int> maxAttempts = const Value.absent(),
            Value<String?> resultJson = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> progressJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisJobsCompanion(
            id: id,
            idempotencyKey: idempotencyKey,
            parentQuestionId: parentQuestionId,
            taskType: taskType,
            workloadProfile: workloadProfile,
            requiredCapabilitiesJson: requiredCapabilitiesJson,
            qualityPolicy: qualityPolicy,
            queuePriority: queuePriority,
            dependencyJobIdsJson: dependencyJobIdsJson,
            modelRole: modelRole,
            requestedModelClass: requestedModelClass,
            requestedModelRole: requestedModelRole,
            resolvedRouteId: resolvedRouteId,
            providerConfigId: providerConfigId,
            modelName: modelName,
            promptVersion: promptVersion,
            verifierIsIndependent: verifierIsIndependent,
            payloadJson: payloadJson,
            status: status,
            attemptCount: attemptCount,
            maxAttempts: maxAttempts,
            resultJson: resultJson,
            errorMessage: errorMessage,
            progressJson: progressJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            startedAt: startedAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String idempotencyKey,
            required String parentQuestionId,
            required String taskType,
            required String workloadProfile,
            required String requiredCapabilitiesJson,
            required String qualityPolicy,
            required String queuePriority,
            required String dependencyJobIdsJson,
            required String modelRole,
            required String requestedModelClass,
            required String requestedModelRole,
            required String resolvedRouteId,
            required String providerConfigId,
            required String modelName,
            required String promptVersion,
            Value<bool> verifierIsIndependent = const Value.absent(),
            required String payloadJson,
            required String status,
            Value<int> attemptCount = const Value.absent(),
            Value<int> maxAttempts = const Value.absent(),
            Value<String?> resultJson = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<String?> progressJson = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalysisJobsCompanion.insert(
            id: id,
            idempotencyKey: idempotencyKey,
            parentQuestionId: parentQuestionId,
            taskType: taskType,
            workloadProfile: workloadProfile,
            requiredCapabilitiesJson: requiredCapabilitiesJson,
            qualityPolicy: qualityPolicy,
            queuePriority: queuePriority,
            dependencyJobIdsJson: dependencyJobIdsJson,
            modelRole: modelRole,
            requestedModelClass: requestedModelClass,
            requestedModelRole: requestedModelRole,
            resolvedRouteId: resolvedRouteId,
            providerConfigId: providerConfigId,
            modelName: modelName,
            promptVersion: promptVersion,
            verifierIsIndependent: verifierIsIndependent,
            payloadJson: payloadJson,
            status: status,
            attemptCount: attemptCount,
            maxAttempts: maxAttempts,
            resultJson: resultJson,
            errorMessage: errorMessage,
            progressJson: progressJson,
            createdAt: createdAt,
            updatedAt: updatedAt,
            startedAt: startedAt,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnalysisJobsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnalysisJobsTable,
    AnalysisJob,
    $$AnalysisJobsTableFilterComposer,
    $$AnalysisJobsTableOrderingComposer,
    $$AnalysisJobsTableAnnotationComposer,
    $$AnalysisJobsTableCreateCompanionBuilder,
    $$AnalysisJobsTableUpdateCompanionBuilder,
    (
      AnalysisJob,
      BaseReferences<_$AppDatabase, $AnalysisJobsTable, AnalysisJob>
    ),
    AnalysisJob,
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
  $$AiConversationMessagesTableTableManager get aiConversationMessages =>
      $$AiConversationMessagesTableTableManager(
          _db, _db.aiConversationMessages);
  $$AnalysisJobsTableTableManager get analysisJobs =>
      $$AnalysisJobsTableTableManager(_db, _db.analysisJobs);
}
