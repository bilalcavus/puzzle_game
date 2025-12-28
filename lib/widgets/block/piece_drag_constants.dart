import 'dart:ui';

// Apply a fixed upward lift so the piece centers above the finger.
const double kPieceDragMinLift = 150;
const double kPieceDragMaxLift = 260;

double pieceDragLiftForGlobal(Offset globalPosition, double screenHeight) {
  if (screenHeight <= 0) return kPieceDragMinLift;
  final t = (1 - (globalPosition.dy / screenHeight).clamp(0.0, 1.0));
  return kPieceDragMinLift +
      (kPieceDragMaxLift - kPieceDragMinLift) * t;
}
const double kPieceDragDynamicYOffset = 0;
const double kPieceDragHitYOffsetFactor = 0;
const double kPieceDragBoardYOffsetFactor = 0;
const double kPieceDragUpwardBoost = 0;
