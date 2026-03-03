import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';


final Signal<bool> sDarkMode = Signal<bool>(true, debugLabel: 'sDarkMode');

// Override textTheme for the XL fonts.
const TextTheme _textThemeOverrides = TextTheme(
  displayLarge: TextStyle(fontFamily: 'BebasNeue'),
  displayMedium: TextStyle(fontFamily: 'BebasNeue'),
  displaySmall: TextStyle(fontFamily: 'BebasNeue'),
);

final Computed<ThemeData> cThemeData = Computed<ThemeData>(() {
  if (sDarkMode.value) {
    return FlexThemeData.dark(
      scheme: FlexScheme.shark,
      fontFamily: 'LeagueGothic',
      textTheme: _textThemeOverrides,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnColors: true,
        useM2StyleDividerInM3: true,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );
  } else {
    return FlexThemeData.light(
      scheme: FlexScheme.shark,
      fontFamily: 'LeagueGothic',
      textTheme: _textThemeOverrides,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: true,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );
  }
});
