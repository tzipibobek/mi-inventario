import 'package:flutter/material.dart';

const appColors = <Color>[
  Color(0xFFAB3615),
  Color(0xFF315E86),
  Color(0xFF47634D),
  Color(0xFF74528F),
];

class AppSettings {
  const AppSettings({
    this.title = 'Mi inventario',
    this.colorIndex = 0,
    this.themeMode = ThemeMode.system,
  });

  final String title;
  final int colorIndex;
  final ThemeMode themeMode;
}
