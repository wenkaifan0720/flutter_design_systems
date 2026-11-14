// The behaviour law (looks/COMPLETE.md §2a). Every part that takes a callback is enumerated from the source, so a new
// one fails here until it is named in the table. Each one: Tab reaches it, its focus ring paints, Enter and Space press
// it, with no callback it takes no focus and its face is told it is disabled, a hover reaches its face's states, and with
// animations disabled nothing it does leaves a running animation. Each part, and every example page, lays out with no
// exception at 390, 768, 1024 and 1440, at text scale 2.0 and right to left.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pages/agenda_page.dart';
import 'pages/home_page.dart';
import 'support.dart';
import 'pages/wall_page.dart';
import 'pages/thread_page.dart';
import 'pages/ledger_page.dart';
import 'pages/method_page.dart';
import 'pages/form_page.dart';
import 'pages/profile_page.dart';

/// One interactive part: [build] wires its main callback to `hit`, or none when `hit` is null.
class _Part {
  const _Part(
    this.build, {
    this.keys = true,
    this.pressable = true,
    this.disables = true,
    this.roving = false,
    this.lit = false,
  });
  final Widget Function(VoidCallback? hit) build;

  /// Enter and Space on its first focus stop call its main callback.
  final bool keys;

  /// Tab stops on it. False for a part that takes no focus by design (page dots).
  final bool focus = true;

  /// It stands on the design kit's pressable, so its face is handed the states.
  final bool pressable;

  /// With no callback it takes no focus (a text field still takes text).
  final bool disables;

  /// The keyboard's focus is the grid's own, one cell lit in turn (the calendar): no press holds the focus, the lit
  /// cell's face rings.
  final bool roving;

  /// Its rows light as a menu's under the keyboard, the selection fill in place of a ring.
  final bool lit;
}

ValueChanged<T>? _on<T>(VoidCallback? hit) => hit == null ? null : (_) => hit();

const _tabs = [
  ComicNavItem(label: 'Today', short: 'Today', icon: LucideIcons.house),
  ComicNavItem(label: 'Places', short: 'Places', icon: LucideIcons.compass),
];

