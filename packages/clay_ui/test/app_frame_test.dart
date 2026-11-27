// The app frame: the shell's act stands in the chrome at every width (the
// dock's end, under the name on the rail, a worded key on the sidebar), a
// pushed page's way out is a back glyph and a sheet's a close, and the
// states and the plain field do what they say.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:clay_ui/clay_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _act = ValueKey<String>('act');
const _out = ValueKey<String>('out');

Widget _root(String brand) => ClayPreview(
  brand: brand,
  tabs: const [
    ClayTab(LucideIcons.sun, 'Today'),
    ClayTab(LucideIcons.listChecks, 'Habits'),
  ],
  action: ClayShellAction(
    icon: LucideIcons.plus,
    label: 'New habit',
    key: _act,
    onPressed: (_) {},
  ),
  child: const ClayScreen(body: Text('Today')),
);

Widget _page(ClayPresentation presentation) => ClayPreview(
  presentation: presentation,
  child: Builder(
    builder: (context) => ClayScreen(
      topBar: ClayTopBar(
        title: 'Drink water',
        leading: ClayTopBar.autoLeading(context, key: _out),
      ),
      body: const Text('Eight glasses a day.'),
    ),
  ),
);

Future<void> _at(WidgetTester tester, double width, Widget app) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a phone: the act stands at the dock\'s end', (tester) async {
    await _at(tester, 390, _root('Steady'));
    expect(
      find.descendant(
        of: find.byType(ClayNavigationBar),
        matching: find.byKey(_act),
      ),
      findsOneWidget,
    );
    final bar = tester.getRect(find.byType(ClayNavigationBar));
    final act = tester.getRect(find.byKey(_act));
    expect(act.right, lessThanOrEqualTo(bar.right));
    expect(act.height, greaterThanOrEqualTo(44));
  });

  testWidgets('a tablet: the act stands under the name on the rail', (
    tester,
  ) async {
    await _at(tester, 800, _root('Steady'));
    expect(
      find.descendant(
        of: find.byType(ClayNavigationRail),
        matching: find.byKey(_act),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a desktop: the act is a worded coral key on the sidebar', (
    tester,
  ) async {
    await _at(tester, 1440, _root('Steady'));
    final key = find.descendant(
      of: find.byType(ClaySidebar),
      matching: find.byKey(_act),
    );
    expect(key, findsOneWidget);
    expect(
      find.descendant(of: key, matching: find.text('New habit')),
      findsOneWidget,
    );
    expect(find.text('Steady'), findsOneWidget);
  });

  testWidgets(
    'a root has no way out; a pushed page goes back; a sheet closes',
    (tester) async {
      await _at(tester, 390, _page(ClayPresentation.root));
      expect(find.byKey(_out), findsNothing);

      await _at(tester, 390, _page(ClayPresentation.pushed));
      expect(
        find.descendant(
          of: find.byKey(_out),
          matching: find.byIcon(LucideIcons.chevronLeft),
        ),
        findsOneWidget,
      );

      await _at(tester, 390, _page(ClayPresentation.sheet));
      expect(
        find.descendant(
          of: find.byKey(_out),
          matching: find.byIcon(LucideIcons.x),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('the error state retries; the plain field hides a password', (
    tester,
  ) async {
    var tries = 0;
    await _at(
      tester,
      390,
      ClayPreview(
        child: ClayScreen(
          body: Column(
            children: [
              ClayErrorState(
                title: 'Could not load',
                message: 'Check your connection.',
                onRetry: () => tries++,
              ),
              const ClayInput(labelText: 'Password', obscureText: true),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(tries, 1);
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
  });
}
