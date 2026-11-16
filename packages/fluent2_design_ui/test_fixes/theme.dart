import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main() {
  final theme = Fluent2ThemeData.lapis(Brightness.light);
  theme.copyWith(shadows: theme.shadows, density: Fluent2Density.compact);
  theme.copyWith(brandShadows: theme.brandShadows);
}
