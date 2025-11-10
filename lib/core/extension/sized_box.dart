
import 'package:flutter/material.dart' show SizedBox;

extension SpaceX on num {
  SizedBox get height => SizedBox(height: toDouble());
  SizedBox get width  => SizedBox(width: toDouble());
}