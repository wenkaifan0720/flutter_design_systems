import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';
import 'world_checks.dart';

/// Each everyday part, laid at the start of a screen 360 wide, mirrors in right to left (ui_core's shared check): its
/// [marker] stands as far from the right as it stood from the left, at the same height and size.
void main() {
  setUpAll(loadNeumorphicFonts);
  final parts = <String, (Widget Function(), Finder)>{
    'button with an icon': (
      () => NeumorphicButton(
        'Save',
        icon: NeumorphicGlyphs.plus,
        onPressed: () {},
      ),
      find.byIcon(NeumorphicGlyphs.plus),
    ),
    'switch row': (
      () => NeumorphicSwitchRow(label: 'Share', value: true, onChanged: (_) {}),
      find.byType(NeumorphicSwitch),
    ),
    'checkbox and its label': (
      () => NeumorphicCheckbox(value: true, label: 'Agree', onChanged: (_) {}),
      find.descendant(
        of: find.byType(NeumorphicCheckbox),
        matching: find.byType(NeumorphicSurface),
      ),
    ),
    'segmented button': (
      () => NeumorphicSegmentedButton<String>(
        label: 'Plan',
        segments: const [
          NeumorphicButtonSegment('m', 'Monthly'),
          NeumorphicButtonSegment('y', 'Yearly'),
        ],
        value: 'y',
        onChanged: (_) {},
      ),
      find.text('Monthly'),
    ),
    'list tile': (
      () => NeumorphicListSection(
        label: 'Account',
        children: [NeumorphicListTile(title: 'Profile', onPressed: () {})],
      ),
      find.text('Profile'),
    ),
    'text field': (
      () => const NeumorphicTextField(label: 'Full name', initialValue: 'Ada'),
      find.text('Full name'),
    ),
    'deletable chip': (
      () => Align(
        alignment: AlignmentDirectional.centerStart,
        child: NeumorphicChip('Warm', onDeleted: () {}),
      ),
      find.text('Warm'),
    ),
  };
  for (final MapEntry(key: name, value: (part, marker)) in parts.entries) {
    testWidgets('$name mirrors right to left', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await expectMirrorsInRtl(
        tester,
        (direction) => neumorphicApp(
          Align(alignment: AlignmentDirectional.topStart, child: part()),
          direction: direction,
        ),
        parts: [marker.first],
      );
    });
  }

  // A loading row is painted, not laid out: between its two lines only the avatar's well is pressed in, so that band
  // shows which end the avatar stands at. It stood at the left in right to left too.
  testWidgets('a loading row mirrors right to left', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const key = Key('skeleton');
    Future<(double, double)> ends(TextDirection direction) async {
      await tester.pumpWidget(
        neumorphicApp(
          const Align(
            alignment: AlignmentDirectional.topStart,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(width: 360, child: NeumorphicSkeleton.row()),
            ),
          ),
          direction: direction,
        ),
      );
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(key),
      );
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        return image.toByteData();
      }))!;
      final width = boundary.size.width.round();
      int at(int x, int y) => bytes.getUint8((y * width + x) * 4);
      // Between the lines (12 tall from 7, 10 apart): only the avatar is pressed in there.
      const y = 24;
      final ground = at(width ~/ 2, y);
      double off(Iterable<int> xs) =>
          xs.map((x) => (at(x, y) - ground).abs()).reduce((a, b) => a + b) /
          xs.length;
      return (
        off([for (var x = 4; x < 40; x++) x]),
        off([for (var x = width - 40; x < width - 4; x++) x]),
      );
    }

    final (ltrStart, ltrEnd) = await ends(TextDirection.ltr);
    final (rtlLeft, rtlRight) = await ends(TextDirection.rtl);
    expect(ltrStart, greaterThan(ltrEnd + 2), reason: 'the avatar at the left');
    expect(
      rtlRight,
      greaterThan(rtlLeft + 2),
      reason: 'the avatar at the right',
    );
  }, tags: ['goldens']);
}
