import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main() {
  final day = Fluent2ThemeData.clover();
  final night = Fluent2ThemeData.clover(Brightness.dark);
  Fluent2Host(light: day, darkData: night, child: const SizedBox());
  Fluent2ThemeData.contrast(day.colors.neutralForeground1, day.background);
}
