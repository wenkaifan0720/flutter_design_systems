// Studio's targets stand at ui_core's tap floor (40 for a finger, 24 for a
// pointer), its chip runs keep it, and its bank keys hold their legend at
// large text.
import 'dart:async';

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double text = 1,
}) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, 1688);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: StudioHost(brightness: Brightness.light, child: app!),
      ),
      home: Center(child: child),
    ),
  );
  await tester.pumpAndSettle();
}

// A glyph's room, drawn as nothing: the legends are what is read.
const _glyph = SizedBox.square(dimension: 20);
const _places = [
  StudioDestination(icon: _glyph, label: 'Home'),
  StudioDestination(icon: _glyph, label: 'Library'),
  StudioDestination(icon: _glyph, label: 'Record'),
];

void main() {
  setUpAll(studioLoadFonts);

  for (final (platform, floor) in [
    (TargetPlatform.android, const Size(40, 40)),
    (TargetPlatform.macOS, const Size(24, 24)),
  ]) {
    final on = TargetPlatformVariant.only(platform);
    group('on ${platform.name}', () {
      testWidgets("a sheet's finger slot is the floor, never under the slot", (
        tester,
      ) async {
        late BuildContext page;
        await _show(
          tester,
          Builder(
            builder: (context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        );
        unawaited(
          showStudioBottomSheet<void>(
            context: page,
            title: 'Export',
            builder: (context) => const Text('MP3, 128 kbps'),
          ),
        );
        await tester.pumpAndSettle();
        // The floor, never under the slot's length (40), which ui_core's
        // handle also keeps.
        expect(
          tester.getSize(find.byType(RawBottomSheetDragHandle)),
          const Size(40, 40),
        );
      }, variant: on);

      testWidgets("a reorderable row's grip is the floor wide", (tester) async {
        await _show(
          tester,
          SizedBox(
            width: 320,
            child: StudioReorderableList<String>(
              items: const ['Intro', 'Interview'],
              labelOf: (s) => s,
              onReorder: (_, _) {},
              itemBuilder: (context, s) => Text(s),
            ),
          ),
        );
        final list = tester.getTopLeft(
          find.byType(StudioReorderableList<String>),
        );
        // Past the glass's lip, the grip, then the row's words.
        expect(
          tester.getTopLeft(find.text('Intro')).dx - list.dx,
          closeTo(StudioMetrics.recessInset + floor.width, 0.5),
        );
      }, variant: on);

      testWidgets(
        "a range fader's caps are the floor tall, never under a cap",
        (tester) async {
          await _show(
            tester,
            SizedBox(
              width: 320,
              child: StudioRangeFader(
                values: const StudioRangeValues(10, 40),
                max: 60,
                onChanged: (_) {},
              ),
            ),
          );
          final thumb = tester
              .widget<RawRangeSlider>(find.byType(RawRangeSlider))
              .thumbSize;
          expect(
            thumb.height,
            floor.height < StudioFader.cap.height
                ? StudioFader.cap.height
                : floor.height,
          );
        },
        variant: on,
      );

      testWidgets('tag runs and breadcrumbs lay out as chip groups', (
        tester,
      ) async {
        await _show(
          tester,
          SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StudioTagInput<String>(
                  values: const ['Audio', 'Field', 'Night'],
                  labelOf: (s) => s,
                  onChanged: (_) {},
                ),
                StudioBreadcrumb(
                  crumbs: [
                    StudioCrumb('Files', onPressed: () {}),
                    const StudioCrumb('Drafts'),
                  ],
                ),
              ],
            ),
          ),
        );
        for (final owner in [
          find.byType(StudioTagInput<String>),
          find.byType(StudioBreadcrumb),
        ]) {
          expect(
            find.descendant(of: owner, matching: find.byType(RawChipGroup)),
            findsOneWidget,
          );
        }
        for (final label in ['Audio', 'Field', 'Night']) {
          final plate = find.ancestor(
            of: find.text(label),
            matching: find.byType(StudioTagInput<String>),
          );
          expect(plate, findsOneWidget);
        }
        DesignTapTargetCheck(
          look: 'Studio',
          input: floor.height == 40 ? RawInput.touch : RawInput.pointer,
        ).check(tester.element(find.byType(StudioBreadcrumb))).verify();
      }, variant: on);
    });
  }

  testWidgets("the bar's keys stand 52 tall at the reader's own text", (
    tester,
  ) async {
    await _show(
      tester,
      StudioNavigationBar(
        destinations: _places,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    );
    // The faceplate's padding (8 and 8), the recess's lips (4 and 4) and
    // the key.
    expect(tester.getSize(find.byType(StudioNavigationBar)).height, 52 + 24);
  });

  for (final text in [1.5, 2.0, 3.0]) {
    testWidgets(
      "the bar's legends keep clear of their keys' edges at ${text}x",
      (tester) async {
        await _show(
          tester,
          StudioNavigationBar(
            destinations: _places,
            selectedIndex: 1,
            onDestinationSelected: (_) {},
          ),
          text: text,
        );
        final report = await const DesignFaceInsetCheck(look: 'Studio').check(
          tester.element(find.byType(StudioNavigationBar)),
          runAsync: tester.runAsync,
        );
        report.verify();
      },
    );
  }
}
