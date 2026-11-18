import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Charts read off a scope: traces of light on ruled glass.
Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Scope charts',
  sections: [
    const KitSection(
      title: 'Line',
      note: 'Each series a glowing trace; the first in the indicator, the next in the readout white.',
      children: [
        StudioLineChart(
          semanticLabel: 'Plays by day',
          labels: _days,
          series: [
            StudioSeries('This week', [120, 180, 150, 210, 260, 320, 280]),
            StudioSeries('Last week', [100, 140, 160, 150, 190, 240, 230]),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Area',
      note: 'The glass under the trace glowing faintly down to the base line.',
      children: [
        StudioAreaChart(
          semanticLabel: 'Listeners by day',
          labels: _days,
          series: [
            StudioSeries('Listeners', [820, 940, 760, 880, 1020, 1240, 1100]),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Bar',
      note: 'Columns of lit segments, as level meters stand.',
      children: [
        StudioBarChart(
          semanticLabel: 'Downloads by episode',
          labels: ['9', '10', '11', '12'],
          series: [
            StudioSeries('Downloads', [280, 340, 410, 290]),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Ring',
      note: 'Shares as lit arcs round a ring, the total in a readout.',
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 320,
            child: StudioPieChart(
              semanticLabel: 'Listening by device',
              slices: [
                StudioSlice('Phone', 62),
                StudioSlice('Desktop', 28),
                StudioSlice('Speaker', 10),
              ],
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Sparkline',
      note: 'A trace with no frame, beside the figure it follows.',
      children: [
        Builder(
          builder: (context) {
            final theme = StudioTheme.of(context);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1,204 plays',
                  style: theme.textTheme.body.copyWith(
                    color: theme.colors.legend,
                  ),
                ),
                const SizedBox(width: StudioSpacing.medium),
                const StudioSparkline(
                  semanticLabel: 'Plays this week, rising',
                  values: [3, 5, 4, 8, 7, 11],
                ),
              ],
            );
          },
        ),
      ],
    ),
  ],
);
