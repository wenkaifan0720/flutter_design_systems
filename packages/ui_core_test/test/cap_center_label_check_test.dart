// DesignLabelCheck over RawCapCenter: a label cap-centred in Roboto, and a
// glyph beside it, read from the drawn pixels. Split from ui_core's
// cap_center_test.dart, which tests the placement itself.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

// Roboto, from the SDK: its OS/2 cap height is 1456 of 2048 units.
const _roboto = 1456 / 2048;
const _black = Color(0xFF000000);
const _white = Color(0xFFFFFFFF);
// Material's chevron_right: its ink is the middle half of its em, centred.
const _chevron = IconData(0xE15F, fontFamily: 'MaterialIcons');

String get _fonts {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  return '$root/bin/cache/artifacts/material_fonts';
}

Future<void> _load(String family, String file) async {
  final data = ByteData.sublistView(File('$_fonts/$file').readAsBytesSync());
  await (FontLoader(family)..addFont(Future.value(data))).load();
}

TextStyle _style(double size, double line) => TextStyle(
  inherit: false,
  fontFamily: 'Roboto',
  fontSize: size,
  height: line / size,
  leadingDistribution: TextLeadingDistribution.even,
  color: _black,
);

Widget _label(
  String words,
  TextStyle style, {
  double textScale = 1,
  bool centred = true,
}) {
  final text = Text(
    words,
    style: style,
    textScaler: TextScaler.linear(textScale),
  );
  return centred ? RawCapCenter(capHeightFactor: _roboto, child: text) : text;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _load('Roboto', 'Roboto-Regular.ttf');
    await _load('MaterialIcons', 'MaterialIcons-Regular.otf');
  });

  testWidgets('DesignLabelCheck(drawnTolerance:) holds the capitals and a '
      'glyph beside them', (tester) async {
    Widget control(String name, Widget content, {double height = 56}) =>
        Semantics(
          button: true,
          label: name,
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFDDDDDD)),
            child: SizedBox(
              width: 160,
              height: height,
              child: Center(child: content),
            ),
          ),
        );
    Future<List<String>> problems(List<Widget> screen) async {
      await tester.pumpWidget(
        RepaintBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: _white,
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(spacing: 8, runSpacing: 8, children: screen),
              ),
            ),
          ),
        ),
      );
      final report = await const DesignLabelCheck(
        look: 'Bare',
        drawnTolerance: 0.5,
      ).check(tester.binding.rootElement!, runAsync: tester.runAsync);
      return report.problems;
    }

    const icon = Icon(_chevron, size: 24, color: _black);
    expect(
      await problems([
        control('Edit', _label('Edit', _style(16, 24))),
        control('Share', _label('Share', _style(16, 24))),
        control('Shipping', _label('Shipping', _style(16, 24))),
        control('more', _label('more', _style(16, 24))),
        control(
          'Next',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [_label('Next', _style(14, 20)), icon],
          ),
          height: 40,
        ),
      ]),
      isEmpty,
    );
    // A line box centred, and an icon 0.7 px low.
    expect(
      await problems([
        control('Done', _label('Done', _style(16, 24), centred: false)),
        control(
          'Next',
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _label('Next', _style(14, 20)),
              Transform.translate(offset: const Offset(0, 0.7), child: icon),
            ],
          ),
          height: 40,
        ),
      ]),
      [
        matches(
          RegExp(
            r'^a button "Done": the capitals of "Done" are drawn '
            r'[0-9.]+ device px (above|below) the middle of its face$',
          ),
        ),
        matches(
          RegExp(
            r'^a button "Next": its icon is drawn [0-9.]+ device px '
            r'below the capitals of "Next"$',
          ),
        ),
      ],
    );
  });

  // 0.3.0 tooling: Frosted's chosen filter chip (11-15). Its face is lit a
  // little from its left to the middle of its words (a sheen 10 a channel
  // lighter than the face's commonest colour, not past both sides of the
  // words as a rule behind them is), and its words are a grey 116 from that
  // colour: read against the face's colour, every row of the sheen above
  // the capitals stood out by more than a sixteenth of the ink, so the
  // capitals read from the top of the line box (30.1 device px high where
  // their RawCapCenter gave 25.2). The ground is the sheen: the row of
  // the words' box nearest the face's colour.
  testWidgets("DesignLabelCheck reads a label's capitals from the sheen "
      'under them, not from the face round it', (tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: _page,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Semantics(
                  button: true,
                  label: 'Money in',
                  child: CustomPaint(
                    painter: _Sheen(),
                    child: SizedBox(
                      width: 180,
                      height: 48,
                      child: Center(
                        child: _label(
                          'Money in',
                          _style(14, 20).copyWith(color: _grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final report = await const DesignLabelCheck(
      look: 'Chip',
      drawnTolerance: 0.5,
    ).check(tester.binding.rootElement!, runAsync: tester.runAsync);
    expect(report.problems, isEmpty);
  });
}

// A page the chip's face stands off (white is within 64 a channel of it).
const _page = Color(0xFF60656F);
const _face = Color(0xFFBFBFBF);
const _lit = Color(0xFFC9C9C9);
const _grey = Color(0xFF4B4C57);

// A chip's face of [_face], lit to [_lit] in a band from its left to its
// middle, over the first half of its words: under a third of it, so the
// face's commonest colour stays [_face].
class _Sheen extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final face = Offset.zero & size;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(face, const Radius.circular(24)),
        Paint()..color = _face,
      )
      ..drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(
            0,
            face.center.dy - 14,
            face.center.dx,
            face.center.dy + 14,
          ),
          topLeft: const Radius.circular(14),
          bottomLeft: const Radius.circular(14),
        ),
        Paint()..color = _lit,
      );
  }

  @override
  bool shouldRepaint(_Sheen oldDelegate) => false;
}
