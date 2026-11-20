// A pagination is one row of keys: the steps are keys of the pages' own face, size and gap, at
// every width and either way the words read; a page held under a finger goes down toward the wall, never flush nor
// into a well, and comes back when it is let go, so it never reads as a second current page; keyboard focus lifts a
// key and never sinks it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

Finder _key(String label) =>
    find.byWidgetPredicate((w) => w is NeumorphicTap && w.label == label);

NeumorphicSurface _face(WidgetTester tester, String label) =>
    tester.widget<NeumorphicSurface>(
      find.descendant(
        of: _key(label),
        matching: find.byType(NeumorphicSurface),
      ),
    );

Future<List<int>> _pump(
  WidgetTester tester, {
  required double width,
  int count = 12,
  int page = 5,
  TextDirection direction = TextDirection.ltr,
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final asked = <int>[];
  await tester.pumpWidget(
    neumorphicApp(
      Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: NeumorphicPagination(
            count: count,
            page: page,
            onChanged: asked.add,
          ),
        ),
      ),
      direction: direction,
      width: width,
      dark: dark,
    ),
  );
  await tester.pumpAndSettle();
  return asked;
}

void main() {
  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'one key size and one gap in the row @$width ${direction.name}',
        (tester) async {
          await _pump(tester, width: width, direction: direction);
          final faces = [
            for (final e
                in find
                    .descendant(
                      of: find.byType(NeumorphicPagination),
                      matching: find.byType(NeumorphicSurface),
                    )
                    .evaluate())
              tester.getRect(find.byWidget(e.widget)),
          ]..sort((a, b) => a.left.compareTo(b.left));
          for (final f in faces) {
            expect(
              f.width,
              closeTo(faces.first.width, .01),
              reason: 'every key one size: $f',
            );
            expect(
              f.height,
              closeTo(faces.first.height, .01),
              reason: 'every key one size: $f',
            );
          }
          if (faces.length == 2) {
            // Too narrow for five pages: the two steps end the row, their faces on its edges, the page in words.
            final row = tester.getRect(find.byType(NeumorphicPagination));
            expect(faces.first.left, closeTo(row.left, .01));
            expect(faces.last.right, closeTo(row.right, .01));
            expect(find.textContaining('6'), findsOneWidget);
            return;
          }
          expect(faces.length, greaterThanOrEqualTo(5));
          final gaps = [
            for (var i = 1; i < faces.length; i++)
              faces[i].left - faces[i - 1].right,
          ];
          final gap = gaps.reduce((a, b) => a < b ? a : b);
          // Two faces never touch, nor their shadows meet: a gap of 8 at the least.
          expect(gap, greaterThanOrEqualTo(8 - .01), reason: 'gaps $gaps');
          final cell = faces[1].left - faces.first.left;
          // Neighbouring keys stand one gap apart; an ellipsis between two pages takes one key's place.
          for (final g in gaps) {
            expect(
              (g - gap).abs() < .01 || (g - gap - cell).abs() < .01,
              isTrue,
              reason: 'gaps $gaps',
            );
          }
          expect(
            gaps.first,
            closeTo(gap, .01),
            reason: 'the step at the start',
          );
          expect(gaps.last, closeTo(gap, .01), reason: 'the step at the end');
        },
        // Touch keys (standard density) and a pointer's (compact), as a phone and a desktop draw them.
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.macOS,
        }),
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'a page held goes down, never into a well, and back when let go '
      '${dark ? 'night' : 'day'}',
      (tester) async {
        final asked = await _pump(
          tester,
          width: 1440,
          count: 9,
          page: 3,
          dark: dark,
        );
        expect(_face(tester, '4 of 9').cast, NeumorphicSurfaceLevel.groove);
        expect(
          tester.widget<NeumorphicTap>(_key('6 of 9')).pressRelief,
          isFalse,
          reason: 'the face draws its own press: no inset rings it',
        );
        final words = tester.getTopLeft(
          find.descendant(of: _key('6 of 9'), matching: find.text('6')),
        );
        final press = await tester.startGesture(
          tester.getCenter(_key('6 of 9')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final held = _face(tester, '6 of 9');
        expect(held.cast, NeumorphicSurfaceLevel.part, reason: 'not the well');
        // Down, and still raised: short of flush (.5), where a face with no relief left reads as out of use.
        expect(
          held.depression,
          closeTo(.35, .001),
          reason: 'down, still a key',
        );
        expect(
          tester
              .getTopLeft(
                find.descendant(of: _key('6 of 9'), matching: find.text('6')),
              )
              .dy,
          words.dy + 1,
          reason: 'its words a pixel down',
        );
        // Slid off and let go: a cancelled press.
        await press.moveTo(const Offset(1400, 800));
        await press.up();
        await tester.pumpAndSettle();
        expect(asked, isEmpty);
        final back = _face(tester, '6 of 9');
        expect(back.cast, NeumorphicSurfaceLevel.part);
        expect(back.depression, 0);
        expect(
          tester
              .getTopLeft(
                find.descendant(of: _key('6 of 9'), matching: find.text('6')),
              )
              .dy,
          words.dy,
        );
        // A press let go on the key asks for its page.
        await tester.tap(_key('6 of 9'));
        await tester.pumpAndSettle();
        expect(asked, [5]);
      },
    );
  }

  testWidgets('keyboard focus lifts a page key and never sinks it', (
    tester,
  ) async {
    await _pump(tester, width: 1440, count: 9, page: 3);
    var landed = false;
    for (var i = 0; i < 12 && !landed; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused != null &&
          find
              .descendant(
                of: _key('6 of 9'),
                matching: find.byWidget(focused.widget),
              )
              .evaluate()
              .isNotEmpty) {
        landed = true;
      }
    }
    expect(landed, isTrue, reason: 'Tab reaches the key');
    final face = _face(tester, '6 of 9');
    expect(face.cast, NeumorphicSurfaceLevel.part);
    expect(face.depression, 0);
    // The lift goes round the whole face: not a smaller key inside it.
    final drawn = tester.getSize(
      find.descendant(
        of: _key('6 of 9'),
        matching: find.byType(NeumorphicSurface),
      ),
    );
    final lift = tester.widget<NeumorphicTap>(_key('6 of 9')).focusSize!;
    expect(lift.width, closeTo(drawn.width, .01));
    expect(lift.height, closeTo(drawn.height, .01));
  });

  testWidgets(
    'a step at the end of the pages is out of use, a page key in shape',
    (tester) async {
      await _pump(tester, width: 1440, count: 9, page: 0);
      expect(
        tester.getSize(
          find.descendant(
            of: _key('Previous page'),
            matching: find.byType(NeumorphicSurface),
          ),
        ),
        tester.getSize(
          find.descendant(
            of: _key('2 of 9'),
            matching: find.byType(NeumorphicSurface),
          ),
        ),
      );
      expect(
        tester.widget<NeumorphicTap>(_key('Previous page')).onPressed,
        isNull,
      );
      expect(
        tester.widget<NeumorphicTap>(_key('Next page')).onPressed,
        isNotNull,
      );
    },
  );
}
