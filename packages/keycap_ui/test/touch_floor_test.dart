// Keycap's parts drawn at a finger's size take ui_core's touch floor, 40 by
// 40, on every input (was Keycap's own 48 under a finger and 44 elsewhere),
// or the floor of an app's RawTapTargetScope: a slider's cap, page dots'
// strip, a reorderable row's grip and the close key in a sheet's head. A tag input's tags and a
// breadcrumb's places lay out in RawChipGroup, their targets taking the
// room between their faces.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _floor48 = RawTapTargets(touch: Size.square(48));

Future<void> _show(
  WidgetTester tester,
  Widget part, {
  RawTapTargets? targets,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          KeycapHost(brightness: Brightness.light, child: app!),
      home: Builder(
        builder: (context) {
          final body = Align(
            alignment: Alignment.topCenter,
            child: Padding(padding: const EdgeInsets.all(24), child: part),
          );
          return targets == null
              ? body
              : RawTapTargetScope(targets: targets, child: body);
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(keycapLoadFonts);
  final floor = RawTapTargets.fallback.touch;

  for (final (name, targets, side) in [
    ('the touch floor', null, floor.width),
    ('an app\'s floor of 48', _floor48, 48.0),
  ]) {
    testWidgets(
      "a slider's cap takes $name, on every input",
      (tester) async {
        await _show(
          tester,
          SizedBox(
            width: 300,
            child: KeycapSlider(value: 0.4, onChanged: (_) {}),
          ),
          targets: targets,
        );
        expect(tester.getSize(find.byType(RawValueHandle)).width, side);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.android,
        TargetPlatform.macOS,
      }),
    );

    testWidgets("page dots' strip takes $name", (tester) async {
      await _show(
        tester,
        KeycapPageDots(pageCount: 4, page: 1, onPageChanged: (_) {}),
        targets: targets,
      );
      expect(tester.getSize(find.byType(KeycapPageDots)).height, side);
    });

    testWidgets("a reorderable row's grip takes $name", (tester) async {
      await _show(
        tester,
        SizedBox(
          width: 340,
          height: 300,
          child: KeycapReorderableList<String>(
            items: const ['Work', 'Home'],
            title: (f) => f,
            onReorder: (_, _) {},
          ),
        ),
        targets: targets,
      );
      final grip = find.ancestor(
        of: find.byIcon(LucideIcons.gripVertical).first,
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(grip.first), Size(side, side));
    });
  }

  testWidgets("a sheet's close key takes the touch floor", (tester) async {
    const side = 40.0;
    {
      await _show(
        tester,
        Builder(
          builder: (context) => KeycapButton(
            onPressed: () => showKeycapBottomSheet<void>(
              context: context,
              title: 'Move to folder',
              builder: (context) => const Text('Work'),
            ),
            child: const Text('Move'),
          ),
        ),
      );
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();
      final close = find.ancestor(
        of: find.byIcon(LucideIcons.x),
        matching: find.byType(KeycapIconButton),
      );
      expect(tester.getSize(close).height, greaterThanOrEqualTo(side));
      expect(tester.getSize(close).height, lessThan(side + 1));
    }
  });

  testWidgets("a tag input's tags lay out in a chip group", (tester) async {
    await _show(
      tester,
      SizedBox(
        width: 340,
        child: KeycapTagInput<String>(
          labelText: 'Tags',
          values: const ['Planning', 'Design', 'Research'],
          options: const ['Planning', 'Design', 'Research'],
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(KeycapTagInput<String>),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
  });

  testWidgets("a tag input's runs sit as far from the well's top as from "
      'its start', (tester) async {
    Rect faceOf(String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(SizedBox))
          .first,
    );
    // One run: the field keeps its height.
    await _show(
      tester,
      SizedBox(
        width: 340,
        child: KeycapTagInput<String>(
          values: const ['Planning'],
          onChanged: (_) {},
        ),
      ),
    );
    final field = find.byType(RawTagInput<String>);
    expect(tester.getSize(field).height, 48);
    // Three runs of tags and a run for the entry.
    await _show(
      tester,
      SizedBox(
        width: 340,
        child: KeycapTagInput<String>(
          values: const [
            'Morning',
            'Evening',
            'Weekend',
            'Anytime',
            'Focus',
            'Outdoors',
          ],
          onChanged: (_) {},
        ),
      ),
    );
    final well = tester.getRect(field);
    final first = faceOf('Morning');
    expect(
      first.top - well.top,
      moreOrLessEquals(first.left - well.left, epsilon: 1),
    );
  });

  testWidgets("a breadcrumb's places lay out in a chip group", (tester) async {
    // From 600 wide, where the whole trail shows (a phone shows the way up).
    await _show(
      tester,
      width: 1024,
      KeycapBreadcrumb(
        crumbs: [
          KeycapCrumb('Notes', onPressed: () {}),
          KeycapCrumb('Work', onPressed: () {}),
          const KeycapCrumb('Plans'),
        ],
      ),
    );
    expect(
      find.descendant(
        of: find.byType(KeycapBreadcrumb),
        matching: find.byType(RawChipGroup),
      ),
      findsOneWidget,
    );
  });
}
