// RawChipGroup: chips wrap onto runs, the room between two faces the
// look's spacing or their targets' room, whichever is more; targets never
// overlap and each keeps the floor.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const _floor = Size.square(40);

Widget _chip(int i, Size face, {VoidCallback? onTap}) => TapTargetPadding(
  key: ValueKey('target $i'),
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox.fromSize(key: ValueKey('face $i'), size: face),
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget group, {
  double width = 230,
  TextDirection direction = TextDirection.ltr,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: RawTapTargetScope(
        targets: const RawTapTargets(input: RawInput.touch),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: group),
        ),
      ),
    ),
  );
}

Rect _face(WidgetTester tester, int i) =>
    tester.getRect(find.byKey(ValueKey('face $i')));
Rect _target(WidgetTester tester, int i) =>
    tester.getRect(find.byKey(ValueKey('target $i')));

void _neverOverlap(WidgetTester tester, int count) {
  for (var a = 0; a < count; a++) {
    final ra = _target(tester, a);
    expect(ra.width, greaterThanOrEqualTo(_floor.width));
    expect(ra.height, greaterThanOrEqualTo(_floor.height));
    for (var b = a + 1; b < count; b++) {
      final both = ra.intersect(_target(tester, b));
      expect(
        both.width <= 1e-6 || both.height <= 1e-6,
        isTrue,
        reason: 'targets $a and $b overlap: $both',
      );
    }
  }
}

