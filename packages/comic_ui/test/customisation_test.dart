// What an app may change in Comic and what it may not (0.2.0, the customisation pass): Flutter's own widgets under
// Comic set their words in the theme's text face, so a typeface an app gives reaches them; the dials 0.2.0 deprecates
// (rounded corners, a free motion, a type scale, free stroke widths) still do what they did until they go; and a part
// whose style resolves a see-through fill or overlay asserts in debug builds, naming law 1 (flat opaque inks).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

Widget _under(ComicThemeData data, Widget child) => MaterialApp(
  home: ComicTheme(
    data: data,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets("Flutter's own widgets under Comic read the theme's text face", (
    tester,
  ) async {
    String? family;
    Future<void> read(ComicThemeData data) async {
      await tester.pumpWidget(
        _under(
          data,
          Builder(
            builder: (context) {
              family = Theme.of(context).textTheme.bodyMedium?.fontFamily;
              return const SizedBox();
            },
          ),
        ),
      );
    }

    await read(ComicThemeData.offset());
    expect(family, endsWith(ComicTypeface.look.text));
    await read(
      ComicThemeData.offset().copyWith(
        typeface: const ComicTypeface.app(
          display: 'BrandDisplay',
          text: 'BrandText',
        ),
      ),
    );
    expect(family, 'BrandText');
    // The same colours with another face: the bridge follows the face, not only the inks.
    await read(ComicThemeData.offset());
    expect(family, endsWith(ComicTypeface.look.text));
  });

  test('the deprecated dials still do what they did until they go', () {
    final rounded = ComicThemeData.offset().copyWith(
      shapes: ComicShapes.rounded(8),
    );
    expect(
      rounded.shapes.small,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    final slow = ComicThemeData.offset().copyWith(
      motion: const ComicMotion(press: Duration(milliseconds: 300)),
    );
    expect(slow.motion.press, const Duration(milliseconds: 300));
    expect(const ComicTypeface(scale: 1.1).scale, 1.1);
    expect(ComicTypeface.look.copyWith(scale: .9).scale, .9);
    expect(const ComicStrokes(regular: 2).regular, 2);
    expect(ComicStrokes.standard.copyWith(heavy: 4).heavy, 4);
    expect(ComicStrokes.look.regular, 2.5);
    // The two steps: the look's own contours (a theme's default) and bold.
    expect(ComicThemeData.offset().strokes, ComicStrokes.standard);
    expect(ComicStrokes.standard.isEmpty, isTrue);
    expect(ComicStrokes.bold.regular, 4);
  });

  group('law 1: a see-through fill or overlay asserts', () {
    testWidgets('a fill part way clear', (tester) async {
      await tester.pumpWidget(
        _under(
          ComicThemeData.offset(),
          ComicButton(
            'Save',
            onPressed: () {},
            style: const ComicStyle(
              fill: WidgetStatePropertyAll(Color(0x80D62828)),
            ),
          ),
        ),
      );
      final error = tester.takeException();
      expect(error, isA<AssertionError>());
      expect('$error', contains('first law'));
    });

    testWidgets('an overlay part way clear when pressed', (tester) async {
      await tester.pumpWidget(
        _under(
          ComicThemeData.offset(),
          ComicButton(
            'Save',
            onPressed: () {},
            style: ComicStyle(
              overlay: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? const Color(0x33000000)
                    : null,
              ),
            ),
          ),
        ),
      );
      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('first law'));
    });

    testWidgets('an opaque ink, or none, draws', (tester) async {
      for (final fill in const [Color(0xFFD62828), Color(0x00000000)]) {
        await tester.pumpWidget(
          _under(
            ComicThemeData.offset(),
            ComicButton(
              'Save',
              onPressed: () {},
              style: ComicStyle(fill: WidgetStatePropertyAll(fill)),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });
  });
}
