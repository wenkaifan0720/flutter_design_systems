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