void main() {
  for (final (face, runSpacing, faceGap, targetGap) in const [
    // The user's case: 32 chips 8 apart on a 40 floor, not 8 + 8.
    (32.0, 8.0, 8.0, 0.0),
    // Spacing enough for the targets: the faces keep it.
    (36.0, 8.0, 8.0, 4.0),
    // Spacing short of the targets' room: the faces stand the floor less a
    // face apart, the targets meeting.
    (24.0, 4.0, 16.0, 0.0),
    // Faces at the floor: the spacing alone.
    (40.0, 6.0, 6.0, 6.0),
  ]) {
    testWidgets('runs of ${face.toInt()} px faces on a 40 floor, run spacing '
        '${runSpacing.toInt()}: faces ${faceGap.toInt()} apart', (
      tester,
    ) async {
      await _pump(
        tester,
        RawChipGroup(
          spacing: 8,
          runSpacing: runSpacing,
          children: [for (var i = 0; i < 6; i++) _chip(i, Size(100, face))],
        ),
      );
      // Two to a run (100 + 8 + 100 in 230), three runs.
      for (final (above, below) in const [(0, 2), (2, 4), (1, 3)]) {
        expect(_face(tester, below).top - _face(tester, above).bottom, faceGap);
        expect(
          _target(tester, below).top - _target(tester, above).bottom,
          targetGap,
        );
      }
      expect(_face(tester, 1).left - _face(tester, 0).right, 8);
      _neverOverlap(tester, 6);
    });
  }

  testWidgets('along a run, faces narrower than the floor stand its room '
      'apart', (tester) async {
    await _pump(
      tester,
      RawChipGroup(
        spacing: 4,
        children: [for (var i = 0; i < 4; i++) _chip(i, const Size(28, 28))],
      ),
    );
    for (var i = 0; i < 3; i++) {
      expect(_face(tester, i + 1).left - _face(tester, i).right, 12);
      expect(_target(tester, i + 1).left, _target(tester, i).right);
    }
    _neverOverlap(tester, 4);
  });

  testWidgets('faces of many sizes: no two targets overlap, each meets the '
      'floor, faces keep the spacing', (tester) async {
    const sizes = [
      Size(60, 24),
      Size(90, 36),
      Size(30, 30),
      Size(120, 44),
      Size(20, 20),
      Size(70, 32),
      Size(50, 28),
      Size(140, 40),
      Size(36, 36),
    ];
    for (final direction in TextDirection.values) {
      await _pump(
        tester,
        RawChipGroup(
          spacing: 6,
          runSpacing: 6,
          children: [for (final (i, s) in sizes.indexed) _chip(i, s)],
        ),
        direction: direction,
      );
      _neverOverlap(tester, sizes.length);
      for (var a = 0; a < sizes.length; a++) {
        for (var b = a + 1; b < sizes.length; b++) {
          final fa = _face(tester, a), fb = _face(tester, b);
          final apartX = fb.left >= fa.right
              ? fb.left - fa.right
              : fa.left - fb.right;
          final apartY = fb.top >= fa.bottom
              ? fb.top - fa.bottom
              : fa.top - fb.bottom;
          expect(
            apartX >= 6 - 1e-6 || apartY >= 6 - 1e-6,
            isTrue,
            reason: 'faces $a and $b stand closer than the spacing',
          );
        }
      }
    }
  });

  testWidgets('right to left mirrors left to right', (tester) async {
    Widget group() => RawChipGroup(
      spacing: 8,
      runSpacing: 8,
      children: [for (var i = 0; i < 5; i++) _chip(i, Size(40.0 + i * 15, 32))],
    );
    await _pump(tester, group());
    final ltr = [for (var i = 0; i < 5; i++) _face(tester, i)];
    await _pump(tester, group(), direction: TextDirection.rtl);
    for (var i = 0; i < 5; i++) {
      final rtl = _face(tester, i);
      expect(rtl.top, ltr[i].top);
      expect(rtl.right, 230 - ltr[i].left);
    }
  });

  testWidgets('down: runs are columns, the same room between faces', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RawTapTargetScope(
          targets: const RawTapTargets(input: RawInput.touch),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 150,
              child: RawChipGroup(
                direction: Axis.vertical,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < 6; i++) _chip(i, const Size(24, 60)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Two to a column (60 + 8 + 60 in 150); columns 16 apart (40 - 24).
    expect(_face(tester, 1).top - _face(tester, 0).bottom, 8);
    expect(_face(tester, 2).left - _face(tester, 0).right, 16);
    expect(_target(tester, 2).left, _target(tester, 0).right);
    _neverOverlap(tester, 6);
  });

  testWidgets('children with no tap target lay out as a Wrap lays them', (
    tester,
  ) async {
    for (final alignment in WrapAlignment.values) {
      for (final cross in WrapCrossAlignment.values) {
        List<Widget> boxes() => [
          for (var i = 0; i < 7; i++)
            SizedBox(
              key: ValueKey('face $i'),
              width: 30.0 + 9 * i,
              height: 10.0 + 3 * (i % 3),
            ),
        ];
        await _pump(
          tester,
          Wrap(
            spacing: 5,
            runSpacing: 7,
            alignment: alignment,
            crossAxisAlignment: cross,
            children: boxes(),
          ),
        );
        final wrap = [for (var i = 0; i < 7; i++) _face(tester, i)];
        await _pump(
          tester,
          RawChipGroup(
            spacing: 5,
            runSpacing: 7,
            alignment: alignment,
            crossAxisAlignment: cross,
            children: boxes(),
          ),
        );
        for (var i = 0; i < 7; i++) {
          expect(
            _face(tester, i),
            rectMoreOrLessEquals(wrap[i]),
            reason: '$alignment $cross $i',
          );
        }
      }
    }
  });

  testWidgets('its dry layout is its layout', (tester) async {
    await _pump(
      tester,
      RawChipGroup(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 6; i++) _chip(i, Size(60.0 + i * 7, 32)),
        ],
      ),
    );
    final group = tester.renderObject<RenderChipGroup>(
      find.byType(RawChipGroup),
    );
    expect(group.getDryLayout(group.constraints), group.size);
    expect(group.getMaxIntrinsicHeight(230), group.size.height);
  });

  testWidgets("a tap on a target's room between faces reaches its chip", (
    tester,
  ) async {
    final taps = <int>[];
    await _pump(
      tester,
      RawChipGroup(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var i = 0; i < 4; i++)
            _chip(i, const Size(100, 32), onTap: () => taps.add(i)),
        ],
      ),
    );
    // Between the first run's faces and the second's: 4 px of each target.
    final gapTop = _face(tester, 0).bottom;
    await tester.tapAt(Offset(50, gapTop + 2));
    await tester.tapAt(Offset(50, gapTop + 6));
    expect(taps, [0, 2]);
  });
}
