// The settings form with no colour and no face of its own: the monochrome
// theme (one ink on one ground) under the test font. Every state still
// reads from its shape: the error from its ✗, the checked box from its x,
// the chosen radio and the on switch from what a screen reader hears, the
// disabled save from its node.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/slipway.dart';

void main() {
  testWidgets('settings read without colour or a face', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 2000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      slipwayApp(
        Brightness.dark,
        place: SlipwayPlace.settings,
        theme: TermThemeData.monochrome(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    final theme = TermTheme.of(tester.element(find.byType(TermPane).first));
    expect(theme.accent, theme.foreground);
    expect(theme.danger, theme.foreground);

    // The invalid timeout says so in words, after a glyph.
    expect(find.text('✗ '), findsOneWidget);
    expect(find.text('a number and s, m or h: 90s, 30m, 2h'), findsOneWidget);

    // The checked box draws its x; a screen reader hears each state.
    expect(
      tester.getSemantics(find.byType(TermCheckbox).first),
      isSemantics(label: 'on_failure', hasCheckedState: true, isChecked: true),
    );
    expect(
      tester.getSemantics(find.byType(TermSwitch).first),
      isSemantics(label: 'auto_merge', hasToggledState: true, isToggled: true),
    );
    expect(
      tester.getSemantics(find.widgetWithText(TermButton, 'save')),
      isSemantics(
        label: 'save',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    semantics.dispose();
  });
}
