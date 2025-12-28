import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../models/piece_model.dart';
import 'piece_drag_constants.dart';

/// Coordinates drag updates between the tray pieces and the game board.
/// Pieces report their global pointer position here so the board can
/// compute grid anchors and preview states without relying solely on
/// DragTarget hit testing.
class BlockDragController {
  void Function(PieceModel piece, Offset globalPosition)? onHover;
  void Function(PieceModel piece, Offset globalPosition)? onDrop;
  VoidCallback? onCancelHover;
  Offset? _lastHoverPosition;
  final ValueNotifier<double> liftOffset =
      ValueNotifier<double>(kPieceDragMinLift);

  Offset? get lastHoverPosition => _lastHoverPosition;

  void updateHover(PieceModel piece, Offset globalPosition) {
    _lastHoverPosition = globalPosition;
    onHover?.call(piece, globalPosition);
  }

  void updateLift(Offset globalPosition, double screenHeight) {
    final lift = pieceDragLiftForGlobal(globalPosition, screenHeight);
    if (liftOffset.value != lift) {
      liftOffset.value = lift;
    }
  }

  void completeDrop(PieceModel piece, Offset globalPosition) {
    onDrop?.call(piece, globalPosition);
  }

  void cancelHover() {
    _lastHoverPosition = null;
    onCancelHover?.call();
  }

  void resetLift() {
    liftOffset.value = kPieceDragMinLift;
  }

  void detach() {
    _lastHoverPosition = null;
    onHover = null;
    onDrop = null;
    onCancelHover = null;
  }

  void dispose() {
    detach();
    liftOffset.dispose();
  }
}
