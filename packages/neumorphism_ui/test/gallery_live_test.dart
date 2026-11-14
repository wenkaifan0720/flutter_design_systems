import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';
import 'package:neumorphism_ui/neumorphism_parts.dart' show NeumorphicChart;

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart' show hearthScreens;
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

/// The gallery on [page], through its own navigation, at a phone's width unless [width] says otherwise.
Future<void> pumpLive(
  WidgetTester tester,
  String page, {
  double width = 390,
  bool customizing = false,
}) async {
  tester.view.physicalSize = Size(width, width < 1024 ? 844 : 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    // A new key each time: a second pump opens its own page instead of keeping the first one's state.
    GalleryApp(
      key: UniqueKey(),
      initialPage: page,
      initialCustomizing: customizing,
    ),
  );
  await settle(tester);
}

/// What a live page builds, by class name, generic arguments dropped.
Set<String> builtWidgets(WidgetTester tester) => {
  for (final element
      in find.byWidgetPredicate((_) => true, skipOffstage: false).evaluate())
    element.widget.runtimeType.toString().split('<').first,
};

/// Every public widget class the package declares, as shape_family_test reads them.
Set<String> exportedWidgets() {
  final hidden = {'NeumorphicFill', 'NeumorphicMark', 'NeumorphicEngraved'};
  final declaration = RegExp(
    r'class\s+((?:Neumorphic|AnimatedNeumorphic)\w+)\s*(?:<[^\n]*?>)?\s+extends\s+(\w+)',
  );
  return {
    for (final file in Directory(
      'lib/src/neumorphism',
    ).listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        for (final match in declaration.allMatches(file.readAsStringSync()))
          if (!hidden.contains(match[1]) &&
              (match[2]!.contains('Widget') || match[2] == 'InheritedTheme'))
            match[1]!,
  };
}

Future<void> tapLive(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await settle(tester);
  await tester.tap(target);
  await settle(tester);
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });

  testWidgets('Hearth\'s account field accepts typing and saves its value', (
    tester,
  ) async {
    await pumpLive(tester, 'form');
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('hearth-email')),
        matching: find.byType(EditableText),
      ),
      'jamie@example.com',
    );
    await tapLive(tester, find.byKey(const Key('hearth-save')));
    expect(
      find.text('Saved. Your receipts go to jamie@example.com.'),
      findsOneWidget,
    );
  });
  testWidgets('Hearth\'s country select opens and selects', (tester) async {
    await pumpLive(tester, 'form');
    await tapLive(tester, find.byKey(const Key('hearth-country')));
    await tapLive(tester, find.text('Ireland').last);
    expect(
      tester
          .widget<NeumorphicSelect<String>>(
            find.byKey(const Key('hearth-country')),
          )
          .value,
      'Ireland',
    );
  });
  testWidgets('example text area accepts typing', (tester) async {
    await pumpLive(tester, 'fields');
    final field = find.descendant(
      of: find.byKey(const Key('live-notes')),
      matching: find.byType(EditableText),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Leave at reception');
    await tester.pump();
    expect(_answer('Notes: Leave at reception'), findsOneWidget);
  });
  testWidgets('example tabs change their content', (tester) async {
    await pumpLive(tester, 'navigation');
    await tapLive(tester, find.text('Activity'));
    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Project overview'), findsNothing);
  });
  for (final (key, initial) in [
    ('hearth-email-updates', true),
    ('hearth-usage', false),
  ]) {
    testWidgets('Hearth\'s $key toggles', (tester) async {
      await pumpLive(tester, 'settings');
      final control = find.byKey(Key(key));
      expect(tester.widget<NeumorphicSwitchRow>(control).value, initial);
      await tapLive(tester, control);
      expect(tester.widget<NeumorphicSwitchRow>(control).value, !initial);
    });
  }
  testWidgets('example slider drags', (tester) async {
    await pumpLive(tester, 'selection');
    final control = find.byKey(const Key('live-volume'));
    await tester.ensureVisible(control);
    await tester.drag(control, const Offset(75, 0));
    await settle(tester);
    expect(tester.widget<NeumorphicSlider>(control).value, greaterThan(.4));
  });
  testWidgets('example disclosure opens', (tester) async {
    await pumpLive(tester, 'lists');
    await tapLive(tester, find.text('Privacy'));
    expect(
      tester
          .widget<NeumorphicDisclosure>(
            find.byKey(const Key('live-disclosure')),
          )
          .expanded,
      isTrue,
    );
  });
  testWidgets('example checkbox changes state', (tester) async {
    await pumpLive(tester, 'selection');
    final control = find.byKey(const Key('live-check'));
    await tapLive(tester, control);
    expect(tester.widget<NeumorphicCheckbox>(control).value, isTrue);
  });
  testWidgets('example standalone switch toggles', (tester) async {
    await pumpLive(tester, 'selection');
    final control = find.byKey(const Key('live-switch'));
    await tapLive(tester, control);
    expect(tester.widget<NeumorphicSwitch>(control).value, isTrue);
  });
  testWidgets('example radio group chooses a value', (tester) async {
    await pumpLive(tester, 'selection');
    await tapLive(tester, find.text('Express'));
    expect(
      tester
          .widget<NeumorphicRadioGroup<String>>(
            find.byKey(const Key('live-radio')),
          )
          .value,
      'express',
    );
  });
  testWidgets('example segments choose a value', (tester) async {
    await pumpLive(tester, 'selection');
    await tapLive(tester, find.text('Yearly'));
    expect(
      tester
          .widget<NeumorphicSegmentedButton<String>>(
            find.byKey(const Key('live-segments')),
          )
          .value,
      'year',
    );
  });
  testWidgets('example latch bank selects', (tester) async {
    await pumpLive(tester, 'selection');
    await tapLive(tester, find.text('On'));
    expect(
      tester
          .widget<NeumorphicLatchGroup>(find.byKey(const Key('live-latches')))
          .value,
      'On',
    );
  });
  testWidgets('example chip selects', (tester) async {
    await pumpLive(tester, 'selection');
    final control = find.byKey(const Key('live-chip'));
    await tapLive(tester, control);
    expect(tester.widget<NeumorphicChip>(control).selected, isTrue);
  });
  testWidgets('example removable chip is removed', (tester) async {
    await pumpLive(tester, 'selection');
    final control = find.descendant(
      of: find.byKey(const Key('live-removable')),
      matching: find.byIcon(NeumorphicGlyphs.close),
    );
    await tapLive(tester, control);
    expect(find.byKey(const Key('live-removable')), findsNothing);
  });
  testWidgets('example icon button changes selection', (tester) async {
    await pumpLive(tester, 'buttons');
    final control = find.byKey(const Key('live-favourite'));
    await tapLive(tester, control);
    expect(tester.widget<NeumorphicIconButton>(control).selected, isTrue);
  });
  testWidgets('example stepper changes count', (tester) async {
    await pumpLive(tester, 'selection');
    final control = find.byKey(const Key('live-stepper'));
    await tapLive(
      tester,
      find
          .descendant(of: control, matching: find.byType(NeumorphicRoundButton))
          .last,
    );
    expect(tester.widget<NeumorphicNumberField>(control).value, '3');
  });
  testWidgets('example page dots select', (tester) async {
    await pumpLive(tester, 'navigation');
    final control = find.byKey(const Key('live-dots'));
    await tester.ensureVisible(control);
    final rect = tester.getRect(control);
    await tester.tapAt(Offset(rect.center.dx + 48, rect.center.dy));
    await settle(tester);
    expect(tester.widget<NeumorphicPageDots>(control).selectedIndex, 2);
  });
  testWidgets('example code field completes', (tester) async {
    await pumpLive(tester, 'fields');
    final field = find.descendant(
      of: find.byKey(const Key('live-code')),
      matching: find.byType(EditableText),
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, '1234');
    await tester.pump();
    expect(_answer('Code 1234 entered'), findsOneWidget);
  });
  testWidgets('example date picker chooses', (tester) async {
    await pumpLive(tester, 'pickers');
    await tapLive(tester, find.byKey(const Key('live-date')));
    // The page's own calendar shows the month too: the sheet's day is the last one built.
    await tapLive(tester, find.text('15').last);
    await tapLive(tester, find.text('Choose'));
    expect(
      tester.widget<NeumorphicButton>(find.byKey(const Key('live-date'))).label,
      '11/15/2026',
    );
  });
  testWidgets('example time picker chooses', (tester) async {
    await pumpLive(tester, 'pickers');
    await tapLive(tester, find.byKey(const Key('live-time')));
    await tapLive(tester, find.text('11').last);
    await tapLive(tester, find.text('Choose'));
    expect(
      tester.widget<NeumorphicButton>(find.byKey(const Key('live-time'))).label,
      '11:00',
    );
  });
  testWidgets('example menu chooses', (tester) async {
    await pumpLive(tester, 'dialogs');
    await tapLive(tester, find.text('More actions'));
    await tapLive(tester, find.text('Archive'));
    expect(_answer('Item archived'), findsOneWidget);
  });
  testWidgets('example sheet opens and closes', (tester) async {
    await pumpLive(tester, 'dialogs');
    await tapLive(tester, find.text('Open a sheet'));
    expect(find.text('How can we help?'), findsOneWidget);
    await tapLive(tester, find.text('Got it'));
    expect(find.text('How can we help?'), findsNothing);
  });
  testWidgets('example dialog returns a result', (tester) async {
    await pumpLive(tester, 'dialogs');
    await tapLive(tester, find.text('Open dialog'));
    await tapLive(tester, find.text('Save changes').last);
    expect(_answer('Changes saved'), findsOneWidget);
  });
  testWidgets('Hearth\'s devices search and open a row beside the list', (
    tester,
  ) async {
    await pumpLive(tester, 'list', width: 1440);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('hearth-search')),
        matching: find.byType(EditableText),
      ),
      'kitchen',
    );
    await settle(tester);
    expect(find.byKey(const Key('hearth-device-floor-lamp')), findsNothing);
    await tapLive(tester, find.byKey(const Key('hearth-device-pendants')));
    expect(find.byKey(const Key('hearth-detail-pendants')), findsOneWidget);
  });
  testWidgets('example cards open', (tester) async {
    await pumpLive(tester, 'cards');
    await tapLive(tester, find.text('Open Team'));
    expect(_answer('Team opened'), findsOneWidget);
  });
  testWidgets('example dialog cancel preserves the prior decision', (
    tester,
  ) async {
    await pumpLive(tester, 'dialogs');
    await tapLive(tester, find.text('Weekly summary'));
    expect(
      tester
          .widget<NeumorphicSwitchRow>(find.byType(NeumorphicSwitchRow))
          .value,
      isFalse,
    );
    await tapLive(tester, find.text('Open dialog'));
    await tapLive(tester, find.text('Cancel'));
    expect(_answer('Changes kept as they were'), findsOneWidget);
  });
  testWidgets('example snackbar appears from its action', (tester) async {
    await pumpLive(tester, 'dialogs');
    await tapLive(tester, find.text('Show message'));
    expect(find.text('Your changes are saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await settle(tester);
    expect(find.text('Your changes are saved'), findsNothing);
  });
  testWidgets('example help reveals its tooltip on hover', (tester) async {
    await pumpLive(tester, 'dialogs');
    final help = find.text('Get help');
    await tester.ensureVisible(help);
    await settle(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(help));
    await tester.pump(const Duration(seconds: 1));
    await settle(tester);
    expect(find.text('This link opens the help panel'), findsOneWidget);
    await mouse.removePointer();
    await settle(tester);
  });
  Future<void> openCustomize(WidgetTester tester) async {
    await tapLive(tester, find.byKey(const Key('gallery-customize-key')));
    expect(find.byType(CustomizePanel), findsOneWidget);
  }

  GalleryCustom panel(WidgetTester tester) =>
      tester.widget<CustomizePanel>(find.byType(CustomizePanel)).custom;

  testWidgets('example custom palette selector changes the theme', (
    tester,
  ) async {
    await pumpLive(tester, 'fields');
    await openCustomize(tester);
    final palette = find.byWidgetPredicate(
      (widget) =>
          widget is NeumorphicSelect<String> &&
          widget.label == 'Your own colours',
    );
    await tapLive(tester, palette);
    await tapLive(tester, find.text('Clay and blue'));
    expect(panel(tester).colours?.name, 'Clay and blue');
  });
  testWidgets('the phone moves between pages through its drawer', (
    tester,
  ) async {
    await pumpLive(tester, 'overview');
    // No page picker: the menu key opens the look's drawer, which names every page.
    expect(
      find.byWidgetPredicate(
        (w) => w is NeumorphicSelect<String> && w.label == 'Page',
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
    expect(_answer('Files opened'), findsOneWidget);
  });
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
  testWidgets('a wide window moves between pages on the rail', (tester) async {
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
  });
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
      (widget) => widget is NeumorphicSelect<String> && widget.label == label,
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
              (w) => w is NeumorphicSelect<String> && w.label == 'Preset',
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

  // polish3 §4: a widget the package exports and no live page builds is a widget the user can't find.
  testWidgets('every exported widget is live on some page', (tester) async {
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
    // Not a part of an app's screen: the catalog's preview frame.
    final notOnAPage = {'$NeumorphicPreview'};
    expect(
      exportedWidgets().difference(seen).difference(notOnAPage),
      isEmpty,
      reason: 'each of these needs a live page that builds it',
    );
    expect(exportedWidgets(), containsAll(notOnAPage));
  });
}

/// The page's answer, as drawn: what the last part tried said, in the status under the page.
Finder _answer(String words) => find.descendant(
  of: find.byKey(const Key('live-status')),
  matching: find.text(words),
);
