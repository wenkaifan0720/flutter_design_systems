// DesignFieldPartsCheck: a date field's segments keep room round their text,
// and a date field's button and a stepper's buttons stand as tall as the
// field beside them.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// The Flutter SDK's Roboto, so words are drawn in a typeface.
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
  final font = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  await (FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
      .load();
}

const _ink = Color(0xFF101010);
const _ground = Color(0xFFF4F4F4);
const _text = TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _ink);

// A box with a 2 px border round [child], [height] tall.
Widget _boxed(Widget child, {double? height, double? width, double pad = 6}) =>
    Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: pad),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: _ink, width: 2),
      ),
      child: child,
    );

// A button [height] tall with a face, or a bare glyph.
Widget _button(String label, {double height = 48, bool face = true}) =>
    Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {},
        child: face
            ? _boxed(const Text('+', style: _text), height: height, width: 48)
            : const SizedBox(
                width: 24,
                height: 24,
                child: Center(child: Text('+', style: _text)),
              ),
      ),
    );

// A well painted round its box: a [ring] px band of ink inside the edge,
// the fill the ground's colour.
class _Well extends CustomPainter {
  const _Well(this.ring);

  final double ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r.deflate(ring / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring
        ..color = const Color(0xFF7A7A7A),
    );
  }

  @override
  bool shouldRepaint(_Well old) => old.ring != ring;
}

Widget _date({
  double pad = 6,
  double segmentHeight = 48,
  double? segmentWidth,
  bool segmentFaces = true,
  DesignDateFieldFrameBuilder? frame,
}) => DesignDateField(
  value: DateTime(2026, 11, 20),
  onChanged: (_) {},
  semanticLabel: 'Due date',
  segmentBuilder: (context, s) {
    final text = Text(s.text, style: _text);
    return segmentFaces
        ? _boxed(text, height: segmentHeight, width: segmentWidth, pad: pad)
        : SizedBox(
            height: segmentHeight,
            child: Center(child: text),
          );
  },
  literalBuilder: (context, l) => Text(l, style: _text),
  frameBuilder: frame,
);

Future<List<String>> _check(
  WidgetTester tester,
  Widget body, {
  double textScale = 1,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    harness(
      RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: _ground,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(padding: const EdgeInsets.all(24), child: body),
          ),
        ),
      ),
      textScale: textScale,
    ),
  );
  final report = await const DesignFieldPartsCheck(look: 'Fixture')
      .check(key.currentContext!, runAsync: tester.runAsync);
  return report.problems;
}

Widget _row(List<Widget> children) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    for (final (i, c) in children.indexed) ...[
      if (i > 0) const SizedBox(width: 8),
      c,
    ],
  ],
);

DesignNumberField _stepper({
  double buttonHeight = 48,
  double fieldHeight = 48,
  bool stacked = false,
}) => DesignNumberField(
  value: 45,
  onChanged: (_) {},
  semanticLabel: 'Estimate',
  fieldBuilder: (context, f) => _boxed(
    EditableText(
      controller: f.controller,
      focusNode: f.focusNode,
      style: _text,
      cursorColor: _ink,
      backgroundCursorColor: _ground,
    ),
    height: fieldHeight,
    width: 72,
  ),
  buttonBuilder: (context, b) => _boxed(
    Text(b.isIncrement ? '+' : '-', style: _text),
    height: buttonHeight,
    width: 48,
  ),
  layoutBuilder: stacked
      ? (context, field, down, up) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            field,
            const SizedBox(width: 8),
            Column(mainAxisSize: MainAxisSize.min, children: [up, down]),
          ],
        )
      : (context, field, down, up) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            down,
            const SizedBox(width: 8),
            field,
            const SizedBox(width: 8),
            up,
          ],
        ),
);

