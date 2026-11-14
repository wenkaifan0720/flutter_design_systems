// The package emitter relocates these public example imports to example/lib.
// ignore_for_file: avoid_relative_lib_imports

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import '../example/lib/kit_gallery/demos/controls.dart';
import '../example/lib/kit_gallery/demos/entries.dart';
import '../example/lib/kit_gallery/demos/complete.dart';
import '../example/lib/kit_gallery/demos/chrome.dart';
import '../example/lib/kit_gallery/demos/charts.dart';
import '../example/lib/kit_gallery/demos/lists.dart';
import '../example/lib/kit_gallery/demos/raised.dart';
import '../example/lib/kit_gallery/demos/ordinary.dart';
import '../example/lib/kit_gallery/demos/papers.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      retroDesktopApp(SingleChildScrollView(child: child)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('example checkbox toggles', (tester) async {
    await pump(tester, kitSpecimenCheck());
    final box = find.byType(RetroDesktopCheckbox).first;
    expect(tester.widget<RetroDesktopCheckbox>(box).value, isTrue);
    await tap(tester, box);
    expect(tester.widget<RetroDesktopCheckbox>(box).value, isFalse);
  });
  testWidgets('example check row toggles', (tester) async {
    await pump(tester, kitSpecimenCheckRow());
    await tap(tester, find.text('Before something is due'));
    expect(
      tester
          .widget<RetroDesktopCheckRow>(find.byType(RetroDesktopCheckRow))
          .value,
      isFalse,
    );
  });
  testWidgets('example switch toggles', (tester) async {
    await pump(tester, kitSpecimenSwitch());
    await tap(tester, find.byType(RetroDesktopSwitch));
    expect(
      tester.widget<RetroDesktopSwitch>(find.byType(RetroDesktopSwitch)).value,
      isTrue,
    );
  });
  testWidgets('example switch row toggles', (tester) async {
    await pump(tester, kitSpecimenSwitchRow());
    await tap(tester, find.text('Keep a local copy'));
    expect(
      tester
          .widget<RetroDesktopSwitchRow>(find.byType(RetroDesktopSwitchRow))
          .value,
      isFalse,
    );
  });
  testWidgets('example radio group selects', (tester) async {
    await pump(tester, kitSpecimenRadioGroup());
    await tap(tester, find.text('Keep both files'));
    expect(
      tester
          .widget<RetroDesktopRadioGroup<String>>(
            find.byType(RetroDesktopRadioGroup<String>),
          )
          .value,
      'keep',
    );
  });
  testWidgets('example segments select', (tester) async {
    await pump(tester, kitSpecimenSegmentedButton());
    await tap(tester, find.text('Grid'));
    expect(
      tester
          .widget<RetroDesktopSegmentedButton<String>>(
            find.byType(RetroDesktopSegmentedButton<String>),
          )
          .value,
      'grid',
    );
  });
  testWidgets('example choices select', (tester) async {
    await pump(tester, kitSpecimenChoices());
    await tap(tester, find.text('Never'));
    expect(
      tester
          .widget<RetroDesktopChoices>(find.byType(RetroDesktopChoices))
          .value,
      'Never',
    );
  });
  testWidgets('example chip selects', (tester) async {
    await pump(tester, kitSpecimenChip());
    await tap(tester, find.text('All'));
    expect(
      tester
          .widget<RetroDesktopChip>(find.byType(RetroDesktopChip).first)
          .selected,
      isFalse,
    );
  });
  testWidgets('example stepper increments', (tester) async {
    await pump(tester, kitSpecimenStepper());
    await tap(tester, find.bySemanticsLabel('More'));
    expect(
      tester
          .widget<RetroDesktopNumberField>(find.byType(RetroDesktopNumberField))
          .value,
      3,
    );
  });
  testWidgets('example tabs switch their content', (tester) async {
    await pump(tester, kitSpecimenFolderTabs());
    await tap(tester, find.text('Soon'));
    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      tester
          .widget<RetroDesktopTabBar>(find.byType(RetroDesktopTabBar))
          .selectedIndex,
      1,
    );
  });
  for (final entry in <String, Widget Function()>{
    'drawer': kitSpecimenNavigationDrawer,
    'rail': kitSpecimenNavigationRail,
    'bar': kitSpecimenTabBar,
  }.entries) {
    testWidgets('example navigation ${entry.key} changes selection', (
      tester,
    ) async {
      await pump(tester, entry.value());
      await tap(
        tester,
        find.bySemanticsLabel(entry.key == 'bar' ? 'Places' : 'Settings').first,
      );
      final selected = entry.key == 'drawer'
          ? tester
                .widget<RetroDesktopNavigationDrawer>(
                  find.byType(RetroDesktopNavigationDrawer),
                )
                .selectedIndex
          : entry.key == 'rail'
          ? tester
                .widget<RetroDesktopNavigationRail>(
                  find.byType(RetroDesktopNavigationRail),
                )
                .selectedIndex
          : tester
                .widget<RetroDesktopNavigationBar>(
                  find.byType(RetroDesktopNavigationBar),
                )
                .selectedIndex;
      expect(selected, 1);
    });
  }
  testWidgets('example select opens and chooses', (tester) async {
    await pump(tester, kitSpecimenSelect());
    await tap(tester, find.text('This computer'));
    await tap(tester, find.text('File server'));
    expect(
      tester
          .widget<RetroDesktopSelect<String>>(
            find.byType(RetroDesktopSelect<String>),
          )
          .value,
      'server',
    );
  });
  testWidgets('example popup opens and chooses', (tester) async {
    await pump(tester, kitSpecimenPopup());
    await tap(tester, find.text('Pick one'));
    await tap(tester, find.text('Archive'));
    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('Pick one'), findsNothing);
  });
  testWidgets('example slider drags', (tester) async {
    await pump(tester, kitSpecimenSlider());
    final before = tester
        .widget<RetroDesktopSlider>(find.byType(RetroDesktopSlider))
        .value;
    await tester.drag(find.byType(RetroDesktopSlider), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(
      tester.widget<RetroDesktopSlider>(find.byType(RetroDesktopSlider)).value,
      greaterThan(before),
    );
  });
  testWidgets('example disclosure expands and collapses', (tester) async {
    await pump(tester, kitSpecimenDisclosure());
    await tap(tester, find.text('Versions'));
    expect(find.text('What it opens onto.'), findsNothing);
    await tap(tester, find.text('Versions'));
    expect(find.text('What it opens onto.'), findsOneWidget);
  });
  testWidgets('example date chooses a day', (tester) async {
    await pump(tester, kitSpecimenDatePicker());
    await tap(tester, find.text('12').first);
    expect(
      tester
          .widget<RetroDesktopDatePicker>(find.byType(RetroDesktopDatePicker))
          .value,
      DateTime(2026, 6, 12),
    );
  });
  testWidgets('example time chooses an hour', (tester) async {
    await pump(tester, kitSpecimenTimePicker());
    final before = tester
        .widget<RetroDesktopTimePicker>(find.byType(RetroDesktopTimePicker))
        .value;
    await tap(tester, find.text('03').first);
    await tap(tester, find.text('04').first);
    expect(
      tester
          .widget<RetroDesktopTimePicker>(find.byType(RetroDesktopTimePicker))
          .value,
      isNot(before),
    );
  });
  testWidgets('example month navigation works', (tester) async {
    await pump(tester, kitSpecimenMonthGrid());
    await tap(tester, find.bySemanticsLabel('Next month'));
    expect(
      tester
          .widget<RetroDesktopMonthGrid>(find.byType(RetroDesktopMonthGrid))
          .month,
      7,
    );
  });
  testWidgets('example text field accepts typing', (tester) async {
    await pump(tester, kitSpecimenTextBox());
    await tester.enterText(find.byType(EditableText).first, 'Project notes');
    expect(find.text('Project notes'), findsOneWidget);
  });
  testWidgets('example checklist updates its item', (tester) async {
    await pump(tester, kitSpecimenChecklist());
    await tap(tester, find.text('The step to take next'));
    expect(
      tester
          .widget<RetroDesktopChecklist>(find.byType(RetroDesktopChecklist))
          .items[1]
          .value,
      isTrue,
    );
  });
  testWidgets('example folders select', (tester) async {
    await pump(tester, kitSpecimenFolderGrid());
    await tap(tester, find.text('Second kind'));
    expect(
      tester
          .widget<RetroDesktopFolderGrid>(find.byType(RetroDesktopFolderGrid))
          .items[1]
          .selected,
      isTrue,
    );
  });
  testWidgets('example files select', (tester) async {
    await pump(tester, kitSpecimenFileGrid());
    await tap(tester, find.text('first-sheet.pdf'));
    expect(
      tester
          .widget<RetroDesktopFileGrid>(find.byType(RetroDesktopFileGrid))
          .items[0]
          .selected,
      isTrue,
    );
  });
  testWidgets('example surface selects', (tester) async {
    await pump(tester, kitSpecimenSurface());
    await tap(tester, find.text('A selectable surface'));
    expect(
      tester
          .widget<RetroDesktopSurface>(find.byType(RetroDesktopSurface))
          .selected,
      isTrue,
    );
  });
  testWidgets('example snack bar action dismisses and can reopen', (
    tester,
  ) async {
    await pump(tester, kitSpecimenSnackBar());
    await tap(tester, find.text('Undo'));
    expect(find.byType(RetroDesktopSnackBar), findsNothing);
    await tap(tester, find.text('Show snack bar'));
    expect(find.byType(RetroDesktopSnackBar), findsOneWidget);
  });
  testWidgets('example dialog closes and reopens', (tester) async {
    await pump(tester, kitSpecimenDialog());
    await tap(tester, find.text('Save'));
    expect(find.byType(RetroDesktopDialog), findsNothing);
    await tap(tester, find.text('Show dialog'));
    expect(find.byType(RetroDesktopDialog), findsOneWidget);
  });
  testWidgets('example sheet closes and reopens', (tester) async {
    await pump(tester, kitSpecimenBottomSheet());
    await tap(tester, find.text('Move here'));
    expect(find.byType(RetroDesktopBottomSheet), findsNothing);
    await tap(tester, find.text('Show sheet'));
    expect(find.byType(RetroDesktopBottomSheet), findsOneWidget);
  });
  testWidgets('ordinary tabs change actual content', (tester) async {
    await tester.pumpWidget(kitOrdinaryScreen('tabs', Brightness.light));
    await tester.pumpAndSettle();
    // Each tab is a list of its own documents: the shared ones replace the recent ones.
    final firstRecent = kitPapers.first.name;
    expect(find.text(firstRecent), findsOneWidget);
    expect(find.text('Team handbook'), findsNothing);
    await tap(tester, find.text('Shared'));
    expect(find.text('Team handbook'), findsOneWidget);
    expect(find.text('Shared by Morgan Kim'), findsOneWidget);
    expect(find.text(firstRecent), findsNothing);
  });
  testWidgets('gallery menu-bar destinations change their selected state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(kitOrdinaryScreen('list', Brightness.light));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Places'));
    expect(
      tester
          .widget<RetroDesktopChromeScope>(find.byType(RetroDesktopChromeScope))
          .active,
      1,
    );
  });
}
