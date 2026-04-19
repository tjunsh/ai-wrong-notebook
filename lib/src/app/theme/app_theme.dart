import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  return FlexThemeData.light(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    scaffoldBackground: const Color(0xFFF8FAFC),
    appBarBackground: Colors.white,
    appBarElevation: 0,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useM2StyleDividerInM3: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorRadius: 10,
      chipRadius: 8,
      navigationBarIndicatorRadius: 10,
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarIndicatorSchemeColor: SchemeColor.primary,
    ),
  );
}

ThemeData buildDarkTheme() {
  return FlexThemeData.dark(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    scaffoldBackground: const Color(0xFF0F172A),
    appBarBackground: const Color(0xFF1E293B),
    appBarElevation: 0,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      useM2StyleDividerInM3: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorRadius: 10,
      chipRadius: 8,
      navigationBarIndicatorRadius: 10,
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarIndicatorSchemeColor: SchemeColor.primary,
    ),
  );
}
