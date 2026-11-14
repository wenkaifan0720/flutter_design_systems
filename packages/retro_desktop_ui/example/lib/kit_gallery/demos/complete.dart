/// Navigation, feedback and display parts use the same desktop chrome.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitCompleteDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation, feedback and display',
  sections: [
    kitSection(
      'Quiet and destructive actions',
      children: [
        kitSpecimenQuietButton(),
        kitSpecimenDangerButton(),
        kitSpecimenLink(),
      ],
    ),
    kitSection(
      'Side navigation',
      children: [kitSpecimenNavigationDrawer(), kitSpecimenNavigationRail()],
    ),
    kitSection(
      'Pages and steps',
      children: [kitSpecimenPageDots(), kitSpecimenStepProgress()],
    ),
    kitSection(
      'Feedback',
      children: [
        kitSpecimenNotice(),
        kitSpecimenBadge(),
        kitSpecimenCircularProgressIndicator(),
        kitSpecimenSkeleton(),
        kitSpecimenSuccessState(),
        kitSpecimenEmptyState(),
      ],
    ),
    kitSection(
      'Faces and pictures',
      children: [
        kitSpecimenAvatar(),
        kitSpecimenFacePile(),
        kitSpecimenPicture(),
      ],
    ),
    kitSection(
      'Surfaces and rows',
      children: [
        kitSpecimenSurface(),
        kitSpecimenCard(),
        kitSpecimenGroupedList(),
        kitSpecimenDivider(),
      ],
    ),
    kitSection(
      'Amounts and plots',
      children: [
        kitSpecimenAmount(),
        kitSpecimenMeter(),
        kitSpecimenChart(),
        kitSpecimenLineChart(),
        kitSpecimenAreaChart(),
        kitSpecimenDonutChart(),
        kitSpecimenSparkline(),
        kitSpecimenChartEmpty(),
        kitSpecimenChartLoading(),
      ],
    ),
    kitSection(
      'Ways through',
      children: [kitSpecimenBreadcrumbs(), kitSpecimenPagination()],
    ),
    kitSection(
      'Ratings and files',
      children: [kitSpecimenRating(), kitSpecimenFileDrop()],
    ),
  ],
);
Widget kitSpecimenQuietButton() => kitAction(
  'More options opened',
  (press) => RetroDesktopButton.text(
    'More options',
    icon: RetroDesktopGlyphs.more,
    onPressed: press,
  ),
);
Widget kitSpecimenDangerButton() => kitAction(
  'Document deleted',
  // A plain button with the caution mark, as everywhere else: a window has one default button, and a destructive
  // action is never it.
  (press) => RetroDesktopButton(
    'Delete document',
    isDestructiveAction: true,
    onPressed: press,
  ),
);
Widget kitSpecimenLink() => kitAction(
  'Guide opened',
  (press) => RetroDesktopLink('Read the guide', onPressed: press),
);
const _places = [
  RetroDesktopNavItem(
    label: 'Documents',
    short: 'Files',
    icon: RetroDesktopGlyphs.inbox,
  ),
  // The gallery's own Settings glyph: the key.
  RetroDesktopNavItem(
    label: 'Settings',
    short: 'Settings',
    icon: RetroDesktopGlyphs.key,
  ),
];
// A side navigation hugs its places: in a page of examples there is no window
// height for it to fill, and a fixed one left blank under two places.
Widget kitSpecimenNavigationDrawer() => kitValue(
  0,
  (value, change) => RetroDesktopNavigationDrawer(
    items: _places,
    selectedIndex: value,
    onDestinationSelected: change,
  ),
);
Widget kitSpecimenNavigationRail() => kitValue(
  0,
  (value, change) => RetroDesktopNavigationRail(
    items: _places,
    selectedIndex: value,
    onDestinationSelected: change,
  ),
);
Widget kitSpecimenPageDots() {
  var value = 0;
  return StatefulBuilder(
    builder: (context, change) => RetroDesktopPageDots(
      count: 4,
      selectedIndex: value,
      label: 'Introduction',
      onChanged: (next) => change(() => value = next),
    ),
  );
}

Widget kitSpecimenStepProgress() => const RetroDesktopStepProgress(
  count: 4,
  currentStep: 1,
  name: 'Set up this computer',
);
Widget kitSpecimenNotice() => const RetroDesktopBanner(
  title: 'Saved locally',
  message: 'Your changes will synchronize when you reconnect.',
  tone: RetroDesktopTone.info,
);
Widget kitSpecimenBadge() =>
    const RetroDesktopBadge(12, label: '12 unread', child: Text('Inbox'));
Widget kitSpecimenCircularProgressIndicator() =>
    const RetroDesktopCircularProgressIndicator(label: 'Copying', value: .5);
Widget kitSpecimenSkeleton() =>
    const RetroDesktopSkeleton(lines: 3, label: 'Loading documents');
Widget kitSpecimenSuccessState() => const RetroDesktopSuccessState(
  title: 'All files copied',
  message: 'You can close this window.',
);
Widget kitSpecimenEmptyState() => kitAction(
  'New document created',
  (press) => RetroDesktopEmptyState(
    title: 'No documents yet',
    message: 'Create a document to get started.',
    action: RetroDesktopButton(
      'New document',
      isDefaultAction: true,
      onPressed: press,
    ),
  ),
);

