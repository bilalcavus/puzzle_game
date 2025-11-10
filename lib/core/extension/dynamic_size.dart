import 'dart:math';

import 'package:flutter/material.dart';

extension MediaQueryExtension on BuildContext {
  double get w => MediaQuery.of(this).size.width;
  double get h => MediaQuery.of(this).size.height;

  double dynamicWidth(double val) => w * val;
  double dynamicHeight(double val) => h * val;

  SizedBox he(double height) {
    return SizedBox(height: height);
  }

  SizedBox we(double width) {
    return SizedBox(width: width);
  }
}

class ResponsiveSize {
  // Screen Breakpoints
  static const double _largeDesktopWidth = 1920.0;
  static const double _desktopWidth = 1024.0;
  static const double _tabletWidth = 768.0;
  static const double _mobileWidth = 375.0;

  // Scale Factor for each device type
  static const double _largeDesktopScale = 1.1;
  static const double _desktopScale = 1.15;
  static const double _tabletScale = 1.05;
  static const double _mobileScale = 0.95;

  static double getSize(BuildContext context, double baseSize) {
    double screenWidth = MediaQuery.of(context).size.width;
    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    late double scaleFactor;

    if (screenWidth >= _largeDesktopWidth) {
      scaleFactor = (screenWidth / _largeDesktopWidth) * _largeDesktopScale;
    } else if (screenWidth >= _desktopWidth) {
      scaleFactor = (screenWidth / _desktopWidth) * _desktopScale;
    } else if (screenWidth >= _tabletWidth) {
      scaleFactor = (screenWidth / _tabletWidth) * _tabletScale;
    } else {
      scaleFactor = (screenWidth / _mobileWidth) * _mobileScale;
    }

    scaleFactor = scaleFactor.clamp(0.75, 1.5);

    final value = max((baseSize * scaleFactor) / (pixelRatio > 2 ? pixelRatio * 0.7 : 1), 8.0);

    return value;
  }
}