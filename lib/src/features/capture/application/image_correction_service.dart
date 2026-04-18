import 'package:smart_wrong_notebook/src/features/capture/application/correction_state.dart';

class ImageCorrectionService {
  CorrectionState rotate90(CorrectionState state) {
    return state.copyWith(quarterTurns: (state.quarterTurns + 1) % 4);
  }

  CorrectionState reset(CorrectionState state) {
    return state.copyWith(quarterTurns: 0);
  }

  Future<CorrectionState> autoStraighten(CorrectionState state) async {
    return state;
  }
}
