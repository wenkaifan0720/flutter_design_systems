// Studio's secondary print, lit legends, drum figures and a chosen day's
// figure read at Material's
// 4.5:1 where an app lays them: on the chassis, by day and by night, in the
// look's own light and in an app's.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _page = ValueKey('page');

Future<void> _show(
  WidgetTester tester,
  StudioThemeData theme,
  Widget child,
) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(780, 3600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => StudioHost(
        brightness: theme.colors.brightness,
        theme: theme,
        darkTheme: theme,
        child: app!,
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          key: _page,
          color: StudioTheme.of(context).colors.chassis,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _parts() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    StudioTabBar(
      tabs: const ['Overview', 'Activity'],
      selectedIndex: 0,
      onChanged: (_) {},
    ),
    const SizedBox(height: 12),
    StudioBreadcrumb(
      crumbs: [
        StudioCrumb('Files', onPressed: () {}),
        const StudioCrumb('Drafts'),
      ],
    ),
    const SizedBox(height: 12),
    const StudioStepProgress(
      steps: ['Cart', 'Address', 'Review'],
      currentStep: 0,
    ),
    const SizedBox(height: 12),
    const StudioSectionHeader('Today'),
    const SizedBox(height: 12),
    const StudioTimeline(
      entries: [
        StudioTimelineEntry(title: 'Packed', time: '10 am', done: true),
      ],
    ),
    const SizedBox(height: 12),
    const StudioDescriptionList(
      entries: [
        StudioDescription('Room', 'Hall'),
        StudioDescription('Day', 'Monday'),
      ],
    ),
    const SizedBox(height: 12),
    const StudioFormField(
      labelText: 'Project name',
      helperText: 'For example, Field notes.',
      child: StudioTextField(),
    ),
    const SizedBox(height: 12),
    StudioListTile(title: 'Route change', subtitle: 'Unread', onTap: () {}),
    const SizedBox(height: 12),
    StudioWheelPicker<int>(
      semanticLabel: 'Day in November',
      items: const [10, 11, 12, 13, 14],
      value: 12,
      onChanged: (_) {},
      labelOf: (day) => '$day',
    ),
    const SizedBox(height: 12),
    StudioTimePicker(
      semanticLabel: 'Reminder',
      value: const StudioTime(hour: 9, minute: 30),
      onChanged: (_) {},
    ),
    const SizedBox(height: 12),
    // A chosen day's figure on its lit slot, today's beside it.
    StudioCalendar(
      firstDate: DateTime(2026, 11),
      lastDate: DateTime(2026, 11, 30),
      selectedDate: DateTime(2026, 11, 12),
      currentDate: DateTime(2026, 11, 20),
      onDateChanged: (_) {},
    ),
  ],
);

void main() {
  setUpAll(studioLoadFonts);
  final themes = <String, StudioThemeData Function(Brightness)>{
    'its own light': StudioThemeData.anodised,
    for (final p in DesignPalette.briefs)
      p.name: (b) => StudioThemeData.from(
        indicator: p.accent,
        finish: p.neutral,
        brightness: b,
      ),
  };
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    for (final b in Brightness.values) {
      testWidgets('the parts read on the chassis in $name by ${b.name}', (
        tester,
      ) async {
        await _show(tester, theme(b), _parts());
        final report = await const DesignContrastCheck(
          look: 'Studio',
        ).check(tester.element(find.byKey(_page)), runAsync: tester.runAsync);
        expect(report.problems, isEmpty);
        expect(report.advisories, isEmpty);
      });
    }
  }
}
