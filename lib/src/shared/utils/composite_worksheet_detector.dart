import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

final _reBlank = RegExp(r'_{2,}|＿{2,}|\(\s*\)|（\s*）');
final _reOptionRows =
    RegExp(r'(^|\n)\s*\d+[\.、．)]\s*[A-C][\.、．)]\s+', multiLine: true);
final _reEnglishPassage = RegExp(
    r'\b(the|that|which|while|however|because|people|money|family|should|china|saving|some|they|was|for|with|and|of|to)\b',
    caseSensitive: false);
final _reChineseMarker = RegExp(r'文常积累|字词释义|翻译卷|课文|文言文|释义');
final _reClassicalChinese = RegExp(r'问所从来|落英|缤纷|阡陌|桃花源记|岳阳楼记|醉翁亭记|出师表|陋室铭');
final _reHumanitiesMarker =
    RegExp(r'材料|阅读|填空|文综|历史|地理|政治|朝代|制度|事件|背景|原因|意义|影响|疆域|气候|地形|人口|公民|法治');
final _reNumberedBlanks =
    RegExp(r'(^|[^\d])(?:[1-9]|10)\s*[\.、．)]?\s*[A-C][\.、．)]', multiLine: true);
final _reChoiceOptionLine =
    RegExp(r'(^|\n)\s*([A-D])\s*[\.、．)]\s*\S', multiLine: true);
final _reIndependentQuestionStart = RegExp(
  r'(^|\n)\s*(?:第\s*\d+\s*题|\d+(?:[、．)]|\.(?!\d)))\s*',
  multiLine: true,
);
final _reMarkdownTableRow = RegExp(r'(^|\n)\s*\|[^\n]+\|', multiLine: true);
final _reLatexTable = RegExp(r'\\begin\{(?:array|tabular)\}');
final _reSupportingBlock = RegExp(
  r'(^|\n)\s*(?:(?:表|图)\s*\d+(?:\s*[：:]|为|说明|所示)?|(?:实验|测量)数据(?:如下)?)',
  multiLine: true,
);
final _reTaskCue = RegExp(r'求|计算|判断|分析|说明|写出|比较|选择|选出|回答|得出');

bool isCompositeLanguageWorksheet(String text, {Subject? subject}) {
  if (subject != null && !_supportsCompositeWorksheetDetection(subject)) {
    return false;
  }

  final hasEnglishPassage = _reEnglishPassage.allMatches(text).length >= 8;
  final optionRows = _reOptionRows.allMatches(text).length;
  final numberedBlanks = _reNumberedBlanks.allMatches(text).length;

  if (hasEnglishPassage && (optionRows >= 3 || numberedBlanks >= 5)) {
    return true;
  }

  if (_reChineseMarker.hasMatch(text)) return true;
  if (_reClassicalChinese.allMatches(text).length >= 2) return true;

  final blankCount = _reBlank.allMatches(text).length;
  return _isHumanitiesSubject(subject) &&
      blankCount >= 6 &&
      _reHumanitiesMarker.hasMatch(text);
}

bool isSingleChoiceQuestionWithOptionBlock(String text, {Subject? subject}) {
  final normalized =
      text.replaceAll('\r\n', '\n').replaceAll(r'\n', '\n').trim();
  if (normalized.isEmpty) return false;

  final optionLabels = _reChoiceOptionLine
      .allMatches(normalized)
      .map((match) => match.group(2))
      .whereType<String>()
      .toSet();
  if (optionLabels.length < 3 || !optionLabels.contains('A')) {
    return false;
  }

  final compact = normalized.replaceAll(RegExp(r'\s+'), '');
  final hasChoicePrompt = <String>[
    '下列',
    '以下',
    '的是',
    '选择',
    '选出',
    '应选',
    '选项',
    '哪一项',
    '哪项',
    '正确的是',
    '错误的是',
    '不正确的是',
    '最合理的是',
    '方案中',
  ].any(compact.contains);
  if (!hasChoicePrompt) return false;

  return true;
}

bool isSingleQuestionWithSupportingBlocks(String text, {Subject? subject}) {
  if (subject == Subject.chinese ||
      subject == Subject.english ||
      _isHumanitiesSubject(subject)) {
    return false;
  }

  final normalized =
      text.replaceAll('\r\n', '\n').replaceAll(r'\n', '\n').trim();
  final paragraphs = normalized
      .split(RegExp(r'\n\s*\n+'))
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();
  if (paragraphs.length < 2) return false;

  if (_reIndependentQuestionStart.allMatches(normalized).length >= 2) {
    return false;
  }

  final hasSupportingBlock = _reMarkdownTableRow.hasMatch(normalized) ||
      _reLatexTable.hasMatch(normalized) ||
      _reSupportingBlock.hasMatch(normalized);
  if (!hasSupportingBlock) return false;

  // A data table or diagram belongs to one question only when the text has
  // exactly one answerable task. Multiple tasks remain eligible for splitting.
  final taskParagraphCount = paragraphs.where(_reTaskCue.hasMatch).length;
  return taskParagraphCount == 1;
}

bool _supportsCompositeWorksheetDetection(Subject subject) {
  return subject == Subject.chinese ||
      subject == Subject.english ||
      _isHumanitiesSubject(subject);
}

bool _isHumanitiesSubject(Subject? subject) {
  return subject == Subject.history ||
      subject == Subject.geography ||
      subject == Subject.politics;
}
