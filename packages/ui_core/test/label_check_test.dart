import 'dart:io';

import 'package:flutter/material.dart' show Theme, ThemeData, VisualDensity;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

const _black = Color(0xFF000000);
const _face = BoxDecoration(color: Color(0xFFDDDDDD));
// Roboto, from the SDK, 14/20: the baseline is laid out 14.79 below the
// label's top and drawn at 15, 0.21 px lower; at 13/20 one laid out at
// 14.44 is drawn at 14, 0.44 px higher. Centred by their capitals as
// drawn, the first is laid out 0.21 px high, the second 0.44 px low.
const _lower = TextStyle(
  inherit: false,
  fontFamily: 'Roboto',
  fontSize: 14,
  height: 20 / 14,
  leadingDistribution: TextLeadingDistribution.even,
  color: _black,
);
const _higher = TextStyle(
  inherit: false,
  fontFamily: 'Roboto',
  fontSize: 13,
  height: 20 / 13,
  leadingDistribution: TextLeadingDistribution.even,
  color: _black,
);
// Material's chevron_right, from the SDK's icon font.
const _chevron = IconData(0xE15F, fontFamily: 'MaterialIcons');

Future<void> _loadFonts() async {
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
  for (final (family, file) in [
    ('MaterialIcons', 'MaterialIcons-Regular.otf'),
    ('Roboto', 'Roboto-Regular.ttf'),
  ]) {
    final font = File('$root/bin/cache/artifacts/material_fonts/$file');
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();
  }
}

// A control: a [height] high face holding [content] at its middle, moved
// down by [nudge].
Widget _control(
  String name,
  Widget content, {
  double nudge = 0,
  double height = 56,
  double width = 120,
  Decoration? face = _face,
}) {
  Widget inside = SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Transform.translate(offset: Offset(0, nudge), child: content),
    ),
  );
  if (face != null) inside = DecoratedBox(decoration: face, child: inside);
  return Semantics(button: true, label: name, child: inside);
}

// Roboto's cap height over its em.
const _roboto = 1456 / 2048;

// Words centred by their capitals, as a look's faces draw them.
Widget _words(String words, [TextStyle style = _lower]) => DesignCapCenter(
  capHeightFactor: _roboto,
  child: Text(words, style: style),
);

Future<List<String>> _labels(WidgetTester tester, List<Widget> screen) async {
  await tester.pumpWidget(
    RepaintBoundary(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: Align(
            alignment: Alignment.topLeft,
            child: Wrap(spacing: 8, runSpacing: 8, children: screen),
          ),
        ),
      ),
    ),
  );
  // Drawn at 2x, where these labels' ink edges fall on whole device pixels.
  final report = await const DesignLabelCheck(
    look: 'Bare',
    pixelRatio: 2,
  ).check(tester.binding.rootElement!, runAsync: tester.runAsync);
  return report.problems;
}

