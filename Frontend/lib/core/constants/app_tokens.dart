import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  static const double rSm = 10.0;
  static const double r = 16.0;
  static const double rLg = 24.0;

  static const EdgeInsets pScreen = EdgeInsets.all(24.0);
  static const EdgeInsets pCard = EdgeInsets.all(18.0);
  static const EdgeInsets pButton = EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0);

  static EdgeInsets screenPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      return const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0);
    } else if (w < 900) {
      return const EdgeInsets.all(18.0);
    }
    return const EdgeInsets.all(24.0);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      return const EdgeInsets.all(13.0);
    }
    return const EdgeInsets.all(18.0);
  }

  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animNormal = Duration(milliseconds: 300);

  static const String appName = 'Vistar Logitek';
  static const String appSubtitle = 'Maxion Wheels Dispatch Operations';
  static const String documentId = 'VLT/MXW/DISP/SSR/001 v2.0';
}
