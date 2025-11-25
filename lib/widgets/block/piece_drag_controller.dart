import 'dart:ui';

import '../../models/piece_model.dart';

/// Coordinates drag updates between the tray pieces and the game board.
/// Pieces report their global pointer position here so the board can
/// compute grid anchors and preview states without relying solely on
/// DragTarget hit testing.
class BlockDragController {
  void Function(PieceModel piece, Offset globalPosition)? onHover;
  void Function(PieceModel piece, Offset globalPosition)? onDrop;
  VoidCallback? onCancelHover;

  void updateHover(PieceModel piece, Offset globalPosition) {
    onHover?.call(piece, globalPosition);
  }

  void completeDrop(PieceModel piece, Offset globalPosition) {
    onDrop?.call(piece, globalPosition);
  }

  void cancelHover() {
    onCancelHover?.call();
  }

  void detach() {
    onHover = null;
    onDrop = null;
    onCancelHover = null;
  }
}
