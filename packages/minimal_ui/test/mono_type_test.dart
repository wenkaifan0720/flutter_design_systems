import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

/// The mono register's word gap, measured with the real faces: a date or a
/// stamp set in Geist Mono reads as one space (`25 Sep`, not `25  Sep`),
/// its words stay mono so a stamp column aligns, and a code block keeps the
/// full cell its indentation needs.

/// [text]'s laid-out width in [style], at text scale 1.
double _width(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

void main() {
  setUpAll(minimalLoadFonts);

  final t = MinimalThemeData.preset('standard', Brightness.light);
  final day = DateTime(2026, 9, 25, 17, 5);

  test('MinimalFormat prints one space between a date\'s parts', () {
    expect(MinimalFormat.dayMonth(day), '25 Sep');
    expect(
      '${MinimalFormat.weekday(day)} ${MinimalFormat.dayMonth(day)}',
      'Fri 25 Sep',
    );
    expect(MinimalFormat.stamp(DateTime(2026, 9, 24, 17, 5)), '24 Sep 17:05');
  });

  test('a mono word gap is Geist\'s space, not a full mono cell', () {
    for (final (name, style) in [
      ('mono', t.mono),
      ('figure', t.figure),
      ('giant', t.giant),
    ]) {
      final size = style.fontSize!;
      final cell = _width('0', style);
      for (final (spaced, joined) in const [
        ('25 Sep', '25Sep'),
        ('Fri 25 Sep', 'Fri25Sep'),
        ('24 Sep 17:05', '24Sep17:05'),
      ]) {
        final gaps = ' '.allMatches(spaced).length;
        final gap = (_width(spaced, style) - _width(joined, style)) / gaps;
        // Geist's space, a quarter em, where Geist Mono's is a full cell
        // (plus the style's tracking, which every glyph takes).
        final tracking = style.letterSpacing ?? 0;
        expect(
          gap,
          closeTo(size * 0.25 + tracking, 0.01),
          reason: '$name "$spaced"',
        );
        expect(gap, lessThan(cell / 2), reason: '$name "$spaced"');
      }
      // Every word is still mono: a digit and a letter are one cell each.
      expect(_width('Sep', style), closeTo(3 * cell, 0.01), reason: name);
    }
  });

  test('a column of stamps still aligns: every stamp is one width', () {
    final widths = {
      for (final at in [
        DateTime(2026, 1, 1, 7, 0),
        DateTime(2026, 5, 31, 23, 59),
        DateTime(2026, 9, 24, 17, 5),
      ])
        _width(MinimalFormat.stamp(at), t.mono),
    };
    expect(widths, hasLength(1));
  });

  testWidgets('a code block keeps the full cell, so indentation lines up', (
    tester,
  ) async {
    const code = 'if (a) {\n  go();\n}';
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MinimalHost(
          light: t,
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          brightness: Brightness.light,
          child: child!,
        ),
        home: const Scaffold(body: MinimalCodeBlock(code, copyable: false)),
      ),
    );
    final text = tester.widget<Text>(find.text(code));
    final style = text.style!;
    expect(style.wordSpacing, 0);
    // Two spaces of indent are two cells, as wide as two characters.
    expect(_width('  go();', style), closeTo(_width('xxgo();', style), 0.01));
  });
}
