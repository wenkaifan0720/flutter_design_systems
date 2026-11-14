// No text in the look falls back to Flutter's unstyled text: every exported widget, and every overlay the look opens,
// is built under a bare WidgetsApp whose only styling is the package's theme. The app's own text style is the one
// MaterialApp gives text outside a Material (red monospace, a yellow double underline), so any text the theme does not
// reach shows it, and the test fails on it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'fixtures.dart';
import 'support.dart';

const _fallback = TextStyle(
  color: Color(0xD0FF0000),
  fontFamily: 'monospace',
  fontSize: 48,
  fontWeight: FontWeight.w900,
  decoration: TextDecoration.underline,
  decorationColor: Color(0xFFFFFF00),
  decorationStyle: TextDecorationStyle.double,
);

/// Every text span on screen that carries the fallback's double underline.
List<String> _unstyled() {
  final found = <String>[];
  void span(InlineSpan? root, String where) {
    root?.visitChildren((s) {
      final style = s.style;
      if (style != null &&
          style.decorationStyle == TextDecorationStyle.double &&
          (style.decoration?.contains(TextDecoration.underline) ?? false)) {
        found.add('$where "${s.toPlainText()}"');
      }
      return true;
    });
  }

  void visit(RenderObject o) {
    if (o is RenderParagraph) span(o.text, 'text');
    if (o is RenderEditable) span(o.text, 'field');
    o.visitChildren(visit);
  }

  for (final view in WidgetsBinding.instance.renderViews) {
    visit(view);
  }
  return found;
}

Widget _app(Widget home) => WidgetsApp(
  color: const Color(0xFF000000),
  textStyle: _fallback,
  pageRouteBuilder: <T>(settings, build) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => build(context),
  ),
  home: NeumorphicTheme(
    data: NeumorphicThemeData.porcelain(),
    child: MediaQuery(
      data: const MediaQueryData(
        size: Size(800, 1000),
        disableAnimations: true,
      ),
      child: home,
    ),
  ),
);

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(800, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(home));
  await tester.pumpAndSettle();
}

/// The overlays the look raises, each opened from a page inside the theme.
final _overlays = <String, void Function(BuildContext)>{
  'showNeumorphicDialog': (c) => showNeumorphicDialog<void>(
    c,
    builder: (_) => NeumorphicDialog(
      title: 'Delete note?',
      message: 'This cannot be undone.',
      content: const [Text('Notes in it go too.')],
      actions: [NeumorphicButton('Delete', onPressed: hit)],
    ),
  ),
  'showNeumorphicBottomSheet': (c) => showNeumorphicBottomSheet<void>(
    c,
    builder: (_) =>
        const NeumorphicBottomSheet(title: 'Share', child: Text('Send a copy')),
  ),
  'showNeumorphicMenu': (c) => showNeumorphicMenu<int>(
    c,
    anchor: const Rect.fromLTWH(40, 40, 120, 40),
    items: const [
      NeumorphicMenuItem(0, 'Rename'),
      NeumorphicMenuItem(1, 'Move'),
    ],
  ),
  'showNeumorphicTooltip': (c) => showNeumorphicTooltip(
    c,
    message: 'Share',
    anchor: const Rect.fromLTWH(40, 40, 40, 40),
  ),
  'showNeumorphicSnackBar': (c) => showNeumorphicSnackBar(
    c,
    message: 'Saved',
    title: 'Draft',
    actionLabel: 'Undo',
    onAction: hit,
  ),
  'showNeumorphicDatePicker': (c) => showNeumorphicDatePicker(
    c,
    value: DateTime(2026, 11, 6),
    first: DateTime(2026),
    last: DateTime(2027),
  ),
  'showNeumorphicTimePicker': (c) =>
      showNeumorphicTimePicker(c, value: const NeumorphicTime(9, 30)),
};

void main() {
  setUpAll(loadNeumorphicFonts);

  for (final MapEntry(key: name, value: build) in neumorphicFixtures.entries) {
    testWidgets('$name: every text is styled by the theme', (tester) async {
      await _pump(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) => boundedFixtures.contains(name)
                    ? SizedBox(height: 800, child: build(context))
                    : build(context),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: name);
      expect(_unstyled(), isEmpty, reason: name);
    });
  }

  for (final MapEntry(key: name, value: open) in _overlays.entries) {
    testWidgets('$name: the overlay\'s text is styled by the theme', (
      tester,
    ) async {
      late BuildContext page;
      await _pump(
        tester,
        Builder(
          builder: (context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      );
      open(page);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: name);
      expect(find.byType(RichText).evaluate().length, greaterThan(0));
      expect(_unstyled(), isEmpty, reason: name);
    });
  }

  testWidgets('an open select\'s menu is styled by the theme', (tester) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 400,
          child: NeumorphicSelect<int>(
            label: 'Country',
            value: 0,
            options: const [
              NeumorphicMenuItem(0, 'Canada'),
              NeumorphicMenuItem(1, 'Chile'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Canada'));
    await tester.pumpAndSettle();
    expect(find.text('Chile'), findsOneWidget);
    expect(_unstyled(), isEmpty);
  });

  testWidgets('the fallback is caught where the theme is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        textStyle: _fallback,
        builder: (_, _) => const Text('Bare'),
      ),
    );
    expect(_unstyled(), isNotEmpty);
  });
}
