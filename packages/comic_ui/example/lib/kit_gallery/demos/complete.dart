/// Navigation, reading, status and people, using the same inked-panel grammar.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

import '../kit.dart';

Widget kitCompleteDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'A complete issue',
  sections: [
    kitSection(
      'Actions and choices',
      children: [
        kitSpecimenQuiet(),
        kitSpecimenDanger(),
        kitSpecimenLink(),
        kitSpecimenFilter(),
        kitSpecimenRemove(),
        kitSpecimenSlider(),
        kitSpecimenDate(),
        kitSpecimenTime(),
      ],
    ),
    kitSection(
      'Places and progress',
      children: [
        kitSpecimenRail(),
        kitSpecimenBreadcrumbs(),
        kitSpecimenPagination(),
        kitSpecimenSideNav(),
        kitSpecimenTabs(),
        kitSpecimenDots(),
        kitSpecimenSteps(),
      ],
    ),
    kitSection('Rating and files', children: [_rating(), _files()]),
    kitSection('A carousel', children: [kitSpecimenCarousel()]),
    kitSection(
      'Reading',
      children: [
        kitSpecimenCard(),
        kitSpecimenGrouped(),
        kitSpecimenDisclosure(),
        kitSpecimenTable(),
      ],
    ),
    kitSection(
      'What happened',
      children: [
        kitSpecimenNotice(),
        kitSpecimenSpinner(),
        kitSpecimenProgress(),
        kitSpecimenSkeleton(),
        kitSpecimenBadge(),
        kitSpecimenSuccess(),
      ],
    ),
    kitSection(
      'Who and how much',
      children: [
        kitSpecimenAvatar(),
        kitSpecimenPile(),
        kitSpecimenMeter(),
        kitSpecimenChart(),
      ],
    ),
  ],
);
// A quiet button has no frame to fill, so the phone's stretching column would leave its word floating mid-row: it
// stands at the start, as the link does.
Widget kitSpecimenQuiet() => Builder(
  builder: (context) => Builder(
    builder: (context) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: ComicButton.text(
        kitSay(context, 'Later'),
        onPressed: () =>
            kitFeedback(context, kitSay(context, 'Saved for later.')),
      ),
    ),
  ),
);
Widget kitSpecimenDanger() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicButton(
      kitSay(context, 'Remove issue'),
      isDestructiveAction: true,
      icon: ComicGlyphs.trash2,
      onPressed: () => kitFeedback(context, kitSay(context, 'Issue removed.')),
    ),
  ),
);
Widget kitSpecimenLink() => Builder(
  builder: (context) => Builder(
    builder: (context) => ComicLink(
      kitSay(context, 'Read this issue'),
      onPressed: () => kitFeedback(context, kitSay(context, 'Issue opened.')),
    ),
  ),
);
Widget kitSpecimenFilter() => kitState(
  true,
  (context, value, change) =>
      ComicChip.filter('In print', selected: value, onSelected: change),
);
Widget kitSpecimenRemove() => kitState(
  true,
  (context, value, change) => value
      ? ComicChip('History', onDeleted: () => change(false))
      : ComicButton.text('Restore History', onPressed: () => change(true)),
);
Widget kitSpecimenSlider() => kitState(
  40.0,
  (context, value, change) => ComicSlider(
    label: 'Pages',
    value: value,
    max: 100,
    divisions: 10,
    onChanged: change,
  ),
);
Widget kitSpecimenDate() => kitState(
  kitToday,
  (context, value, change) =>
      ComicDatePicker(value: value, currentDate: kitToday, onChanged: change),
);
Widget kitSpecimenTime() => kitState(
  const ComicTime(19, 30),
  (context, value, change) =>
      ComicTimePicker(value: value, minuteStep: 15, onChanged: change),
);
Widget kitSpecimenSideNav() => kitState(
  1,
  (context, value, change) => ComicNavigationDrawer(
    destinations: kitTabs,
    selectedIndex: value,
    onDestinationSelected: change,
  ),
);
Widget kitSpecimenTabs() => kitState(
  1,
  (context, value, change) => ComicTabBar(
    tabs: const ['All', 'Saved', 'Read'],
    selectedIndex: value,
    onChanged: change,
  ),
);
Widget kitSpecimenDots() => kitState(
  1,
  (context, value, change) => ComicPageDots(
    count: 4,
    selectedIndex: value,
    label: 'Preview pages',
    onChanged: change,
  ),
);
Widget kitSpecimenSteps() => const ComicStepProgress(
  count: 4,
  currentStep: 1,
  name: 'Your issue',
  phase: 'Choose a format',
);
Widget kitSpecimenCard() => const ComicCard(
  title: 'This issue',
  children: [Text('Twelve pages, printed in two inks.')],
);
Widget kitSpecimenGrouped() => Builder(
  builder: (context) => ComicListSection(
    label: kitSay(context, 'Publication'),
    children: [
      ComicKvRow(kitSay(context, 'Pages'), '24', isFirst: true),
      ComicKvRow(kitSay(context, 'Print run'), '500'),
    ],
  ),
);
Widget kitSpecimenDisclosure() => Builder(
  builder: (context) => ComicDisclosure(
    title: kitSay(context, 'About this edition'),
    initiallyExpanded: true,
    child: Text(kitSay(context, 'An offset reprint of the original issue.')),
  ),
);
Widget kitSpecimenTable() => Builder(
  builder: (context) => ComicTable(
    columns: [kitSay(context, 'Issue'), kitSay(context, 'Pages')],
    rows: [
      [kitSay(context, 'Twelve'), '24'],
      [kitSay(context, 'Thirteen'), '32'],
    ],
  ),
);
Widget kitSpecimenNotice() => Builder(
  builder: (context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final tone in ComicTone.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ComicBanner(switch (tone) {
            ComicTone.info => kitSay(context, 'A new issue arrives Friday.'),
            ComicTone.success => kitSay(context, 'Your issue is saved.'),
            ComicTone.warning => kitSay(context, 'Only a few copies remain.'),
            ComicTone.danger => kitSay(
              context,
              'We could not save this issue.',
            ),
          }, tone: tone),
        ),
    ],
  ),
);
Widget kitSpecimenSpinner() => Builder(
  builder: (context) => Wrap(
    spacing: 16,
    children: [
      ComicCircularProgressIndicator(
        value: .5,
        label: kitSay(context, 'Half uploaded'),
      ),
      ComicCircularProgressIndicator(label: kitSay(context, 'Loading')),
    ],
  ),
);
Widget kitSpecimenProgress() => Builder(
  builder: (context) =>
      ComicLinearProgressIndicator(value: .6, label: kitSay(context, 'Upload')),
);
Widget kitSpecimenSkeleton() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    ComicSkeleton(width: 160),
    SizedBox(height: 8),
    ComicSkeleton(width: 240),
  ],
);
// A badge keeps its own size at the column's start, as it would beside the thing it counts.
Widget kitSpecimenBadge() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ComicBadge(12, label: kitSay(context, 'Unread issues')),
  ),
);
Widget kitSpecimenSuccess() => Builder(
  builder: (context) => ComicSuccessState(
    title: kitSay(context, 'Saved'),
    message: kitSay(context, 'Your issue is ready to read.'),
  ),
);
Widget kitSpecimenAvatar() => const Wrap(
  spacing: 12,
  children: [
    ComicAvatar('NW', name: 'Nia Walker'),
    ComicAvatar('AK', name: 'Alex Kim', size: 56, selected: true),
  ],
);
Widget kitSpecimenPile() => const ComicAvatarGroup([
  ComicFace('NW'),
  ComicFace('AK'),
  ComicFace('JR'),
  ComicFace('AM'),
  ComicFace('LT'),
], label: 'Five contributors');
Widget kitSpecimenMeter() => Builder(
  builder: (context) => ComicMeter(
    label: kitSay(context, 'Capacity'),
    value: 35,
    max: 100,
    unit: kitSay(context, 'pages'),
  ),
);

