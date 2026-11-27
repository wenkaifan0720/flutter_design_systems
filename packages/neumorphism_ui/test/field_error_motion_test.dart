// A field turning wrong, and right again, eases: its failure line fades in as the room under the field opens (what
// stands below slides, it never jumps), and the error mark at its end fades in as the entry gives it room. A date
// field's calendar crosses to the mark, and a label lights in the pigment's ink as its field takes the focus, easing
// across. Under Reduce Motion each cuts.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/src/neumorphism/internal/error_mark.dart';

import 'support.dart';

const _below = ValueKey('below');
const _message = 'Enter the title';

Widget _stage(Widget field) => neumorphicApp(
  Align(
    alignment: Alignment.topCenter,
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          field,
          const SizedBox(key: _below, height: 10),
        ],
      ),
    ),
  ),
);

// How much of [f] shows: the fades over it multiplied.
double _shown(WidgetTester t, Finder f) {
  var o = 1.0;
  for (final e
      in find
          .ancestor(of: f, matching: find.byType(FadeTransition))
          .evaluate()) {
    o *= (e.widget as FadeTransition).opacity.value;
  }
  for (final e
      in find.ancestor(of: f, matching: find.byType(Opacity)).evaluate()) {
    o *= (e.widget as Opacity).opacity;
  }
  return o;
}

Color _ink(WidgetTester t, String words) =>
    (t.renderObject<RenderParagraph>(find.text(words)).text as TextSpan)
        .style!
        .color!;

double _belowTop(WidgetTester t) => t.getTopLeft(find.byKey(_below)).dy;

// The mark at the field's end (the failure line leads with one of its own).
final _mark = find.descendant(
  of: find.byType(NeumorphicFieldBox),
  matching: find.byType(NeumorphicErrorMark),
);

bool _between(double v, double a, double b) =>
    v > (a < b ? a : b) + 0.5 && v < (a < b ? b : a) - 0.5;

Future<void> _midway(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(loadNeumorphicFonts);

  testWidgets('a text field turning wrong eases its line, room and mark', (
    t,
  ) async {
    await t.pumpWidget(_stage(const NeumorphicTextField(labelText: 'Title')));
    await t.pumpAndSettle();
    final top0 = _belowTop(t);
    await t.pumpWidget(
      _stage(
        const NeumorphicTextField(labelText: 'Title', errorText: _message),
      ),
    );
    await _midway(t);
    final topMid = _belowTop(t);
    final lineMid = _shown(t, find.text(_message));
    final markMid = _shown(t, _mark);
    await t.pumpAndSettle();
    final top1 = _belowTop(t);
    expect(_shown(t, find.text(_message)), 1);
    expect(_shown(t, _mark), 1);
    expect(top1, greaterThan(top0 + 8));
    expect(
      _between(topMid, top0, top1),
      isTrue,
      reason: 'below at $topMid, from $top0 to $top1',
    );
    expect(lineMid, inExclusiveRange(0, 1));
    expect(markMid, inExclusiveRange(0, 1));
  });

  testWidgets('a text field turning right again eases its line and mark out', (
    t,
  ) async {
    await t.pumpWidget(
      _stage(
        const NeumorphicTextField(labelText: 'Title', errorText: _message),
      ),
    );
    await t.pumpAndSettle();
    final top0 = _belowTop(t);
    await t.pumpWidget(_stage(const NeumorphicTextField(labelText: 'Title')));
    await _midway(t);
    final topMid = _belowTop(t);
    expect(_shown(t, find.text(_message)), inExclusiveRange(0, 1));
    expect(_shown(t, _mark), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(find.text(_message), findsNothing);
    expect(_mark, findsNothing);
    expect(_between(topMid, top0, _belowTop(t)), isTrue);
  });

  testWidgets('a help line and its failure cross', (t) async {
    const help = 'As on the cover';
    await t.pumpWidget(
      _stage(const NeumorphicTextField(labelText: 'Title', helperText: help)),
    );
    await t.pumpAndSettle();
    await t.pumpWidget(
      _stage(
        const NeumorphicTextField(
          labelText: 'Title',
          helperText: help,
          errorText: _message,
        ),
      ),
    );
    await _midway(t);
    expect(_shown(t, find.text(help)), inExclusiveRange(0, 1));
    expect(_shown(t, find.text(_message)), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(find.text(help), findsNothing);
  });

  testWidgets("a date field's calendar crosses to the mark", (t) async {
    Widget date(String? error) => NeumorphicDateField(
      labelText: 'Started',
      value: null,
      errorText: error,
      onChanged: (_) {},
    );
    await t.pumpWidget(_stage(date(null)));
    await t.pumpAndSettle();
    final calendar = find.byWidgetPredicate(
      (w) => w is Icon && w.icon == NeumorphicGlyphs.calendarDays,
    );
    expect(calendar, findsOneWidget);
    await t.pumpWidget(_stage(date('Pick a day')));
    await _midway(t);
    expect(_shown(t, calendar), inExclusiveRange(0, 1));
    expect(_shown(t, find.text('Pick a day')), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(calendar, findsNothing);
  });

  testWidgets('a label lights as its field takes the focus, easing across', (
    t,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      _stage(NeumorphicTextField(labelText: 'Title', focusNode: focus)),
    );
    await t.pumpAndSettle();
    final rest = _ink(t, 'Title');
    focus.requestFocus();
    // The focus lands on the next frame; the ink starts easing from there.
    await t.pump();
    await _midway(t);
    final mid = _ink(t, 'Title');
    await t.pumpAndSettle();
    final lit = _ink(t, 'Title');
    expect(lit, isNot(rest));
    expect(mid, isNot(rest));
    expect(mid, isNot(lit));
  });

  testWidgets('under Reduce Motion a field turns wrong at once', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(_stage(const NeumorphicTextField(labelText: 'Title')));
    await t.pumpAndSettle();
    await t.pumpWidget(
      _stage(
        const NeumorphicTextField(labelText: 'Title', errorText: _message),
      ),
    );
    await t.pump();
    final top = _belowTop(t);
    expect(_shown(t, find.text(_message)), 1);
    expect(_shown(t, _mark), 1);
    await t.pumpAndSettle();
    expect(_belowTop(t), top);
  });
}