final _parts = <String, _Part>{
  'ComicPressable': _Part(
    (hit) => ComicPressable(
      label: 'Tile',
      onPressed: hit,
      child: const Padding(padding: EdgeInsets.all(12), child: Text('Tile')),
    ),
  ),
  'ComicButton.filled': _Part(
    (hit) => ComicButton.filled('Save', onPressed: hit),
  ),
  'ComicButton.outlined': _Part(
    (hit) => ComicButton('Details', onPressed: hit),
  ),
  'ComicButton.text': _Part((hit) => ComicButton.text('Later', onPressed: hit)),
  'ComicButton.destructive': _Part(
    (hit) => ComicButton(
      'Remove',
      isDestructiveAction: true,
      icon: ComicGlyphs.trash2,
      onPressed: hit,
    ),
  ),
  'ComicLink': _Part((hit) => ComicLink('Read', onPressed: hit)),
  'ComicIconButton': _Part(
    (hit) => ComicIconButton(LucideIcons.heart, label: 'Save', onPressed: hit),
  ),
  'ComicButton': _Part((hit) => ComicButton('Go', onPressed: hit)),
  'ComicSendButton': _Part((hit) => ComicSendButton(onPressed: hit)),
  'ComicBackButton': _Part(
    (hit) => ComicBackButton(onPressed: hit),
    disables: false,
  ),
  'ComicChip': _Part((hit) => ComicChip('History', onPressed: hit)),
  'ComicChip.filter': _Part(
    (hit) =>
        ComicChip.filter('In print', selected: false, onSelected: _on(hit)),
  ),
  'ComicChip.removable': _Part((hit) => ComicChip('History', onDeleted: hit)),
  'ComicCheckbox': _Part(
    (hit) => ComicCheckbox(value: false, label: 'Agree', onChanged: _on(hit)),
  ),
  'ComicCheckRow': _Part(
    (hit) => ComicCheckRow(value: false, label: 'Agree', onChanged: _on(hit)),
  ),
  'ComicSwitch': _Part(
    (hit) => ComicSwitch(value: false, label: 'Alerts', onChanged: _on(hit)),
  ),
  'ComicSwitchRow': _Part(
    (hit) => ComicSwitchRow(value: false, label: 'Alerts', onChanged: _on(hit)),
  ),
  'ComicGroupChip': _Part((hit) => ComicGroupChip('The crew', onPressed: hit)),
  'ComicChoiceBox': _Part(
    (hit) => ComicChoiceBox(
      label: 'Tonight',
      onPressed: hit,
      child: const Text('Tonight'),
    ),
  ),
  'ComicChoices': _Part(
    (hit) => ComicChoices(
      options: const [
        ComicChoice('All', value: 'all'),
        ComicChoice('Saved', value: 'saved'),
      ],
      onChanged: _on(hit),
    ),
  ),
  'ComicNumberField': _Part(
    (hit) => ComicNumberField(value: 2, unit: 'people', onChanged: _on(hit)),
  ),
  'ComicRadioGroup': _Part(
    (hit) => ComicRadioGroup<String>(
      label: 'Format',
      options: const [
        ComicRadio('print', 'Print'),
        ComicRadio('digital', 'Digital'),
      ],
      onChanged: _on(hit),
    ),
  ),
  'ComicSegmentedButton': _Part(
    (hit) => ComicSegmentedButton<String>(
      label: 'View',
      segments: const [
        ComicButtonSegment('all', 'All'),
        ComicButtonSegment('saved', 'Saved'),
      ],
      onChanged: _on(hit),
    ),
  ),
  'ComicSlider': _Part(
    (hit) => ComicSlider(label: 'Volume', value: .5, onChanged: _on(hit)),
    keys: false,
    pressable: false,
  ),
  'ComicNavItem': _Part(
    (hit) => ComicNavigationBar(
      destinations: [
        ComicNavItem(
          label: 'Today',
          short: 'Today',
          icon: LucideIcons.house,
          onPressed: hit,
        ),
      ],
    ),
  ),
  'ComicNavigationBar': _Part(
    (hit) => ComicNavigationBar(
      destinations: _tabs,
      onDestinationSelected: _on(hit),
    ),
  ),
  'ComicNavigationDrawer': _Part(
    (hit) => ComicNavigationDrawer(
      destinations: _tabs,
      onDestinationSelected: _on(hit),
    ),
  ),
  'ComicTabBar': _Part(
    (hit) => ComicTabBar(tabs: const ['All', 'Saved'], onChanged: _on(hit)),
  ),
  'ComicPageDots': _Part(
    (hit) => ComicPageDots(
      count: 4,
      selectedIndex: 1,
      label: 'Pages',
      onChanged: _on(hit),
    ),
  ),
  'ComicNavigationRail': _Part(
    (hit) => SizedBox(
      height: 400,
      child: ComicNavigationRail(
        destinations: _tabs,
        onDestinationSelected: _on(hit),
      ),
    ),
  ),
  'ComicCrumb': _Part(
    (hit) => ComicBreadcrumb([
      ComicCrumb('Home', onPressed: hit),
      const ComicCrumb('Issue 12'),
    ]),
  ),
  'ComicPagination': _Part(
    (hit) => ComicPagination(count: 6, page: 2, onChanged: _on(hit)),
  ),
  'ComicRating': _Part(
    (hit) => ComicRating(label: 'Rate it', value: 2, onChanged: _on(hit)),
  ),
  // Its pages are the caller's: a button on one is reached by Tab and pressed by Enter. Its own dots move it whether or
  // not the caller listens, so it keeps a focus stop with no callback.
  'ComicCarouselView': _Part(
    (hit) => ComicCarouselView(
      label: 'Covers',
      height: 120,
      onChanged: _on(hit),
      children: [
        ComicButton.filled('First', onPressed: hit),
        ComicButton.filled('Second', onPressed: hit),
      ],
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicFileUpload': _Part(
    (hit) => ComicFileUpload(label: 'Attachments', onChoose: hit),
  ),
  'ComicMoreLink': _Part((hit) => ComicMoreLink('See all', onPressed: hit)),
  'ComicPanelHead': _Part(
    (hit) => ComicPanelHead('Issues', more: 'See all', onMore: hit),
  ),
  'ComicPanel': _Part(
    (hit) =>
        ComicPanel(label: 'Issue', onPressed: hit, child: const Text('Issue')),
  ),
  'ComicListTile': _Part(
    (hit) => ComicListTile(title: 'Issue', onPressed: hit),
  ),
  'ComicPictureCard': _Part(
    (hit) =>
        ComicPictureCard(slotId: 'missing', title: 'Issue', onPressed: hit),
  ),
  'ComicCover': _Part(
    (hit) => ComicCover(masthead: 'Issue', compact: true, onPressed: hit),
  ),
  'ComicCoverBox': _Part(
    (hit) => ComicCover(
      masthead: 'Issue',
      compact: true,
      issue: ComicCoverBox('12', 'pages', onPressed: hit),
    ),
  ),
  'ComicEventPanel': _Part(
    (hit) => ComicEventPanel(when: 'Friday', title: 'Reading', onPressed: hit),
  ),
  'ComicMarkPanel': _Part(
    (hit) => ComicMarkPanel(title: 'Issue', onPressed: hit),
  ),
  'ComicErrorState': _Part(
    (hit) => ComicErrorState(title: 'Could not load', onRetry: hit),
  ),
  'ComicBanner': _Part((hit) => ComicBanner('Saved', onDismiss: hit)),
  'ComicSnackBar': _Part(
    (hit) => ComicSnackBar('Saved', actionLabel: 'Undo', onAction: hit),
  ),
  'ComicBottomSheet': _Part(
    (hit) => SizedBox(
      height: 400,
      child: ComicBottomSheet(
        title: 'Details',
        onClose: hit,
        child: const Text('The full story'),
      ),
    ),
    disables: false,
  ),
  'ComicMenu': _Part(
    (hit) => ComicMenu<String>(
      items: const [
        ComicMenuItem('save', 'Save'),
        ComicMenuItem('share', 'Share'),
      ],
      onSelected: _on(hit),
    ),
  ),
  'ComicMenuAnchor': _Part(
    (hit) => ComicMenuAnchor<String>(
      items: const [ComicMenuItem('save', 'Save')],
      onSelected: _on(hit),
      builder: (context, open) => ComicButton('Open', onPressed: open),
    ),
    keys: false,
    disables: false,
  ),
  'ComicSelect': _Part(
    (hit) => ComicSelect<String>(
      label: 'Format',
      options: const [ComicSelectOption('print', 'Print')],
      onChanged: _on(hit),
    ),
    keys: false,
  ),
  'ComicSelectField': _Part(
    (hit) => ComicSelectField(value: 'Thursday', onPressed: hit),
  ),
  'ComicDisclosure': _Part(
    (hit) => ComicDisclosure(
      title: 'Details',
      onExpansionChanged: _on(hit),
      child: const Text('Full story'),
    ),
    disables: false,
  ),
  'ComicTextField': _Part(
    (hit) => ComicTextField(label: 'Name', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicInput': _Part(
    (hit) => ComicInput(hint: 'Your name', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicSearchField': _Part(
    (hit) => ComicSearchField(hint: 'Search', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicCombobox': _Part(
    (hit) => ComicCombobox<String>(
      label: 'City',
      options: const ['Lisbon', 'London'],
      onSelected: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicInputOtp': _Part(
    (hit) => ComicInputOtp(label: 'Code', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicTextArea': _Part(
    (hit) => ComicTextArea(label: 'Notes', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicReply': _Part(
    (hit) => ComicReply(
      person: const ComicPerson(initials: 'NW'),
      onSend: hit,
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicPasswordField': _Part(
    (hit) => ComicPasswordField(label: 'Password', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicInputGroup': _Part(
    (hit) => ComicInputGroup(label: 'Price', onChanged: _on(hit)),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicRangeSlider': _Part(
    (hit) => ComicRangeSlider(
      label: 'Price',
      values: const DesignRangeValues(.2, .7),
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
  ),
  'ComicCalendar': _Part(
    (hit) => ComicCalendar(
      controller: DesignCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        initialMonth: DateTime(2026, 11),
        currentDate: DateTime(2026, 11, 9),
      ),
      onChanged: _on(hit),
    ),
    keys: false,
    disables: false,
    roving: true,
  ),
  'ComicDateRangePicker': _Part(
    (hit) => ComicDateRangePicker(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      currentDate: DateTime(2026, 11, 9),
      onChanged: _on(hit),
    ),
    keys: false,
    disables: false,
    roving: true,
  ),
  'ComicWheelPicker': _Part(
    (hit) => ComicWheelPicker<int>(
      label: 'Copies',
      values: const [1, 2, 3],
      value: 2,
      labelOf: (n) => '$n',
      onChanged: _on(hit),
    ),
    keys: false,
    pressable: false,
  ),
  'ComicCommand': _Part(
    (hit) => ComicCommand(
      maxHeight: 160,
      commands: [DesignCommand(label: 'New issue', onPressed: () {})],
      onRun: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicDataTable': _Part(
    (hit) => ComicDataTable<String>(
      controller: DesignTableController<String>(
        rows: const ['Issue 12'],
        columns: [
          DesignTableColumn(id: 'title', label: 'Issue', sortKey: (row) => row),
        ],
      ),
      cellBuilder: (context, row, column) => Text(row),
      onActivate: _on(hit),
    ),
    keys: false,
    disables: false,
  ),
  'ComicTreeView': _Part(
    (hit) => ComicTreeView<String>(
      controller: DesignTreeController<String>(
        roots: const ['Issue 12'],
        childrenOf: (node) => const [],
      ),
      labelOf: (node) => node,
      onActivate: _on(hit),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicResizable': _Part(
    (hit) => SizedBox(
      height: 120,
      child: ComicResizable(
        first: const Text('Issues'),
        second: const Text('Page'),
        onChanged: _on(hit),
      ),
    ),
    keys: false,
    pressable: false,
    disables: false,
  ),
  'ComicSwipeActions': _Part(
    (hit) => ComicSwipeActions(
      endActions: [DesignSwipeAction(label: 'Delete', onPressed: () {})],
      onOpenChanged: _on(hit),
      child: ComicListTile(title: 'Issue 12', onPressed: hit),
    ),
  ),
  'ComicSheet': _Part(
    (hit) => ComicSheet(
      title: 'Filters',
      showClose: hit != null,
      onClose: hit,
      child: const Text('Only unread'),
    ),
  ),
  'ComicPopover': _Part(
    (hit) => ComicPopover(
      label: 'Filters',
      anchorBuilder: (context, anchor) => ComicButton('Filter', onPressed: hit),
      builder: (context, close) => const Text('Only unread'),
    ),
  ),
  'ComicStatusView': _Part(
    (hit) => ComicStatusView.error(title: 'It did not load', onRetry: hit),
  ),
  'ComicActionSheet': _Part(
    (hit) => ComicActionSheet<int>(
      actions: [ComicSheetAction('Share', value: 1, enabled: hit != null)],
      onSelected: (_) => hit?.call(),
    ),
    // Its cancel always closes it.
    disables: false,
    lit: true,
  ),
  'ComicButtonGroupItem': _Part(
    (hit) => ComicButtonGroup(
      label: 'Text',
      items: [ComicButtonGroupItem('Copy', onPressed: hit)],
    ),
  ),
  'ComicSplitButton': _Part(
    (hit) => ComicSplitButton(
      'Save',
      onPressed: hit,
      actions: [
        ComicSplitAction('Save a copy', onPressed: hit == null ? null : () {}),
      ],
    ),
  ),
  'ComicDatePicker': _Part(
    (hit) => ComicDatePicker(value: DateTime(2026, 11, 6), onChanged: _on(hit)),
    keys: false,
    disables: false,
  ),
  'ComicTimePicker': _Part(
    (hit) =>
        ComicTimePicker(value: const ComicTime(19, 30), onChanged: _on(hit)),
    keys: false,
  ),
};

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

/// Public parts that take a callback, read from the library.
Set<String> _interactive() {
  final found = <String>{};
  final cls = RegExp(
    r'^class (Comic\w+)[^{]*\{(.*?)^\}',
    multiLine: true,
    dotAll: true,
  );
  final cb = RegExp(
    r'final (?:VoidCallback|ValueChanged<[^>]+>|void Function\([^)]*\))\? \w+',
  );
  for (final file in Directory(
    'lib/src/comic',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    for (final m in cls.allMatches(file.readAsStringSync())) {
      // The text field's editor without its frame is plumbing, out of the barrel; the fields on it are here.
      if (m[1] == 'ComicBareEditor') continue;
      // A split button's menu action is data its button carries, pressed through the button's row in the table.
      if (m[1] == 'ComicSplitAction') continue;
      if (cb.hasMatch(m[2]!)) found.add(m[1]!);
    }
  }
  return found;
}

bool _styled = false;
ComicThemeData _appearance(Brightness mode) {
  final plain = ComicThemeData.preset('offset', mode);
  if (!_styled) return plain;
  return plain.copyWith(
    shapes: ComicShapes.rounded(8),
    strokes: ComicStrokes.bold,
    density: ComicDensity.compact,
    typeface: const ComicTypeface(scale: 1.15),
    filledButtonTheme: ComicStyle(
      shape: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.pressed) ? const StadiumBorder() : null,
      ),
    ),
  );
}

Widget _host(
  Widget child, {
  bool still = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  localizationsDelegates: const [
    ComicLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(disableAnimations: still, textScaler: TextScaler.linear(scale)),
    child: ComicHost(
      light: _appearance(Brightness.light),
      dark: _appearance(Brightness.dark),
      brightness: Brightness.light,
      child: Directionality(textDirection: direction, child: page!),
    ),
  ),
  home: Material(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: KeyedSubtree(key: _part, child: child),
      ),
    ),
  ),
);

Future<void> _size(
  WidgetTester tester,
  double width, [
  double height = 1000,
]) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _part = ValueKey('part');

bool _focusInPart(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final part = find.byKey(_part).evaluate().single;
  var inside = false;
  focused.visitAncestorElements((e) {
    if (e == part) inside = true;
    return !inside;
  });
  return inside;
}

/// Every error a build reports, each with the library line of the widget that raised it, so a failure names its
/// place rather than only the first of several.
Future<List<String>> _faults(Future<void> Function() body) async {
  final seen = <String>[];
  final before = FlutterError.onError;
  FlutterError.onError = (d) {
    final at = RegExp(r'lib/src/[\w/]+\.dart:\d+')
        .firstMatch(d.toString())
        ?.group(0);
    seen.add(
      '${d.exceptionAsString().split('\n').first} (${at ?? 'no place'})',
    );
  };
  try {
    await body();
  } finally {
    FlutterError.onError = before;
  }
  return seen;
}

/// A word's column: narrow and tall, a word a letter per line (as pages_test).
List<String> _crushed(WidgetTester tester) => [
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText, skipOffstage: false),
  ))
    if (p.text.toPlainText().trim().length >= 8 &&
        p.size.width < 72 &&
        p.size.height > 3 * p.size.width)
      '"${p.text.toPlainText().trim()}" ${p.size.width.toStringAsFixed(0)}x${p.size.height.toStringAsFixed(0)}',
];

/// Foreground painters: a focus ring is one.
int _painters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .where((p) => p.foregroundPainter != null)
    .length;

List<DesignPressableState> _pressables(WidgetTester tester) => tester
    .stateList<DesignPressableState>(find.byType(DesignPressable))
    .toList();

void main() {
  setUpAll(loadComicFonts);

  test('every part that takes a callback is named in the table', () {
    final found = _interactive();
    // A key names its class, and after a dot the variant it draws (`ComicButton.filled`).
    final named = {for (final k in _parts.keys) k.split('.').first};
    expect(
      found.difference(named),
      isEmpty,
      reason: 'a new control: add it to the table',
    );
    expect(
      named.difference(found),
      isEmpty,
      reason: 'gone from the library: take it out',
    );
  });

  test('no part keeps a press of its own: every tap stands on the design kit\'s pressable', () {
    // The few gesture detectors left are drags (the slider, the sheet's grip, a chart's reading line), the tooltip's
    // long press, the page dots' tap-either-side and a form field's label, whose tap focuses its control as the
    // design kit's own label does; none of them a press.
    final allowed = {
      'slider.dart': 1,
      'raised.dart': 1,
      'chart.dart': 1,
      'rows.dart': 1,
    };
    for (final file in Directory(
      'lib/src/comic',
    ).listSync(recursive: true).whereType<File>()) {
      final name = file.uri.pathSegments.last;
      final n = RegExp(r'GestureDetector\(')
          .allMatches(file.readAsStringSync())
          .length;
      expect(
        n,
        lessThanOrEqualTo(allowed[name] ?? 0),
        reason: '$name has $n GestureDetector(s)',
      );
    }
  });

  for (final styled in [false, true]) {
    group(styled ? 'styled controls' : 'as drawn controls', () {
      setUp(() => _styled = styled);
      tearDown(() => _styled = false);
      for (final MapEntry(key: name, value: part) in _parts.entries) {
        group(name, () {
          if (part.focus) {
            testWidgets(
              'Tab reaches it and its ring paints; Enter and Space press it',
              (tester) async {
                await _size(tester, 390);
                var hits = 0;
                await tester.pumpWidget(
                  _host(part.build(() => hits++), still: true),
                );
                await tester.pump();
                FocusManager.instance.highlightStrategy =
                    FocusHighlightStrategy.alwaysTraditional;
                addTearDown(
                  () => FocusManager.instance.highlightStrategy =
                      FocusHighlightStrategy.automatic,
                );
                final unringed = _painters(tester);
                await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                await tester.pump();
                expect(
                  _focusInPart(tester),
                  isTrue,
                  reason: 'Tab did not reach $name',
                );
                if (part.pressable && !part.roving) {
                  expect(
                    _pressables(tester)
                        .any((s) => s.states.contains(WidgetState.focused)),
                    isTrue,
                    reason: 'the focused press was not told to ring',
                  );
                }
                if (part.pressable && !part.lit) {
                  expect(
                    _painters(tester),
                    greaterThan(unringed),
                    reason: 'no ring painted',
                  );
                }
                if (part.keys) {
                  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
                  await tester.pump();
                  final afterEnter = hits;
                  expect(
                    afterEnter,
                    greaterThan(0),
                    reason: 'Enter did nothing',
                  );
                  if (_focusInPart(tester)) {
                    await tester.sendKeyEvent(LogicalKeyboardKey.space);
                    await tester.pump();
                    expect(
                      hits,
                      greaterThan(afterEnter),
                      reason: 'Space did nothing',
                    );
                  }
                }
                await tester.pumpWidget(const SizedBox());
              },
              variant: TargetPlatformVariant.all(),
            );
          }

          if (part.disables) {
            testWidgets(
              'with no callback it takes no focus and its face is told',
              (tester) async {
                await _size(tester, 390);
                await tester.pumpWidget(_host(part.build(null), still: true));
                await tester.pump();
                await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                await tester.pump();
                expect(
                  _focusInPart(tester),
                  isFalse,
                  reason: 'a disabled $name took focus',
                );
                for (final s in _pressables(tester)) {
                  expect(s.states, contains(WidgetState.disabled));
                }
              },
              variant: TargetPlatformVariant.all(),
            );
          }

          if (part.pressable) {
            testWidgets('a hover reaches its face', (tester) async {
              await _size(tester, 390);
              await tester.pumpWidget(_host(part.build(() {}), still: true));
              await tester.pump();
              final first = find.byType(DesignPressable).first;
              final mouse = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              await mouse.addPointer(location: Offset.zero);
              addTearDown(mouse.removePointer);
              await mouse.moveTo(tester.getCenter(first));
              await tester.pump();
              expect(
                tester.state<DesignPressableState>(first).states,
                contains(WidgetState.hovered),
              );
            }, variant: TargetPlatformVariant.all());
          }

          if (part.pressable) {
            testWidgets('targets hold the platform minimum', (tester) async {
              await _size(tester, 390);

              await tester.pumpWidget(_host(part.build(() {}), still: true));
              await tester.pump();
              for (final press in find.byType(DesignPressable).evaluate()) {
                final target = find.byElementPredicate(
                  (element) => identical(element, press),
                );
                // A scroll viewport clips a partly visible semantics rect.
                // Reveal the control before measuring its actual target.
                await tester.ensureVisible(target);
                await tester.pump();
                final node = tester.getSemantics(target);
                final minimum = ComicTapTarget.targetOf(press);
                expect(node.rect.width, greaterThanOrEqualTo(minimum));
                expect(node.rect.height, greaterThanOrEqualTo(minimum));
              }
            }, variant: TargetPlatformVariant.all());
          }

          testWidgets(
            'with animations disabled a press leaves nothing running',
            (tester) async {
              await _size(tester, 390);
              await tester.pumpWidget(_host(part.build(() {}), still: true));
              await tester.pump();
              if (part.pressable) {
                await tester.tap(
                  find.byType(DesignPressable).first,
                  warnIfMissed: false,
                );
              }
              await tester.pump();
              await tester.pump();
              expect(tester.hasRunningAnimations, isFalse);
              expect(tester.takeException(), isNull);
            },
            variant: TargetPlatformVariant.all(),
          );

          for (final width in const [390.0, 768.0, 1024.0, 1440.0]) {
            testWidgets('lays out at $width, at 2.0 text, and right to left', (
              tester,
            ) async {
              await _size(tester, width, 1400);
              expect(
                await _faults(() async {
                  await tester.pumpWidget(
                    _host(part.build(() {}), still: true),
                  );
                  await tester.pump();
                }),
                isEmpty,
              );
              expect(
                await _faults(() async {
                  await tester.pumpWidget(
                    _host(part.build(() {}), still: true, scale: 2),
                  );
                  await tester.pump();
                }),
                isEmpty,
                reason: 'at 2.0 text',
              );
              expect(_crushed(tester), isEmpty, reason: 'at 2.0 text');
              expect(
                await _faults(() async {
                  await tester.pumpWidget(
                    _host(
                      part.build(() {}),
                      still: true,
                      direction: TextDirection.rtl,
                    ),
                  );
                  await tester.pump();
                }),
                isEmpty,
                reason: 'right to left',
              );
            }, variant: TargetPlatformVariant.all());
          }
        });
      }
    });
  }

  group('example pages', () {
    const nav = [
      ComicNavItem(label: 'Today', short: 'Today', icon: LucideIcons.house),
      ComicNavItem(label: 'Places', short: 'Places', icon: LucideIcons.compass),
    ];
    const brand = ComicBrand(name: 'Your name');
    final pages = <String, Widget Function()>{
      'home': () => const HomePage(),
      'agenda': () => const AgendaPage(),
      'wall': () => const WallPage(),
      'thread': () => const ThreadPage(),
      'ledger': () => const LedgerPage(),
      'method': () => const MethodPage(),
      'form': () => const FormPage(),
      'profile': () => const ProfilePage(),
    };
    for (final page in pages.entries) {
      for (final width in const [390.0, 768.0, 1024.0, 1440.0]) {
        for (final (what, scale, dir) in const [
          ('', 1.0, TextDirection.ltr),
          (' at 2.0 text', 2.0, TextDirection.ltr),
          (' right to left', 1.0, TextDirection.rtl),
        ]) {
          testWidgets('${page.key} at $width$what', (tester) async {
            await _size(tester, width, 900);
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            tester.platformDispatcher.accessibilityFeaturesTestValue =
                const FakeAccessibilityFeatures(disableAnimations: true);
            addTearDown(tester.platformDispatcher.clearAllTestValues);
            expect(
              await _faults(() async {
                await tester.pumpWidget(
                  comicApp(
                    ComicChromeScope(
                      brand: brand,
                      nav: nav,
                      active: 0,
                      child: page.value(),
                    ),
                    direction: dir,
                  ),
                );
                await tester.pump();
              }),
              isEmpty,
            );
            expect(_crushed(tester), isEmpty);
          }, variant: TargetPlatformVariant.all());
        }
      }
    }
  });
  testWidgets('a hit in the target\'s margin goes to the face', (tester) async {
    var hits = 0;
    // The target's sides stand outward beside the face, so the press stands where the boxes round it leave room
    // for them (at a screen's corner there is none).
    await tester.pumpWidget(
      _host(
        Center(
          child: ComicPressable(
            onPressed: () => hits++,
            label: 'Small',
            child: const SizedBox(
              key: ValueKey('small-face'),
              width: 20,
              height: 20,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final face = tester.getRect(find.byKey(const ValueKey('small-face')));
    await tester.tapAt(face.topLeft - const Offset(10, 10));
    expect(hits, 1);
  }, variant: TargetPlatformVariant.all());

  testWidgets('a busy press keeps its focus and takes no press', (
    tester,
  ) async {
    var hits = 0;
    await tester.pumpWidget(
      _host(
        ComicPressable(
          onPressed: () => hits++,
          busy: true,
          label: 'Wait',
          child: const SizedBox(width: 60, height: 60),
        ),
      ),
    );
    await tester.pump();
    await _tab(tester);
    expect(_focusInPart(tester), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(hits, 0);
  }, variant: TargetPlatformVariant.all());

  testWidgets('the face is handed the states', (tester) async {
    // Connect the pointer before mounting so the initial platform highlight
    // mode reflects the input device when FocusableActionDetector initializes.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    Set<WidgetState> seen = {};
    await tester.pumpWidget(
      _host(
        ComicPressable(
          onPressed: () {},
          label: 'Face',
          builder: (context, states) {
            seen = states;
            return const SizedBox(
              key: ValueKey('state-face'),
              width: 60,
              height: 60,
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(seen.hovered, isFalse);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('state-face'))),
    );
    await tester.pump();
    expect(seen.hovered, isTrue);
    await _tab(tester);
    await tester.pumpAndSettle();
    expect(
      _focusInPart(tester),
      isTrue,
      reason: '${FocusManager.instance.primaryFocus}',
    );
    expect(
      seen.focused,
      isTrue,
      reason: '${FocusManager.instance.highlightMode}: $seen',
    );
  }, variant: TargetPlatformVariant.all());
}