Widget kitSpecimenChart() => const ComicChart(
  label: 'Weekly pages',
  labels: ['M', 'T', 'W', 'T', 'F'],
  series: [
    ComicChartSeries('First run', [12, 18, 14, 16, 24]),
    ComicChartSeries('Reprint', [8, 11, 15, 9, 18]),
  ],
  band: ComicChartBand(14, 20, label: 'Target'),
);

Widget kitSpecimenRail() => kitState(
  0,
  (context, value, change) => SizedBox(
    height: 300,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ComicNavigationRail(
          destinations: kitTabs,
          selectedIndex: value,
          onDestinationSelected: change,
        ),
        Expanded(
          child: Center(
            child: Text(
              kitTabs[value].label,
              style: ComicTheme.of(context).type.section,
            ),
          ),
        ),
      ],
    ),
  ),
);

Widget kitSpecimenBreadcrumbs() => Builder(
  builder: (context) => ComicBreadcrumb([
    ComicCrumb('Shop', onPressed: () => kitFeedback(context, 'Shop opened.')),
    ComicCrumb(
      'Comics',
      onPressed: () => kitFeedback(context, 'Comics opened.'),
    ),
    const ComicCrumb('Issue 12'),
  ]),
);

Widget kitSpecimenPagination() => kitState(
  3,
  (context, value, change) => ComicPagination(
    label: 'Results pages',
    count: 12,
    page: value,
    onChanged: change,
  ),
);