Widget kitSpecimenAvatar() => const RetroDesktopAvatar('AL', name: 'Alex Lee');
Widget kitSpecimenFacePile() => const RetroDesktopAvatarGroup(
  children: [
    RetroDesktopAvatar('AL', name: 'Alex Lee'),
    RetroDesktopAvatar('MK', name: 'Morgan Kim'),
    RetroDesktopAvatar('JR', name: 'Jamie Rivera'),
  ],
);
// The application's own picture in the frame: here one of the look's pixel objects, grown by whole pixels.
Widget kitSpecimenPicture() => const RetroDesktopPicture(
  label: 'A floppy disk',
  child: RetroDesktopObjectArt(RetroDesktopObject.floppy, fill: .6),
);
Widget kitSpecimenSurface() => kitValue(
  false,
  (value, change) => RetroDesktopSurface(
    label: 'Open folder',
    selected: value,
    onPressed: () => change(!value),
    child: const Text('A selectable surface'),
  ),
);
Widget kitSpecimenCard() => const RetroDesktopCard(
  title: 'Document details',
  child: Text('A titled card holds ordinary application content.'),
);
Widget kitSpecimenGroupedList() => const RetroDesktopListSection(
  title: 'Recent documents',
  footer: 'Stored on this computer',
  children: [
    RetroDesktopListTile(title: 'Notes', subtitle: 'Today'),
    RetroDesktopListTile(title: 'Plan', subtitle: 'Yesterday'),
  ],
);
Widget kitSpecimenDivider() => const RetroDesktopDivider();
Widget kitSpecimenAmount() =>
    const RetroDesktopAmount('1,024', label: 'Storage used', unit: 'MB');
Widget kitSpecimenMeter() =>
    const RetroDesktopMeter(label: 'Storage', value: 64, max: 100);
Widget kitSpecimenChart() => RetroDesktopBarChart(
  label: 'Files copied each day',
  labels: const ['Mon', 'Tue', 'Wed', 'Thu'],
  series: [
    RetroDesktopChartSeries('Documents', [4, 8, 6, 12]),
    RetroDesktopChartSeries('Pictures', [2, 5, 7, 9]),
  ],
);
Widget kitSpecimenLineChart() => RetroDesktopLineChart(
  label: 'Visits this week',
  labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
  series: [
    RetroDesktopChartSeries('This week', [12, 18, 9, 22, 17]),
    RetroDesktopChartSeries('Last week', [10, 11, 14, 13, 19]),
  ],
);
Widget kitSpecimenAreaChart() => RetroDesktopAreaChart(
  label: 'Disk used',
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May'],
  format: (v) => '${v.round()} GB',
  series: [
    RetroDesktopChartSeries('Disk used', [12, 15, 21, 24, 30]),
  ],
);
Widget kitSpecimenDonutChart() => RetroDesktopPieChart(
  label: 'What fills the disk',
  height: 200,
  labels: const ['Documents', 'Pictures', 'Music', 'Other'],
  series: [
    RetroDesktopChartSeries('Space', [42, 30, 18, 10]),
  ],
);
Widget kitSpecimenSparkline() => const Row(
  children: [
    Expanded(child: Text('Visits')),
    RetroDesktopSparkline(
      label: 'Visits, last seven days',
      values: [3, 5, 4, 8, 6, 9, 7],
    ),
  ],
);
Widget kitSpecimenChartEmpty() => RetroDesktopChart(
  label: 'Files shared',
  height: 120,
  series: [RetroDesktopChartSeries('Shared', const [])],
);
Widget kitSpecimenChartLoading() => RetroDesktopChart(
  label: 'Files shared',
  height: 120,
  loading: true,
  series: [RetroDesktopChartSeries('Shared', const [])],
);
Widget kitSpecimenBreadcrumbs() => kitAction(
  'Opened a folder',
  (press) => RetroDesktopBreadcrumb(
    items: [
      RetroDesktopBreadcrumbItem('Everything', onPressed: press),
      RetroDesktopBreadcrumbItem('Letters', onPressed: press),
      const RetroDesktopBreadcrumbItem('To the bank'),
    ],
  ),
);
Widget kitSpecimenPagination() => kitValue(
  3,
  (value, change) =>
      RetroDesktopPagination(count: 12, page: value, onChanged: change),
);
Widget kitSpecimenRating() => kitValue(
  4,
  (value, change) => RetroDesktopRating(
    label: 'Your rating',
    value: value.toDouble(),
    onChanged: change,
  ),
);
Widget kitSpecimenFileDrop() => kitValue(
  const ['notes.txt'],
  (files, change) => RetroDesktopFileUpload(
    label: 'Attachments',
    hint: 'Up to 10 MB each',
    files: files,
    onChoose: () => change([...files, 'file ${files.length + 1}.txt']),
    onRemove: (i) => change([...files]..removeAt(i)),
  ),
);
