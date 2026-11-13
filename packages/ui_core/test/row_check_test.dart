// DesignRowCheck: a row of controls read by their drawn outlines and their
// capitals. The fixtures are a dialog's actions: a filled OK beside a glass
// or outline Cancel, on a light and a dark ground, a pill with a soft
// shadow, a smaller secondary, and a field beside a button.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:ui_core/ui_core.dart';

// Roboto's cap height over its em, the factor its labels are centred by.
const _roboto = 1456 / 2048;

// The Flutter SDK's Roboto, so words are drawn in a typeface, not the test's
// boxes.
Future<void> _loadRoboto() async {
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
    ('Roboto', 'Roboto-Regular.ttf'),
    ('MaterialIcons', 'MaterialIcons-Regular.otf'),
  ]) {
    final font = File('$root/bin/cache/artifacts/material_fonts/$file');
    await (FontLoader(family)
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();
  }
}

// Material's chevron_right, from the SDK's icon font.
const _chevron = IconData(0xE15F, fontFamily: 'MaterialIcons');

// An icon, drawn [nudge] px low.
Widget _icon({double nudge = 0}) => Transform.translate(
  offset: Offset(0, nudge),
  child: const Icon(_chevron, size: 24, color: Color(0xFF101010)),
);

// A control [size] square showing an icon on its middle and no face of its
// own; with a [badge] in its top right corner.
Widget _bare(
  String label, {
  double size = 48,
  double nudge = 0,
  Widget? badge,
  double badgeTop = 0,
}) => Semantics(
  button: true,
  label: label,
  child: GestureDetector(
    onTap: () {},
    child: SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _icon(nudge: nudge),
          if (badge != null) Positioned(top: badgeTop, right: 0, child: badge),
        ],
      ),
    ),
  ),
);

// A badge [size] square holding [count].
Widget _badge(String count, double size) => DecoratedBox(
  decoration: const BoxDecoration(
    color: Color(0xFFD93025),
    shape: BoxShape.circle,
  ),
  child: SizedBox(
    width: size,
    height: size,
    child: Center(
      child: Text(
        count,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 10,
          color: Color(0xFFFFFFFF),
        ),
      ),
    ),
  ),
);

// [children] side by side on a light dialog, [wrap] round the row.
Future<List<String>> _checkRow(
  WidgetTester tester,
  List<Widget> children, {
  Widget Function(Widget row)? wrap,
}) async {
  final row = Row(mainAxisSize: MainAxisSize.min, children: children);
  return _checkBody(tester, wrap == null ? row : wrap(row));
}

// [body] on a light dialog.
Future<List<String>> _checkBody(WidgetTester tester, Widget body) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: _light,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(padding: const EdgeInsets.all(24), child: body),
          ),
        ),
      ),
    ),
  );
  final report = await const DesignRowCheck(look: 'Fixture')
      .check(key.currentContext!, runAsync: tester.runAsync);
  return report.problems;
}

// A one-line label in Roboto, its capitals on its box's middle.
Widget _label(
  String text, {
  double size = 14,
  Color colour = const Color(0xFF101010),
}) => DesignCapCenter(
  capHeightFactor: _roboto,
  child: Text(
    text,
    style: TextStyle(fontFamily: 'Roboto', fontSize: size, color: colour),
  ),
);

const _light = Color(0xFFF4F6FA);
const _dark = Color(0xFF1C1F26);
const _blue = Color(0xFF2F5BD3);

// A face [width] by [height]: [fill] over the whole of it, or inside an
// outer 2 px [ring].
Widget _face({
  required Color fill,
  Color? ring,
  List<BoxShadow>? shadow,
  double width = 150,
  double height = 48,
  double radius = 12,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: ring ?? fill,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow,
    ),
    child: SizedBox(
      width: width,
      height: height,
      child: ring == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(radius - 2),
                ),
              ),
            ),
    ),
  );
}

Widget _button(String label, Widget face, {Widget? text}) => Semantics(
  button: true,
  label: label,
  child: GestureDetector(
    onTap: () {},
    child: Stack(
      alignment: Alignment.center,
      children: [face, text ?? _label(label)],
    ),
  ),
);

// A dialog of [surface] on a page, its actions [cancel] and [ok] in a row
// 24 px in from each side.
Future<List<String>> _check(
  WidgetTester tester, {
  required Color surface,
  required Widget cancel,
  required Widget ok,
  Color page = const Color(0xFF7F8794),
  double floor = 1.25,
  bool stacked = false,
}) async {
  final key = GlobalKey();
  final actions = [cancel, const SizedBox(width: 12, height: 12), ok];
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: page,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: stacked
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: actions,
                        )
                      : Row(mainAxisSize: MainAxisSize.min, children: actions),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final report = await DesignRowCheck(
    look: 'Fixture',
    contrastFloor: floor,
  ).check(key.currentContext!, runAsync: tester.runAsync);
  return report.problems;
}

const _cancelOff = [
  'a button "Cancel" beside a button "OK": its top is level with theirs as '
      'laid out, 6 device px below as drawn',
  'a button "Cancel" beside a button "OK": its bottom is level with theirs '
      'as laid out, 6 device px above as drawn',
  'a row of a button "Cancel" and a button "OK": its sides are 24 px in as '
      'laid out, 26 px on the left and 24 px on the right as drawn',
];

