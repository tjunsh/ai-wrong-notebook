import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/shared/utils/composite_worksheet_detector.dart';

class QuestionSplitService {
  const QuestionSplitService({this.aiAnalysisService});

  final AiAnalysisService? aiAnalysisService;

  Future<QuestionSplitResult> split(String text, {Subject? subject}) async {
    if (aiAnalysisService != null) {
      return aiAnalysisService!.splitQuestionCandidates(
        text: text,
        subjectName: subject?.name,
      );
    }
    return _splitLocally(text, subject: subject);
  }

  QuestionSplitResult _splitLocally(String text, {Subject? subject}) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const QuestionSplitResult(
        sourceText: '',
        candidates: <QuestionSplitCandidate>[],
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (isCompositeLanguageWorksheet(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (_isCompositeQuestionWithSubparts(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final numberedSegments = _splitByNumberedQuestions(normalized);
    if (numberedSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates:
            _buildCandidates(numberedSegments, QuestionSplitStrategy.numbered),
        strategy: QuestionSplitStrategy.numbered,
      );
    }

    if (isSingleChoiceQuestionWithOptionBlock(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (isSingleQuestionWithSupportingBlocks(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final paragraphSegments = normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (paragraphSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(
            paragraphSegments, QuestionSplitStrategy.paragraph),
        strategy: QuestionSplitStrategy.paragraph,
      );
    }

    return QuestionSplitResult(
      sourceText: normalized,
      candidates: _buildCandidates(
          <String>[normalized], QuestionSplitStrategy.fallback),
      strategy: QuestionSplitStrategy.fallback,
    );
  }

  List<QuestionSplitCandidate> _buildCandidates(
      List<String> segments, QuestionSplitStrategy strategy) {
    return segments.asMap().entries.map((entry) {
      return QuestionSplitCandidate(
        id: 'candidate-${entry.key}',
        order: entry.key + 1,
        text: entry.value,
        strategy: strategy,
      );
    }).toList();
  }

  bool _isCompositeQuestionWithSubparts(String text, {Subject? subject}) {
    if (subject == Subject.chinese ||
        subject == Subject.english ||
        subject == Subject.history ||
        subject == Subject.geography ||
        subject == Subject.politics) {
      return false;
    }
    final hasSubQuestions =
        RegExp(r'（\s*\d+\s*）|\(\s*\d+\s*\)').allMatches(text).length >= 2;
    if (!hasSubQuestions) return false;

    final independentQuestionCount =
        RegExp(r'(^|\n)\s*(?:第\s*\d+\s*题|\d+[\.、．)])\s*', multiLine: true)
            .allMatches(text)
            .length;
    if (independentQuestionCount >= 2) return false;

    return _hasSharedCompositeStemSignal(text, subject: subject);
  }

  bool _hasSharedCompositeStemSignal(String text, {Subject? subject}) {
    final lower = text.toLowerCase();
    final hasGenericStem = <String>[
      '如图',
      '根据下列',
      '结合材料',
      '已知',
      '条件',
      '回答下列问题',
      '完成下列问题',
    ].any(lower.contains);
    final hasMathPhysicsStem = <String>[
      '电路',
      '装置',
      '实验',
      '函数图像',
      '坐标系',
      '正方形',
      '矩形',
      '三角形',
      '圆',
    ].any(lower.contains);
    final hasChemistryStem = <String>[
      '合成路线',
      '流程',
      '路线',
      '转化关系',
      '可通过如下',
      '如图',
      '条件',
      '已知',
      '写出',
      '结构简式',
      '分子式',
      '化学方程式',
      '反应类型',
    ].any(lower.contains);
    final hasChemistryContext = <String>[
      'naoh',
      'nh2oh',
      'hcl',
      'br',
      'fecl3',
      'c6h',
      '苯',
      '酯',
      '醇',
      '醛',
      '羧酸',
      '有机',
      '官能团',
      '同分异构体',
    ].any(lower.contains);
    if (subject == Subject.chemistry) {
      return hasGenericStem || hasChemistryStem || hasChemistryContext;
    }
    if (subject == Subject.math || subject == Subject.physics) {
      return hasGenericStem || hasMathPhysicsStem;
    }
    return hasGenericStem || hasMathPhysicsStem || hasChemistryStem;
  }

  List<String> _splitByNumberedQuestions(String text) {
    final matches = RegExp(
      r'(^|\n)\s*(?:第\s*\d+\s*题|\d+(?:[、．)]|\.(?!\d)))\s*',
      multiLine: true,
    ).allMatches(text).toList();
    if (matches.length < 2) return const <String>[];

    final segments = <String>[];
    for (var index = 0; index < matches.length; index++) {
      final current = matches[index];
      final start = current.start + (current.group(1)?.length ?? 0);
      final end =
          index + 1 < matches.length ? matches[index + 1].start : text.length;
      final segment = text.substring(start, end).trim();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    return segments;
  }
}
