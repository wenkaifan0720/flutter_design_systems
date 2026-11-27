// The app frame: the shell's act stands in the chrome at every width (the
// bottom bar's last cell, under the name on the rail, a worded key on the
// sidebar), a pushed page's way out is a back glyph and a sheet's a close,
// and the states and the plain field do what they say.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_host.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _act = ValueKey<String>('act');
const _out = ValueKey<String>('out');

Widget _root(String brand) => GlossPreview(
  brand: brand,
  tabs: const [
    GlossTab(LucideIcons.house, 'Today'),
    GlossTab(LucideIcons.bookOpen, 'Recipes'),
  ],
  action: GlossShellAction(
    icon: LucideIcons.plus,
    label: 'Plan the week',
    key: _act,
    onPressed: (_) {},
  ),
  child: const GlossScreen(body: Text('Tonight')),
);

Widget _page(GlossPresentation presentation) => GlossPreview(
  presentation: presentation,
  child: Builder(
    builder: (context) => GlossScreen(
      topBar: GlossTopBar(
        title: 'Recipe',
        leading: GlossTopBar.autoLeading(context, key: _out),
      ),
      body: const Text('Serves two.'),
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
  testWidgets('a phone: the act is the bottom bar\'s last cell', (
    tester,
  ) async {
    await _at(tester, 390, _root('Simmer'));
    expect(
      find.descendant(of: find.byType(GlossBar), matching: find.byKey(_act)),
      findsOneWidget,
    );
    final bar = tester.getRect(find.byType(GlossBar));
    final act = tester.getRect(find.byKey(_act));
    expect(act.right, lessThanOrEqualTo(bar.right));
    final floor = RawTapTargets.of(tester.element(find.byKey(_act)))
        .floorOn()
        .height;
    expect(act.height, greaterThanOrEqualTo(floor));
  });

  testWidgets('a tablet: the act stands under the name on the rail', (
    tester,
  ) async {
    await _at(tester, 800, _root('Simmer'));
    expect(
      find.descendant(
        of: find.byType(GlossNavigationRail),
        matching: find.byKey(_act),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a desktop: the act is a worded gel key on the sidebar', (
    tester,
  ) async {
    await _at(tester, 1440, _root('Simmer'));
    final key = find.descendant(
      of: find.byType(GlossSidebar),
      matching: find.byKey(_act),
    );
    expect(key, findsOneWidget);
    expect(
      find.descendant(of: key, matching: find.text('Plan the week')),
      findsOneWidget,
    );
    expect(find.text('Simmer'), findsOneWidget);
  });

  testWidgets(
    'a root has no way out; a pushed page goes back; a sheet closes',
    (tester) async {
      await _at(tester, 390, _page(GlossPresentation.root));
      expect(find.byKey(_out), findsNothing);

      await _at(tester, 390, _page(GlossPresentation.pushed));
      expect(
        find.descendant(
          of: find.byKey(_out),
          matching: find.byIcon(LucideIcons.chevronLeft),
        ),
        findsOneWidget,
      );

      await _at(tester, 390, _page(GlossPresentation.sheet));
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
      GlossPreview(
        child: GlossScreen(
          body: Column(
            children: [
              GlossErrorState(
                title: 'Could not load',
                message: 'Check your connection.',
                onRetry: () => tries++,
              ),
              const GlossInput(labelText: 'Password', obscureText: true),
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
