import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/domain/services/deep_analysis_quality_gate.dart';

void main() {
  const gate = DeepAnalysisQualityGate();

  test('high-confidence proof plan may continue to proof writing', () {
    final decision = gate.evaluateProofPlan(<String, dynamic>{
      'target': '3ii',
      'verifiedSteps': <String>['由条件①得到集合包含关系'],
      'reasoningDraft': <String>['反设存在两个点破坏严格递增'],
      'missingEvidence': <String>[],
      'draftConfidence': 'high',
    });

    expect(decision.disposition, DeepAnalysisDisposition.continueToProof);
    expect(decision.draft, isNull);
  });

  test('low-confidence proof plan becomes a visible reasoning draft', () {
    final decision = gate.evaluateProofPlan(<String, dynamic>{
      'target': '3ii',
      'verifiedSteps': <String>['可推出一个集合包含关系'],
      'reasoningDraft': <String>['尝试用反证法构造位移'],
      'missingEvidence': <String>['尚未找到可验证的关键位移'],
      'draftConfidence': 'low',
    });

    expect(decision.disposition, DeepAnalysisDisposition.publishReasoningDraft);
    expect(decision.draft?.target, '3ii');
    expect(decision.draft?.draftConfidence, ReasoningDraftConfidence.low);
    expect(
      decision.draft?.missingEvidence,
      <String>['尚未找到可验证的关键位移'],
    );
  });

  test('missing confidence never triggers another proof request', () {
    final decision = gate.evaluateProofPlan(<String, dynamic>{
      'target': '3ii',
      'reasoningDraft': <String>['只有一个尚未核验的方向'],
    });

    expect(decision.disposition, DeepAnalysisDisposition.publishReasoningDraft);
    expect(decision.draft?.draftConfidence, ReasoningDraftConfidence.low);
    expect(decision.draft?.missingEvidence, isNotEmpty);
  });
}
