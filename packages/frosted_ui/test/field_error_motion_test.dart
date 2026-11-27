// A field turning wrong, and right again, eases: its message fades in as the
// room under the field opens (what stands below slides, it never jumps), and
// the label's ink and the mark at the well's end ease to the danger's. A date
// field's calendar crosses to the mark. Under Reduce Motion each cuts.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/well.dart';

const _below = ValueKey('below');
const _message = 'Enter the title';

Widget _stage(Widget field) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(child: page!),
  home: Align(
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

Finder _glyph(IconData glyph) =>
    find.byWidgetPredicate((w) => w is Icon && w.icon == glyph);

// The mark at the well's end (the message leads with one of its own).
final _mark = find.descendant(
  of: find.byType(FrostedWell),
  matching: _glyph(FrostedGlyphs.danger),
);

bool _between(double v, double a, double b) =>
    v > (a < b ? a : b) + 0.5 && v < (a < b ? b : a) - 0.5;

void main() {
  testWidgets(
    'a text field turning wrong eases its message, room, ink and mark',
    (t) async {
      await t.pumpWidget(_stage(const FrostedTextField(labelText: 'Title')));
      await t.pumpAndSettle();
      final top0 = _belowTop(t);
      final ink0 = _ink(t, 'Title');
      await t.pumpWidget(
        _stage(const FrostedTextField(labelText: 'Title', errorText: _message)),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      final topMid = _belowTop(t);
      final inkMid = _ink(t, 'Title');
      final messageMid = _shown(t, find.text(_message));
      final markMid = _shown(t, _mark);
      await t.pumpAndSettle();
      final over = FrostedTheme.of(t.element(find.text('Title')))
          .colorScheme
          .over;
      expect(_ink(t, 'Title'), over);
      expect(_shown(t, find.text(_message)), 1);
      expect(_shown(t, _mark), 1);
      final top1 = _belowTop(t);
      expect(top1, greaterThan(top0 + 8));
      expect(
        _between(topMid, top0, top1),
        isTrue,
        reason: 'below at $topMid, from $top0 to $top1',
      );
      expect(messageMid, inExclusiveRange(0, 1));
      expect(markMid, inExclusiveRange(0, 1));
      expect(inkMid, isNot(ink0));
      expect(inkMid, isNot(over));
    },
  );

  testWidgets('a text field turning right again eases its message out', (
    t,
  ) async {
    await t.pumpWidget(
      _stage(const FrostedTextField(labelText: 'Title', errorText: _message)),
    );
    await t.pumpAndSettle();
    final top0 = _belowTop(t);
    await t.pumpWidget(_stage(const FrostedTextField(labelText: 'Title')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    final topMid = _belowTop(t);
    expect(find.text(_message), findsOneWidget);
    expect(_shown(t, find.text(_message)), inExclusiveRange(0, 1));
    expect(_shown(t, _mark), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(find.text(_message), findsNothing);
    expect(_mark, findsNothing);
    final top1 = _belowTop(t);
    expect(
      _between(topMid, top0, top1),
      isTrue,
      reason: 'below at $topMid, from $top0 to $top1',
    );
  });

  testWidgets('a help line and its error cross, the room easing between', (
    t,
  ) async {
    await t.pumpWidget(
      _stage(
        const FrostedTextField(
          labelText: 'Title',
          helperText: 'As on the cover',
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.pumpWidget(
      _stage(
        const FrostedTextField(
          labelText: 'Title',
          helperText: 'As on the cover',
          errorText: _message,
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(_shown(t, find.text('As on the cover')), inExclusiveRange(0, 1));
    expect(_shown(t, find.text(_message)), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(find.text('As on the cover'), findsNothing);
  });

  testWidgets('a date field\'s calendar crosses to the mark', (t) async {
    Widget date(String? error) => FrostedDateField(
      labelText: 'Started',
      value: null,
      errorText: error,
      onChanged: (_) {},
    );
    await t.pumpWidget(_stage(date(null)));
    await t.pumpAndSettle();
    await t.pumpWidget(_stage(date('Pick a day')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    expect(_shown(t, _glyph(FrostedGlyphs.calendar)), inExclusiveRange(0, 1));
    expect(_shown(t, _mark), inExclusiveRange(0, 1));
    expect(_shown(t, find.text('Pick a day')), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(_glyph(FrostedGlyphs.calendar), findsNothing);
  });

  testWidgets('a radio group\'s message fades in as its room opens', (t) async {
    Widget group(String? error) => FrostedRadioGroup<String>(
      labelText: 'Delivery',
      value: null,
      errorText: error,
      onChanged: (_) {},
      options: const [
        FrostedRadio('standard', 'Standard'),
        FrostedRadio('express', 'Express'),
      ],
    );
    await t.pumpWidget(_stage(group(null)));
    await t.pumpAndSettle();
    final top0 = _belowTop(t);
    await t.pumpWidget(_stage(group('Choose one')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));
    final topMid = _belowTop(t);
    expect(_shown(t, find.text('Choose one')), inExclusiveRange(0, 1));
    await t.pumpAndSettle();
    expect(_between(topMid, top0, _belowTop(t)), isTrue);
  });

  testWidgets('a line a list opens over goes at once', (t) async {
    Widget slot(String? words) => FrostedHintSlot(
      gap: 6,
      eased: words != null,
      child: words == null ? null : Text(words),
    );
    await t.pumpWidget(_stage(slot('As on the cover')));
    await t.pumpAndSettle();
    final top0 = _belowTop(t);
    await t.pumpWidget(_stage(slot(null)));
    await t.pump();
    expect(find.text('As on the cover'), findsNothing);
    expect(_belowTop(t), lessThan(top0 - 6));
  });

  testWidgets('under Reduce Motion a field turns wrong at once', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(_stage(const FrostedTextField(labelText: 'Title')));
    await t.pumpAndSettle();
    await t.pumpWidget(
      _stage(const FrostedTextField(labelText: 'Title', errorText: _message)),
    );
    await t.pump();
    final top = _belowTop(t);
    final over = FrostedTheme.of(t.element(find.text('Title')))
        .colorScheme
        .over;
    expect(_shown(t, find.text(_message)), 1);
    expect(_ink(t, 'Title'), over);
    await t.pumpAndSettle();
    expect(_belowTop(t), top);
  });
}
