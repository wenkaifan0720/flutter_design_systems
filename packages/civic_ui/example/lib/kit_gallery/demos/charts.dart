// A service's figures drawn: lines over months, bars by quarter, an area
// of what is waiting, the parts of a whole, and a trend beside its words.
// Each tells its series apart by more than colour and folds out as a table.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Charts',
  intro:
      'A chart shows the shape of figures the page also gives in words and '
      'as a table. Its series differ in line and mark, not colour alone.',
  sections: const [
    KitSection(
      title: 'Line chart',
      children: [
        CivicLineChart(
          title: 'Permits issued each month',
          summary: 'Visitor permits rose each month to June.',
          labelHeader: 'Month',
          labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          series: [
            CivicChartSeries('Resident', [120, 135, 128, 142, 138, 150]),
            CivicChartSeries('Visitor', [80, 92, 110, 104, 121, 133]),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Bar chart',
      children: [
        CivicBarChart(
          title: 'Fines paid by quarter',
          labelHeader: 'Quarter',
          missingLabel: 'No data yet',
          labels: ['Q1', 'Q2', 'Q3', 'Q4'],
          series: [
            CivicChartSeries('2025', [310, 280, 355, 290]),
            CivicChartSeries('2026', [295, 330, 340, null]),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Area chart',
      children: [
        CivicAreaChart(
          title: 'Applications waiting to be checked',
          labelHeader: 'Day',
          labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          series: [
            CivicChartSeries('Waiting', [42, 38, 51, 47, 33]),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Pie chart',
      children: [
        CivicPieChart(
          title: 'Permits by kind',
          summary: '2,000 permits in force on 31 October 2026.',
          labelHeader: 'Kind',
          valueHeader: 'Permits',
          shareHeader: 'Share',
          slices: [
            CivicPieSlice('Resident', 1240),
            CivicPieSlice('Visitor', 610),
            CivicPieSlice('Business', 150),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Sparkline',
      children: [
        Row(
          spacing: CivicSpacing.s16,
          children: [
            Expanded(child: Text('Visitor permits this week')),
            CivicSparkline(
              label: 'Visitor permits this week',
              values: [12, 18, 15, 22, 19, 26, 31],
            ),
          ],
        ),
      ],
    ),
  ],
);
