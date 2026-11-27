// DesignFaceInsetCheck: a control's label keeps clear of its face's edges,
// by as much as Material's and Cupertino's controls keep.
import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

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
  for (final weight in ['Regular', 'Medium']) {
    final font = File(
      '$root/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf',
    );
    await (FontLoader('Roboto')
          ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
        .load();
  }
}

const _ink = Color(0xFF16181D);
const _fill = Color(0xFFDDE4F5);
const _line = Color(0xFF8A93A6);
const _style = TextStyle(
  fontFamily: 'Roboto',
  fontSize: 14,
  height: 1.2,
  fontWeight: FontWeight.w500,
  color: _ink,
);

final _key = GlobalKey();

Future<List<String>> _check(
  WidgetTester tester,
  Widget body, {
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(900, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(900, 600),
        textScaler: TextScaler.linear(scale),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFFF7F7F5),
          child: Center(
            child: RepaintBoundary(key: _key, child: body),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final report = await const DesignFaceInsetCheck(look: 'Fixture')
      .check(_key.currentContext!, runAsync: tester.runAsync);
  return report.problems;
}

BoxDecoration get _face => BoxDecoration(
  color: _fill,
  border: Border.all(color: _line),
  borderRadius: BorderRadius.circular(8),
);

// A button whose face [builder] draws round its label.
Widget _button(
  Widget Function(Widget label) builder, {
  String label = 'Apply',
  TextStyle style = _style,
}) => RawButton(
  onPressed: () {},
  builder: (context, states, _) => builder(Text(label, style: style)),
);

const _page = Color(0xFFF7F7F5);

void main() {
  setUpAll(_loadRoboto);

  testWidgets('a face drawn round its label alone is named', (tester) async {
    // The face inside a RawControlBox: centred on the box's height, it hugs
    // the label's line.
    final problems = await _check(
      tester,
      _button(
        (label) => RawControlBox(
          minHeight: 44,
          child: DecoratedBox(
            decoration: _face,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: label,
            ),
          ),
        ),
      ),
    );
    expect(problems, hasLength(1));
    expect(
      problems.single,
      allOf(
        startsWith('a button "Apply": the ink of "Apply" is '),
        contains('px from the foot of its face'),
        contains('px from its top'),
        endsWith('closer than 4 px: pad the label inside the face'),
      ),
    );
  });

  testWidgets('the label padded inside its face passes', (tester) async {
    final problems = await _check(
      tester,
      _button(
        (label) => DecoratedBox(
          decoration: _face,
          child: RawControlBox(
            minHeight: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: label,
            ),
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets('a face with no room at its sides is named', (tester) async {
    final problems = await _check(
      tester,
      _button(
        (label) => DecoratedBox(
          decoration: _face,
          child: SizedBox(
            height: 40,
            child: Center(widthFactor: 1, child: label),
          ),
        ),
      ),
    );
    expect(problems, hasLength(1));
    expect(problems.single, contains('side of its face'));
    expect(problems.single, isNot(contains('top')));
  });

  testWidgets('a face 3 px short of the room is named, at its room passes', (
    tester,
  ) async {
    Widget padded(double side) => _button(
      (label) => DecoratedBox(
        decoration: const BoxDecoration(color: _fill),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: side),
            child: Center(widthFactor: 1, child: label),
          ),
        ),
      ),
      label: 'HIH',
    );
    expect(await _check(tester, padded(1)), hasLength(1));
    expect(await _check(tester, padded(5)), isEmpty);
  });

  testWidgets("words drawn into the face's outline are named", (tester) async {
    // A 4 px outline round the face: words that reach into it at the sides
    // touch it, however far the reading of the face's inside would put them.
    Widget outlined(double side) => _button(
      (label) => DecoratedBox(
        decoration: BoxDecoration(
          color: _fill,
          border: Border.all(color: _line, width: 4),
        ),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: side),
            child: Center(widthFactor: 1, child: label),
          ),
        ),
      ),
      label: 'HIH',
    );
    for (final side in const [1.0, 3.0]) {
      final problems = await _check(tester, outlined(side));
      expect(problems, hasLength(1), reason: '$side');
      expect(problems.single, contains('side of its face'));
    }
    expect(await _check(tester, outlined(4)), isEmpty);
  });

  testWidgets('a stroke over and under the words is not their ink', (
    tester,
  ) async {
    // A face ruled 4 px thick along its top and its foot, its words' line
    // reaching into both rules: the face's colour is read inside them, and
    // the rules are not the words' ink.
    Widget ruled(double side) => _button(
      (label) => DecoratedBox(
        decoration: const BoxDecoration(
          color: _fill,
          border: Border(
            top: BorderSide(color: _line, width: 4),
            bottom: BorderSide(color: _line, width: 4),
          ),
        ),
        child: SizedBox(
          height: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: side),
            child: Center(widthFactor: 1, child: label),
          ),
        ),
      ),
      label: 'HIH',
    );
    expect(await _check(tester, ruled(4)), isEmpty);
    final short = await _check(tester, ruled(2));
    expect(short, hasLength(1));
    expect(short.single, contains('side of its face'));
    expect(short.single, isNot(contains('top')));
  });

  testWidgets('an underline or a rule beside the words holds nothing in', (
    tester,
  ) async {
    for (final border in const [
      Border(bottom: BorderSide(color: _line)),
      Border(left: BorderSide(color: _line, width: 3)),
    ]) {
      final problems = await _check(
        tester,
        _button(
          (label) => DecoratedBox(
            decoration: BoxDecoration(border: border),
            child: label,
          ),
        ),
      );
      expect(problems, isEmpty, reason: '$border');
    }
  });

  testWidgets("a text entry's words and a badge's count are not read", (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Agpy');
    addTearDown(controller.dispose);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final problems = await _check(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            textField: true,
            child: DecoratedBox(
              decoration: _face,
              child: SizedBox(
                width: 200,
                child: EditableText(
                  controller: controller,
                  focusNode: focus,
                  style: _style,
                  cursorColor: _ink,
                  backgroundCursorColor: _line,
                ),
              ),
            ),
          ),
          _button(
            (label) => DecoratedBox(
              decoration: _face,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label,
                    const SizedBox(width: 8),
                    const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFB00020)),
                      child: Text('3', style: _style),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    expect(problems, isEmpty);
  });

  // The least room is Material's and Cupertino's: their controls pass at
  // every text size up to 3x, the tightest of them (a FilledButton's foot
  // at 2x, a SegmentedButton's side at 3x) at 4 px.
  for (final scale in const [1.0, 1.3, 2.0, 3.0]) {
    testWidgets("Material's and Cupertino's controls pass at ${scale}x", (
      tester,
    ) async {
      const roboto = TextStyle(fontFamily: 'Roboto');
      final problems = await _check(
        tester,
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Roboto',
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            cupertinoOverrideTheme: CupertinoThemeData(
              textTheme: CupertinoTextThemeData(
                textStyle: roboto.copyWith(fontSize: 17, color: _ink),
                actionTextStyle: roboto.copyWith(fontSize: 17),
              ),
            ),
          ),
          home: Material(
            child: MediaQuery(
              data: MediaQueryData(
                size: const Size(900, 600),
                textScaler: TextScaler.linear(scale),
              ),
              child: Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(onPressed: () {}, child: const Text('Agpy')),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Hbdfgjklpqy'),
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Agpy')),
                        ButtonSegment(value: 1, label: Text('Hbdfgjklpqy')),
                      ],
                      selected: const {1},
                      onSelectionChanged: (_) {},
                    ),
                    ActionChip(label: const Text('Agpy'), onPressed: () {}),
                    CupertinoButton.filled(
                      sizeStyle: CupertinoButtonSize.small,
                      onPressed: () {},
                      child: const Text('Save', style: roboto),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        scale: scale,
      );
      expect(problems, isEmpty);
    });
  }

  testWidgets("a face's own painting is not its label's ink: a bevel along "
      'its edge, a gradient down it', (tester) async {
    // A dark key lit from above, painted (no decoration to read a stroke
    // from): a gradient down its face and a light bevel along its top. At
    // twice the text its words' line reaches the face's edges; their ink
    // stands well inside.
    final problems = await _check(
      tester,
      RawButton(
        onPressed: () {},
        builder: (context, states, _) => CustomPaint(
          painter: const _KeyFace(),
          child: SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  'Publish',
                  style: _style.copyWith(
                    color: const Color(0xFFFFB347),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      scale: 2,
    );
    expect(problems, isEmpty);
  });

  testWidgets('a face the screen shows only in part is read when it comes '
      'into view', (tester) async {
    // A face drawn round its label alone, half past a list's foot.
    Widget list(double offset) {
      final controller = ScrollController(initialScrollOffset: offset);
      addTearDown(controller.dispose);
      return SizedBox(
        width: 240,
        height: 200,
        child: SingleChildScrollView(
          key: ValueKey(offset),
          controller: controller,
          child: Column(
            children: [
              const SizedBox(height: 180),
              _button(
                (label) => RawControlBox(
                  minHeight: 44,
                  child: DecoratedBox(
                    decoration: _face,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: label,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 300),
            ],
          ),
        ),
      );
    }

    expect(await _check(tester, list(0)), isEmpty, reason: 'cut by the foot');
    expect(await _check(tester, list(100)), hasLength(1), reason: 'in view');
  });

  testWidgets('a face that shows no edge holds nothing in: a text button on '
      'its page, rows on their card', (tester) async {
    // A text button painted in its page's colour, and rows painting only
    // what sits in them (a blob as high as the row before the words, a dot
    // at the end) on their card, all hugging their words: no edge shows for
    // the words to crowd.
    const card = Color(0xFFFFFFFF);
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                (label) =>
                    CustomPaint(painter: const _Fill(_page), child: label),
                label: 'Agpy',
              ),
              const SizedBox(height: 16),
              ColoredBox(
                color: card,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final row in const ['Morning walk', 'Drink water'])
                        _button(
                          (label) => CustomPaint(
                            painter: const _RowMarks(),
                            child: SizedBox(
                              width: 220,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 30,
                                  right: 16,
                                ),
                                child: label,
                              ),
                            ),
                          ),
                          label: row,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets('only the edges a face shows are read: one that runs on into '
      'a panel of its colour is not', (tester) async {
    // A face whose top runs on into a panel in its own colour above it: its
    // words have no edge to crowd there, but have one at its foot.
    Widget under(double foot) => ColoredBox(
      color: _page,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 200,
              height: 24,
              child: ColoredBox(color: _fill),
            ),
            _button(
              (label) => DecoratedBox(
                decoration: const BoxDecoration(color: _fill),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, foot),
                  child: label,
                ),
              ),
              label: 'Hgy',
            ),
          ],
        ),
      ),
    );
    expect(await _check(tester, under(8)), isEmpty);
    final tight = await _check(tester, under(0));
    expect(tight, hasLength(1));
    expect(tight.single, contains('the foot of its face'));
    expect(tight.single, isNot(contains('top')));
  });

  testWidgets('an outline round a painted face is its own, not its words\' '
      'ink', (tester) async {
    // A rounded face painted with its outline, its words' line reaching the
    // outline over and under them, the words near its rounded ends (no rule
    // runs on past them there to tell the outline by, the face's corners
    // round it). Their ink stands well inside it.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _button(
            (label) => CustomPaint(
              painter: const _Outlined(stroke: 1.5, fill: _fill),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: label,
              ),
            ),
            label: 'HIH',
            style: _style.copyWith(height: 2),
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("words drawn into a painted face's outline touch it", (
    tester,
  ) async {
    // A 4 px outline, the words lifted into it: a capital that runs on into
    // the outline touches it, though a small letter beside it stands clear.
    for (final words in const ['Hx', 'HIH']) {
      final problems = await _check(
        tester,
        _button(
          (label) => CustomPaint(
            painter: const _Outlined(stroke: 4, fill: _fill),
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Center(
                  widthFactor: 1,
                  child: Transform.translate(
                    offset: const Offset(0, -7.5),
                    child: label,
                  ),
                ),
              ),
            ),
          ),
          label: words,
          style: _style.copyWith(fontSize: 28, height: 1),
        ),
      );
      expect(problems, hasLength(1), reason: words);
      expect(problems.single, contains('the top of its face'), reason: words);
    }
  });

  testWidgets('an outline on its page holds its words in', (tester) async {
    // No fill, the page through it: the outline is the face's edge, painted
    // or decorated, though the words' box covers it (a face hugging its
    // words).
    for (final (name, face) in <(String, Widget Function(Widget))>[
      (
        'painted',
        (label) => CustomPaint(
          painter: const _Outlined(stroke: 1.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: label,
          ),
        ),
      ),
      (
        'hugging',
        (label) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: _line, width: 1.5),
          ),
          child: label,
        ),
      ),
    ]) {
      final problems = await _check(
        tester,
        ColoredBox(
          color: _page,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _button(face, label: 'Hgy'),
          ),
        ),
      );
      expect(problems, hasLength(1), reason: name);
      expect(problems.single, contains('foot'), reason: name);
    }
  });

  testWidgets('a gradient down a face is its colour under large words', (
    tester,
  ) async {
    // A day picked in a calendar: a strong gradient down its face, its
    // figures' line as high as the face. The colour round them on the face
    // is its colour, not what is round the face: figures with room pass,
    // figures at its sides are named.
    Widget day(double side) => ColoredBox(
      color: _page,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _button(
          (label) => DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF9A5A), Color(0xFFE0561C)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: label,
            ),
          ),
          label: '18',
          style: _style.copyWith(fontSize: 40, height: 1.2),
        ),
      ),
    );
    expect(await _check(tester, day(6)), isEmpty);
    final tight = await _check(tester, day(0));
    expect(tight, hasLength(1));
    expect(tight.single, contains('side of its face'));
  });

  testWidgets("a round face's corners are not its words' ink", (tester) async {
    // A day in a calendar, a circle round figures whose line is nearly as
    // high as it; a tab, a pill with an outline round words whose line is
    // nearly as high and as wide as it. What shows past the curve inside
    // the box (the page in its corners, the outline round the curve) is
    // not ink: words with room pass, words lifted to its top are named.
    Widget on(Widget face) => ColoredBox(
      color: _page,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RawButton(
          onPressed: () {},
          builder: (context, states, _) => face,
        ),
      ),
    );
    Widget lifted(double lift, String words, double size, double height) =>
        Transform.translate(
          offset: Offset(0, -lift),
          child: Text(
            words,
            style: _style.copyWith(fontSize: size, height: height),
          ),
        );
    Widget day(double lift) => on(
      DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _fill,
          border: Border.all(color: _line),
        ),
        child: SizedBox.square(
          dimension: 46,
          child: Center(child: lifted(lift, '120', 20, 2)),
        ),
      ),
    );
    Widget tab(double lift) => on(
      DecoratedBox(
        decoration: BoxDecoration(
          color: _fill,
          borderRadius: const BorderRadius.all(Radius.circular(22)),
          border: Border.all(color: _line, width: 1.5),
        ),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              widthFactor: 1,
              child: lifted(lift, 'Recent', 22, 1.8),
            ),
          ),
        ),
      ),
    );
    expect(await _check(tester, day(0)), isEmpty);
    expect(await _check(tester, tab(0)), isEmpty);
    for (final (name, face) in [('day', day(13)), ('tab', tab(11))]) {
      final tight = await _check(tester, face);
      expect(tight, hasLength(1), reason: name);
      expect(tight.single, contains('the top of its face'), reason: name);
    }
  });

  testWidgets('an edge that runs on past its box holds nothing in there', (
    tester,
  ) async {
    // A tab's label over the key its bar draws under it, the key running on
    // past the tab's own face: the face's foot is the key's colour, and so
    // is what is past it. Words over that edge are not held in by it; the
    // top, which stands off the panel, is read.
    final problems = await _check(
      tester,
      ColoredBox(
        color: const Color(0xFFD7D3CA),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RawButton(
                onPressed: () {},
                builder: (context, states, _) => DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.6, 0.8, 1],
                      colors: [
                        Color(0xFFFAF9F6),
                        Color(0xFFFAF9F6),
                        Color(0xFFEBE8E2),
                        Color(0xFFEBE8E2),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Text(
                      'Hgy',
                      style: _style.copyWith(fontSize: 20, height: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 80,
                height: 8,
                child: ColoredBox(color: Color(0xFFEBE8E2)),
              ),
            ],
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("a rim of the page's colour along a face's edge still shows it", (
    tester,
  ) async {
    // A light rim the page's own colour inside the face's edge: the face
    // stands off the page a little further in, so its foot holds its words
    // in.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RawButton(
            onPressed: () {},
            builder: (context, states, _) => DecoratedBox(
              decoration: BoxDecoration(
                color: _fill,
                border: Border.all(color: _page, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Text(
                  'Hgy',
                  style: _style.copyWith(fontSize: 20, height: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(problems, hasLength(1));
    expect(problems.single, contains('the foot of its face'));
  });

  testWidgets('a gradient across a wide face is ground where it is drawn', (
    tester,
  ) async {
    // A wide act, its colour running from one end to the other, its line as
    // high as it: each part of a row is read against the face near it, so
    // words with room pass, and words lifted to its top are named.
    Widget act(double lift) => ColoredBox(
      color: _page,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RawButton(
          onPressed: () {},
          builder: (context, states, _) => DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3050E0), Color(0xFF1C2E9A)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Transform.translate(
                offset: Offset(0, -lift),
                child: Text(
                  'Start now, then later',
                  style: _style.copyWith(
                    fontSize: 24,
                    height: 1.6,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(await _check(tester, act(0)), isEmpty);
    final tight = await _check(tester, act(10.5));
    expect(tight, hasLength(1));
    expect(tight.single, contains('the top of its face'));
  });

  testWidgets('a band drawn through words holds nothing in', (tester) async {
    // A marker drawn through a status's words, thinner than half their em:
    // no face round them.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: RawButton(
            onPressed: () {},
            builder: (context, states, _) => CustomPaint(
              painter: const _Band(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'HIH',
                  style: _style.copyWith(fontSize: 32, height: 1.2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("a legend across a frame's top is the frame's", (tester) async {
    // A field drawn as a frame, its name in a gap cut in its top: the name
    // sits across the edge by design; the value inside keeps its room.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: RawButton(
            onPressed: () {},
            builder: (context, states, _) => Stack(
              clipBehavior: Clip.none,
              children: [
                const CustomPaint(
                  painter: _Outlined(stroke: 1.5),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 18, 60, 14),
                    child: Text('every branch', style: _style),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: -8,
                  child: ColoredBox(
                    color: _page,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'branch',
                        style: _style.copyWith(height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("a round face's outline is not ink where its curve starts", (
    tester,
  ) async {
    // A pill tab outlined a pixel thick, its words' line as high as it:
    // where its ends start to curve, the outline dips a fraction of a pixel
    // below the line along its top; that is the face's, not its words'.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _button(
            (label) => DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEBF3FC),
                border: Border.all(color: const Color(0xFF0F6CBD)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: SizedBox(
                width: 104,
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: label),
                ),
              ),
            ),
            label: 'Recent',
            style: _style.copyWith(
              fontSize: 26,
              height: 44 / 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("a painted round face's ends are not its words' ink", (
    tester,
  ) async {
    // A pill its own painter draws (no clip, no decoration to read its
    // shape from) on a dark page, its words' box reaching into its curved
    // ends: the page there is past the face, not ink; words that come close
    // to its ends are still named.
    Widget pill(double room, {double shift = 0}) => ColoredBox(
      color: const Color(0xFF2B2F3A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _button(
          (label) => CustomPaint(
            painter: const _Pill(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: room, vertical: 2),
              child: Transform.translate(
                offset: Offset(-shift, 0),
                child: label,
              ),
            ),
          ),
          label: '000',
          style: _style.copyWith(fontSize: 32, height: 1.2),
        ),
      ),
    );
    expect(await _check(tester, pill(4.5)), isEmpty);
    final close = await _check(tester, pill(4.5, shift: 3));
    expect(close, hasLength(1));
    expect(close.single, contains('from the left side of its face'));
  });

  // A ball its own painter draws (an avatar's), shaded at its end or its foot
  // toward a dark page by night, lit at its start toward a light page by
  // day, so its rim stands only a little off the page: its edge is its
  // box's, and initials well inside it pass. Initials close to that edge are
  // still named, and a soft shadow a painter casts inside its box, fading
  // into the page before the box's edge, is not its face.
  Widget ball(_Ball painter, {Offset shift = Offset.zero, double target = 0}) =>
      ColoredBox(
        color: painter.page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _button(
            (label) => SizedBox.square(
              dimension: painter.size + target,
              child: Center(
                child: CustomPaint(
                  painter: painter,
                  child: SizedBox.square(
                    dimension: painter.size,
                    child: Center(
                      child: Transform.translate(offset: shift, child: label),
                    ),
                  ),
                ),
              ),
            ),
            label: 'SO',
            style: _style.copyWith(
              fontSize: 10.64,
              height: 1,
              color: painter.ink,
            ),
          ),
        ),
      );
  // Each ball with its initials where they keep the room (a little nearer
  // its lit top, where its rim is widest), then moved toward that edge half
  // a pixel at a time, from where they come closer than 4 px until their ink
  // reaches it: named at every step, over the rim as over the face.
  for (final (painter, rest, toward, from, to, edge) in const [
    (_Ball.nightEnd, Offset.zero, Offset(1, 0), 4.5, 7.5, 'right side'),
    (_Ball.nightFoot, Offset.zero, Offset(0, 1), 8.0, 11.0, 'foot'),
    (_Ball.dayStart, Offset.zero, Offset(-1, 0), 4.5, 7.5, 'left side'),
    (_Ball.dayTop, Offset(0, -3), Offset(0, -1), 6.0, 9.0, 'top'),
  ]) {
    testWidgets("a painted face's rim shaded toward the page is the face's: "
        '$painter', (tester) async {
      expect(await _check(tester, ball(painter, shift: rest)), isEmpty);
      for (var by = from; by <= to; by += 0.5) {
        final named = await _check(tester, ball(painter, shift: toward * by));
        expect(named, hasLength(1), reason: 'moved $by px');
        expect(
          named.single,
          contains('from the $edge of its face'),
          reason: 'moved $by px',
        );
      }
    });
  }

  // A ball lit at its top only a little off the page, its outermost pixel
  // row blending into the page where its curve covers it in part: its rim
  // still reaches its box's top, so initials in its middle (11 px under its
  // top, as Clay's avatars hold them) pass, and moved within 4 px of that
  // top they are named from it.
  testWidgets("a faint lit rim reaches its box's edge past its last, part-"
      'covered pixel', (tester) async {
    // In a tap target 12 px larger than the ball, as an avatar's button.
    expect(
      await _check(
        tester,
        ball(_Ball.dayTopFaint, target: 12, shift: const Offset(0, -2)),
      ),
      isEmpty,
    );
    final named = await _check(
      tester,
      ball(_Ball.dayTopFaint, target: 12, shift: const Offset(0, -10)),
    );
    expect(named, hasLength(1));
    expect(named.single, contains('from the top of its face'));
  });

  // Initials moved off a ball's middle, toward where its shaded rim curves
  // round: by its end, above or below its middle, they are named from that
  // side, read over the rim there too; over its foot, beside the curve, the
  // page past the curve is not their ink.
  testWidgets("a painted face's rim is read off its middle too", (
    tester,
  ) async {
    for (final shift in const [Offset(4, 7.5), Offset(4, -4.5)]) {
      final named = await _check(tester, ball(_Ball.nightEnd, shift: shift));
      expect(named, hasLength(1), reason: 'moved $shift');
      expect(
        named.single,
        contains('from the right side of its face'),
        reason: 'moved $shift',
      );
    }
    final foot = await _check(
      tester,
      ball(_Ball.nightFoot, shift: const Offset(4, 6)),
    );
    expect(foot, hasLength(1));
    expect(foot.single, contains('from the right side of its face'));
    expect(foot.single, isNot(contains('foot')));
  });

  // A row (a list tile) whose plate paints the page's colour, with an avatar
  // ball at its start, its rim shaded toward the page: the ball's edge is its
  // own box's, not the row's, whether the plate holds the ball or the ball is
  // drawn over the plate beside it.
  Widget row(_Ball painter, {Offset shift = Offset.zero, bool over = false}) {
    final ball = CustomPaint(
      painter: painter,
      child: SizedBox.square(
        dimension: painter.size,
        child: Center(
          child: Transform.translate(
            offset: shift,
            child: Text(
              'SO',
              style: _style.copyWith(
                fontSize: 10.64,
                height: 1,
                color: painter.ink,
              ),
            ),
          ),
        ),
      ),
    );
    final content = SizedBox(
      width: 300,
      height: 60,
      child: Row(children: [const SizedBox(width: 12), ball]),
    );
    return ColoredBox(
      color: painter.page,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RawButton(
          onPressed: () {},
          builder: (context, states, _) => over
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _Fill(painter.page)),
                    ),
                    content,
                  ],
                )
              : CustomPaint(painter: _Fill(painter.page), child: content),
        ),
      ),
    );
  }

  for (final over in const [false, true]) {
    testWidgets("a row's plate that draws nothing of its own: the ball "
        '${over ? 'drawn over it' : 'it holds'} is read to its own box', (
      tester,
    ) async {
      expect(await _check(tester, row(_Ball.dayStart, over: over)), isEmpty);
      expect(await _check(tester, row(_Ball.nightEnd, over: over)), isEmpty);
      final close = await _check(
        tester,
        row(_Ball.nightEnd, shift: const Offset(5, 0), over: over),
      );
      expect(close, hasLength(1));
      expect(close.single, contains('from the right side of its face'));
    });
  }

  testWidgets("a row's ball a list's foot cuts is read when it comes into "
      'view, not up to the cut', (tester) async {
    // Stint's task list by night: a row whose plate draws nothing of its
    // own, so its avatar ball is the face read from its pixels, scrolled
    // half past the list's foot, over a bar in the page's colour. What
    // shows of the ball ends at the foot, its initials' ink 0 to 3 px above
    // it (named), while the ball runs on past it. In view, initials near the
    // ball's own foot are named.
    // A row whose plate paints its avatar's ball itself: the box the ball is
    // painted in is the row's.
    Widget plateRow(double down) => RawButton(
      onPressed: () {},
      builder: (context, states, _) => CustomPaint(
        painter: const _PlateBall(Color(0xFF29243F), Color(0xFF7B6219)),
        child: SizedBox(
          width: 300,
          height: 60,
          child: Row(
            children: [
              const SizedBox(width: 12),
              SizedBox.square(
                dimension: 28,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, down),
                    child: Text(
                      'SO',
                      style: _style.copyWith(
                        fontSize: 10.64,
                        height: 1,
                        color: const Color(0xFFF3F0FF),
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
    Widget list(
      double top, {
      double offset = 0,
      _Ball painter = _Ball.nightEnd,
      double down = 0,
      bool plate = false,
    }) {
      final controller = ScrollController(initialScrollOffset: offset);
      addTearDown(controller.dispose);
      // The list, its page painted in it (what it draws, a repaint boundary
      // of its own, is read), over a bar in the page's colour, as a
      // navigation bar under it by night.
      return ColoredBox(
        color: painter.page,
        child: SizedBox(
          width: 332,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  key: ValueKey('$top $offset $down $plate'),
                  controller: controller,
                  child: ColoredBox(
                    color: painter.page,
                    child: Column(
                      children: [
                        SizedBox(height: top),
                        if (plate)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: plateRow(down),
                          )
                        else
                          row(painter, shift: Offset(0, down)),
                        const SizedBox(height: 300),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }

    for (final top in const <double>[147, 148, 149, 150]) {
      expect(
        await _check(tester, list(top)),
        isEmpty,
        reason: 'the ball cut by the foot, ${top - 146} px past it',
      );
    }
    // Scrolled on, the ball cut by the list's top, its initials' ink 1 to 3
    // px below it.
    for (final offset in const <double>[187, 188, 189]) {
      expect(
        await _check(tester, list(148, offset: offset)),
        isEmpty,
        reason: 'the ball cut by the top, scrolled $offset px',
      );
    }
    expect(await _check(tester, list(148, offset: 100)), isEmpty);
    // The row cut by the foot below its ball, whole above the cut: the ball
    // is read, its initials near its foot named.
    final above = await _check(
      tester,
      list(136, painter: _Ball.nightFoot, down: 9),
    );
    expect(above, hasLength(1), reason: 'the row cut below its whole ball');
    expect(above.single, contains('from the foot of its face'));
    // A ball the row's plate paints itself: cut, it is not read; whole above
    // the cut, with the plate running on past it, it is.
    expect(await _check(tester, list(148, plate: true)), isEmpty);
    final painted = await _check(tester, list(136, plate: true, down: 9));
    expect(painted, hasLength(1), reason: "the plate's own ball, whole");
    expect(painted.single, contains('from the foot of its face'));
    final close = await _check(
      tester,
      list(148, offset: 100, painter: _Ball.nightFoot, down: 9),
    );
    expect(close, hasLength(1), reason: 'in view, its initials near its foot');
    expect(close.single, contains('from the foot of its face'));
  });

  // A face its painter draws only a little off what is round it (a pale
  // select on its pale card by day, its rim shaded back to the card's colour
  // at its edge, and on its card by night; a dark face on its card by
  // night, outlined in a tone near it), with a mark of
  // stronger ink at its start (an avatar's ball, a key) and its words,
  // slanting past their line's box, at its end: the face is the box it
  // draws, not the stronger ink drawn on it. Words 16 px in from its end
  // pass; 1 px in, they are named at that end alone.
  for (final (name, page, plate, outline, ink) in const [
    (
      'pale by day, its rim shaded back to the page',
      Color(0xFFE7E4F4),
      Color(0xFFFBFAFF),
      Color(0xFFE8E5F5),
      Color(0xFF2A2440),
    ),
    (
      'pale by night',
      Color(0xFF1E1A31),
      Color(0xFF29243F),
      null,
      Color(0xFFF3F0FF),
    ),
    (
      'outlined by night',
      Color(0xFF1C1F24),
      Color(0xFF181A1F),
      Color(0xFF3B3D41),
      Color(0xFFECEEF2),
    ),
  ]) {
    testWidgets('a face drawn only a little off what is round it, $name: its '
        "edges are its box's, not the stronger ink drawn on it", (
      tester,
    ) async {
      Widget select(double end) => ColoredBox(
        color: page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _button(
            (label) => CustomPaint(
              painter: _Plate(plate, outline: outline),
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 14, end, 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: CustomPaint(painter: _Fill(ink)),
                    ),
                    const SizedBox(width: 12),
                    label,
                  ],
                ),
              ),
            ),
            label: 'Apply later',
            style: _style.copyWith(color: ink, fontStyle: FontStyle.italic),
          ),
        ),
      );
      expect(await _check(tester, select(16)), isEmpty);
      final close = await _check(tester, select(1));
      expect(close, hasLength(1));
      expect(close.single, contains('from the right side of its face'));
      expect(close.single, isNot(contains('foot')));
    });
  }

  testWidgets("a row that draws nothing of its own: its words' marks past "
      'their lines are theirs, not a face round its key', (tester) async {
    // A task row on its card by night whose painter draws only
    // the card's colour, a key at its end, and two lines of words before it
    // whose letters reach past their lines' boxes (a script's marks: here
    // Vietnamese's stacked accents): the key is the only face it draws, and
    // the words are not on it.
    const card = Color(0xFF181A1F);
    final tight = _style.copyWith(color: const Color(0xFFECEEF2));
    final problems = await _check(
      tester,
      ColoredBox(
        color: card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _button(
            (label) => CustomPaint(
              painter: const _Fill(card),
              child: SizedBox(
                width: 320,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            label,
                            Text(
                              'Chuỗi xưởng, Ấp Bảy',
                              style: tight.copyWith(
                                color: const Color(0xFFA3A9B3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      const SizedBox.square(
                        dimension: 22,
                        child: CustomPaint(painter: _Fill(Color(0xFF6A6E75))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            label: 'Ấn phẩm: xác nhận xưởng',
            style: tight,
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("a decoration of the look's own that draws nothing is not a "
      "face: a link's clear press surface", (tester) async {
    // A breadcrumb's link: its press wash and focus ring in one
    // decoration of the look's own, which draws nothing at rest, hugging its
    // words between the separators. Drawing a wash, the same decoration is a
    // face, and the words are named on it.
    Widget crumbs(Color? wash) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Home /', style: _style.copyWith(color: _line)),
        const SizedBox(width: 6),
        _button(
          (label) => DecoratedBox(decoration: _Wash(wash), child: label),
          label: 'Files',
        ),
        const SizedBox(width: 6),
        Text('/ Q3', style: _style.copyWith(color: _line)),
      ],
    );
    expect(await _check(tester, crumbs(null)), isEmpty);
    final washed = await _check(tester, crumbs(_fill));
    expect(washed, hasLength(1));
    expect(washed.single, contains('"Files"'));
  });

  testWidgets('a face part of the screen paints over right across is not '
      'read: an avatar half under a bar', (tester) async {
    // A list's 24 px avatar, its ring its own painter's, scrolled down under
    // a bar painted after the list (a tab bar): its foot is the
    // bar's edge, not its own, and the screen does not show it whole. Clear
    // of the bar, initials near its foot are named, and so they are under a
    // box painted after it that covers it nowhere right across (a dot on its
    // corner) or covers it whole (a sheen over the list).
    Widget list(
      double under, {
      double shift = 0,
      Widget? over,
      Color bar = const Color(0xFFE9E4DA),
    }) => ColoredBox(
      color: const Color(0xFFF2EEE6),
      child: SizedBox(
        width: 320,
        height: 120,
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 72 + under,
              child: _button(
                (label) => CustomPaint(
                  painter: const _Ring(),
                  child: SizedBox.square(
                    dimension: 24,
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, shift),
                        child: label,
                      ),
                    ),
                  ),
                ),
                label: 'SO',
                style: _style.copyWith(fontSize: 9, height: 1),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24,
              child: ColoredBox(color: bar),
            ),
            ?over,
          ],
        ),
      ),
    );
    // A bar a shade off the page, or in the page's own colour (what shows
    // of the avatar then ends at the bar's edge).
    for (final bar in const [Color(0xFFE9E4DA), Color(0xFFF2EEE6)]) {
      for (var under = 6.0; under <= 9; under += 0.5) {
        expect(
          await _check(tester, list(under, bar: bar)),
          isEmpty,
          reason: 'under a bar of $bar by $under px',
        );
      }
    }
    final close = await _check(tester, list(-8, shift: 6));
    expect(close, hasLength(1));
    expect(close.single, contains('from the foot of its face'));
    const dot = Positioned(
      left: 34,
      top: 58,
      width: 10,
      height: 10,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFD64545),
          shape: BoxShape.circle,
        ),
      ),
    );
    const sheen = Positioned.fill(child: CustomPaint(painter: _Sheen()));
    for (final (name, over) in [('a dot', dot), ('a sheen', sheen)]) {
      final shown = await _check(tester, list(-8, shift: 6, over: over));
      expect(shown, hasLength(1), reason: 'under $name');
      expect(shown.single, contains('from the foot of its face'));
    }
  });

  testWidgets("a soft shadow inside a painted face's box is not the face", (
    tester,
  ) async {
    final shadowed = await _check(
      tester,
      ball(_Ball.shadowed, shift: const Offset(5, 0)),
    );
    expect(shadowed, hasLength(1));
    expect(shadowed.single, contains('from the right side of its face'));
  });

  testWidgets("an outlined face its painter draws round: its outline's curve "
      'is not ink', (tester) async {
    // A pill its own painter outlines on a page of its fill's colour, its
    // words' line nearly as high as it: the outline round its ends, where
    // they reach in under the line, is the face's.
    Widget pill(double lift) => ColoredBox(
      color: _page,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _button(
          (label) => CustomPaint(
            painter: const _OutlinedPill(),
            child: SizedBox(
              width: 104,
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, -lift),
                    child: label,
                  ),
                ),
              ),
            ),
          ),
          label: 'Recent',
          style: _style.copyWith(fontSize: 26, height: 40 / 26),
        ),
      ),
    );
    expect(await _check(tester, pill(0)), isEmpty);
  });

  testWidgets("words across a face's side are not held in by it", (
    tester,
  ) async {
    // A range's band starting under a day's circle: the day's number,
    // centred on the circle at the band's start, sits across the band's
    // side; the band holds nothing in.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: RawButton(
            onPressed: () {},
            builder: (context, states, _) => SizedBox(
              width: 60,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: ColoredBox(color: _fill)),
                  Positioned(
                    left: -17,
                    top: 1,
                    width: 38,
                    height: 38,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF6750A4),
                      ),
                      child: Center(
                        child: Text(
                          '16',
                          style: _style.copyWith(
                            fontSize: 22,
                            height: 40 / 22,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(problems, isEmpty);
  });

  testWidgets("an outlined round face's sides show where its outline is", (
    tester,
  ) async {
    // A pill outlined on a page of its own colour, no fill: its round ends
    // show at their middle, so words drawn close to one are named.
    final problems = await _check(
      tester,
      ColoredBox(
        color: _page,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _button(
            (label) => DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _line, width: 1.5),
                borderRadius: BorderRadius.circular(22),
              ),
              child: SizedBox(
                width: 120,
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: label,
                  ),
                ),
              ),
            ),
            label: 'HIH',
            style: _style.copyWith(fontSize: 18, height: 1),
          ),
        ),
      ),
    );
    expect(problems, hasLength(1));
    expect(problems.single, contains('from the right side of its face'));
  });

  testWidgets("a painted outline inside a clipped round face is the face's", (
    tester,
  ) async {
    // A toggle clipped to a pill, its outline painted inside the clip, its
    // words' line nearly as high as it, on a page or on nothing: the
    // outline's curve over the words' columns is not ink; a pill too low
    // for its words, cutting them at its foot, is named.
    Widget pill({required bool page, double height = 34}) {
      final Widget body = Padding(
        padding: const EdgeInsets.all(16),
        child: _button(
          (label) => ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: CustomPaint(
              painter: const _OutlinedPill(),
              child: SizedBox(
                width: 52,
                height: height,
                child: Center(child: label),
              ),
            ),
          ),
          label: 'PM',
          style: _style.copyWith(fontSize: 22, height: 31 / 22),
        ),
      );
      return page ? ColoredBox(color: _page, child: body) : body;
    }

    expect(await _check(tester, pill(page: true)), isEmpty);
    expect(await _check(tester, pill(page: false)), isEmpty);
    final low = await _check(tester, pill(page: true, height: 22));
    expect(low, hasLength(1));
    expect(low.single, contains('from the foot of its face'));
  });

  testWidgets('a face filling all that is read does not stop the check', (
    tester,
  ) async {
    // A menu row's face as large as the boundary read, which stands a
    // fraction of a pixel off the screen's: its edges, a hair past the
    // image's as read back, are read inside it.
    for (final size in const [
      Size(342 + 1 / 3, 44 + 1 / 3),
      Size(342 + 2 / 3, 44 + 2 / 3),
      Size(341 + 1 / 3, 43 + 1 / 3),
    ]) {
      final problems = await _check(
        tester,
        _button(
          (label) => CustomPaint(
            painter: const _OutlinedPill(),
            child: SizedBox.fromSize(
              size: size,
              child: Center(child: label),
            ),
          ),
          label: 'Habits',
        ),
      );
      expect(problems, isEmpty, reason: '$size');
    }
  });

  testWidgets("words in the test's own font over most of their face ask for "
      "the look's fonts", (tester) async {
    // Solid boxes over most of the face: they are not its colour, nor are
    // they where a short line centred over a longer one leaves the face
    // beside it. Words wrapped, or narrower than their box, are read on their
    // first line.
    for (final (words, width, pad) in const [
      ('HIHIH', null, 2.0),
      ('HIH HIH', 60.0, 2.0),
      ('HIH', 90.0, 2.0),
      ('HIH HIHIH', 70.0, 0.0),
    ]) {
      final problems = await _check(
        tester,
        RawButton(
          onPressed: () {},
          builder: (context, states, _) => DecoratedBox(
            decoration: const BoxDecoration(color: _fill),
            child: Padding(
              padding: EdgeInsets.all(pad),
              child: SizedBox(
                width: width,
                child: Text(
                  words,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _ink),
                ),
              ),
            ),
          ),
        ),
      );
      expect(problems, hasLength(1), reason: words);
      expect(problems.single, contains("the test's own font"), reason: words);
    }
  });
}

// A pill outlined 1.5 px thick inside its edge, not filled.
class _OutlinedPill extends CustomPainter {
  const _OutlinedPill();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    ).deflate(0.75),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _line,
  );

  @override
  bool shouldRepaint(_OutlinedPill oldDelegate) => false;
}

// A ball in [face] on [page], painted by its own painter, shaded toward
// [shade] along [toward] over its last [reach] (lit, at the start); or, with
// [shadow], a ball [size] less 12 wide in the middle of its box, casting a
// soft shadow there that fades into the page before the box's edge.
class _Ball extends CustomPainter {
  const _Ball({
    required this.page,
    required this.face,
    required this.shade,
    required this.ink,
    this.toward = Alignment.centerRight,
    this.reach = 0.3,
    this.shadow = false,
    this.size = 28,
    this.inset = 0,
  });

  // Clay's avatar by night: shaded at its end, or at its foot.
  static const nightEnd = _Ball(
    page: Color(0xFF29243F),
    face: Color(0xFF7B6219),
    shade: Color(0xFF544313),
    ink: Color(0xFFF3F0FF),
  );
  static const nightFoot = _Ball(
    page: Color(0xFF29243F),
    face: Color(0xFF7B6219),
    shade: Color(0xFF544313),
    ink: Color(0xFFF3F0FF),
    toward: Alignment.bottomCenter,
  );

  // By day: lit at its start.
  static const dayStart = _Ball(
    page: Color(0xFFFBFAFF),
    face: Color(0xFFFFEAAA),
    shade: Color(0xFFFFF5D6),
    ink: Color(0xFF2A2440),
    toward: Alignment.centerLeft,
    reach: 0.25,
  );

  static const dayTop = _Ball(
    page: Color(0xFFFBFAFF),
    face: Color(0xFFFFEAAA),
    shade: Color(0xFFFFF5D6),
    ink: Color(0xFF2A2440),
    toward: Alignment.topCenter,
    reach: 0.25,
  );

  // Clay's lilac avatar by day on its slab: a deeper lilac, lit toward its
  // top to a tone only a little off the page (25 levels at most), so the
  // ball's outermost row of pixels, part covered by its curve, blends into
  // the page while the lit band under it stands off.
  static const dayTopFaint = _Ball(
    page: Color(0xFFF6F3FF),
    face: Color(0xFFB9A6EE),
    shade: Color(0xFFE4DAFF),
    ink: Color(0xFF2A2440),
    toward: Alignment.topCenter,
    size: 36,
    inset: 0.17,
  );

  // A flat ball whose soft shadow, darker than the page, falls to its end
  // inside its box and fades into the page before the box's edge.
  static const shadowed = _Ball(
    page: Color(0xFF29243F),
    face: Color(0xFF7B6219),
    shade: Color(0xFF000000),
    ink: Color(0xFFF3F0FF),
    shadow: true,
    size: 40,
  );

  final Color page;
  final Color face;
  final Color shade;
  final Color ink;
  final Alignment toward;
  final double reach;
  final bool shadow;
  final double size;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    if (shadow) {
      final ball = box.deflate(6);
      canvas
        ..drawOval(
          ball.translate(2, 0),
          Paint()
            ..color = shade.withValues(alpha: 0.8)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1),
        )
        ..drawOval(ball, Paint()..color = face);
      return;
    }
    final ball = box.deflate(inset);
    canvas.drawOval(
      ball,
      Paint()
        ..shader = LinearGradient(
          begin: -toward,
          end: toward,
          colors: [face, face, shade],
          stops: [0, 1 - reach, 1],
        ).createShader(ball),
    );
  }

  @override
  bool shouldRepaint(_Ball oldDelegate) => false;

  @override
  String toString() => switch (toward) {
    _ when inset > 0 => 'faint at its top by day, its edge part-covered',
    Alignment.centerLeft => 'lit at its start by day',
    Alignment.topCenter => 'lit at its top by day',
    Alignment.bottomCenter => 'shaded at its foot by night',
    _ => 'shaded at its end by night',
  };
}

// A pill in one colour, its ends round.
class _Pill extends CustomPainter {
  const _Pill();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    ),
    Paint()..color = const Color(0xFFEAE7F5),
  );

  @override
  bool shouldRepaint(_Pill oldDelegate) => false;
}

// A band through the middle of what it is under, 5 px high.
class _Band extends CustomPainter {
  const _Band();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(0, size.height / 2 - 2.5, size.width, 5),
    Paint()..color = _line,
  );

  @override
  bool shouldRepaint(_Band oldDelegate) => false;
}

// A face painted in one colour, edge to edge.
class _Fill extends CustomPainter {
  const _Fill(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawRect(Offset.zero & size, Paint()..color = colour);

  @override
  bool shouldRepaint(_Fill oldDelegate) => oldDelegate.colour != colour;
}

// A row that paints what sits in it, no face of its own: a blob as high as
// the row at its start and a dot at its end.
class _RowMarks extends CustomPainter {
  const _RowMarks();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 2;
    canvas
      ..drawCircle(Offset(r, r), r, Paint()..color = const Color(0xFF9BE3B5))
      ..drawCircle(Offset(size.width - 4, r), 3, Paint()..color = _line);
  }

  @override
  bool shouldRepaint(_RowMarks oldDelegate) => false;
}

// A rounded face with an outline [stroke] thick inside its edge, filled with
// [fill] when given.
class _Outlined extends CustomPainter {
  const _Outlined({required this.stroke, this.fill});

  final double stroke;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final face = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(8),
    );
    if (fill case final fill?) canvas.drawRRect(face, Paint()..color = fill);
    canvas.drawRRect(
      face.deflate(stroke / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = _line,
    );
  }

  @override
  bool shouldRepaint(_Outlined oldDelegate) =>
      oldDelegate.stroke != stroke || oldDelegate.fill != fill;
}

// A key's face lit from above: a gradient down it and a bevel along its top.
class _KeyFace extends CustomPainter {
  const _KeyFace();

  @override
  void paint(Canvas canvas, Size size) {
    final face = Offset.zero & size;
    canvas.drawRect(
      face,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3D42), Color(0xFF2A2C30)],
        ).createShader(face),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 3),
      Paint()..color = const Color(0xFF8C9099),
    );
  }

  @override
  bool shouldRepaint(_KeyFace oldDelegate) => false;
}

// A rounded face in [fill], outlined 2 px wide inside its edge in [outline]
// when given.
// A row's plate that paints its avatar's ball itself: [page] over its box,
// a ball of [face] 28 across, 12 in from its start, centred down it.
class _PlateBall extends CustomPainter {
  const _PlateBall(this.page, this.face);

  final Color page;
  final Color face;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = page);
    canvas.drawCircle(Offset(26, size.height / 2), 14, Paint()..color = face);
  }

  @override
  bool shouldRepaint(_PlateBall oldDelegate) =>
      oldDelegate.page != page || oldDelegate.face != face;
}

