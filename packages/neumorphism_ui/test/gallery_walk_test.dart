// The gallery walked as a reader walks it: the phone's drawer and the desk's rail, the Overview's tour, a preset and
// the appearance across every page, the Customize panel, and every widget the package exports live on some page. The
// parts' own examples are gallery_live_test's.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:neumorphism_ui/neumorphism_parts.dart' show NeumorphicChart;

// ignore_for_file: avoid_relative_lib_imports — the gallery under test is the example app, not a package dependency.
import '../example/lib/main.dart';
import '../example/lib/kit_gallery/live.dart';
import '../example/lib/kit_gallery/hearth.dart' show hearthScreens;
import 'flutter_test_config.dart' show longWalkLeakTesting;
import 'gallery_live_test.dart'
    show
        builtWidgets,
        exportedWidgets,
        liveAnswer,
        openCustomize,
        panel,
        pumpLive,
        tapLive;
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  testWidgets(
    'the phone moves between pages through its drawer',
    (tester) async {
      await pumpLive(tester, 'overview');
      // No page picker: the menu key opens the look's drawer, which names every page.
      expect(
        find.byWidgetPredicate(
          (w) => w is NeumorphicSelect<String> && w.labelText == 'Page',
        ),
        findsNothing,
      );
      await tapLive(tester, find.byKey(const Key('gallery-menu')));
      final drawer = find.byKey(const Key('gallery-drawer'));
      expect(drawer, findsOneWidget);
      for (final page in liveGalleryPages) {
        expect(
          find.descendant(of: drawer, matching: find.text(page.title)),
          findsOneWidget,
        );
      }
      await tapLive(
        tester,
        find.descendant(of: drawer, matching: find.text('Navigation')),
      );
      expect(drawer, findsNothing);
      expect(find.text('Project overview'), findsOneWidget);
      await tapLive(tester, find.text('Files'));
      await tapLive(tester, find.text('Open files'));
      expect(liveAnswer('Files opened'), findsOneWidget);
    },
    // A walk of the whole gallery in one go: ui_core's long-walk setting, each part tracked in its own tests.
    experimentalLeakTesting: longWalkLeakTesting,
  );
  testWidgets('the drawer closes on its scrim and keeps the page', (
    tester,
  ) async {
    await pumpLive(tester, 'charts');
    await tapLive(tester, find.byKey(const Key('gallery-menu')));
    await tester.tapAt(const Offset(380, 400));
    await settle(tester);
    expect(find.byKey(const Key('gallery-drawer')), findsNothing);
    expect(find.byType(NeumorphicChart), findsOneWidget);
  });
  testWidgets(
    'a wide window moves between pages on the rail',
    (tester) async {
      await pumpLive(tester, 'overview', width: 1440);
      expect(find.byKey(const Key('gallery-menu')), findsNothing);
      for (final page in liveGalleryPages) {
        expect(find.byKey(Key('nav-${page.id}')), findsOneWidget);
      }
      await tapLive(tester, find.byKey(const Key('nav-charts')));
      expect(find.byType(NeumorphicChart), findsOneWidget);
      await tapLive(tester, find.text('Night'));
      expect(
        NeumorphicTheme.of(tester.element(find.byType(NeumorphicChart)))
            .colors
            .dark,
        isTrue,
      );
      await tapLive(tester, find.byKey(const Key('gallery-customize')));
      expect(find.byType(CustomizePanel), findsOneWidget);
      // The app opens from the rail, and keeps the night.
      await tapLive(tester, find.byKey(const Key('nav-home')));
      expect(find.byKey(const Key('hearth-home')), findsOneWidget);
      expect(
        NeumorphicTheme.of(tester.element(find.byKey(const Key('hearth-home'))))
            .colors
            .dark,
        isTrue,
      );
    },
    // A walk of the whole gallery in one go: ui_core's long-walk setting, each part tracked in its own tests.
    experimentalLeakTesting: longWalkLeakTesting,
  );
  testWidgets('the Overview tour opens a page', (tester) async {
    await pumpLive(tester, 'overview');
    await tapLive(tester, find.text('Pickers'));
    expect(find.text('Autocomplete'), findsOneWidget);
  });
  testWidgets('example preset and appearance change every page', (
    tester,
  ) async {
    await pumpLive(tester, 'navigation');
    await openCustomize(tester);
    Finder select(String label) => find.byWidgetPredicate(
      (widget) =>
          widget is NeumorphicSelect<String> && widget.labelText == label,
    );
    await tapLive(tester, select('Preset'));
    await tapLive(tester, find.text('Siena'));
    expect(
      tester.widget<NeumorphicSelect<String>>(select('Preset')).value,
      'siena',
    );
    await tapLive(tester, find.byKey(const Key('gallery-brightness')));
    expect(
      NeumorphicTheme.of(tester.element(find.text('Project overview')))
          .colors
          .dark,
      isTrue,
    );
  });
  testWidgets('the Customize panel keeps its controls at their own widths', (
    tester,
  ) async {
    await pumpLive(tester, 'fields', width: 1440, customizing: true);
    final relief = find.byWidgetPredicate(
      (w) => w is NeumorphicSegmentedButton && w.label == 'Relief',
    );
    final density = find.byWidgetPredicate(
      (w) => w is NeumorphicSegmentedButton && w.label == 'Density',
    );
    // A two-choice control is not the panel's width at 1440, and the knobs start at the panel's left.
    expect(tester.getSize(relief).width, lessThanOrEqualTo(260));
    expect(tester.getSize(density).width, lessThanOrEqualTo(400));
    final left = tester.getTopLeft(find.byKey(const Key('customize-knobs'))).dx;
    expect(
      tester
          .getTopLeft(
            find.byWidgetPredicate(
              (w) => w is NeumorphicSelect<String> && w.labelText == 'Preset',
            ),
          )
          .dx,
      closeTo(left, .5),
    );
  });
  testWidgets('example customization turns high contrast on', (tester) async {
    await pumpLive(tester, 'fields');
    await openCustomize(tester);
    await tapLive(tester, find.text('High contrast'));
    expect(panel(tester).highContrast, isTrue);
    await tapLive(tester, find.text('Done'));
    expect(find.byType(CustomizePanel), findsNothing);
  });
  testWidgets('example keeps a chosen state when appearance changes', (
    tester,
  ) async {
    await pumpLive(tester, 'selection');
    final push = find.byKey(const Key('live-switch'));
    await tapLive(tester, push);
    expect(tester.widget<NeumorphicSwitch>(push).value, isTrue);
    await tapLive(tester, find.byKey(const Key('gallery-brightness')));
    expect(tester.widget<NeumorphicSwitch>(push).value, isTrue);
    expect(NeumorphicTheme.of(tester.element(push)).colors.dark, isTrue);
  });
  for (final (label, choice) in [
    ('Density', 'Standard'),
    ('Density', 'Compact'),
    ('Relief', 'Low'),
  ]) {
    testWidgets('example customization $label selects $choice', (tester) async {
      await pumpLive(tester, 'fields');
      await openCustomize(tester);
      await tapLive(tester, find.text(choice));
      final custom = panel(tester);
      expect(switch (label) {
        'Density' => custom.density.label == choice,
        _ => custom.depth == .5,
      }, isTrue);
    });
  }

  // A widget the package exports and no live page builds is a widget a developer can't find.
  testWidgets(
    'every exported widget is live on some page',
    (tester) async {
      final seen = <String>{};
      // The gallery's pages and each of Hearth's screens, on a desk and on a phone.
      for (final width in [1440.0, 390.0]) {
        for (final id in {
          for (final page in liveGalleryPages) page.id,
          for (final screen in hearthScreens) screen.id,
        }) {
          await pumpLive(tester, id, width: width);
          seen.addAll(builtWidgets(tester));
        }
      }
      // What opens on a press is live too: the phone's drawer, the dialog, the sheet, a field's selection menu.
      await pumpLive(tester, 'dialogs');
      await tapLive(tester, find.byKey(const Key('gallery-menu')));
      seen.addAll(builtWidgets(tester));
      await tester.tapAt(const Offset(380, 400));
      await settle(tester);
      await tapLive(tester, find.text('Open dialog'));
      seen.addAll(builtWidgets(tester));
      await tapLive(tester, find.text('Cancel'));
      await tapLive(tester, find.text('Open a sheet'));
      seen.addAll(builtWidgets(tester));
      await tapLive(tester, find.text('Got it'));
      await pumpLive(tester, 'form');
      await tester.longPress(
        find.descendant(
          of: find.byKey(const Key('hearth-first')),
          matching: find.byType(EditableText),
        ),
      );
      await settle(tester);
      seen.addAll(builtWidgets(tester));
      // Saving an email that is not one puts its error under the field.
      await pumpLive(tester, 'form');
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('hearth-email')),
          matching: find.byType(EditableText),
        ),
        'alex.morgan',
      );
      await tapLive(tester, find.byKey(const Key('hearth-save')));
      expect(
        find.text('Enter an email address, like name@example.com.'),
        findsOneWidget,
      );
      seen.addAll(builtWidgets(tester));
      // The Feedback page's states, one at a time through its own control.
      await pumpLive(tester, 'feedback');
      for (final state in ['Loading', 'Empty', 'Error']) {
        await tapLive(
          tester,
          find.descendant(
            of: find.byType(NeumorphicSegmentedButton<String>),
            matching: find.text(state),
          ),
        );
        seen.addAll(builtWidgets(tester));
      }
      // The Charts page's kinds, each its own class, through its own control.
      await pumpLive(tester, 'charts');
      for (final kind in ['Bar', 'Area']) {
        await tapLive(
          tester,
          find.descendant(
            of: find.byType(NeumorphicSegmentedButton<LiveChartKind>),
            matching: find.text(kind),
          ),
        );
        seen.addAll(builtWidgets(tester));
      }
      // The overlays page's side sheet opens from its button.
      await pumpLive(tester, 'overlays');
      await tapLive(tester, find.text('Filters'));
      seen.addAll(builtWidgets(tester));
      await tapLive(tester, find.text('Show 12 rooms'));
      // Not a part of an app's screen: the gallery's preview frame.
      final notOnAPage = {'$NeumorphicPreview'};
      expect(
        exportedWidgets().difference(seen).difference(notOnAPage),
        isEmpty,
        reason: 'each of these needs a live page that builds it',
      );
      expect(exportedWidgets(), containsAll(notOnAPage));
    },
    // A walk of the whole gallery in one go: ui_core's long-walk setting, each part tracked in its own tests.
    experimentalLeakTesting: longWalkLeakTesting,
  );
}