// A split button at [density]'s size: the leading half's content takes
// 40 px less the density's adjustment; the trailing half keeps 40 unless it
// [follows], and the row stretches both faces to the taller half.
Widget _split(BuildContext context, {required bool follows}) {
  final leading = 40 + Theme.of(context).visualDensity.baseSizeAdjustment.dy;
  return Align(
    alignment: Alignment.topLeft,
    child: IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'Share',
            child: DecoratedBox(
              decoration: _face,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 100,
                  height: leading,
                  child: Center(child: _words('Share')),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Semantics(
            button: true,
            label: 'More',
            child: DecoratedBox(
              decoration: _face,
              child: SizedBox(
                width: 48,
                height: follows ? leading : 40,
                child: const Center(
                  child: Icon(_chevron, size: 24, color: _black),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final Map<String, DesignAlignmentTheme> _densities = {
  for (final (name, density) in [
    ('standard', VisualDensity.standard),
    ('compact', VisualDensity.compact),
  ])
    name: (context, child) => Theme(
      data: ThemeData(visualDensity: density),
      child: child,
    ),
};

Future<List<String>> _underEach(
  WidgetTester tester,
  WidgetBuilder screen,
) async {
  final report = await const DesignLabelCheck(look: 'Bare', pixelRatio: 2)
      .checkDensities(
        densities: _densities,
        screen: screen,
        pump: tester.pumpWidget,
        runAsync: tester.runAsync,
      );
  return report.problems;
}

// A ruled page: paper with a hairline across it every 32 px from [first],
// as a look's empty state draws one behind its words.
class _Ruling extends CustomPainter {
  const _Ruling(this.first);

  final double first;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _paper);
    final rule = Paint()..color = const Color(0xFFE7E4DF);
    for (var y = first; y < size.height; y += 32) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), rule);
    }
  }

  @override
  bool shouldRepaint(_Ruling old) => old.first != first;
}

const _paper = Color(0xFFF9F6F0);

// An outlined button on a ruled page, its face 48 px high less [context]'s
// density's adjustment and unfilled, so the page's rules show through it:
// under compact (40) one runs 1.5 px above its capitals, inside their
// columns; under standard (48) it is above the label's line. Its label is
// centred with [factor] as its cap height.
Widget _onRuledPage(BuildContext context, {double factor = _roboto}) {
  final face = 48 + Theme.of(context).visualDensity.baseSizeAdjustment.dy;
  return Align(
    alignment: Alignment.topLeft,
    child: CustomPaint(
      painter: const _Ruling(20.5),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Semantics(
          button: true,
          label: 'Try again',
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: _black)),
            child: SizedBox(
              width: 140,
              height: face,
              child: Center(
                child: DesignCapCenter(
                  capHeightFactor: factor,
                  child: const Text('Try again', style: _lower),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  testWidgets('a label on the middle of its face passes; one laid out 1 px '
      'low fails, named as laid out and as drawn, whichever way the engine '
      'rounds it', (tester) async {
    expect(
      await _labels(tester, [
        _control('Centred', _words('Centred')),
        // Laid out 0.45 low, drawn about 1 low: the rest is the engine's.
        _control('Nearly', _words('Nearly'), nudge: 0.45),
      ]),
      isEmpty,
    );
    expect(
      await _labels(tester, [
        _control('Low', _words('Low'), nudge: 1),
        _control('High', _words('High', _higher), nudge: 1),
        _control('Up', _words('Up'), nudge: -1),
      ]),
      [
        'a button "Low": the label "Low" is 0.8 px below the middle of its '
            'face as laid out, 1 px below as drawn',
        // Drawn 0.9 low: at 2x its capitals are 18.5 device px high, so
        // their middle is not on a whole device pixel.
        'a button "High": the label "High" is 1.4 px below the middle of its '
            'face as laid out, 0.9 px below as drawn',
        'a button "Up": the label "Up" is 1.2 px above the middle of its face '
            'as laid out, 1 px above as drawn',
      ],
    );
  });

  testWidgets('a split button: each half is its own control, and the half '
      'whose label is off is named', (tester) async {
    final found = await _labels(tester, [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _control('Share', _words('Share'), nudge: -1, width: 100),
          const SizedBox(width: 2),
          _control(
            'More',
            const Icon(_chevron, size: 24, color: _black),
            width: 48,
          ),
        ],
      ),
    ]);
    expect(found, [
      'a button "Share": the label "Share" is 1.2 px above the middle of its '
          'face as laid out, 1 px above as drawn',
    ]);
  });

  testWidgets('an icon beside a label is read on its own', (tester) async {
    final found = await _labels(tester, [
      _control(
        'Next',
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _words('Next'),
            Transform.translate(
              offset: const Offset(0, 2),
              child: const Icon(_chevron, size: 24, color: _black),
            ),
          ],
        ),
        width: 160,
      ),
    ]);
    expect(found, [
      matches(
        RegExp(
          r'^a button "Next": its icon is (1\.[6-9]|2(\.[0-2])?) px below the '
          r'middle of its face as laid out, [0-9.]+ px below as drawn$',
        ),
      ),
    ]);
  });

  testWidgets("a painted mark before a row's words is read by its ink: on "
      'their middle it passes, at the top of their line it is named', (
    tester,
  ) async {
    // A way back: a triangle 10 high painted before "Back" in a line 20
    // high, centred on it or at its top.
    Widget back(String name, CrossAxisAlignment align) => _control(
      name,
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          const CustomPaint(size: Size(8, 10), painter: _BackTriangle()),
          const SizedBox(width: 6),
          _words('Back'),
        ],
      ),
    );
    expect(
      await _labels(tester, [back('Back', CrossAxisAlignment.center)]),
      isEmpty,
    );
    expect(await _labels(tester, [back('Up', CrossAxisAlignment.start)]), [
      matches(
        RegExp(
          r'^a button "Up": its painted mark, before its words, is -?[0-9.]+ '
          r'px above the middle of its face as drawn$',
        ),
      ),
    ]);
  });

  testWidgets('left out: no face, two lines, a tall card, a badge, a text '
      'entry, a label beside its face, a control off stage', (tester) async {
    final controller = TextEditingController(text: 'Typed');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    final found = await _labels(tester, [
      _control('Faceless', _words('Faceless'), nudge: 3, face: null),
      _control(
        'Two lines',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [_words('Title'), _words('Subtitle')],
        ),
        height: 64,
        nudge: 3,
      ),
      Semantics(
        button: true,
        label: 'Card',
        child: DecoratedBox(
          decoration: _face,
          child: SizedBox(
            width: 160,
            height: 120,
            child: Align(
              alignment: Alignment.topLeft,
              child: _words('Card title'),
            ),
          ),
        ),
      ),
      _control(
        'Inbox',
        Stack(
          clipBehavior: Clip.none,
          children: [
            _words('Inbox'),
            Positioned(
              right: -16,
              top: -12,
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Color(0xFFCC0000)),
                child: _words('3'),
              ),
            ),
          ],
        ),
      ),
      _control(
        'Field',
        SizedBox(
          width: 100,
          child: EditableText(
            controller: controller,
            focusNode: focus,
            style: _lower,
            cursorColor: _black,
            backgroundCursorColor: _black,
          ),
        ),
        nudge: 3,
      ),
      Semantics(
        checked: true,
        label: 'Remember me',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: _face,
              child: SizedBox(width: 18, height: 18),
            ),
            Transform.translate(
              offset: const Offset(0, 3),
              child: _words('Remember me'),
            ),
          ],
        ),
      ),
      Offstage(child: _control('Hidden', _words('Hidden'), nudge: 3)),
    ]);
    expect(found, isEmpty);
  });

  testWidgets('a label beside a text entry of more than one line stands on '
      "the entry's first line, not the face's middle", (tester) async {
    final controller = TextEditingController(text: 'Typed');
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    // A note row: the label at the top beside a three-line entry, the
    // whole row the field's target (its face the row's).
    Widget note(String name, {double nudge = 0}) => Semantics(
      button: true,
      label: name,
      child: DecoratedBox(
        decoration: _face,
        child: SizedBox(
          width: 260,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Transform.translate(
                    offset: Offset(0, nudge),
                    child: _words(name),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    textField: true,
                    child: EditableText(
                      controller: controller,
                      focusNode: focus,
                      style: _lower,
                      maxLines: 3,
                      cursorColor: _black,
                      backgroundCursorColor: _black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(await _labels(tester, [note('Note')]), isEmpty);
    expect(await _labels(tester, [note('Lower', nudge: 2)]), [
      // The entry's capitals are read from its pixels (its T), a tenth of a
      // pixel off the label's cap height on macOS (2.1), on it on Linux (2).
      matches(
        RegExp(
          r'^a button "Lower": the label "Lower" is 2(\.1)? px below the '
          r'capitals of the first line of the text entry beside it as laid '
          r'out, 2(\.1)? px below as drawn$',
        ),
      ),
    ]);
  });

  testWidgets("a row ruled at its foot centres its label in the band above "
      'the rule', (tester) async {
    // A list row whose decoration is a 2 px rule under it: the box lays its
    // label out inside the rule, as Container does.
    final found = await _labels(tester, [
      Semantics(
        button: true,
        label: 'Meditate',
        child: Container(
          width: 160,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _black, width: 2)),
          ),
          child: _words('Meditate'),
        ),
      ),
    ]);
    expect(found, isEmpty);
  });

  testWidgets("a style's cap height is not read from a wrapped line's "
      'letters in its first line', (tester) async {
    // The note's only flat-topped capital, P, starts its second line, under
    // the first line's lower-case m: read there, the style's capitals would
    // be the m's height. The label's capitals (S, round) are read alone.
    final found = await _labels(tester, [
      const SizedBox(
        width: 120,
        child: Text('mmmm mmmm\nPqrs mmmm', style: _lower),
      ),
      _control('Saga', const Text('Saga', style: _lower)),
    ]);
    expect(found, isEmpty);
  });

  testWidgets("an icon tile's name under its picture is placed, not "
      'centred', (tester) async {
    // A desk icon: a painted picture 24 high over its name, in a face 72
    // high; the name stands 14 px under the face's middle.
    final found = await _labels(tester, [
      _control(
        'Trash',
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomPaint(size: Size(24, 24), painter: _Picture()),
            const SizedBox(height: 4),
            _words('Trash'),
          ],
        ),
        height: 72,
        width: 96,
      ),
    ]);
    expect(found, isEmpty);
  });

  testWidgets('under each density: a split button whose halves part under '
      'compact fails there, named with the density; halves that agree pass', (
    tester,
  ) async {
    expect(
      await _underEach(tester, (context) => _split(context, follows: false)),
      [
        'compact · a button "Share": the label "Share" is 4.2 px above the '
            'middle of its face as laid out, 4 px above as drawn',
      ],
    );
    expect(
      await _underEach(tester, (context) => _split(context, follows: true)),
      isEmpty,
    );
    expect(
      (await const DesignLabelCheck(look: 'Bare').checkDensities(
        densities: const {},
        screen: (context) => const SizedBox(),
        pump: tester.pumpWidget,
        runAsync: tester.runAsync,
      )).problems,
      ['no density to check under'],
    );
  });

  testWidgets('a face the colour of the ground is read where a look marks '
      'it', (tester) async {
    Widget ground({required bool marked}) {
      Widget face = ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: SizedBox(
          width: 120,
          height: 56,
          child: Center(
            child: Transform.translate(
              offset: const Offset(0, -1),
              child: _words('Share'),
            ),
          ),
        ),
      );
      if (marked) face = DesignKeylineFace(child: face);
      return Semantics(button: true, label: 'Share', child: face);
    }

    expect(
      await _labels(tester, [ground(marked: false)]),
      isEmpty,
      reason: 'unmarked, it has no face to be off the middle of',
    );
    expect(await _labels(tester, [ground(marked: true)]), [
      'a button "Share": the label "Share" is 1.2 px above the middle of its '
          'face as laid out, 1 px above as drawn',
    ]);
  });

  testWidgets('a label is read by its capitals: words with descenders, '
      'centred by their line box or their capitals, are not low', (
    tester,
  ) async {
    Widget plain(String words) => Text(words, style: _lower);
    expect(
      await _labels(tester, [
        for (final words in ['Spending', 'Light', 'Night sky', 'gypsy'])
          _control(words, plain(words)),
        for (final words in ['Spending', 'Light', 'Night sky', 'gypsy'])
          _control('$words, centred', _words(words)),
      ]),
      isEmpty,
    );
  });

  testWidgets('a line holding a widget is read by its capitals as drawn, '
      'the engine\'s rounding allowed', (tester) async {
    // A shortcut: its key is a box with a letter in it.
    Widget shortcut({double nudge = 0}) => Transform.translate(
      offset: Offset(0, nudge),
      child: Text.rich(
        TextSpan(
          style: _lower,
          children: [
            const TextSpan(text: 'Find '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF888888)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text('K', style: _lower),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    expect(
      await _labels(tester, [_control('Find', shortcut(), width: 160)]),
      isEmpty,
    );
    expect(
      await _labels(tester, [_control('Find', shortcut(nudge: 3), width: 160)]),
      [
        matches(
          RegExp(
            r'^a button "Find": the label "Find .*" is [2-4](\.[0-9])? px '
            r'below the middle of its face as drawn, more than the engine.s '
            r'rounding of a line holding a widget$',
          ),
        ),
      ],
    );
  });

  testWidgets('a control laid out but not shown is not read', (tester) async {
    Widget off(String name) => _control(name, _words(name), nudge: 3);
    expect(
      await _labels(tester, [
        IndexedStack(
          index: 0,
          children: [_control('Shown', _words('Shown')), off('Hidden')],
        ),
        Visibility(visible: false, maintainState: true, child: off('Kept')),
      ]),
      isEmpty,
    );
  });

  testWidgets('a ruled page behind an unfilled face: the rule just above '
      'the capitals is not read as their top; a wrong cap height still is', (
    tester,
  ) async {
    Future<List<String>> held(WidgetBuilder screen) async =>
        (await const DesignLabelCheck(
              look: 'Bare',
              pixelRatio: 2,
              drawnTolerance: 0.5,
            ).checkDensities(
              densities: _densities,
              screen: screen,
              pump: tester.pumpWidget,
              runAsync: tester.runAsync,
            ))
            .problems;

    expect(await held(_onRuledPage), isEmpty);
    // Roboto's capitals given as 0.6 of the font size, not 0.71: placed by
    // that, and named under both densities, the rule or none. They are read
    // about 20 device px high (20.2 on macOS, 20.0 on Linux: each engine's
    // antialiasing of the top).
    final wrong = await held((context) => _onRuledPage(context, factor: 0.6));
    for (final density in ['standard', 'compact']) {
      expect(
        wrong,
        contains(
          matches(
            RegExp(
              '^$density · a button "Try again": the capitals of "Try again" '
              r"are drawn (19\.[5-9]|20\.[0-4]) device px high; its "
              r"DesignCapCenter's capHeightFactor gives 16\.8$",
            ),
          ),
        ),
      );
    }
  });

  testWidgets('text drawn in the test\'s own font (a font not loaded) fails '
      'once, with that reason', (tester) async {
    const missing = IconData(0xE15F, fontFamily: 'NotLoaded');
    expect(
      await _labels(tester, [
        _control('Next', const Icon(missing, size: 24, color: _black)),
        _control(
          'More',
          const Text(
            'More',
            style: TextStyle(
              inherit: false,
              fontFamily: 'NotLoaded',
              fontSize: 14,
              color: _black,
            ),
          ),
          nudge: 3,
        ),
        _control('Share', _words('Share'), nudge: 3),
        // Material's own outline square is no missing glyph.
        _control(
          'Box',
          const Icon(
            IconData(0xE835, fontFamily: 'MaterialIcons'),
            size: 24,
            color: _black,
          ),
        ),
      ]),
      [
        '2 controls draw their text in the test\'s own font (solid boxes), a '
            'button "Next" first: load every font family the look ships (each '
            'family in its FontManifest.json) before the check',
      ],
    );
  });

  testWidgets('a screen that repainted since its last frame (an image that '
      'decoded) is refused, with what to do', (tester) async {
    await _labels(tester, [_control('Share', _words('Share'))]);
    tester
        .renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first)
        .markNeedsPaint();
    await expectLater(
      const DesignLabelCheck(look: 'Bare')
          .check(tester.binding.rootElement!, runAsync: tester.runAsync),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Decode the screen\'s images and pump'),
        ),
      ),
    );
  });

  group('a chosen fill', () {
    const trough = Color(0xFFE6E8EE);
    const lit = Color(0xFF2F5BD3);
    const white = Color(0xFFFFFFFF);
    const lift = TextStyle(
      inherit: false,
      fontFamily: 'Roboto',
      fontSize: 14,
      height: 20 / 14,
      leadingDistribution: TextLeadingDistribution.even,
      color: white,
    );

    // A cell of a toggle group: 110 by 44, its words on a fill [fill] in
    // size when chosen, nothing drawn when not.
    Widget cell(String name, {required bool on, required Size fill}) =>
        Semantics(
          button: true,
          toggled: on,
          label: name,
          child: SizedBox(
            width: 110,
            height: 44,
            child: Center(
              child: on
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: lit,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SizedBox.fromSize(
                        size: fill,
                        child: Center(child: _words(name, lift)),
                      ),
                    )
                  : _words(name),
            ),
          ),
        );
    Widget group(Size fill) => DecoratedBox(
      decoration: BoxDecoration(
        color: trough,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            cell('Bold', on: true, fill: fill),
            cell('Italic', on: false, fill: fill),
            cell('Underline', on: false, fill: fill),
          ],
        ),
      ),
    );

    testWidgets('a marker behind the words of a toggle group\'s cell is '
        'named; a fill of the cell passes', (tester) async {
      expect(
        await _labels(tester, [group(const Size(61, 20))]),
        contains(
          'a switch "Bold": its chosen fill is 61 by 20 px in its cell of 110 '
          'by 44; the chosen ground fills the cell, to 11 px short',
        ),
      );
      expect(
        (await _labels(tester, [
          group(const Size(110, 44)),
        ])).where((f) => f.contains('chosen fill')),
        isEmpty,
      );
      // A round mark a few pixels in from the cell (a day's): within a
      // quarter of its height.
      expect(
        (await _labels(tester, [
          group(const Size(102, 36)),
        ])).where((f) => f.contains('chosen fill')),
        isEmpty,
      );
    });

    testWidgets("a drawer's chosen destination: an indicator hugging its "
        'words is named; one across the row passes', (tester) async {
      Widget destination(String name, {bool on = false, bool hug = false}) =>
          Semantics(
            button: true,
            selected: on,
            label: name,
            child: SizedBox(
              width: 230,
              height: 56,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: on
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: lit,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: SizedBox(
                          width: hug ? 80 : 230,
                          height: hug ? 32 : 56,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _words(name, lift),
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _words(name),
                      ),
              ),
            ),
          );
      Widget drawer({required bool hug}) => ColoredBox(
        color: const Color(0xFFF3F1F8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            destination('Chats', on: true, hug: hug),
            destination('Calls'),
            destination('People'),
          ],
        ),
      );
      expect(
        await _labels(tester, [drawer(hug: true)]),
        contains(
          'a button "Chats": its chosen fill is 80 by 32 px in its cell of '
          '230 by 56; the chosen ground fills the cell, to 14 px short',
        ),
      );
      expect(
        (await _labels(tester, [
          drawer(hug: false),
        ])).where((f) => f.contains('chosen fill')),
        isEmpty,
      );
    });

    testWidgets("chips, whose faces are their cells, and a navigation bar's "
        'mark beside its words are not read', (tester) async {
      // Chips: a 32 face in a 48 target, a face chosen or not.
      Widget chip(String name, {bool on = false}) => Semantics(
        button: true,
        selected: on,
        label: name,
        child: SizedBox(
          height: 48,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: on ? lit : white,
                border: Border.all(color: const Color(0xFF8A8F99)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    widthFactor: 1,
                    child: _words(name, on ? lift : _lower),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // A destination: its mark round its glyph, its words under it.
      Widget destination(String name, {bool on = false}) => Semantics(
        button: true,
        selected: on,
        label: name,
        child: SizedBox(
          width: 96,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: on ? lit : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const SizedBox(
                  width: 56,
                  height: 28,
                  child: Icon(_chevron, size: 18, color: _black),
                ),
              ),
              _words(name),
            ],
          ),
        ),
      );
      final found = await _labels(tester, [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [chip('All', on: true), chip('Food'), chip('Travel')],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            destination('Home', on: true),
            destination('Search'),
            destination('Profile'),
          ],
        ),
      ]);
      expect(found.where((f) => f.contains('chosen fill')), isEmpty);
    });
  });
}

// A picture: a filled square.
class _Picture extends CustomPainter {
  const _Picture();

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = _black);

  @override
  bool shouldRepaint(_Picture oldDelegate) => false;
}

// A triangle pointing back, filling its box.
class _BackTriangle extends CustomPainter {
  const _BackTriangle();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close(),
    Paint()..color = _black,
  );

  @override
  bool shouldRepaint(_BackTriangle oldDelegate) => false;
}
