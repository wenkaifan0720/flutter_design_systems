// Raised and pressed don't stack up when parts nest: what each surface draws by what it stands on.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/frames.dart' show NeumorphicDraw;

import 'support.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadNeumorphicFonts();
  });

  group('raised and pressed, nesting', () {
    // The whole table: what each surface draws by what it stands on. The wrong nesting can't be written: it comes out as the right one.
    const draws = <(NeumorphicSurfaceLevel, NeumorphicDraw?, NeumorphicDraw)>[
      // On the wall, each is what it says.
      (NeumorphicSurfaceLevel.part, null, NeumorphicDraw.part),
      (NeumorphicSurfaceLevel.slab, null, NeumorphicDraw.slab),
      (NeumorphicSurfaceLevel.casting, null, NeumorphicDraw.casting),
      (NeumorphicSurfaceLevel.groove, null, NeumorphicDraw.groove),
      (NeumorphicSurfaceLevel.well, null, NeumorphicDraw.well),
      // A slab in a slab is only a small part, a slab on a part a step: shadows don't stack.
      (NeumorphicSurfaceLevel.slab, NeumorphicDraw.slab, NeumorphicDraw.part),
      (NeumorphicSurfaceLevel.slab, NeumorphicDraw.part, NeumorphicDraw.step),
      (
        NeumorphicSurfaceLevel.casting,
        NeumorphicDraw.slab,
        NeumorphicDraw.part,
      ),
      (NeumorphicSurfaceLevel.part, NeumorphicDraw.part, NeumorphicDraw.step),
      (NeumorphicSurfaceLevel.part, NeumorphicDraw.step, NeumorphicDraw.step),
      // A well in a slab is a real well. A well in a well, or a groove in a groove, is only a floor: a hole in a hole is mud.
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.slab, NeumorphicDraw.well),
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.well, NeumorphicDraw.floor),
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.floor, NeumorphicDraw.floor),
      (
        NeumorphicSurfaceLevel.groove,
        NeumorphicDraw.groove,
        NeumorphicDraw.floor,
      ),
      (
        NeumorphicSurfaceLevel.groove,
        NeumorphicDraw.floor,
        NeumorphicDraw.floor,
      ),
      // A well on a button is at most a groove, and a part stands in a well, a button in its bank.
      (NeumorphicSurfaceLevel.well, NeumorphicDraw.part, NeumorphicDraw.groove),
      (NeumorphicSurfaceLevel.part, NeumorphicDraw.well, NeumorphicDraw.part),
    ];
    for (final (cast, on, want) in draws) {
      test('${cast.name} on ${on?.name ?? 'the wall'} draws ${want.name}', () {
        expect(NeumorphicSurface.resolve(cast, on), want);
      });
    }

    testWidgets('the parts obey it: a well in a slab, a well in that', (
      tester,
    ) async {
      await tester.pumpWidget(
        neumorphicApp(
          const NeumorphicSlab(
            child: NeumorphicWell(
              child: NeumorphicColumn(
                children: [
                  Text('a', key: ValueKey('a')),
                  NeumorphicWell(child: Text('b', key: ValueKey('b'))),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        NeumorphicSurface.on(tester.element(find.byKey(const ValueKey('a')))),
        NeumorphicDraw.well,
      );
      expect(
        NeumorphicSurface.on(tester.element(find.byKey(const ValueKey('b')))),
        NeumorphicDraw.floor,
      );
    });
  });
}
