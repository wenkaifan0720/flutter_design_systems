import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
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

/// The Customize panel, opened from its key.
Future<void> openCustomize(WidgetTester tester) async {
  await tapLive(tester, find.byKey(const Key('gallery-customize-key')));
  expect(find.byType(CustomizePanel), findsOneWidget);
}

/// What the Customize panel has chosen.
GalleryCustom panel(WidgetTester tester) =>
    tester.widget<CustomizePanel>(find.byType(CustomizePanel)).custom;

// The gallery's walks (its navigation, the tour, the presets, the Customize panel, every exported widget live on a page)
// are gallery_walk_test's: two files, so neither is the suite's long pole.
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
    expect(liveAnswer('Notes: Leave at reception'), findsOneWidget);
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
    expect(liveAnswer('Code 1234 entered'), findsOneWidget);
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
    expect(liveAnswer('Item archived'), findsOneWidget);
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
    expect(liveAnswer('Changes saved'), findsOneWidget);
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
    expect(liveAnswer('Team opened'), findsOneWidget);
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
    expect(liveAnswer('Changes kept as they were'), findsOneWidget);
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
}

/// The page's answer, as drawn: what the last part tried said, in the status under the page.
Finder liveAnswer(String words) => find.descendant(
  of: find.byKey(const Key('live-status')),
  matching: find.text(words),
);
