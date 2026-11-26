// The README's examples, as they are written there: if one stops compiling
// or stops doing what the README says, this fails.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// "Getting started".
class Deploy extends StatelessWidget {
  const Deploy({super.key});

  @override
  Widget build(BuildContext context) => TermPane(
    title: 'new deploy',
    child: TermButton.filled(label: 'deploy', onPressed: () {}),
  );
}

void rollBack() {}

// "Make it yours".
(TermThemeData, Widget) makeItYours() {
  final base = TermThemeData.dark(
    // Your brand's colour; the theme steps it until it reads at 4.5:1.
    accent: const Color(0xFF0A7D4F),
  );

  final theme = base.copyWith(
    // Every primary button.
    filledButtonStyle: TermStyle(
      fill: WidgetStatePropertyAll(TermAnsi.magenta.of(base.palette)),
      edge: WidgetStatePropertyAll(TermAnsi.magenta.of(base.palette)),
    ),
  );

  // One button.
  final button = TermButton(
    label: 'roll back',
    onPressed: rollBack,
    style: TermStyle(
      foreground: WidgetStatePropertyAll(theme.warning),
      edge: WidgetStatePropertyAll(theme.warning),
    ),
  );
  return (theme, button);
}

// The hover paragraph.
TermThemeData withHover() => TermThemeData.dark().copyWith(
  listTileStyle: TermStyle(
    fill: WidgetStateProperty.fromMap({
      WidgetState.hovered: TermAnsi.blue
          .of(TermPalette.night)
          .withValues(alpha: 0.2),
    }),
  ),
);

void main() {
  testWidgets('getting started builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TermTheme(data: TermThemeData.dark(), child: child!),
        home: const Deploy(),
      ),
    );
    expect(find.textContaining('new deploy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the brand reads at 4.5:1 and every primary button is magenta', () {
    final (theme, _) = makeItYours();
    expect(
      RawPalette.contrastRatio(theme.accent, theme.background),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      theme.filledButtonStyle?.fill?.resolve(const {}),
      TermAnsi.magenta.of(theme.palette),
    );
  });

  testWidgets('one button takes its own colours', (tester) async {
    final (theme, button) = makeItYours();
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: theme,
          child: Center(child: button),
        ),
      ),
    );
    expect(find.text('roll back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a hover style is one line away', () {
    final style = withHover().listTileStyle!;
    expect(style.fill?.resolve(const {}), isNull);
    expect(style.fill?.resolve(const {WidgetState.hovered}), isNotNull);
  });
}
