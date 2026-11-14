// Every callback-bearing part must keep a keyboard path. New parts cannot silently
// bypass this table; value models are exercised through their public parent.
import 'dart:io';
import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

typedef _Build = Widget Function(VoidCallback? hit);
final _parts = <String, _Build>{
  // A cluster with a press opens the people behind it: one button, as a lone avatar with a press is.
  'NeumorphicAvatarGroup': (hit) => NeumorphicAvatarGroup(
    const [
      NeumorphicFace('NW', name: 'Nia Walker'),
      NeumorphicFace('AK', name: 'Amir Khan'),
    ],
    label: 'People',
    onPressed: hit,
  ),
  // An action of a split button's menu, reached from the button.
  'NeumorphicSplitAction': (hit) => NeumorphicSplitButton(
    'Start',
    onPressed: () {},
    actions: [NeumorphicSplitAction('Later', onPressed: hit)],
  ),
  'NeumorphicBanner': (hit) => NeumorphicBanner('Saved', onDismiss: hit),
  'NeumorphicDisclosure': (hit) => NeumorphicDisclosure(
    title: 'Details',
    expanded: false,
    onExpansionChanged: hit == null ? null : (_) => hit(),
    child: const Text('More'),
  ),
  'NeumorphicTableRow': (hit) => NeumorphicTable(
    columns: const [NeumorphicTableColumn('Name')],
    rows: [
      NeumorphicTableRow(['Room'], onPressed: hit),
    ],
  ),
  'NeumorphicNavigationDrawer': (hit) => NeumorphicNavigationDrawer(
    items: const [
      NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
    ],
    onDestinationSelected: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicTabBar': (hit) => NeumorphicTabBar(
    tabs: const ['Overview'],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicPageDots': (hit) => NeumorphicPageDots(
    count: 1,
    selectedIndex: 0,
    label: 'Introduction',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicDatePicker': (hit) => NeumorphicDatePicker(
    value: DateTime(2026, 11, 6),
    first: DateTime(2026, 11, 6),
    last: DateTime(2026, 11, 6),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicTimePicker': (hit) => NeumorphicTimePicker(
    value: const NeumorphicTime(0, 0),
    twentyFour: true,
    minuteStep: 30,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicIconButton': (hit) =>
      NeumorphicIconButton(NeumorphicGlyphs.plus, label: 'Add', onPressed: hit),
  'NeumorphicSearchField': (hit) => NeumorphicSearchField(
    hint: 'Search',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicTextArea': (hit) => NeumorphicTextArea(
    label: 'Notes',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicInputOtp': (hit) => NeumorphicInputOtp(
    label: 'Code',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicSelect': (hit) => NeumorphicSelect<String>(
    label: 'Space',
    options: const [NeumorphicMenuItem('room', 'Room')],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicCheckbox': (hit) => NeumorphicCheckbox(
    value: false,
    label: 'Agree',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicCheckRow': (hit) => NeumorphicCheckRow(
    value: false,
    label: 'Agree',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicRadioGroup': (hit) => NeumorphicRadioGroup<String>(
    label: 'Space',
    options: const [NeumorphicRadio('room', 'Room')],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicSegmentedButton': (hit) => NeumorphicSegmentedButton<String>(
    label: 'Period',
    segments: const [NeumorphicButtonSegment('day', 'Day')],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicBottomSheet': (hit) => SizedBox(
    height: 300,
    child: NeumorphicBottomSheet(
      title: 'Options',
      onClose: hit,
      child: const Text('Choose'),
    ),
  ),
  'NeumorphicMenu': (hit) => NeumorphicMenu<String>(
    autofocus: false,
    items: const [NeumorphicMenuItem('copy', 'Copy')],
    onSelected: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicSnackBar': (hit) =>
      NeumorphicSnackBar('Saved', actionLabel: 'Undo', onAction: hit),
  'NeumorphicTap': (hit) =>
      NeumorphicTap(onPressed: hit, child: const Text('Open')),
  'NeumorphicLink': (hit) => NeumorphicLink('Open', onPressed: hit),
  'NeumorphicRoundButton': (hit) =>
      NeumorphicRoundButton(Icons.add, label: 'Add', onPressed: hit),
  'NeumorphicChip': (hit) => NeumorphicChip('All', onPressed: hit),
  'NeumorphicLatchGroup': (hit) => NeumorphicLatchGroup(
    options: const [NeumorphicLatch('Day'), NeumorphicLatch('Week')],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicTextField': (hit) =>
      NeumorphicTextField(onChanged: hit == null ? null : (_) => hit()),
  'NeumorphicSendButton': (hit) => NeumorphicSendButton(onPressed: hit),
  'NeumorphicSelectField': (hit) =>
      NeumorphicSelectField(value: 'Town', onPressed: hit),
  'NeumorphicChoiceBox': (hit) =>
      NeumorphicChoiceBox(onPressed: hit, child: const Text('One')),
  'NeumorphicChoices': (hit) => NeumorphicChoices(
    options: const [NeumorphicChoice('One')],
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicNumberField': (hit) =>
      NeumorphicNumberField(value: '2', onDecrease: hit, onIncrease: hit),
  'NeumorphicSwitch': (hit) => NeumorphicSwitch(
    value: false,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicSwitchRow': (hit) => NeumorphicSwitchRow(
    label: 'Enabled',
    value: false,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicSlider': (hit) => NeumorphicSlider(
    label: 'Level',
    value: .5,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicRoundCheckbox': (hit) =>
      NeumorphicRoundCheckbox(onChanged: hit == null ? null : (_) => hit()),
  'NeumorphicListTile': (hit) =>
      NeumorphicListTile(title: 'Open', onPressed: hit),
  'NeumorphicTodoRow': (hit) => NeumorphicTodoRow(
    title: 'Task',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicLevelRow': (hit) => NeumorphicLevelRow(
    icon: Icons.light,
    title: 'Lamp',
    state: 'Off',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicNavigationBar': (hit) => NeumorphicNavigationBar(
    items: const [NeumorphicNavItem(label: 'Home', icon: Icons.home)],
    onDestinationSelected: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicNavItem': (hit) => NeumorphicNavigationBar(
    items: [NeumorphicNavItem(label: 'Home', icon: Icons.home, onPressed: hit)],
  ),
  'NeumorphicRailLink': (hit) =>
      NeumorphicRailLink(label: 'Home', onPressed: hit),
  'NeumorphicBackButton': (hit) => NeumorphicBackButton(onPressed: hit),
  'NeumorphicButton': (hit) => NeumorphicButton('Save', onPressed: hit),
  'NeumorphicInput': (hit) =>
      NeumorphicInput(onChanged: hit == null ? null : (_) => hit()),
  'NeumorphicPictureCard': (hit) =>
      NeumorphicPictureCard(glyph: Icons.photo, title: 'Photo', onPressed: hit),
  'NeumorphicErrorState': (hit) =>
      NeumorphicErrorState(title: 'Failed', onRetry: hit),
  'NeumorphicBay': (hit) => NeumorphicRelief(
    title: 'House',
    courses: [
      NeumorphicCourse('Floor', [NeumorphicBay(name: 'Room', onPressed: hit)]),
    ],
  ),
  'NeumorphicRelief': (hit) =>
      NeumorphicRelief(title: 'House', compact: true, onPressed: hit),
  'NeumorphicTrayEvent': (hit) => NeumorphicDayTray(
    from: 9,
    to: 10,
    events: [
      NeumorphicTrayEvent(
        start: '09:00',
        end: '10:00',
        title: 'Meet',
        onPressed: hit,
      ),
    ],
  ),
  'NeumorphicMonth': (hit) => NeumorphicMonth(
    year: 2026,
    month: 11,
    onDay: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicPush': (hit) => NeumorphicPushGroup(
    items: [NeumorphicPush(icon: Icons.sunny, label: 'Day', onPressed: hit)],
  ),
  'NeumorphicDial': (hit) => NeumorphicDial(
    value: 40,
    figure: '40',
    compact: true,
    onDecrease: hit,
    onIncrease: hit,
  ),
  'NeumorphicPagination': (hit) => NeumorphicPagination(
    count: 5,
    page: 1,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicCrumb': (hit) => NeumorphicBreadcrumb(
    crumbs: [
      NeumorphicCrumb('Home', onPressed: hit),
      const NeumorphicCrumb('Kitchen'),
    ],
  ),
  'NeumorphicCarouselView': (hit) => NeumorphicCarouselView(
    label: 'Rooms',
    height: 80,
    onChanged: hit == null ? null : (_) => hit(),
    children: const [Text('One'), Text('Two'), Text('Three')],
  ),
  'NeumorphicRating': (hit) => NeumorphicRating(
    label: 'Rating',
    value: 0,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicButtonGroupItem': (hit) => NeumorphicButtonGroup(
    label: 'Days',
    items: [NeumorphicButtonGroupItem('Today', onPressed: hit)],
  ),
  'NeumorphicSplitButton': (hit) => NeumorphicSplitButton(
    'Start',
    onPressed: hit,
    actions: [NeumorphicSplitAction('Later', onPressed: () {})],
  ),
  'NeumorphicNavigationRail': (hit) => SizedBox(
    height: 300,
    child: NeumorphicNavigationRail(
      items: const [
        NeumorphicNavItem(label: 'Home', icon: NeumorphicGlyphs.house),
        NeumorphicNavItem(label: 'Rooms', icon: NeumorphicGlyphs.lamp),
      ],
      selectedIndex: 1,
      onDestinationSelected: hit == null ? null : (_) => hit(),
    ),
  ),
  // A side sheet stands the height of the screen it opens on.
  'NeumorphicSheet': (hit) => SizedBox(
    height: 400,
    child: NeumorphicSheet(
      title: 'Filters',
      onClose: hit,
      child: const Text('Warm white'),
    ),
  ),
  'NeumorphicStatusView': (hit) => NeumorphicStatusView(
    status: NeumorphicStatusKind.error,
    title: 'Could not load',
    actionLabel: 'Try again',
    onAction: hit,
  ),
  'NeumorphicActionSheet': (hit) => NeumorphicActionSheet<String>(
    actions: const [],
    onSelected: (_) {},
    onCancel: hit,
  ),
  'NeumorphicPasswordField': (hit) => NeumorphicPasswordField(
    label: 'Password',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicInputGroup': (hit) => NeumorphicInputGroup(
    label: 'Site',
    prefix: 'https://',
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicCombobox': (hit) => NeumorphicCombobox<String>(
    label: 'Room',
    options: const ['Bedroom', 'Study'],
    onSelected: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicCommand': (hit) => NeumorphicCommand(
    commands: const [DesignCommand(label: 'New scene')],
    onRun: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicRangeSlider': (hit) => NeumorphicRangeSlider(
    label: 'Comfort',
    values: const DesignRangeValues(.2, .8),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicWheelPicker': (hit) => NeumorphicWheelPicker<int>(
    label: 'Lamps',
    items: const [1, 2, 3],
    value: 2,
    rows: 3,
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicResizable': (hit) => SizedBox(
    height: 160,
    child: NeumorphicResizable(
      first: const Text('Rooms'),
      second: const Text('Bedroom'),
      onChanged: hit == null ? null : (_) => hit(),
    ),
  ),
  'NeumorphicCalendar': (hit) => NeumorphicCalendar(
    controller: DesignCalendarController(
      firstDate: DateTime(2026, 6),
      lastDate: DateTime(2026, 6, 30),
      currentDate: DateTime(2026, 6, 10),
    ),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicDateRangePicker': (hit) => NeumorphicDateRangePicker(
    controller: DesignCalendarController(
      firstDate: DateTime(2026, 6),
      lastDate: DateTime(2026, 6, 30),
      mode: DesignCalendarMode.range,
      currentDate: DateTime(2026, 6, 10),
    ),
    onChanged: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicDataTable': (hit) => NeumorphicDataTable<String>(
    label: 'Rooms',
    controller: DesignTableController<String>(
      rows: const ['Bedroom'],
      columns: [DesignTableColumn<String>(id: 'room', label: 'Room')],
    ),
    cell: (row, column) => row,
    onActivate: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicTreeView': (hit) => NeumorphicTreeView<String>(
    label: 'Rooms',
    controller: DesignTreeController<String>(
      roots: const ['Bedroom'],
      childrenOf: (_) => const [],
    ),
    labelOf: (node) => node,
    onActivate: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicFileUpload': (hit) => NeumorphicFileUpload(
    onPressed: hit,
    onRemove: hit == null ? null : (_) => hit(),
  ),
  'NeumorphicGauge': (hit) =>
      NeumorphicGauge(value: 40, figure: '40', name: 'Level', onPressed: hit),
};

/// Parts whose keyboard path is ui_core's own rather than a pressable's Enter and Space: after the first Tab, each drive
/// walks its path and checks [count] itself.
typedef _Drive = Future<void> Function(
  WidgetTester tester,
  int Function() count,
);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

/// Tab along until [key] acts (a month's buttons and a table's head come before the day or row that answers).
_Drive _tabUntil(LogicalKeyboardKey key, {int tabs = 8}) =>
    (tester, count) async {
      for (var i = 0; i < tabs && count() == 0; i++) {
        if (i > 0) await _key(tester, LogicalKeyboardKey.tab);
        await _key(tester, key);
      }
      expect(count(), greaterThanOrEqualTo(1));
    };

Future<void> _typeThenEnter(WidgetTester tester, int Function() count) async {
  expect(
    tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
    isTrue,
  );
  await tester.enterText(find.byType(EditableText), 'B');
  await tester.pumpAndSettle();
  // Enter on a field reaches it as the keyboard's done action.
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
  expect(count(), 1);
}

final _drives = <String, _Drive>{
  // Down on the focused half opens the menu at its first action; Enter runs it.
  'NeumorphicSplitAction': (tester, count) async {
    await _key(tester, LogicalKeyboardKey.arrowDown);
    await _key(tester, LogicalKeyboardKey.enter);
    expect(count(), 1);
  },
  // A choice from the list: words narrow it, Enter takes the highlighted option.
  'NeumorphicCombobox': _typeThenEnter,
  // Its rows are pressed in where the keyboard is, as the look's menus are, rather than lifted.
  'NeumorphicActionSheet': (tester, count) async {
    await _key(tester, LogicalKeyboardKey.enter);
    expect(count(), 1);
    await _key(tester, LogicalKeyboardKey.space);
    expect(count(), 2);
  },
  // The palette's field has the focus; Enter runs the highlighted command.
  'NeumorphicCommand': (tester, count) async {
    await _key(tester, LogicalKeyboardKey.enter);
    expect(count(), 1);
  },
  // Handles and wheels move by the arrows.
  'NeumorphicRangeSlider': _tabUntil(LogicalKeyboardKey.arrowRight),
  'NeumorphicWheelPicker': _tabUntil(LogicalKeyboardKey.arrowDown),
  'NeumorphicResizable': _tabUntil(LogicalKeyboardKey.arrowRight),
  // The keyboard's day: Enter picks it, and so does Space.
  'NeumorphicCalendar': (tester, count) async {
    await _tabUntil(LogicalKeyboardKey.enter)(tester, count);
    final picked = count();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.space);
    expect(count(), picked + 1);
  },
  'NeumorphicDateRangePicker': _tabUntil(LogicalKeyboardKey.enter),
  // A row: Enter opens it (Space chooses it).
  'NeumorphicDataTable': _tabUntil(LogicalKeyboardKey.enter),
  'NeumorphicTreeView': _tabUntil(LogicalKeyboardKey.enter),
};

/// Parts with no pressable target of their own: a handle, a wheel, a groove between panes.
const _noPressable = {
  'NeumorphicRangeSlider',
  'NeumorphicWheelPicker',
  'NeumorphicResizable',
};

Set<String> _interactive() {
  final cls = RegExp(
    r'^class (Neumorphic\w+)[^{]*\{(.*?)^\}',
    multiLine: true,
    dotAll: true,
  );
  final callback = RegExp(
    r'final (?:VoidCallback|ValueChanged<[^>]+>|void Function\([^)]*\))\? \w+',
  );
  return {
    for (final file in Directory(
      'lib/src/neumorphism',
    ).listSync(recursive: true).whereType<File>())
      if (file.path.endsWith('.dart'))
        for (final match in cls.allMatches(file.readAsStringSync()))
          if (callback.hasMatch(match[2]!)) match[1]!,
  };
}

void main() {
  setUpAll(loadNeumorphicFonts);
  test('every callback-bearing part is covered by the interaction table', () {
    expect(_interactive(), _parts.keys.toSet());
  });
  test('raw gestures only read control positions or handle sheet drag and tooltip hold', () {
    for (final file in Directory(
      'lib/src/neumorphism',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final count = 'GestureDetector('
          .allMatches(file.readAsStringSync())
          .length;
      expect(
        count,
        file.path.endsWith('/controls.dart')
            ? 1
            // Compact page dots use tap position to move backward or forward;
            // their enclosing NeumorphicTap still owns focus and keyboard input.
            : file.path.endsWith('/moves.dart')
            ? 1
            : file.path.endsWith('/raised.dart')
            ? 2
            // A press on a field's padding, off its text, focuses the text, as a Material field's decorator does.
            : file.path.endsWith('/text_entry.dart')
            ? 1
            : 0,
        reason: file.path,
      );
    }
  });
  for (final MapEntry(key: name, value: build) in _parts.entries) {
    final text = {
      'NeumorphicInput',
      'NeumorphicTextField',
      'NeumorphicSearchField',
      'NeumorphicTextArea',
      'NeumorphicInputOtp',
      'NeumorphicPasswordField',
      'NeumorphicInputGroup',
    }.contains(name);
    // A field is the target of these two: what they offer opens from typing.
    final typed =
        text || {'NeumorphicCombobox', 'NeumorphicCommand'}.contains(name);
    testWidgets('$name is reachable and activates from the keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var count = 0;
      await tester.pumpWidget(
        neumorphicApp(
          SingleChildScrollView(
            child: SizedBox(width: 350, child: build(() => count++)),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final drive = _drives[name];
      if (drive != null) {
        await drive(tester, () => count);
      } else if (text) {
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
        await tester.enterText(
          find.byType(EditableText),
          name == 'NeumorphicInputOtp' ? '123' : 'Written',
        );
        expect(count, 1);
      } else {
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                // The slider lifts its thumb, the part that moves; the parts on
                // ui_core's behaviours lift their region (`neumorphicFocusLift`).
                {
                  '_FocusLift',
                  '_ThumbLift',
                  '_Lift',
                }.contains(w.foregroundPainter.runtimeType.toString()),
          ),
          findsOneWidget,
        );
        if (name == 'NeumorphicSlider') {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pump();
          expect(count, 1);
        } else if (name == 'NeumorphicCarouselView') {
          // The lifted strip turns by the arrows; onChanged reports the item that settles.
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(count, 1);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(count, 2);
        } else if (name == 'NeumorphicSelect') {
          for (var i = 1; i <= 2; i++) {
            await tester.sendKeyEvent(
              i == 1 ? LogicalKeyboardKey.enter : LogicalKeyboardKey.space,
            );
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(count, i);
          }
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(count, 1);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pump();
          expect(count, 2);
        }
      }
      expect(tester.takeException(), isNull);
    });
    // A text field remains editable without an onChanged listener; Back defaults
    // to Navigator.maybePop. These are supported actions, not disabled controls.
    // A carousel moves by its dots with no listener; onChanged only reports.
    // The driven parts work on their controller without a listener: their callback only reports.
    // A split button with no act keeps its menu half: only the act is out.
    if (!text &&
        !_drives.containsKey(name) &&
        name != 'NeumorphicBackButton' &&
        name != 'NeumorphicCarouselView' &&
        name != 'NeumorphicSplitButton') {
      testWidgets('$name with no callback cannot focus or activate', (
        tester,
      ) async {
        await tester.pumpWidget(
          neumorphicApp(
            SingleChildScrollView(
              child: SizedBox(width: 350, child: build(null)),
            ),
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        for (final press in tester.stateList<DesignPressableState>(
          find.byType(DesignPressable),
        )) {
          expect(press.states.contains(WidgetState.focused), isFalse);
        }
        expect(tester.takeException(), isNull);
      });
    }
    if (!typed && !_noPressable.contains(name)) {
      testWidgets('$name exposes hover and a touch target', (tester) async {
        await tester.pumpWidget(
          neumorphicApp(
            SingleChildScrollView(
              child: SizedBox(width: 350, child: build(() {})),
            ),
          ),
        );
        // A month's first key can be out of use (the earliest month has no way back).
        final target =
            {
              'NeumorphicDatePicker',
              'NeumorphicCalendar',
              'NeumorphicDateRangePicker',
            }.contains(name)
            ? find
                  .byWidgetPredicate(
                    (w) => w is DesignPressable && w.onPressed != null,
                  )
                  .first
            : find.byType(DesignPressable).first;
        final rect = tester.getRect(target);
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(rect.center);
        await tester.pumpAndSettle();
        expect(
          tester.state<DesignPressableState>(target).states,
          contains(WidgetState.hovered),
        );
        await mouse.removePointer();
        await tester.pumpAndSettle();
        expect(
          tester.state<DesignPressableState>(target).states,
          isNot(contains(WidgetState.hovered)),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
