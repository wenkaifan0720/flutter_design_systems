/// Gloss's charts: lines and areas drawn as gel tubes over a well, bars cast
/// in gel, a donut and the sparkline.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../kit.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// The charts page.
Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  sections: const [
    KitSection(
      title: 'Lines and areas',
      children: [
        _Narrow(
          GlossLineChart(
            semanticLabel: 'Meals cooked and planned this week',
            labels: _days,
            series: [
              GlossSeries('Cooked', [2, 3, 1, 3, 2, 4, 3]),
              GlossSeries('Planned', [3, 3, 2, 3, 3, 3, 2]),
            ],
          ),
        ),
        _Narrow(
          GlossAreaChart(
            semanticLabel: 'Recipes saved each day',
            labels: _days,
            series: [
              GlossSeries('Saved', [4, 7, 5, 9, 6, 11, 8]),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Bars',
      children: [
        _Narrow(
          GlossBarChart(
            semanticLabel: 'Minutes at the stove each day',
            labels: _days,
            series: [
              GlossSeries('Minutes', [35, 50, 20, 45, 30, 90, 60]),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'A donut',
      children: [
        GlossPieChart(
          semanticLabel: 'This month by course',
          centerLabel: 'dinners',
          slices: [
            GlossSlice('Mains', 12),
            GlossSlice('Sides', 6),
            GlossSlice('Soups', 4),
            GlossSlice('Puddings', 2),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'A sparkline in a line of words',
      children: [_SparkLine()],
    ),
  ],
);

class _Narrow extends StatelessWidget {
  const _Narrow(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: child,
  );
}

/// A sparkline where one sits: inline, beside the figure it tracks.
class _SparkLine extends StatelessWidget {
  const _SparkLine();

  @override
  Widget build(BuildContext context) {
    final t = context.glossTheme.textTheme;
    return Wrap(
      spacing: GlossSpacing.medium,
      runSpacing: GlossSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Meals this week', style: t.body),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GlossSparkline(
              semanticLabel: 'Meals this week, day by day',
              values: [2, 3, 1, 3, 2, 4, 3],
            ),
            const SizedBox(width: GlossSpacing.medium),
            Text('18', style: t.label),
          ],
        ),
      ],
    );
  }
}
