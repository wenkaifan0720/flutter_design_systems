import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

void main() {
  group('RawTapTargets', () {
    test('a finger by default on phones, a pointer on desks', () {
      expect(RawInput.forPlatform(TargetPlatform.iOS), RawInput.touch);
      expect(RawInput.forPlatform(TargetPlatform.android), RawInput.touch);
      expect(RawInput.forPlatform(TargetPlatform.macOS), RawInput.pointer);
      const targets = RawTapTargets.fallback;
      expect(targets.floorOn(TargetPlatform.iOS), const Size.square(44));
      expect(targets.floorOn(TargetPlatform.windows), const Size.square(24));
      const pinned = RawTapTargets(input: RawInput.touch);
      expect(pinned.floorOn(TargetPlatform.macOS), const Size.square(44));
    });

    testWidgets('of reads the nearest scope, else the fallback', (
      tester,
    ) async {
      late RawTapTargets inside;
      late RawTapTargets outside;
      RawTapTargets? none;
      await tester.pumpWidget(
        Column(
          children: [
            Builder(
              builder: (context) {
                outside = RawTapTargets.of(context);
                none = RawTapTargets.maybeOf(context);
                return const SizedBox();
              },
            ),
            RawTapTargetScope(
              targets: const RawTapTargets(touch: Size.square(48)),
              child: Builder(
                builder: (context) {
                  inside = RawTapTargets.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      );
      expect(outside, RawTapTargets.fallback);
      expect(none, isNull);
      expect(inside.touch, const Size.square(48));
      expect(inside.pointer, const Size.square(24));
    });

    test('equality, copyWith and diagnostics', () {
      const a = RawTapTargets(touch: Size.square(48));
      expect(a, RawTapTargets.fallback.copyWith(touch: const Size.square(48)));
      expect(a.hashCode, const RawTapTargets(touch: Size.square(48)).hashCode);
      final description = a.toDiagnosticsNode().toStringDeep();
      expect(description, contains('touch: Size(48.0, 48.0)'));
      expect(description, isNot(contains('pointer')));
    });
  });

  group('TapTargetPadding', () {
    testWidgets('lays a small face out at the floor, centred', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: TapTargetPadding(
              child: GestureDetector(
                key: const Key('face'),
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox.square(dimension: 24),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(TapTargetPadding)), const Size(44, 44));
      expect(
        tester.getTopLeft(find.byKey(const Key('face'))),
        const Offset(10, 10),
      );
      // A tap in the margin, past the face, reaches it.
      await tester.tapAt(const Offset(2, 2));
      expect(taps, 1);
      // Past the target, nothing.
      await tester.tapAt(const Offset(46, 46));
      expect(taps, 1);
    });

    for (final (alignment, ltr, rtl) in const [
      (AlignmentDirectional.centerStart, Offset(0, 10), Offset(20, 10)),
      (AlignmentDirectional.centerEnd, Offset(20, 10), Offset(0, 10)),
      (AlignmentDirectional.topStart, Offset.zero, Offset(20, 0)),
      (AlignmentDirectional.bottomEnd, Offset(20, 20), Offset(0, 20)),
    ]) {
      testWidgets('$alignment: the face stands on those edges and the target '
          'grows away from them; right to left mirrors', (tester) async {
        for (final (direction, at) in [
          (TextDirection.ltr, ltr),
          (TextDirection.rtl, rtl),
        ]) {
          var taps = 0;
          await tester.pumpWidget(
            Directionality(
              textDirection: direction,
              child: Align(
                alignment: Alignment.topLeft,
                child: TapTargetPadding(
                  alignment: alignment,
                  child: GestureDetector(
                    key: const Key('face'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => taps++,
                    child: const SizedBox.square(dimension: 24),
                  ),
                ),
              ),
            ),
          );
          expect(
            tester.getSize(find.byType(TapTargetPadding)),
            const Size(44, 44),
          );
          expect(
            tester.getTopLeft(find.byKey(const Key('face'))),
            at,
            reason: '$direction',
          );
          // Every corner of the target reaches the face.
          for (final corner in const [
            Offset(1, 1),
            Offset(43, 1),
            Offset(1, 43),
            Offset(43, 43),
          ]) {
            await tester.tapAt(corner);
          }
          expect(taps, 4, reason: '$direction');
        }
      });
    }

    testWidgets('a face stands on whole device pixels, rounded toward its '
        'start edge and the top; right to left mirrors', (tester) async {
      // A 27 pt face centred in 44 would stand 8.5 in.
      for (final (ratio, ltr, rtl) in const [
        (1.0, Offset(8, 8), Offset(9, 8)),
        (2.0, Offset(8.5, 8.5), Offset(8.5, 8.5)),
        (3.0, Offset(25 / 3, 25 / 3), Offset(17 - 25 / 3, 25 / 3)),
      ]) {
        for (final (direction, at) in [
          (TextDirection.ltr, ltr),
          (TextDirection.rtl, rtl),
        ]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(devicePixelRatio: ratio),
              child: Directionality(
                textDirection: direction,
                child: const Align(
                  alignment: Alignment.topLeft,
                  child: TapTargetPadding(
                    child: SizedBox.square(key: Key('face'), dimension: 27),
                  ),
                ),
              ),
            ),
          );
          final face = tester.getTopLeft(find.byKey(const Key('face')));
          expect(face.dx, moreOrLessEquals(at.dx), reason: '$ratio $direction');
          expect(face.dy, moreOrLessEquals(at.dy), reason: '$ratio $direction');
        }
      }
      // A face flush with an edge stays flush.
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topLeft,
              child: TapTargetPadding(
                alignment: AlignmentDirectional.bottomStart,
                child: SizedBox(key: Key('face'), width: 27, height: 27),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('face'))),
        const Offset(17, 17),
      );
    });

    testWidgets("the control's node spans its target, so Flutter's "
        'tap-target guidelines pass, at a finger and at a pointer', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      Widget page(Widget control, [RawTapTargets? targets]) {
        final Widget centred = Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: control),
        );
        return targets == null
            ? centred
            : RawTapTargetScope(targets: targets, child: centred);
      }

      Widget face(Size size) => Semantics(
        button: true,
        label: '1M',
        onTap: () {},
        child: GestureDetector(
          onTap: () {},
          child: SizedBox.fromSize(size: size),
        ),
      );
      // Ledger's '1M': a 44 × 26 face.
      await tester.pumpWidget(page(face(const Size(44, 26))));
      await expectLater(tester, doesNotMeetGuideline(iOSTapTargetGuideline));
      await tester.pumpWidget(
        page(TapTargetPadding(child: face(const Size(44, 26)))),
      );
      expect(
        tester.getSemantics(find.byType(TapTargetPadding)).rect.size,
        const Size(44, 44),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      // A face on its start edge, at Android's 48.
      await tester.pumpWidget(
        page(
          TapTargetPadding(
            alignment: AlignmentDirectional.centerStart,
            child: face(const Size(28, 28)),
          ),
          const RawTapTargets(touch: Size.square(48), input: RawInput.touch),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      // A pointer's 24.
      const pointer = MinimumTapTargetGuideline(
        size: Size.square(24),
        link: 'https://www.w3.org/TR/WCAG22/#target-size-minimum',
      );
      await tester.pumpWidget(page(face(const Size(16, 16))));
      await expectLater(tester, doesNotMeetGuideline(pointer));
      await tester.pumpWidget(
        page(
          TapTargetPadding(child: face(const Size(16, 16))),
          const RawTapTargets(input: RawInput.pointer),
        ),
      );
      await expectLater(tester, meetsGuideline(pointer));
      semantics.dispose();
    });

    testWidgets('a face over the floor keeps its own size', (tester) async {
      await tester.pumpWidget(
        const Align(
          alignment: Alignment.topLeft,
          child: TapTargetPadding(
            minSize: Size.square(24),
            child: SizedBox(width: 120, height: 32),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(TapTargetPadding)),
        const Size(120, 32),
      );
    });

    testWidgets('it takes the floor from the scope and its input', (
      tester,
    ) async {
      await tester.pumpWidget(
        const RawTapTargetScope(
          targets: RawTapTargets(input: RawInput.pointer),
          child: Align(
            alignment: Alignment.topLeft,
            child: TapTargetPadding(child: SizedBox.square(dimension: 16)),
          ),
        ),
      );
      expect(tester.getSize(find.byType(TapTargetPadding)), const Size(24, 24));
    });
  });

  group('RawDensity', () {
    test('a step takes from the height and the padding, never past least', () {
      expect(RawDensity.standard.height(44), 44);
      expect(RawDensity.compact.height(44), 36);
      expect(RawDensity.compact.height(20), 16);
      expect(
        RawDensity.compact.padding(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        const EdgeInsets.fromLTRB(12, 6, 12, 6),
      );
      expect(const RawDensity(vertical: -1, heightStep: 2).height(40), 38);
    });

    test('desks are compact, phones standard', () {
      expect(
        RawDensity.defaultDensityForPlatform(TargetPlatform.macOS),
        RawDensity.compact,
      );
      expect(
        RawDensity.defaultDensityForPlatform(TargetPlatform.iOS),
        RawDensity.standard,
      );
    });

    test('lerp, equality and diagnostics', () {
      expect(
        RawDensity.lerp(RawDensity.standard, RawDensity.compact, .5),
        RawDensity.comfortable,
      );
      expect(
        RawDensity.compact.toDiagnosticsNode().toStringDeep(),
        allOf(contains('horizontal: -2.0'), isNot(contains('heightStep'))),
      );
    });
  });
}
