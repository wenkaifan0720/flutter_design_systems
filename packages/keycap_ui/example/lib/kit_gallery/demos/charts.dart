import 'package:material_ui/material_ui.dart';

import '../kit.dart';

/// Figures to read, sunk in wells; a picked point shows on a small flat panel.
Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: kitSpecimens(const [
    'LineChart',
    'AreaChart',
    'BarChart',
    'PieChart',
    'Sparkline',
  ]),
);
