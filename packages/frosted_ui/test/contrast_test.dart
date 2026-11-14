// Contrast (law 8) where the self-review found words or glyphs too faint: a count's words on the unread dot, a
// tone's glyph on its snack-bar disc by night, "Working…" on a busy action bar, and a person not chosen in a pick.
// Also the snack bar's desktop measure (380, at the line's start), and a button's words at 200% kept inside its
// pill's round ends, found in the same round.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/dim.dart';

Future<void> _pump(
  WidgetTester t,
  Widget part, {
  Brightness brightness = Brightness.light,
  Size size = const Size(390, 844),
  TextScaler scale = TextScaler.noScaling,
}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scale),
        child: FrostedHost(brightness: brightness, child: page!),
      ),
      home: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [part],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

FrostedThemeData _theme(WidgetTester t, Finder at) =>
    (t.element(at.first) as BuildContext).frostedTheme;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a count reads 4.5:1 on its dot (${brightness.name})', (
      t,
    ) async {
      await _pump(
        t,
        const Align(child: FrostedBadge(3, label: '3 new')),
        brightness: brightness,
      );
      final theme = _theme(t, find.byType(FrostedBadge));
      final words = t.widget<Text>(find.text('3')).style!.color!;
      expect(
        FrostedThemeData.contrast(words, theme.colorScheme.unreadDot),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('a tone glyph reads 3:1 on its disc (${brightness.name})', (
      t,
    ) async {
      for (final tone in [
        FrostedTone.danger,
        FrostedTone.warning,
        FrostedTone.info,
        FrostedTone.quiet,
      ]) {
        await _pump(
          t,
          FrostedSnackBar('Payment failed', tone: tone),
          brightness: brightness,
        );
        final theme = _theme(t, find.byType(FrostedSnackBar));
        final glyph = t.widget<Icon>(
          find.descendant(
            of: find.byType(FrostedSnackBar),
            matching: find.byType(Icon),
          ),
        );
        // The disc as it shows: opaque by day, its tone's tint over the
        // slab by night (self-review round 5), read on each slab stop.
        final disc = t.widget<DecoratedBox>(
          find.descendant(
            of: find.byType(FrostedSnackBar),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).shape == BoxShape.circle,
            ),
          ),
        );
        final fill = (disc.decoration as BoxDecoration).color!;
        for (final stop in [theme.toast.top, theme.toast.bottom]) {
          final ground = Color.alphaBlend(fill, stop.withValues(alpha: 1));
          expect(
            FrostedThemeData.contrast(glyph.color!, ground),
            greaterThanOrEqualTo(3),
            reason: tone.name,
          );
        }
      }
    });
  }

  testWidgets('a busy action bar reads Working at full strength', (t) async {
    await _pump(
      t,
      FrostedActionBar(label: 'Transfer', busy: true, onPressed: () {}),
    );
    final fades = find.ancestor(
      of: find.text('Working…'),
      matching: find.byType(FrostedFade),
    );
    expect(
      fades.evaluate().every((e) => (e.widget as FrostedFade).opacity == 1),
      isTrue,
    );
  });

  testWidgets('a person not chosen keeps the name in its ink', (t) async {
    await _pump(
      t,
      const FrostedPeople(
        children: [
          FrostedPerson('Jonah Reyes', selected: true),
          FrostedPerson('Priya Anand', dimmed: true),
        ],
      ),
    );
    final theme = _theme(t, find.byType(FrostedPeople));
    expect(
      t.widget<Text>(find.text('Priya')).style!.color,
      theme.colorScheme.textSecondary,
    );
    expect(
      find
          .ancestor(of: find.text('Priya'), matching: find.byType(Opacity))
          .evaluate()
          .every((e) => (e.widget as Opacity).opacity == 1),
      isTrue,
    );
  });

  testWidgets('a snack bar is 380 wide at the line start on the desktop', (
    t,
  ) async {
    await _pump(t, const FrostedSnackBar('Saved'), size: const Size(1440, 900));
    final bar = t.getRect(
      find
          .descendant(
            of: find.byType(FrostedSnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(bar.width, 380);
    expect(bar.left, 16);
  });

  testWidgets("at 200% a long word stays inside the pill's round ends", (
    t,
  ) async {
    await _pump(
      t,
      FrostedActionBar(
        floating: true,
        label: 'Remind me Thursday morning',
        onPressed: () {},
      ),
      scale: const TextScaler.linear(2),
    );
    final pill = t.getRect(find.byType(FrostedButton));
    final words = t.getRect(
      find.descendant(
        of: find.byType(FrostedButton),
        matching: find.byType(Text),
      ),
    );
    final r = pill.height / 2;
    final into = math.min(words.height / 2, r);
    final curve = r - math.sqrt(r * r - into * into);
    expect(words.left - pill.left, greaterThanOrEqualTo(curve - 0.5));
    expect(pill.right - words.right, greaterThanOrEqualTo(curve - 0.5));
  });
}
