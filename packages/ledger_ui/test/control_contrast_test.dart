// Every palette's controls read, by day and by lamplight: a radio's and a
// checkbox's empty ring at 3:1 on its face and on the page (WCAG 1.4.11), and a
// filled button's words at 4.5:1 on its fill at rest, under a pointer and held.
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<void> _pump(WidgetTester t, LedgerThemeData theme, Widget child) async {
  t.view.physicalSize = const Size(390, 400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, _) => LedgerHost(
        brightness: theme.brightness,
        theme: theme,
        darkTheme: theme,
        child: Center(child: child),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// The colour [c] shows at on [ground].
Color _on(Color c, Color ground) => Color.alphaBlend(c, ground);

/// The fill of the box [of] paints its face with: the innermost decorated
/// box around [words].
Color _fill(WidgetTester t, Finder words) {
  for (final box
      in find
          .ancestor(of: words, matching: find.byType(DecoratedBox))
          .evaluate()) {
    final d = (box.widget as DecoratedBox).decoration;
    if (d is BoxDecoration && d.color != null && d.color!.a > 0) {
      return d.color!;
    }
  }
  throw StateError('no fill around the words');
}

Color _ink(WidgetTester t, Finder words) =>
    t.renderObject<RenderParagraph>(words).text.style!.color!;

void main() {
  for (final b in Brightness.values) {
    for (final p in LedgerThemeData.palettes) {
      final t0 = LedgerThemeData.preset(p.id, b);
      testWidgets('${p.id} by ${b.name}: an empty ring reads 3:1', (t) async {
        await _pump(
          t,
          t0,
          RadioGroup<int>(
            groupValue: 1,
            onChanged: (_) {},
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LedgerRadio<int>(value: 1, label: 'Chosen'),
                LedgerRadio<int>(value: 2, label: 'Empty'),
              ],
            ),
          ),
        );
        final rings = [
          for (final box in find.byType(Container).evaluate())
            if ((box.widget as Container).decoration case BoxDecoration(
              shape: BoxShape.circle,
              :final Border border,
              :final color?,
            ))
              (border.top.color, color),
        ];
        expect(rings, isNotEmpty);
        for (final (ring, face) in rings) {
          for (final ground in [face, t0.background, t0.surface]) {
            expect(
              RawPalette.contrastRatio(_on(ring, ground), ground),
              greaterThanOrEqualTo(3),
              reason: '${p.id} ${b.name}: ring $ring on $ground',
            );
          }
        }
      });

      testWidgets(
        '${p.id} by ${b.name}: a filled button reads 4.5:1 at rest, hovered and held',
        (t) async {
          await _pump(
            t,
            t0,
            LedgerButton.filled('Save book', onPressed: () {}),
          );
          final words = find.text('Save book');
          void reads(String state) {
            final fill = _fill(t, words);
            final ink = _ink(t, words);
            expect(
              RawPalette.contrastRatio(_on(ink, fill), fill),
              greaterThanOrEqualTo(4.5),
              reason: '${p.id} ${b.name} $state: $ink on $fill',
            );
          }

          reads('at rest');
          final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
          await mouse.addPointer(location: Offset.zero);
          addTearDown(mouse.removePointer);
          await mouse.moveTo(t.getCenter(words));
          await t.pumpAndSettle();
          reads('hovered');
          await mouse.down(t.getCenter(words));
          await t.pumpAndSettle();
          reads('held');
          await mouse.up();
          await t.pumpAndSettle();
        },
      );
    }
  }
}