Widget kitSpecimenCarousel() => Builder(
  builder: (context) => ComicCarouselView(
    label: 'This week',
    // Tall enough for its two lines at any text size: 180 at the reader's own size, growing with larger text.
    height: math.max(180, MediaQuery.textScalerOf(context).scale(76) + 40),
    children: [
      for (final (title, note) in const [
        ('The night shift', 'Twelve pages'),
        ('Harbour lights', 'A short story'),
        ('The long walk', 'Part two'),
        ('Small hours', 'Four panels'),
      ])
        ComicPanel(
          onPressed: () => kitFeedback(context, '$title opened.'),
          label: title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(title, style: ComicTheme.of(context).type.panel),
              Text(note, style: ComicTheme.of(context).type.small),
            ],
          ),
        ),
    ],
  ),
);

/// Each sparkline beside the figure it trends, at a size it reads at.
Widget kitSpecimenSparkline() => Builder(
  builder: (context) {
    final t = ComicTheme.of(context);
    Widget row(String label, List<double> values, String figure) => Row(
      children: [
        Expanded(child: Text(label, style: t.type.body)),
        const SizedBox(width: 12),
        ComicSparkline(label: label, values: values, width: 120, height: 32),
        const SizedBox(width: 12),
        SizedBox(
          width: MediaQuery.textScalerOf(context).scale(36),
          child: Text(
            figure,
            textAlign: TextAlign.end,
            style: t.type.number(22, color: t.colors.text),
          ),
        ),
      ],
    );
    return ComicColumn(
      gap: 12,
      children: [
        row('Sales this week', [3, 5, 4, 8, 7, 9, 12], '12'),
        row('Returns this week', [6, 4, 5, 5, 3, 2, 2], '2'),
      ],
    );
  },
);

// The frames and controls demos' rating and file specimens, drawn here too:
// a demo imports only the public surface, never another demo.
Widget _rating() => kitState(
  3,
  (context, value, change) =>
      ComicRating(label: 'Rate this issue', value: value, onChanged: change),
);

Widget _files() => kitState(
  const [
    ComicDroppedFile('cover-final.png', size: '2.4 MB'),
    ComicDroppedFile('page-03.jpg', size: '1.1 MB', progress: .6),
  ],
  (context, value, change) => ComicFileUpload(
    label: 'Cover art',
    hint: 'PNG or JPG, up to 10\u00A0MB',
    files: value,
    onChoose: () => change([
      ...value,
      ComicDroppedFile('page-${value.length + 1}.png', size: '0.8 MB'),
    ]),
    onRemove: (i) => change([...value]..removeAt(i)),
  ),
);

const _weeks = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4', 'Wk 5', 'Wk 6'];

Widget kitSpecimenLineChart() => const ComicLineChart(
  label: 'Pages read each week',
  labels: _weeks,
  series: [
    ComicChartSeries('You', [12, 18, 16, 24, 21, 27]),
    ComicChartSeries('The group', [10, 14, 15, 17, 18, 20]),
  ],
  band: ComicChartBand(15, 22, label: 'Target 15 to 22'),
);

Widget kitSpecimenAreaChart() => const ComicAreaChart(
  label: 'Visitors each week',
  labels: _weeks,
  series: [
    ComicChartSeries('Visitors', [320, 410, 380, 520, 610, 580]),
  ],
);

Widget kitSpecimenBarChart() => const ComicBarChart(
  label: 'Orders each week',
  labels: _weeks,
  series: [
    ComicChartSeries('Online', [42, 51, 38, 60, 55, 64]),
    ComicChartSeries('In store', [30, 28, 35, 32, 40, 37]),
  ],
);
