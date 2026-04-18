import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  return FlexThemeData.light(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
  );
}

ThemeData buildDarkTheme() {
  return FlexThemeData.dark(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
  );
}
