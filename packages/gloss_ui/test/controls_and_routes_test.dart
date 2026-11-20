// Interaction, layout and motion of Gloss controls and routes.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

Widget _app(Widget home, {Brightness brightness = Brightness.light}) =>
    WidgetsApp(
      color: const Color(0xFF0E7652),
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: GlossTheme(data: GlossThemeData.jade(brightness), child: home),
    );

/// A key that opens what [open] shows.
Widget _opener(void Function(BuildContext context) open) => Builder(
  builder: (context) =>
      Center(child: GlossButton('Open', onPressed: () => open(context))),
);

/// Sizes the test's window to [width] by 900 logical pixels.
void _window(WidgetTester tester, double width) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('$brightness: a dialog rises, and Escape or its action '
        'closes it', (tester) async {
      String? answer;
      await tester.pumpWidget(
        _app(
          brightness: brightness,
          _opener(
            (context) => showGlossDialog<void>(
              context: context,
              builder: (context) => GlossDialog(
                title: 'Delete the plan?',
                content: const Text('Its seven dinners go with it.'),
                actions: [
                  GlossDialogAction(
                    label: 'Keep',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  GlossDialogAction(
                    label: 'Delete',
                    destructive: true,
                    primary: true,
                    onPressed: () {
                      answer = 'deleted';
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Delete the plan?'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Delete the plan?'), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(answer, 'deleted');
      expect(find.text('Delete the plan?'), findsNothing);
    });
  }

  testWidgets('an alert dialog stays when the page beside it is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showGlossDialog<void>(
            context: context,
            isAlert: true,
            builder: (context) => GlossDialog(
              title: 'Leave without saving?',
              actions: [
                GlossDialogAction(
                  label: 'Stay',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Leave without saving?'), findsNothing);
  });

  testWidgets('a sheet closes on a press beside it, and stays on a press '
      'inside it', (tester) async {
    await tester.pumpWidget(
      _app(
        _opener(
          (context) => showGlossSheet<void>(
            context: context,
            builder: (context) => const Text('Two servings'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Two servings'), findsOneWidget);
    await tester.tap(find.text('Two servings'));
    await tester.pumpAndSettle();
    expect(find.text('Two servings'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.text('Two servings'), findsNothing);
  });

  // Gloss's scrim keeps its own pace on ui_core's spring: 50 ms in, it is
  // a little of the way dark (eased over the route's time), not over half
  // (ui_core's ease on the spring).
  for (final kind in ['sheet', 'dialog']) {
    testWidgets(
      'the scrim of a $kind comes in behind its panel, then stands full',
      (tester) async {
        final scrim = GlossThemeData.jade(Brightness.light).colors.scrim;
        double shown() {
          final box = tester.widget<ColoredBox>(
            find.byWidgetPredicate(
              (w) =>
                  w is ColoredBox &&
                  w.child is SizedBox &&
                  w.color.withValues(alpha: 1) == scrim.withValues(alpha: 1),
            ),
          );
          return box.color.a / scrim.a;
        }

        await tester.pumpWidget(
          _app(
            _opener(
              (context) => kind == 'sheet'
                  ? showGlossSheet<void>(
                      context: context,
                      builder: (context) => const Text('Two servings'),
                    )
                  : showGlossDialog<void>(
                      context: context,
                      builder: (context) => const GlossDialog(title: 'Delete?'),
                    ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(shown(), inInclusiveRange(0.05, 0.3));
        await tester.pumpAndSettle();
        expect(shown(), 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(GlossDialog), findsNothing);
        expect(find.text('Two servings'), findsNothing);
      },
    );
  }

  // Sample the closing panel and scrim at three points in the transition.
  for (final kind in ['dialog', 'side sheet']) {
    testWidgets('a $kind closes with the expected travel and opacity', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final scrim = GlossThemeData.jade(Brightness.light).colors.scrim;
      final mark = find.text(kind == 'dialog' ? 'Delete?' : 'Courses');
      double scrimShown() {
        var best = 0.0;
        for (final e in find.byType(ColoredBox).evaluate()) {
          final c = (e.widget as ColoredBox).color;
          if (c.withValues(alpha: 1) == scrim.withValues(alpha: 1)) {
            best = best > c.a / scrim.a ? best : c.a / scrim.a;
          }
        }
        return best;
      }

      double seen() {
        var o = 1.0;
        for (final e
            in find
                .ancestor(of: mark, matching: find.byType(Opacity))
                .evaluate()) {
          o *= (e.widget as Opacity).opacity;
        }
        return o;
      }

      await tester.pumpWidget(
        _app(
          _opener(
            (context) => kind == 'dialog'
                ? showGlossDialog<void>(
                    context: context,
                    builder: (context) => const GlossDialog(title: 'Delete?'),
                  )
                : showGlossSideSheet<void>(
                    context: context,
                    builder: (context) => const Text('Courses'),
                  ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      final gone = tester.getRect(mark);
      await tester.pumpAndSettle();
      final open = tester.getRect(mark);
      double presence() {
        final r = tester.getRect(mark);
        return kind == 'dialog'
            ? (r.width / open.width - 0.96) / 0.04
            : (gone.left - r.left) / (gone.left - open.left);
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      // Closing time in milliseconds, panel presence, scrim and opacity.
      final samples = kind == 'dialog'
          ? const [
              [64, 0.54, 0.98, 0.69],
              [128, 0.23, 0.88, 0.43],
              [192, 0.09, 0.68, 0.21],
            ]
          : const [
              [64, 0.57, 0.98, 1.0],
              [128, 0.26, 0.90, 1.0],
              [192, 0.11, 0.73, 1.0],
            ];
      var at = 0;
      for (final [ms, panel, shade, opacity] in samples) {
        await tester.pump(Duration(milliseconds: ms.toInt() - at));
        at = ms.toInt();
        expect(presence(), closeTo(panel, 0.07), reason: '$kind at $ms ms');
        expect(scrimShown(), closeTo(shade, 0.03), reason: 'scrim at $ms ms');
        expect(seen(), closeTo(opacity, 0.04), reason: 'shown at $ms ms');
      }
      await tester.pumpAndSettle();
      expect(mark, findsNothing);
    });
  }

  // Opening routes have separate timing for panel travel and scrim opacity.
  for (final kind in ['dialog', 'sheet', 'action sheet', 'side sheet']) {
    testWidgets('a $kind opens with the expected travel and opacity', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final scrim = GlossThemeData.jade(Brightness.light).colors.scrim;
      final mark = find.text(switch (kind) {
        'dialog' => 'Delete?',
        'sheet' => 'Two servings',
        'action sheet' => 'Share',
        _ => 'Courses',
      });
      double scrimShown() {
        var best = 0.0;
        for (final e in find.byType(ColoredBox).evaluate()) {
          final c = (e.widget as ColoredBox).color;
          if (c.withValues(alpha: 1) == scrim.withValues(alpha: 1)) {
            best = best > c.a / scrim.a ? best : c.a / scrim.a;
          }
        }
        return best;
      }

      double seen() {
        var o = 1.0;
        for (final e
            in find
                .ancestor(of: mark, matching: find.byType(Opacity))
                .evaluate()) {
          o *= (e.widget as Opacity).opacity;
        }
        return o;
      }

      await tester.pumpWidget(
        _app(
          _opener(
            (context) => switch (kind) {
              'dialog' => showGlossDialog<void>(
                context: context,
                builder: (context) => const GlossDialog(title: 'Delete?'),
              ),
              'sheet' => showGlossSheet<void>(
                context: context,
                builder: (context) => const Text('Two servings'),
              ),
              'action sheet' => showGlossActionSheet<int>(
                context: context,
                actions: const [
                  GlossSheetAction<int>(label: 'Share', value: 1),
                ],
              ),
              _ => showGlossSideSheet<void>(
                context: context,
                builder: (context) => const Text('Courses'),
              ),
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      final gone = tester.getRect(mark);
      // Opening time in milliseconds, panel presence, scrim and opacity.
      final samples = switch (kind) {
        'dialog' => const [
          [64, 0.59, 0.30, 0.57],
          [128, 0.93, 0.68, 0.94],
          [192, 1.0, 0.88, 1.0],
        ],
        'sheet' => const [
          [64, 0.49, 0.22, 0.49],
          [128, 0.86, 0.58, 0.85],
          [192, 0.98, 0.81, 1.0],
        ],
        'action sheet' => const [
          [64, 0.55, 0.27, 0.54],
          [128, 0.91, 0.65, 0.91],
          [192, 0.99, 0.86, 1.0],
        ],
        _ => const [
          [64, null, 0.27, 1.0],
          [128, null, 0.65, 1.0],
          [192, null, 0.86, 1.0],
        ],
      };
      final rects = <Rect>[];
      var at = 0;
      for (final [ms!, _, shade!, shown!] in samples) {
        await tester.pump(Duration(milliseconds: ms.toInt() - at));
        at = ms.toInt();
        rects.add(tester.getRect(mark));
        expect(scrimShown(), closeTo(shade, 0.03), reason: 'scrim at $ms ms');
        expect(seen(), closeTo(shown, 0.04), reason: 'shown at $ms ms');
      }
      await tester.pumpAndSettle();
      final open = tester.getRect(mark);
      for (final (i, [ms, panel, _, _]) in samples.indexed) {
        if (panel == null) continue;
        final r = rects[i];
        final presence = kind == 'dialog'
            ? (r.width / open.width - 0.96) / 0.04
            : (gone.top - r.top) / (gone.top - open.top);
        expect(presence, closeTo(panel, 0.07), reason: '$kind at $ms ms');
      }
      expect(scrimShown(), 1);
    });
  }

  testWidgets('a tab is chosen once, by a press or (from one Tab) the arrows', (
    tester,
  ) async {
    final chosen = <int>[];
    await tester.pumpWidget(
      _app(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => GlossTabBar(
              tabs: const ['Ingredients', 'Method', 'Notes'],
              selectedIndex: chosen.isEmpty ? 0 : chosen.last,
              onSelected: (i) => setState(() => chosen.add(i)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Method'));
    await tester.pumpAndSettle();
    expect(chosen, [1]);
    // A press does not take the keyboard's focus; one Tab reaches the bar
    // (one stop), the arrows choose.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(chosen, [1, 2]);
  });

  testWidgets('a rating takes a press, and a press on the star given takes '
      'it back', (tester) async {
    var value = 3;
    await tester.pumpWidget(
      _app(
        Center(
          child: StatefulBuilder(
            builder: (context, setState) => GlossRating(
              value: value,
              semanticLabel: 'Your rating',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    Offset star(int n) {
      final rect = tester.getRect(find.byType(GlossRating));
      return Offset(rect.left + rect.width / 5 * (n - 0.5), rect.center.dy);
    }

    await tester.tapAt(star(5));
    await tester.pumpAndSettle();
    expect(value, 5);
    await tester.tapAt(star(5));
    await tester.pumpAndSettle();
    expect(value, 4);
  });

  testWidgets('a combobox and a tag input name their fields as their labels '
      'read', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlossCombobox<String>(
                  label: 'Herb',
                  options: const ['Basil', 'Dill'],
                  onSelected: (_) {},
                ),
                GlossTagInput<String>(
                  label: 'Tags',
                  values: const [],
                  options: const ['Quick'],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (final name in ['Herb', 'Tags']) {
      expect(
        tester.getSemantics(
          find.descendant(
            of: find.byType(
              name == 'Herb' ? GlossCombobox<String> : GlossTagInput<String>,
            ),
            matching: find.byType(EditableText),
          ),
        ),
        isSemantics(label: name, isTextField: true),
        reason: name,
      );
    }
    semantics.dispose();
  });

  for (final (width, kind) in [
    (390.0, GlossNavigationBar),
    (800.0, GlossNavigationRail),
    (1440.0, GlossSidebar),
  ]) {
    testWidgets('at $width the app shell lays its places in a $kind', (
      tester,
    ) async {
      _window(tester, width);
      var place = 0;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => GlossScaffold(
              destinations: const [
                GlossDestination(icon: IconData(0x41), label: 'Today'),
                GlossDestination(icon: IconData(0x42), label: 'Recipes'),
                GlossDestination(icon: IconData(0x43), label: 'Plan'),
              ],
              selectedIndex: place,
              onSelected: (i) => setState(() => place = i),
              body: Center(child: Text('Place $place')),
            ),
          ),
        ),
      );
      expect(find.byType(kind), findsOneWidget);
      await tester.tap(find.text('Recipes'));
      await tester.pumpAndSettle();
      expect(place, 1);
      expect(find.text('Place 1'), findsOneWidget);
    });
  }

  // The dialog fills the available width up to its limit, leaving
  // a margin from the screen's edges. On a page it sits flush with its
  // column's start.
  Rect panel() => find
      .descendant(
        of: find.byType(GlossDialog),
        matching: find.byType(GlossSurface),
      )
      .evaluate()
      .map((e) => (e.renderObject! as RenderBox))
      .map((b) => b.localToGlobal(Offset.zero) & b.size)
      .reduce((a, b) => a.width >= b.width ? a : b);

  for (final (width, wide) in [(390.0, 390.0 - 48), (1440.0, 440.0)]) {
    testWidgets('at ${width.toInt()} a dialog is ${wide.toInt()} wide', (
      tester,
    ) async {
      _window(tester, width);
      await tester.pumpWidget(
        _app(
          _opener(
            (context) => showGlossDialog<void>(
              context: context,
              builder: (context) => GlossDialog(
                title: 'Delete?',
                actions: [GlossDialogAction(label: 'Keep', onPressed: () {})],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(panel().width, wide);
      expect(panel().center.dx, width / 2);
    });

    testWidgets('at ${width.toInt()} a dialog at rest stands at its '
        "column's start", (tester) async {
      _window(tester, width);
      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GlossDialog(
                  title: 'Delete?',
                  actions: [GlossDialogAction(label: 'Keep', onPressed: () {})],
                ),
              ],
            ),
          ),
        ),
      );
      expect(panel().left, 16);
      expect(panel().top, 16);
      expect(panel().width, width == 390 ? 390 - 32 : 440);
    });
  }
}