class _Plate extends CustomPainter {
  const _Plate(this.fill, {this.outline});

  final Color fill;
  final Color? outline;

  @override
  void paint(Canvas canvas, Size size) {
    final face = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(12),
    );
    canvas.drawRRect(face, Paint()..color = fill);
    if (outline case final o?) {
      canvas.drawRRect(
        face.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = o,
      );
    }
  }

  @override
  bool shouldRepaint(_Plate oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.outline != outline;
}

// An avatar's ring: a pale disc outlined in [_line].
class _Ring extends CustomPainter {
  const _Ring();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    canvas
      ..drawCircle(
        centre,
        size.width / 2,
        Paint()..color = const Color(0xFFE8E6F0),
      )
      ..drawCircle(
        centre,
        size.width / 2 - 0.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = _line,
      );
  }

  @override
  bool shouldRepaint(_Ring oldDelegate) => false;
}

// A sheen painted over a whole list: a faint light along its top edge.
class _Sheen extends CustomPainter {
  const _Sheen();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Rect.fromLTWH(0, 0, size.width, 1),
    Paint()..color = const Color(0x33FFFFFF),
  );

  @override
  bool shouldRepaint(_Sheen oldDelegate) => false;
}

// A decoration of a look's own: a [wash] over its box, nothing without one.
class _Wash extends Decoration {
  const _Wash(this.wash);

  final Color? wash;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _WashPainter(wash);
}

class _WashPainter extends BoxPainter {
  _WashPainter(this.wash);

  final Color? wash;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (wash case final w? when size != null) {
      canvas.drawRect(offset & size, Paint()..color = w);
    }
  }
}