void main() {
  setUpAll(_loadRoboto);

  testWidgets('what is never painted is not read: rows laid out past a '
      "list's end, with or without a boundary of their own; the rest of the "
      'page still is', (tester) async {
    Widget pair(String a, String b, {double tall = 48}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(a, _face(fill: _blue, width: 100)),
        const SizedBox(width: 12),
        _button(b, _face(fill: _blue, width: 100, height: tall)),
      ],
    );
    Widget left(Widget child) =>
        Align(alignment: Alignment.centerLeft, child: child);
    for (final boundaries in [true, false]) {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: _light,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pair('Back', 'Next', tall: 40),
                    const SizedBox(height: 12),
                    // Two rows shown; the rest laid out past the list's end.
                    SizedBox(
                      height: 96,
                      child: ListView(
                        addRepaintBoundaries: boundaries,
                        children: [
                          for (var i = 0; i < 2; i++)
                            left(pair('Keep $i', 'Drop $i')),
                          for (var i = 2; i < 10; i++)
                            left(pair('Keep $i', 'Drop $i', tall: 40)),
                        ],
                      ),
                    ),
                    // Drawn where the first rows past the end are laid out.
                    pair('Up', 'Down', tall: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final problems = (await const DesignRowCheck(
        look: 'Fixture',
      ).check(key.currentContext!, runAsync: tester.runAsync)).problems;
      expect(
        problems,
        allOf(
          contains(contains('"Back"')),
          contains(contains('"Up"')),
          isNot(contains(matches(RegExp('Keep|Drop')))),
        ),
        reason: 'boundaries: $boundaries',
      );
    }
  });

  testWidgets("an icon scaled to nothing (an empty checkbox's check) is not "
      'read, so what lies under it is not taken for it; one at its size '
      'is', (tester) async {
    // A checkbox with no face of its own: its check at [scale], drawn
    // [nudge] px low, over a bar low in its box (what a faint ring leaves).
    Widget check(String label, double scale, {double nudge = 0}) => Semantics(
      checked: scale > 0,
      label: label,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (scale == 0)
                const Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  height: 2,
                  child: ColoredBox(color: Color(0xFF101010)),
                ),
              Transform.scale(
                scale: scale,
                child: _icon(nudge: nudge),
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      await _checkRow(tester, [
        check('Round up', 0),
        const SizedBox(width: 12),
        check('Rent paid', 1),
      ]),
      isEmpty,
    );
    // Frosted's marks by day: the node is the 24 disc. An empty one is a
    // ring at 3:1 with its check scaled to nothing; a done one is a disc
    // whose fill fades into the ground at its foot, so its drawn middle
    // stands above its box's. Each sits beside its words, in a wrap, two
    // done ones round an empty one, so a done one is held. The fade is read
    // (the empty ring's foot is below theirs as drawn); the empty check,
    // never drawn, is not held against their drawn middle as well.
    Widget mark(String label, {required bool on}) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Semantics(
          checked: on,
          label: label,
          child: GestureDetector(
            onTap: () {},
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: on
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_blue, _light],
                      )
                    : null,
                border: on
                    ? null
                    : Border.all(color: const Color(0xFF878D99), width: 1.5),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Transform.scale(
                    scale: on ? 1 : 0,
                    child: const Icon(
                      _chevron,
                      size: 14,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        _label(label),
      ],
    );
    expect(
      await _checkBody(
        tester,
        Wrap(
          spacing: 24,
          children: [
            mark('Rent paid', on: true),
            mark('Round up', on: false),
            mark('Bills split', on: true),
          ],
        ),
      ),
      [allOf(contains('"Round up" beside'), contains('its bottom'))],
    );
    expect(
      await _checkRow(tester, [
        check('Round up', 1, nudge: 4),
        const SizedBox(width: 12),
        check('Rent paid', 1),
      ]),
      contains(contains('"Round up"')),
    );
  });

  testWidgets("capitals whose tops are at their sides (V, Y) are not read "
      'for the cap height: "View" and "Yes" are level with "File"', (
    tester,
  ) async {
    Widget plain(String words) => Text(
      words,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 48,
        color: Color(0xFF101010),
      ),
    );
    // A menu bar's words, with no face of their own.
    Widget item(String words) => Semantics(
      button: true,
      label: words,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(widthFactor: 1, child: plain(words)),
          ),
        ),
      ),
    );
    final problems = await _checkRow(tester, [
      for (final words in ['File', 'Edit', 'View', 'Yes', 'Help']) item(words),
    ]);
    expect(problems, isEmpty);
  });

  testWidgets("a week's days, figures alone, are read at one figure height "
      'whichever figures they show', (tester) async {
    // Days with no face of their own: a 3 or an 8 overshoots the figures'
    // height, a 1 or a 7 stands on it. Read each by its own figures, they
    // stood apart.
    Widget day(String figures) => Semantics(
      button: true,
      label: 'June $figures',
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: 64,
          height: 64,
          child: Center(
            child: Text(
              figures,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 40,
                color: Color(0xFF101010),
              ),
            ),
          ),
        ),
      ),
    );
    final problems = await _checkRow(tester, [
      for (final figures in ['11', '13', '17', '28', '30', '14', '15'])
        day(figures),
    ]);
    expect(problems, isEmpty);
  });

  testWidgets('faces level as laid out read level as drawn wherever their '
      'edges fall between device pixels: a light tint beside a ring', (
    tester,
  ) async {
    // A chosen day's light tint beside a ringed face, both rounded, moved
    // down by a tenth of a pixel at a time.
    Widget face(Color fill, {Color? ring}) => DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: ring == null ? null : Border.all(color: ring),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(width: 90, height: 36),
    );
    for (var i = 0; i < 10; i++) {
      final problems = await _checkRow(
        tester,
        [
          _button(
            'Today',
            face(const Color(0xFFDCE6F8)),
            text: _label('Today'),
          ),
          const SizedBox(width: 12),
          _button(
            'Later',
            face(_light, ring: const Color(0xFF8A8F99)),
            text: _label('Later'),
          ),
          const SizedBox(width: 12),
          _button('Next', face(_blue), text: _label('Next')),
        ],
        wrap: (row) => Padding(
          padding: EdgeInsets.only(top: i / 10),
          child: row,
        ),
      );
      expect(problems, isEmpty, reason: 'moved ${i / 10} px');
    }
  });

  testWidgets("a segmented control's segments are read by its track, "
      'beside a square as tall as it', (tester) async {
    const sunken = Color(0xFFE6E9EF);
    const rim = Color(0xFF8A8F99);
    // A segment 26 tall inside a 32 track, 3 in; the chosen one on a raised
    // thumb drawn behind it.
    Widget segment(String label, {required bool chosen}) => _button(
      label,
      DecoratedBox(
        decoration: BoxDecoration(
          color: chosen ? _light : const Color(0x00000000),
          border: chosen ? Border.all(color: rim) : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const SizedBox(width: 72, height: 26),
      ),
      text: _label(label),
    );
    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: sunken,
        border: Border.all(color: rim),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            segment('Light', chosen: true),
            segment('Dark', chosen: false),
          ],
        ),
      ),
    );
    final square = _button(
      'Customize',
      DecoratedBox(
        decoration: BoxDecoration(
          color: _light,
          border: Border.all(color: rim),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const SizedBox(width: 32, height: 32),
      ),
      text: const SizedBox.shrink(),
    );
    final problems = await _checkRow(tester, [
      square,
      const SizedBox(width: 8),
      track,
    ]);
    expect(problems, isEmpty);
  });

  testWidgets('icon tiles side by side: each name under its picture is '
      'placed, not held to the centre line', (tester) async {
    Widget tile(String name) => _button(
      name,
      _face(fill: _light, width: 88, height: 72, radius: 8),
      text: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The tile's picture, painted.
          const CustomPaint(size: Size(24, 24), painter: _Picture()),
          const SizedBox(height: 4),
          _label(name),
        ],
      ),
    );
    expect(
      await _checkRow(tester, [
        tile('Mail'),
        const SizedBox(width: 8),
        tile('Trash'),
      ]),
      isEmpty,
    );
  });

  testWidgets("a segment's words on a thumb sliding under it are read on "
      'the thumb, not the track', (tester) async {
    // A dark track, the chosen segment's thumb drawn behind the segments
    // (not inside the chosen one), each segment its words alone.
    Widget segment(String words, Color ink) => _button(
      words,
      const SizedBox(width: 72, height: 26),
      text: _label(words, colour: ink),
    );
    final track = DecoratedBox(
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 72,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                segment('Day', const Color(0xFFFFFFFF)),
                segment('Week', const Color(0xFFB8BEC9)),
              ],
            ),
          ],
        ),
      ),
    );
    final square = _button(
      'More',
      _face(fill: _dark, width: 32, height: 32, radius: 8),
      text: const SizedBox.shrink(),
    );
    expect(
      await _checkRow(tester, [square, const SizedBox(width: 8), track]),
      isEmpty,
    );
  });

  testWidgets("a table header's rule under its headings is no track: its "
      'checkbox and headings are read as themselves', (tester) async {
    const rim = Color(0xFF8A8F99);
    // A heading drawn as its words alone (a subtle button at rest), 40
    // tall, touching the next.
    Widget heading(String words) => _button(
      'Sort by $words',
      const SizedBox(width: 120, height: 40),
      text: _label(words),
    );
    final tick = Semantics(
      checked: false,
      label: 'Select all rows',
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: 48,
          height: 40,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _light,
                border: Border.all(color: rim),
              ),
              child: const SizedBox(width: 16, height: 16),
            ),
          ),
        ),
      ),
    );
    Widget ruled(Widget row) => DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: rim)),
      ),
      child: row,
    );
    expect(
      await _checkRow(tester, [
        tick,
        heading('Name'),
        heading('Owner'),
      ], wrap: ruled),
      isEmpty,
    );
    expect(
      await _checkRow(tester, [heading('Name'), heading('Owner')], wrap: ruled),
      isEmpty,
    );
  });

  group('on a light dialog', () {
    final ok = _button('OK', _face(fill: _blue));

    testWidgets('a glass Cancel whose ring has no contrast is read inside it', (
      tester,
    ) async {
      // The ring is 3 a channel off the dialog: 1.02 to 1.
      final glass = _face(
        fill: const Color(0xFFC9D1DE),
        ring: const Color(0xFFF1F3F7),
      );
      expect(
        await _check(
          tester,
          surface: _light,
          cancel: _button('Cancel', glass),
          ok: ok,
        ),
        _cancelOff,
      );
    });

    testWidgets('its ring with contrast reaches the box', (tester) async {
      final outlined = _face(fill: _light, ring: const Color(0xFF8C96A8));
      expect(
        await _check(
          tester,
          surface: _light,
          cancel: _button('Cancel', outlined),
          ok: ok,
        ),
        isEmpty,
      );
    });

    testWidgets('a fill that reaches the box', (tester) async {
      final filled = _face(fill: const Color(0xFFC9D1DE));
      expect(
        await _check(
          tester,
          surface: _light,
          cancel: _button('Cancel', filled),
          ok: ok,
        ),
        isEmpty,
      );
    });

    testWidgets('the floor decides what a person sees', (tester) async {
      // A ring 1.35 to 1 against the dialog, a fill well inside it.
      final ringed = _face(
        fill: const Color(0xFF9AA3B2),
        ring: const Color(0xFFD0D6E0),
      );
      final cancel = _button('Cancel', ringed);
      expect(
        await _check(tester, surface: _light, cancel: cancel, ok: ok),
        isEmpty,
      );
      expect(
        await _check(
          tester,
          surface: _light,
          cancel: cancel,
          ok: ok,
          floor: 1.5,
        ),
        _cancelOff,
      );
    });
  });

  group('on a dark dialog', () {
    final ok = _button('OK', _face(fill: const Color(0xFF8AB4F8)));

    testWidgets('a glass Cancel whose ring has no contrast', (tester) async {
      final glass = _face(
        fill: const Color(0xFF3A404C),
        ring: const Color(0xFF1F2229),
      );
      expect(
        await _check(
          tester,
          surface: _dark,
          cancel: _button('Cancel', glass),
          ok: ok,
        ),
        _cancelOff,
      );
    });

    testWidgets('its ring with contrast', (tester) async {
      final outlined = _face(fill: _dark, ring: const Color(0xFF6A7282));
      expect(
        await _check(
          tester,
          surface: _dark,
          cancel: _button('Cancel', outlined),
          ok: ok,
        ),
        isEmpty,
      );
    });
  });

  group("Ledger's night dialog", () {
    // An outlined Cancel beside a filled Sign out: what a person saw as 40
    // beside 48.
    const ring = Color(0xFFEEE8DC);
    final signOut = _button('Sign out', _face(fill: const Color(0xFFE57F68)));
    Widget outlined(double height) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: ring),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(width: 150, height: height),
    );

    testWidgets('its ring 40 high in a 48 box beside a 48 face', (
      tester,
    ) async {
      // The face is 40, centred in the 48 its press reaches.
      final cancel = _button(
        'Cancel',
        SizedBox(height: 48, child: Center(child: outlined(40))),
      );
      expect(
        await _check(tester, surface: _dark, cancel: cancel, ok: signOut),
        [
          'a button "Cancel" beside a button "Sign out": its top is 4 px '
              'below theirs as laid out, 12 device px below as drawn',
          'a button "Cancel" beside a button "Sign out": its bottom is 4 px '
              'above theirs as laid out, 12 device px above as drawn',
        ],
      );
    });

    testWidgets('its ring drawn 4 inside its own 48 face', (tester) async {
      // The face is 48, the colour of the dialog; the ring 4 inside it.
      final cancel = _button(
        'Cancel',
        DecoratedBox(
          decoration: BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 150,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: outlined(40),
            ),
          ),
        ),
      );
      expect(
        await _check(tester, surface: _dark, cancel: cancel, ok: signOut),
        [
          'a button "Cancel" beside a button "Sign out": its top is level '
              'with theirs as laid out, 12 device px below as drawn',
          'a button "Cancel" beside a button "Sign out": its bottom is level '
              'with theirs as laid out, 12 device px above as drawn',
        ],
      );
    });
  });

  testWidgets('a pill with a soft shadow is read by its face, not the shadow', (
    tester,
  ) async {
    const soft = [
      BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
    ];
    Widget pill(Color fill) => _face(fill: fill, shadow: soft, radius: 24);
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button('Cancel', pill(const Color(0xFFC9D1DE))),
        ok: _button('OK', pill(_blue)),
      ),
      isEmpty,
    );
    // A pill the colour of the dialog, drawn by its shadow alone: no pixel
    // inside it stands off, so it is read by its box.
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button('Cancel', pill(_light)),
        ok: _button('OK', pill(_blue)),
      ),
      isEmpty,
    );
  });

  testWidgets('a smaller secondary is named, whatever the reason', (
    tester,
  ) async {
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button(
          'Later',
          _face(fill: const Color(0xFFC9D1DE), height: 40),
        ),
        ok: _button('OK', _face(fill: _blue)),
      ),
      [
        'a button "Later" beside a button "OK": its top is 4 px below theirs '
            'as laid out, 12 device px below as drawn',
        'a button "Later" beside a button "OK": its bottom is 4 px above '
            'theirs as laid out, 12 device px above as drawn',
      ],
    );
  });

  testWidgets('what is not a row of controls is not held as one', (
    tester,
  ) async {
    final glass = _face(
      fill: const Color(0xFFC9D1DE),
      ring: const Color(0xFFF1F3F7),
    );
    // One above the other.
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button('Cancel', glass),
        ok: _button('OK', _face(fill: _blue)),
        stacked: true,
      ),
      isEmpty,
    );
    // A checkbox beside a button: less than half its height.
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button(
          'Agree',
          _face(fill: _blue, width: 20, height: 20, radius: 4),
        ),
        ok: _button('OK', _face(fill: _blue)),
      ),
      isEmpty,
    );
  });

  testWidgets('a face marked with DesignKeylineFace is taken as it is', (
    tester,
  ) async {
    final glass = DesignKeylineFace(
      child: _face(
        fill: const Color(0xFFC9D1DE),
        ring: const Color(0xFFF1F3F7),
      ),
    );
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button('Cancel', glass),
        ok: _button('OK', _face(fill: _blue)),
      ),
      isEmpty,
    );
  });

  testWidgets('a label off the row\'s centre line is named, as laid out and '
      'as drawn', (tester) async {
    final problems = await _check(
      tester,
      surface: _light,
      cancel: _button('Cancel', _face(fill: const Color(0xFFC9D1DE))),
      ok: _button(
        'OK',
        _face(fill: _blue),
        text: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _label('OK'),
        ),
      ),
    );
    expect(problems, hasLength(1));
    expect(
      problems.single,
      matches(
        RegExp(
          r'^a button "OK" beside a button "Cancel": the capitals of "OK" are '
          r"[0-9.]+ px below the row's centre line as laid out, "
          r'(2\.[5-9]|3(\.[0-4])?) device px below as drawn$',
        ),
      ),
    );
  });

  group('a control with no face of its own', () {
    final ok = _button('OK', _face(fill: _blue));

    testWidgets('an icon button drawn as a bare glyph is read by its icon on '
        'the centre line', (tester) async {
      expect(await _checkRow(tester, [_bare('More'), ok]), isEmpty);
      final problems = await _checkRow(tester, [_bare('More', nudge: 2), ok]);
      expect(problems, hasLength(1));
      expect(
        problems.single,
        matches(
          RegExp(
            r'^a button "More" beside a button "OK": its icon is 2 px below '
            r"the row's centre line as laid out, (5\.[5-9]|6(\.[0-4])?) device "
            r'px below as drawn$',
          ),
        ),
      );
    });

    testWidgets('a text button is read by its capitals, not its box', (
      tester,
    ) async {
      // Its press reaches 40 of the 48: no outline, so no top or bottom.
      final later = _button('Later', const SizedBox(width: 100, height: 40));
      expect(await _checkRow(tester, [later, ok]), isEmpty);
      final low = _button(
        'Later',
        const SizedBox(width: 100, height: 40),
        text: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _label('Later'),
        ),
      );
      final problems = await _checkRow(tester, [low, ok]);
      expect(problems, hasLength(1));
      expect(
        problems.single,
        matches(
          RegExp(
            r'^a button "Later" beside a button "OK": the capitals of "Later" '
            r"are [0-9.]+ px below the row's centre line as laid out, "
            r'(2\.[5-9]|3(\.[0-4])?) device px below as drawn$',
          ),
        ),
      );
    });

    testWidgets("a badge is not its icon's face", (tester) async {
      // Each badge is more than a quarter of its 28 px control, so it was
      // read as its face: 16 beside 18, a bottom 2 px apart.
      expect(
        await _checkRow(tester, [
          _bare('Inbox', size: 28, badge: _badge('3', 16)),
          const SizedBox(width: 12),
          _bare('Alerts', size: 28, badge: _badge('12', 18)),
        ]),
        isEmpty,
      );
    });

    testWidgets("navigation destinations: an indicator holds only the icon, "
        'each read by its icon', (tester) async {
      Widget destination(
        String label, {
        bool chosen = false,
        double nudge = 0,
      }) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            width: 80,
            height: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: chosen ? const Color(0xFFD3E3FD) : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    width: 64,
                    height: 32,
                    child: Center(child: _icon(nudge: nudge)),
                  ),
                ),
                const SizedBox(height: 4),
                _label(label, size: 12),
              ],
            ),
          ),
        ),
      );
      expect(
        await _checkRow(tester, [
          destination('Home', chosen: true),
          destination('Saved'),
          destination('Search'),
        ]),
        isEmpty,
      );
      final problems = await _checkRow(tester, [
        destination('Home', chosen: true),
        destination('Saved'),
        destination('Search', nudge: 2),
      ]);
      expect(problems, hasLength(1));
      expect(
        problems.single,
        matches(
          RegExp(
            r'^a button "Search" beside a button "Home": its icon is 2 px '
            r"below the row's centre line as laid out, (5\.[5-9]|6(\.[0-4])?) "
            r'device px below as drawn$',
          ),
        ),
      );
    });

    testWidgets("a pressable layer's pixels are its own, not an icon drawn "
        'over it from beside it', (tester) async {
      // Each item: a clear pressed-state layer (the control), and over it,
      // outside the control, an icon of its own shape.
      Widget item(String label, IconData glyph) => Stack(
        alignment: Alignment.center,
        children: [
          Semantics(
            button: true,
            label: label,
            child: GestureDetector(
              onTap: () {},
              child: const CustomPaint(painter: _Layer(), size: Size(56, 32)),
            ),
          ),
          Icon(glyph, size: 24, color: const Color(0xFF101010)),
        ],
      );
      expect(
        await _checkRow(tester, [
          item('Home', const IconData(0xE318, fontFamily: 'MaterialIcons')),
          item('Search', const IconData(0xE567, fontFamily: 'MaterialIcons')),
          item('Add', const IconData(0xE047, fontFamily: 'MaterialIcons')),
        ]),
        isEmpty,
      );
    });

    testWidgets("a tab's indicator line is a mark on it, not its face", (
      tester,
    ) async {
      Widget tab(String label, {bool chosen = false}) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () {},
          // A face that shows only its bottom border: the chosen tab's
          // indicator, or the strip's divider under the others.
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: _blue, width: chosen ? 3 : 1),
              ),
            ),
            child: SizedBox(
              width: 100,
              height: 48,
              child: Center(child: _label(label)),
            ),
          ),
        ),
      );
      expect(
        await _checkRow(tester, [
          tab('Day', chosen: true),
          tab('Week'),
          tab('Month'),
        ]),
        isEmpty,
      );
    });
  });

  testWidgets("a control scrolled out of the image is left out", (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: _light,
              child: SizedBox(
                width: 200,
                height: 96,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        _button('Day', _face(fill: _blue)),
                        const SizedBox(width: 12),
                        // Its middle past the image's edge.
                        _button('Week', _face(fill: _blue, height: 40)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final report = await const DesignRowCheck(look: 'Fixture')
        .check(key.currentContext!, runAsync: tester.runAsync);
    expect(report.problems, isEmpty);
  });

  testWidgets("a card's title over its body is placed, not centred", (
    tester,
  ) async {
    Widget card(String title) => Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 160,
            height: 96,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_label(title, size: 16), _label('Sold out')],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      await _checkRow(tester, [
        card('Elevated'),
        const SizedBox(width: 12),
        card('Filled'),
      ]),
      isEmpty,
    );
  });

  testWidgets("a text field's own parts are one field, not a row", (
    tester,
  ) async {
    final text = TextEditingController(text: 'Lisbon');
    final focus = FocusNode();
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    // Its clear button's icon 3 px low: the field's own layout, not a row's.
    final field = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 240,
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Semantics(
                  textField: true,
                  child: EditableText(
                    controller: text,
                    focusNode: focus,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Color(0xFF101010),
                    ),
                    cursorColor: const Color(0xFF101010),
                    backgroundCursorColor: _light,
                  ),
                ),
              ),
            ),
            _bare('Clear', nudge: 3),
          ],
        ),
      ),
    );
    expect(await _checkRow(tester, [field]), isEmpty);
  });

  testWidgets("a field's parts whose touch targets overhang its face are one "
      'field', (tester) async {
    final text = TextEditingController(text: 'Lisbon');
    final focus = FocusNode();
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    // A 44 search pill; its 28 clear round's node spreads over a 48 target
    // centred on it, as Material pads its targets, overhanging the pill by 2
    // above and below. Its entry's line has a paint round it that draws
    // nothing, as Material's InputDecorator has with no border.
    final field = DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: SizedBox(
        width: 240,
        height: 44,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Row(
            spacing: 10,
            children: [
              Expanded(child: _bareEntry(text, focus)),
              SizedBox.square(
                dimension: 28,
                child: OverflowBox(
                  maxWidth: 48,
                  maxHeight: 48,
                  child: Semantics(
                    button: true,
                    label: 'Clear search',
                    child: GestureDetector(
                      onTap: () {},
                      child: SizedBox.square(
                        dimension: 48,
                        child: Center(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFFDDDDDD),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(
                              dimension: 28,
                              child: Center(child: _icon()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(await _checkRow(tester, [field]), isEmpty);
  });

  testWidgets("a paint round a text entry that draws nothing is not its face", (
    tester,
  ) async {
    final text = TextEditingController(text: 'Lisbon');
    final focus = FocusNode();
    addTearDown(text.dispose);
    addTearDown(focus.dispose);
    // A bare entry, its line on the row's middle in a 24 band, beside a 40
    // button: no face of its own to hold against the button's.
    final problems = await _checkRow(tester, [
      SizedBox(width: 160, height: 24, child: _bareEntry(text, focus)),
      const SizedBox(width: 12),
      _button(
        'Go',
        _face(fill: _blue, width: 64, height: 40),
        text: _label('Go', size: 16),
      ),
    ]);
    expect(problems, isEmpty);
  });

  testWidgets("words whose capitals are round or pointed are read at their "
      "style's cap height", (tester) async {
    // Three links laid out on one line: "Open" and "Archived" have no
    // flat-topped capital (an O and an A overshoot the cap height), "Version"
    // has one. Read from their own capitals they stood a device pixel apart
    // (large here, as small words in a face whose overshoot is larger).
    Widget link(String words) => Semantics(
      link: true,
      label: words,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          height: 64,
          child: Center(
            child: Text(
              words,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 40,
                color: Color(0xFF2F5BD3),
              ),
            ),
          ),
        ),
      ),
    );
    final problems = await _checkRow(tester, [
      link('Open'),
      const SizedBox(width: 12),
      link('Version'),
      const SizedBox(width: 12),
      link('Archived'),
    ]);
    expect(problems, isEmpty);
  });

  testWidgets("a box with a clear fill and a clear stroke is no face", (
    tester,
  ) async {
    // A subtle icon button: its 48 box decorated with a clear fill and a
    // clear 1 px stroke, so nothing shows round its glyph; beside it a 32
    // avatar, both on the bar's middle. Read by its glyph, not its box.
    final subtle = Semantics(
      button: true,
      label: 'Upload',
      child: GestureDetector(
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x00000000),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0x00000000)),
          ),
          child: SizedBox.square(dimension: 48, child: Center(child: _icon())),
        ),
      ),
    );
    final avatar = Semantics(
      button: true,
      label: 'Profile',
      child: GestureDetector(
        onTap: () {},
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
    expect(await _checkRow(tester, [subtle, avatar]), isEmpty);
  });

  testWidgets("a count on a badge's pill is not its control's words", (
    tester,
  ) async {
    // A bare bell with a count on a red pill at its end, on the bell's
    // middle, beside a 48 button: the pill is not read as the count drawn in
    // solid boxes, nor the count as the bell's words.
    final bell = _bare(
      'Notifications, 3 unread',
      badge: _badge('3', 18),
      badgeTop: 15,
    );
    expect(
      await _checkRow(tester, [
        bell,
        const SizedBox(width: 8),
        _bare('Search'),
      ]),
      isEmpty,
    );
  });

  testWidgets("words on a fill of their own inside a control are read on it", (
    tester,
  ) async {
    // A swiped row: its action's red fill is the control's face, and its
    // words stand on the row's own white surface, slid half off it.
    final row = Semantics(
      button: true,
      label: 'Mara Okafor',
      child: GestureDetector(
        onTap: () {},
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFD93025)),
          child: SizedBox(
            width: 200,
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 100,
                height: 48,
                color: const Color(0xFFFFFFFF),
                alignment: Alignment.center,
                child: _label('Mara Okafor'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      await _checkRow(tester, [
        row,
        const SizedBox(width: 8),
        _button('Go', _face(fill: _blue, width: 64, height: 48)),
      ]),
      isEmpty,
    );
  });

  testWidgets("a face's words under its icon are placed, not on the centre "
      'line', (tester) async {
    // A swiped row's action: an icon over its words, the two centred in its
    // face as one block, beside the row. The face holds them.
    final action = Semantics(
      button: true,
      label: 'Archive',
      child: GestureDetector(
        onTap: () {},
        child: _face(fill: _blue, width: 72, height: 72, radius: 0)._under(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [_icon(), const SizedBox(height: 4), _label('Archive')],
          ),
        ),
      ),
    );
    expect(
      await _checkRow(tester, [
        _button('Row', _face(fill: _blue, width: 200, height: 72)),
        action,
      ]),
      isEmpty,
    );
  });

  testWidgets("a chosen destination's face round its icon and words does not "
      "move its neighbours' icons", (tester) async {
    // A bar of destinations, each an icon over its words; the chosen one
    // has a pill round both, the others no face. Their icons line up.
    Widget destination(String label, {bool chosen = false}) {
      final content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [_icon(), const SizedBox(height: 4), _label(label, size: 12)],
      );
      return Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: () {},
          child: SizedBox(
            width: 80,
            height: 64,
            child: Center(
              child: chosen
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE3F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        width: 72,
                        height: 56,
                        child: Center(child: content),
                      ),
                    )
                  : content,
            ),
          ),
        ),
      );
    }

    expect(
      await _checkRow(tester, [
        destination('Home', chosen: true),
        destination('Move'),
        destination('Cards'),
      ]),
      isEmpty,
    );
  });

  testWidgets("a row's one face is not held to itself: its words in it are "
      "the label check's", (tester) async {
    // Destinations with no face, each an icon over its words, and one with
    // only its words, in a pill whose words sit 1 px high: nothing beside
    // the pill to hold it to.
    Widget destination(String label) => Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: 80,
          height: 64,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _icon(),
                const SizedBox(height: 4),
                _label(label, size: 12),
              ],
            ),
          ),
        ),
      ),
    );
    final pill = Semantics(
      button: true,
      label: 'Move',
      child: GestureDetector(
        onTap: () {},
        child: SizedBox(
          width: 80,
          height: 64,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 64,
                height: 24,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -1),
                    child: _label('Move', size: 12, colour: _light),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      await _checkRow(tester, [
        destination('Home'),
        pill,
        destination('Cards'),
      ]),
      isEmpty,
    );
  });

  testWidgets('a region that says why its controls differ is not held; a '
      'to-do there is named', (tester) async {
    // One button per size, side by side on purpose: a gallery's ladder.
    final ladder = [
      for (final (label, height) in [('S', 32.0), ('M', 40.0), ('L', 48.0)])
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _button(
            label,
            _face(fill: _blue, width: 80, height: height),
            text: _label(label, colour: const Color(0xFFFFFFFF)),
          ),
        ),
    ];
    expect(await _checkRow(tester, ladder), hasLength(4));
    expect(
      await _checkRow(
        tester,
        ladder,
        wrap: (row) => DesignKeylineRegion(
          mixedHeights: 'one button per size, side by side on purpose',
          child: row,
        ),
      ),
      isEmpty,
    );
    expect(
      await _checkRow(
        tester,
        ladder,
        wrap: (row) =>
            DesignKeylineRegion(mixedHeights: 'TODO level these', child: row),
      ),
      [
        'a row of a button "S", a button "M" and a button "L": "TODO level '
            'these" is a to-do, not a reason its controls differ',
      ],
    );
  });

  testWidgets("text in the test's own font fails the check once", (
    tester,
  ) async {
    final box = Text('Cancel', style: TextStyle(color: Color(0xFF101010)));
    expect(
      await _check(
        tester,
        surface: _light,
        cancel: _button(
          'Cancel',
          _face(fill: const Color(0xFFC9D1DE)),
          text: box,
        ),
        ok: _button('OK', _face(fill: _blue)),
      ),
      [
        "1 control draws its text in the test's own font (solid boxes), a "
            'button "Cancel" first: load every font family the look ships '
            '(each family in its FontManifest.json) before the check',
      ],
    );
  });

  group('a field beside a button holds one line of capitals', () {
    // A 13 px button label beside a 14 px field's text: their baselines
    // differ, their capitals do not.
    Future<List<String>> fieldRow(
      WidgetTester tester, {
      required VisualDensity density,
      required bool typed,
      required double ratio,
      double nudge = 0,
    }) async {
      final height = density == VisualDensity.compact ? 40.0 : 48.0;
      const style = TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        color: Color(0xFF101010),
      );
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(visualDensity: density),
          home: Material(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: _light,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            border: Border.all(color: const Color(0xFF8C96A8)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SizedBox(
                            width: 180,
                            height: height,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Padding(
                                  padding: EdgeInsets.only(top: nudge),
                                  child: DesignCapCenter(
                                    capHeightFactor: _roboto,
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: typed ? 'TEXT' : '',
                                      ),
                                      style: style,
                                      decoration: const InputDecoration(
                                        isCollapsed: true,
                                        isDense: false,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: 'HINT',
                                        hintStyle: style,
                                        border: InputBorder.none,
                                        visualDensity: VisualDensity.standard,
                                        constraints: BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _button(
                          'EDIT',
                          _face(fill: _blue, width: 96, height: height),
                          text: _label(
                            'EDIT',
                            size: 13,
                            colour: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final report = await DesignRowCheck(
        look: 'Fixture',
        pixelRatio: ratio,
      ).check(key.currentContext!, runAsync: tester.runAsync);
      return report.problems;
    }

    testWidgets('a field whose line sits low is named', (tester) async {
      for (final typed in [true, false]) {
        final problems = await fieldRow(
          tester,
          density: VisualDensity.standard,
          typed: typed,
          ratio: 3,
          nudge: 2,
        );
        expect(problems, hasLength(1));
        expect(
          problems.single,
          matches(
            RegExp(
              '^a text field( "HINT")? beside a button "EDIT": the capitals of '
              '"${typed ? 'TEXT' : 'HINT'}" are [0-9.]+ px below the row\'s '
              r'centre line as laid out, (2\.[5-9]|3(\.[0-4])?) device px '
              r'below as drawn$',
            ),
          ),
        );
      }
    });

    for (final density in [VisualDensity.standard, VisualDensity.compact]) {
      for (final typed in [true, false]) {
        final what =
            '${density == VisualDensity.compact ? 'compact' : 'standard'}, '
            '${typed ? 'typed' : 'its hint'}';
        testWidgets(what, (tester) async {
          for (final ratio in [1.0, 2.0, 3.0]) {
            expect(
              await fieldRow(
                tester,
                density: density,
                typed: typed,
                ratio: ratio,
              ),
              isEmpty,
              reason: '${ratio}x',
            );
          }
        });
      }
    }
  });

  group('by drawn face', () {
    // A chip: its words on a face 44 tall.
    Widget chip(String label) => _button(
      label,
      _face(fill: const Color(0xFFDDE4F5), width: 88, height: 44, radius: 22),
    );

    // One face 64 tall round the chip's press (its words) and the remove
    // button at its end (a 48 touch target).
    Widget removable({required double height}) => DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDDE4F5),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: 'Design',
              child: GestureDetector(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16),
                  child: Center(widthFactor: 1, child: _label('Design')),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Remove Design',
              child: GestureDetector(
                onTap: () {},
                child: SizedBox.square(
                  dimension: math.min(48, height),
                  child: const Center(
                    child: Icon(_chevron, size: 18, color: _dark),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    testWidgets('a chip whose face is drawn round its press and its remove '
        'button stands the height of the chips beside it', (tester) async {
      final row = [
        chip('All'),
        const SizedBox(width: 12),
        chip('Food'),
        const SizedBox(width: 12),
        chip('Travel'),
        const SizedBox(width: 12),
      ];
      expect(
        await _checkRow(tester, [...row, removable(height: 64)]),
        contains(matches(RegExp(r'"Design".*: its (top|bottom) is'))),
      );
      expect(await _checkRow(tester, [...row, removable(height: 44)]), isEmpty);
    });

    testWidgets('a select with its label over its face, beside buttons, is '
        'held by its face', (tester) async {
      // The label 16 over a face 30 tall, all one control 46 tall, centred
      // in the row with buttons 30 tall: its face 8 below theirs.
      Widget select({required bool labelOver}) => Semantics(
        button: true,
        expanded: false,
        label: 'Preset',
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (labelOver)
                SizedBox(
                  height: 16,
                  child: Text(
                    'Preset',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: _dark,
                    ),
                  ),
                ),
              _face(
                fill: const Color(0xFFFFFFFF),
                width: 140,
                height: 30,
                radius: 6,
              )._under(_label('Opal')),
            ],
          ),
        ),
      );
      Widget button(String label) => _button(
        label,
        _face(fill: _blue, width: 88, height: 30, radius: 6),
        text: _label(label, colour: const Color(0xFFFFFFFF)),
      );
      final found = await _checkRow(tester, [
        button('Light'),
        const SizedBox(width: 8),
        button('Dark'),
        const SizedBox(width: 8),
        select(labelOver: true),
      ]);
      expect(found, contains(matches(RegExp(r'"Preset".*: its top is'))));
      expect(
        await _checkRow(tester, [
          button('Light'),
          const SizedBox(width: 8),
          button('Dark'),
          const SizedBox(width: 8),
          select(labelOver: false),
        ]),
        isEmpty,
      );
    });

    testWidgets("a wrap's chips are read run by run, each run a row", (
      tester,
    ) async {
      // All, Food and Design on the first run, Travel and Home on the
      // second; the runs start at their tops.
      Widget chips(double removableHeight) => SizedBox(
        width: 340,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            chip('All'),
            chip('Food'),
            removable(height: removableHeight),
            chip('Travel'),
            chip('Home'),
          ],
        ),
      );
      expect(
        await _checkBody(tester, chips(64)),
        contains(matches(RegExp(r'"Design".*: its bottom is'))),
      );
      expect(await _checkBody(tester, chips(44)), isEmpty);
    });

    testWidgets('a control a clip partly hides (a week scrolled in its '
        'strip) is not held; whole, it is', (tester) async {
      // All, Food and Travel, then Design from 300: a strip 340 wide shows
      // 40 of it.
      Widget strip(double width) => SizedBox(
        width: width,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              chip('All'),
              const SizedBox(width: 12),
              chip('Food'),
              const SizedBox(width: 12),
              chip('Travel'),
              const SizedBox(width: 12),
              removable(height: 64),
            ],
          ),
        ),
      );
      expect(await _checkBody(tester, strip(340)), isEmpty);
      expect(
        await _checkBody(tester, strip(480)),
        contains(matches(RegExp(r'"Design".*: its (top|bottom) is'))),
      );
      // A date picker's week: seven day cells 48 wide scrolling in a column
      // 268 wide, Saturday partly past the column's edge and Sunday wholly,
      // though both lie on the screen. Sunday's face stands 56 high among
      // 44: hidden, it is not held; shown, it is.
      Widget day(String label) => _button(
        label,
        _face(
          fill: const Color(0xFFDDE4F5),
          width: 48,
          height: label == '7' ? 56 : 44,
          radius: 6,
        ),
      );
      Widget week(double width) => SizedBox(
        width: width,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final d in ['1', '2', '3', '4', '5', '6', '7']) day(d),
            ],
          ),
        ),
      );
      expect(await _checkBody(tester, week(268)), isEmpty);
      expect(
        await _checkBody(tester, week(336)),
        contains(matches(RegExp(r'"7".*: its (top|bottom) is'))),
      );
    });

    testWidgets('a field with a key inside its face: the key is held by the '
        "field's face, not as a row with its entry", (tester) async {
      final text = TextEditingController(text: 'Hello');
      final focus = FocusNode();
      addTearDown(text.dispose);
      addTearDown(focus.dispose);
      // A well 48 high round an entry and a send key 32 square on a face of
      // its own, 8 in from the well's end.
      Widget field({double keyNudge = 0}) => SizedBox(
        width: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            border: Border.all(color: const Color(0xFF8A8F99)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Expanded(child: _bareEntry(text, focus)),
                Transform.translate(
                  offset: Offset(0, keyNudge),
                  child: _button(
                    'Send',
                    _face(fill: _blue, width: 32, height: 32, radius: 8),
                    text: const Icon(_chevron, size: 18, color: _light),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      );
      expect(await _checkBody(tester, field()), isEmpty);
    });
  });
}

// A pressed-state layer at rest: clear, so it draws nothing.
// A text entry on its own line, centred in what it is given, inside a paint
// that draws nothing (Material's InputDecorator with no border has one).
Widget _bareEntry(TextEditingController text, FocusNode focus) => CustomPaint(
  painter: const _NoInk(),
  child: Center(
    child: Semantics(
      textField: true,
      child: EditableText(
        controller: text,
        focusNode: focus,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: Color(0xFF101010),
        ),
        cursorColor: const Color(0xFF101010),
        backgroundCursorColor: _light,
      ),
    ),
  ),
);

extension on Widget {
  // This face with [child] centred over it.
  Widget _under(Widget child) =>
      Stack(alignment: Alignment.center, children: [this, child]);
}

class _NoInk extends CustomPainter {
  const _NoInk();

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_NoInk oldDelegate) => false;
}

class _Layer extends CustomPainter {
  const _Layer();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0x00000000),
    );
  }

  @override
  bool shouldRepaint(_Layer oldDelegate) => false;
}

// A picture: a filled square.
class _Picture extends CustomPainter {
  const _Picture();

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = _blue);

  @override
  bool shouldRepaint(_Picture oldDelegate) => false;
}