void main() {
  setUpAll(_loadRoboto);

  group('room in a segment', () {
    testWidgets('digits 2 px from their box are cramped; 6 px is room', (
      tester,
    ) async {
      final cramped = await _check(
        tester,
        _row([_date(pad: 2), _button('Choose date')]),
      );
      expect(cramped, hasLength(3));
      expect(
        cramped.first,
        allOf(
          contains('a date field "Due date"'),
          contains('segment "11"'),
          contains('2 px from its frame on the left and 2 px on the right'),
          contains('keeps 4 px on both sides'),
        ),
      );
      expect(
        await _check(tester, _row([_date(), _button('Choose date')])),
        isEmpty,
      );
    });

    testWidgets('a box sized for 100% text is cramped at 200%', (tester) async {
      Widget field() =>
          _row([_date(segmentWidth: 64, pad: 0), _button('Choose date')]);
      expect(await _check(tester, field()), isEmpty);
      final doubled = await _check(tester, field(), textScale: 2);
      expect(doubled, isNotEmpty);
      expect(doubled.join('\n'), contains('segment "2026"'));
    });

    testWidgets('segments with no box of their own are read against the '
        "field's frame", (tester) async {
      Widget framed(double pad) => _date(
        segmentFaces: false,
        frame: (context, states, segments) => _boxed(segments, pad: pad),
      );
      final tight = await _check(tester, _row([framed(1)]));
      expect(tight, isNotEmpty);
      expect(tight.first, contains("from its field's frame"));
      expect(await _check(tester, _row([framed(8)])), isEmpty);
    });
  });

  testWidgets("a painted ring is read to its inner edge: 5 px in, a 3 px "
      'ring leaves 2', (tester) async {
    Widget well(double ring) => DesignDateField(
      value: DateTime(2026, 11, 20),
      onChanged: (_) {},
      semanticLabel: 'Due date',
      segmentBuilder: (context, s) => CustomPaint(
        painter: _Well(ring),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Center(child: Text(s.text, style: _text)),
          ),
        ),
      ),
      literalBuilder: (context, l) => Text(l, style: _text),
    );
    final ringed = await _check(tester, _row([well(3)]));
    expect(ringed, hasLength(3));
    expect(ringed.first, contains('2 px from its frame on the left'));
    expect(await _check(tester, _row([well(1)])), isEmpty);
  });

  group('one row, one height', () {
    testWidgets('segments 34 px tall beside a 48 px button differ', (
      tester,
    ) async {
      final problems = await _check(
        tester,
        _row([_date(segmentHeight: 34), _button('Choose date')]),
      );
      expect(problems, [
        allOf(
          contains('a date field "Due date": its segments are 34 px tall'),
          contains('button "Choose date", 48 px tall'),
        ),
      ]);
    });

    testWidgets("a frame beside its button is held to the button's height; "
        'a button inside the frame is its own part', (tester) async {
      Widget framed({required bool inside, double height = 40}) => _date(
        segmentFaces: false,
        segmentHeight: 24,
        frame: (context, states, segments) => _boxed(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              segments,
              if (inside) _button('Choose date', height: 32),
            ],
          ),
          height: height,
          pad: 8,
        ),
      );
      final beside = await _check(
        tester,
        _row([framed(inside: false), _button('Choose date')]),
      );
      expect(beside, [contains('its frame is 40 px tall beside')]);
      expect(
        await _check(
          tester,
          _row([framed(inside: false, height: 48), _button('Choose date')]),
        ),
        isEmpty,
      );
      expect(await _check(tester, _row([framed(inside: true)])), isEmpty);
    });

    testWidgets('a bare glyph button has no height to compare', (tester) async {
      expect(
        await _check(
          tester,
          _row([_date(segmentHeight: 34), _button('Choose date', face: false)]),
        ),
        isEmpty,
      );
    });

    testWidgets("a number field's buttons stand as tall as its field", (
      tester,
    ) async {
      final short = await _check(tester, _stepper(buttonHeight: 40));
      expect(short, [
        allOf(
          contains('a stepper "Estimate": its buttons are 40 px tall'),
          contains('beside its field, 48 px tall'),
        ),
      ]);
      expect(await _check(tester, _stepper()), isEmpty);
      expect(
        await _check(tester, _stepper(stacked: true, buttonHeight: 24)),
        isEmpty,
      );
      expect(await _check(tester, _stepper(stacked: true, buttonHeight: 20)), [
        contains('stacked buttons are 40 px tall together'),
      ]);
    });

    testWidgets('a look of its own: two buttons round a value that steps', (
      tester,
    ) async {
      Widget value() => Semantics(
        label: 'Seats',
        value: '2',
        increasedValue: '3',
        decreasedValue: '1',
        onIncrease: () {},
        onDecrease: () {},
        child: _boxed(const Text('2', style: _text), height: 48, width: 64),
      );
      expect(
        await _check(
          tester,
          _row([
            _button('Fewer', height: 36),
            value(),
            _button('More', height: 36),
          ]),
        ),
        [contains('a stepper "Seats": its buttons are 36 px tall')],
      );
      expect(
        await _check(
          tester,
          _row([_button('Fewer'), value(), _button('More')]),
        ),
        isEmpty,
      );
    });

    testWidgets('a value that only says its value, between two buttons', (
      tester,
    ) async {
      final problems = await _check(
        tester,
        _row([
          _button('Fewer'),
          Semantics(
            label: 'Guests',
            value: '4',
            child: _boxed(const Text('4', style: _text), height: 40, width: 64),
          ),
          _button('More'),
        ]),
      );
      expect(problems, [
        allOf(
          contains('a stepper "Guests": its buttons are 48 px tall'),
          contains('beside its field, 40 px tall'),
        ),
      ]);
    });

    testWidgets('one node that steps, its buttons inside it for a pointer', (
      tester,
    ) async {
      // A screen reader steps the node; the buttons are a pointer's.
      Widget stepper(double field) => Semantics(
        label: 'Rooms',
        value: '3',
        increasedValue: '4',
        decreasedValue: '2',
        onIncrease: () {},
        onDecrease: () {},
        child: _row([
          ExcludeSemantics(child: _button('Fewer')),
          _boxed(const Text('3', style: _text), height: field, width: 64),
          ExcludeSemantics(child: _button('More')),
        ]),
      );
      expect(await _check(tester, stepper(40)), [
        allOf(
          contains('a stepper "Rooms": its buttons are 48 px tall'),
          contains('beside its field, 40 px tall'),
        ),
      ]);
      expect(await _check(tester, stepper(48)), isEmpty);
    });

    testWidgets('a pager is no value field: its buttons round its position '
        'are not held', (tester) async {
      Widget pager({required bool live}) => _row([
        _button('Previous', height: 44),
        Semantics(
          label: 'Page',
          value: '3 of 10',
          liveRegion: live,
          child: _boxed(const Text('3 of 10', style: _text), height: 32),
        ),
        _button('Next', height: 44),
      ]);
      expect(await _check(tester, pager(live: true)), isEmpty);
      expect(await _check(tester, pager(live: false)), [
        contains('its buttons are 44 px tall beside its field, 32 px tall'),
      ]);
    });

    testWidgets("a slider's node with words between its buttons is a stepper; "
        'with a track between them it is not', (tester) async {
      Widget slider(Widget between) => Semantics(
        slider: true,
        label: 'Rooms',
        value: '3',
        increasedValue: '4',
        decreasedValue: '2',
        onIncrease: () {},
        onDecrease: () {},
        child: _row([
          ExcludeSemantics(child: _button('Fewer')),
          between,
          ExcludeSemantics(child: _button('More')),
        ]),
      );
      expect(
        await _check(
          tester,
          slider(_boxed(const Text('3', style: _text), height: 40, width: 64)),
        ),
        [contains('a stepper "Rooms": its buttons are 48 px tall')],
      );
      expect(
        await _check(
          tester,
          slider(
            const SizedBox(
              width: 120,
              height: 4,
              child: ColoredBox(color: _ink),
            ),
          ),
        ),
        isEmpty,
      );
    });
  });
}
