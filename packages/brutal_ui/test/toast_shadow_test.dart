// A toast stands off the page as every raised Brutal surface does (a
// dialog, a menu, a list): the surface in the ink rule, on the look's hard
// ink shadow, the shadow clear of the tab bar. It stood flat, an ink band.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  double width = 390,
  double height = 844,
  TextDirection direction = TextDirection.ltr,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: BrutalTheme(
          data: brightness == Brightness.light
              ? BrutalThemeData.light()
              : BrutalThemeData.dark(),
          child: BrutalToaster(child: navigator!),
        ),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

// The phone's bar: the tallest full-width box round the first place's icon
// that stands on the screen's foot.
Rect _bar(WidgetTester tester) {
  Rect? bar;
  for (final e
      in find
          .ancestor(
            of: find.byIcon(LucideIcons.house),
            matching: find.byWidgetPredicate((_) => true),
          )
          .evaluate()) {
    final box = e.renderObject;
    if (box is! RenderBox || !box.hasSize) continue;
    final r = MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
    if (r.width < 389 || r.bottom < 843 || r.height > 200) continue;
    if (bar == null || r.height > bar.height) bar = r;
  }
  return bar!;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final direction in TextDirection.values) {
      testWidgets('a toast casts the hard shadow, clear of the bar '
          '(${brightness.name}, ${direction.name})', (tester) async {
        final page = GlobalKey();
        await _pump(
          tester,
          BrutalScaffold(
            destinations: const [
              BrutalDestination(icon: LucideIcons.house, label: 'Home'),
              BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            body: SizedBox.expand(key: page),
          ),
          direction: direction,
          brightness: brightness,
        );
        showBrutalToast(
          page.currentContext!,
          'Ticket cancelled',
          actionLabel: 'Undo',
          onAction: () {},
          duration: null,
        );
        await tester.pumpAndSettle();
        final theme = brightness == Brightness.light
            ? BrutalThemeData.light()
            : BrutalThemeData.dark();
        final surface = find
            .ancestor(
              of: find.text('Ticket cancelled'),
              matching: find.byType(BrutalSurface),
            )
            .last;
        final face = tester.widget<BrutalSurface>(surface).face;
        expect(face.shadow, theme.colors.ink, reason: 'no hard shadow');
        expect(face.fill, theme.colors.surface);
        expect(face.border, theme.colors.ink);
        final toast = tester.getRect(surface);
        final bar = _bar(tester);
        expect(
          toast.bottom + theme.shadowOffset,
          lessThanOrEqualTo(bar.top),
          reason: 'toast $toast, bar $bar',
        );
      });
    }
  }
}
