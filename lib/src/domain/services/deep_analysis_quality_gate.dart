enum DeepAnalysisDisposition {
  continueToProof,
  publishReasoningDraft,
}

enum ReasoningDraftConfidence {
  low,
  medium,
  high,
}

class ReasoningDraft {
  const ReasoningDraft({
    required this.target,
    required this.verifiedSteps,
    required this.reasoningDraft,
    required this.missingEvidence,
    required this.draftConfidence,
  });

  final String target;
  final List<String> verifiedSteps;
  final List<String> reasoningDraft;
  final List<String> missingEvidence;
  final ReasoningDraftConfidence draftConfidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'target': target,
      'verifiedSteps': verifiedSteps,
      'reasoningDraft': reasoningDraft,
      'missingEvidence': missingEvidence,
      'draftConfidence': draftConfidence.name,
    };
  }
}

class DeepAnalysisGateDecision {
  const DeepAnalysisGateDecision({
    required this.disposition,
    this.draft,
  });

  final DeepAnalysisDisposition disposition;
  final ReasoningDraft? draft;
}

class DeepAnalysisQualityGate {
  const DeepAnalysisQualityGate();

  DeepAnalysisGateDecision evaluateProofPlan(Map<String, dynamic> result) {
    final confidence = _parseConfidence(result['draftConfidence']);
    final verifiedSteps = _stringList(result['verifiedSteps']);
    final reasoningDraft = _stringList(result['reasoningDraft']);
    final missingEvidence = _stringList(result['missingEvidence']);
    final canContinue = confidence == ReasoningDraftConfidence.high &&
        missingEvidence.isEmpty &&
        reasoningDraft.isNotEmpty;

    if (canContinue) {
      return const DeepAnalysisGateDecision(
        disposition: DeepAnalysisDisposition.continueToProof,
      );
    }

    return DeepAnalysisGateDecision(
      disposition: DeepAnalysisDisposition.publishReasoningDraft,
      draft: ReasoningDraft(
        target: result['target']?.toString().trim() ?? '',
        verifiedSteps: verifiedSteps,
        reasoningDraft: reasoningDraft,
        missingEvidence: missingEvidence.isEmpty
            ? const <String>['这部分推导仍缺少关键依据。']
            : missingEvidence,
        draftConfidence: confidence,
      ),
    );
  }

  ReasoningDraftConfidence _parseConfidence(Object? value) {
    for (final confidence in ReasoningDraftConfidence.values) {
      if (confidence.name == value) return confidence;
    }
    return ReasoningDraftConfidence.low;
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
