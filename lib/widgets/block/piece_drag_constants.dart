// Shared lift offset so drag feedback and board hit testing stay aligned.
// Keep the dragged piece above the finger and close to the board.
const double kPieceDragPointerYOffset = 140;

// Portion of the visual lift applied to hit-testing; lower keeps bottom rows reachable.
const double kPieceDragHitYOffsetFactor = 0.3;

// Additional lift based on board height to make the piece track the board with less finger travel.
// Higher values mean your finger can stay lower while the piece reaches higher rows.
const double kPieceDragBoardYOffsetFactor = 0.22;

// Boost upward motion so small finger lifts move the piece further up the board.
const double kPieceDragUpwardBoost = 1.4;
