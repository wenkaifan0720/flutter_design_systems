// The keys of the lists Frosted opens on ui_core's combobox, tag input and
// menu bar (ui_core 0.2.0),
// through Frosted's own wrappers: the arrows go round the ends; on a closed
// list they open it without moving; a combobox opens on its value (else the
// first option that can be taken) and lists every option until the words
// are edited; a disabled option stands dimmed, passed over and never taken;
// a menu bar's menu jumps to a typed letter. The frost under the held row
// clears, the chosen one stands on the plate. A pointer's row and the keys'
// row are one place (ui_core's highlightFollowsPointer, fec8131445), since
// Frosted lights both alike. Choices are made as a phone's keyboard
// makes them, by its done action.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/chosen_plate.dart';
import 'package:frosted_ui/src/frosted/internal/dim.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/panel.dart';

const _cities = ['Amsterdam', 'Berlin', 'Dublin', 'Lisbon', 'Madrid'];
const _tags = ['Design', 'Review', 'Writing', 'Travel'];

Widget _host(FrostedThemeData t, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    light: t,
    dark: t,
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    child: page!,
  ),
  home: ColoredBox(
    color: t.colorScheme.background,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(width: 400, child: child),
      ),
    ),
  ),
);

/// A combobox over [_cities], its value held.
class _City extends StatefulWidget {
  const _City({this.value = 'Lisbon', this.isOptionEnabled});

  final String? value;
  final bool Function(String option)? isOptionEnabled;

  @override
  State<_City> createState() => _CityState();
}

String? _city;

class _CityState extends State<_City> {
  late String? _value = widget.value;

  @override
  Widget build(BuildContext context) => FrostedCombobox<String>(
    label: 'City',
    options: _cities,
    value: _value,
    isOptionEnabled: widget.isOptionEnabled,
    onSelected: (v) => setState(() => _city = _value = v),
  );
}

/// A multi-select over [_tags], its values held.
class _Tags extends StatefulWidget {
  const _Tags({this.isOptionEnabled});

  final bool Function(String option)? isOptionEnabled;

  @override
  State<_Tags> createState() => _TagsState();
}

List<String> _chosen = [];

class _TagsState extends State<_Tags> {
  @override
  Widget build(BuildContext context) => FrostedMultiSelect<String>(
    label: 'Tags',
    options: _tags,
    values: _chosen,
    isOptionEnabled: widget.isOptionEnabled,
    onChanged: (v) => setState(() => _chosen = v),
  );
}

Iterable<FrostedPanelRow> _rows(WidgetTester tester) =>
    tester.widgetList<FrostedPanelRow>(find.byType(FrostedPanelRow));

/// The rows the open list shows, in order.
List<String> _listed(WidgetTester tester) => [
  for (final r in _rows(tester)) r.label,
];

/// The one row the keyboard holds, or null.
String? _held(WidgetTester tester) {
  final held = [
    for (final r in _rows(tester))
      if (r.states.contains(WidgetState.focused)) r.label,
  ];
  return held.length == 1 ? held.single : null;
}

Finder _row(String label) =>
    find.byWidgetPredicate((w) => w is FrostedPanelRow && w.label == label);

Finder _plate(String label) =>
    find.descendant(of: _row(label), matching: find.byType(FrostedChosenPlate));

/// How far the frost under [label]'s row has cleared: 1 held, 0 not.
double _clear(WidgetTester tester, String label) => tester
    .widget<FrostedCleared>(
      find
          .descendant(of: _row(label), matching: find.byType(FrostedCleared))
          .first,
    )
    .level;

bool _dimmed(WidgetTester tester, String label) => tester
    .widget<FrostedDim>(
      find.descendant(of: _row(label), matching: find.byType(FrostedDim)),
    )
    .off;

/// The lit rows not chosen (the chosen row stands on its plate).
List<String> _washed(WidgetTester tester) => [
  for (final r in _rows(tester))
    if (_plate(r.label).evaluate().isEmpty && _clear(tester, r.label) > 0)
      r.label,
];

/// A mouse resting over the middle of [label]'s row.
Future<TestGesture> _hover(WidgetTester tester, String label) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  await mouse.moveTo(tester.getCenter(_row(label)));
  await tester.pumpAndSettle();
  return mouse;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    _city = null;
    _chosen = ['Design'];
  });

  for (final t in [
    FrostedThemeData.opal(),
    FrostedThemeData.opal(Brightness.dark),
  ]) {
    final night = t.isDark ? 'night' : 'day';

    testWidgets("$night: a combobox opens on every option, its value held on "
        'the plate; the arrows go round; on a closed list they only open it; '
        'edited words filter', (tester) async {
      await tester.pumpWidget(_host(t, const _City()));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_listed(tester), _cities, reason: 'every option, not "Lisbon"');
      expect(_held(tester), 'Lisbon');
      expect(_plate('Lisbon'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Madrid');
      expect(_clear(tester, 'Madrid'), 1);
      expect(_plate('Lisbon'), findsOneWidget, reason: 'still chosen');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Amsterdam', reason: 'round the end');
      expect(_clear(tester, 'Madrid'), 0);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_held(tester), 'Madrid', reason: 'round the start');
      await _done(tester);
      expect(_city, 'Madrid');
      expect(_listed(tester), isEmpty, reason: 'taking one closes the list');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_listed(tester), _cities, reason: 'Down opens every option');
      expect(_held(tester), 'Madrid', reason: 'and only opens it');
      expect(_plate('Madrid'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_listed(tester), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_held(tester), 'Madrid', reason: 'Up only opens it too');

      await tester.enterText(find.byType(EditableText), 'er');
      await tester.pumpAndSettle();
      expect(_listed(tester), [
        'Amsterdam',
        'Berlin',
      ], reason: 'edited: the matches');
      expect(_held(tester), 'Amsterdam');
    });

    testWidgets('$night: a combobox at the foot of the screen opens its list '
        'above it, every option in reach', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => FrostedHost(
            light: t,
            dark: t,
            brightness: t.isDark ? Brightness.dark : Brightness.light,
            child: page!,
          ),
          home: ColoredBox(
            color: t.colorScheme.background,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(padding: EdgeInsets.all(16), child: _City()),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(EditableText));
      final list = tester.getRect(find.byType(FrostedPanel));
      expect(list.bottom, lessThanOrEqualTo(field.top), reason: 'above');
      expect(list.height, greaterThan(200), reason: 'not one row');
      expect(_listed(tester), _cities);
      expect(_held(tester), 'Lisbon');
    });

    testWidgets('$night: a combobox with nothing chosen opens at the first', (
      tester,
    ) async {
      await tester.pumpWidget(_host(t, const _City(value: null)));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_listed(tester), _cities);
      expect(_held(tester), 'Amsterdam');
      expect(_clear(tester, 'Amsterdam'), 1);
    });

    testWidgets("$night: a pointer over a combobox's row holds it, the keys "
        'go on from there, and only one row is ever lit', (tester) async {
      await tester.pumpWidget(_host(t, const _City()));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_held(tester), 'Lisbon', reason: 'held on its plate');
      expect(_washed(tester), isEmpty);
      final mouse = await _hover(tester, 'Berlin');
      expect(_held(tester), 'Berlin');
      expect(_washed(tester), ['Berlin'], reason: 'one row, not two');
      expect(_plate('Lisbon'), findsOneWidget, reason: 'still chosen');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Dublin', reason: 'on from the pointer');
      expect(_washed(tester), ['Dublin'], reason: 'the resting pointer too');
      await mouse.moveTo(const Offset(600, 500));
      await tester.pumpAndSettle();
      expect(_washed(tester), ['Dublin'], reason: 'leaving keeps it');
      await _done(tester);
      expect(_city, 'Dublin');
    });

    testWidgets("$night: a pointer over a multi-select's row holds it, one "
        'row lit', (tester) async {
      await tester.pumpWidget(_host(t, const _Tags()));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await _hover(tester, 'Travel');
      expect(_washed(tester), ['Travel']);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_washed(tester), ['Review'], reason: 'round the end');
    });

    testWidgets("$night: a combobox's disabled option stands dimmed, passed "
        'over by the arrows and never taken', (tester) async {
      await tester.pumpWidget(
        _host(t, _City(isOptionEnabled: (c) => c != 'Berlin' && c != 'Lisbon')),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_listed(tester), _cities);
      expect(_held(tester), 'Amsterdam', reason: 'the value cannot be taken');
      expect(_dimmed(tester, 'Berlin'), isTrue);
      expect(_dimmed(tester, 'Lisbon'), isTrue);
      expect(_dimmed(tester, 'Dublin'), isFalse);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Dublin', reason: 'past Berlin');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Madrid', reason: 'past Lisbon');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Amsterdam', reason: 'round the end');

      await tester.tap(_row('Berlin'));
      await tester.pumpAndSettle();
      expect(_city, isNull, reason: 'a press takes no disabled option');
      await _done(tester);
      expect(_city, 'Amsterdam');
    });

    testWidgets("$night: a multi-select's list goes round, opens at the first "
        'on a closed list, passes over a disabled option', (tester) async {
      await tester.pumpWidget(_host(t, const _Tags()));
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_listed(tester), [
        'Review',
        'Writing',
        'Travel',
      ], reason: 'Design stands as a tag');
      expect(_held(tester), 'Review');
      expect(_clear(tester, 'Review'), 1);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_held(tester), 'Travel', reason: 'round the start');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Review', reason: 'round the end');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Writing');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_listed(tester), isEmpty);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Review', reason: 'Down only opens it');
      await _done(tester);
      expect(_chosen, ['Design', 'Review']);

      await tester.pumpWidget(const SizedBox());
      _chosen = ['Design'];
      await tester.pumpWidget(
        _host(t, _Tags(isOptionEnabled: (o) => o != 'Review')),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(_held(tester), 'Writing', reason: 'the first that can be taken');
      expect(_dimmed(tester, 'Review'), isTrue);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Travel');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'Writing', reason: 'round the end, past Review');
      await tester.tap(_row('Review'));
      await tester.pumpAndSettle();
      expect(_chosen, ['Design'], reason: 'a press takes no disabled one');
    });

    testWidgets("$night: in a menu bar's menu a typed letter goes to the next "
        'item it starts, letters in a run spell it; the held item under the '
        'wash', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final ran = <String>[];
      RawMenuEntry item(String label) =>
          RawMenuEntry(label: label, onPressed: () => ran.add(label));
      await tester.pumpWidget(
        _host(
          t,
          FrostedMenuBar(
            menus: [
              RawMenuEntry(
                label: 'File',
                children: [
                  item('New'),
                  item('Open'),
                  item('Open recent'),
                  item('Print'),
                  item('Quit'),
                ],
              ),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_held(tester), 'New');
      Future<void> pause() => tester.pump(const Duration(seconds: 1));

      await _key(tester, LogicalKeyboardKey.keyQ);
      expect(_held(tester), 'Quit');
      expect(_clear(tester, 'Quit'), 1);
      expect(_clear(tester, 'New'), 0);
      await pause();
      await _key(tester, LogicalKeyboardKey.keyN);
      expect(_held(tester), 'New', reason: 'round past the end');
      await pause();
      await _key(tester, LogicalKeyboardKey.keyO);
      expect(_held(tester), 'Open');
      await pause();
      await _key(tester, LogicalKeyboardKey.keyO);
      expect(_held(tester), 'Open recent', reason: 'the same letter steps on');
      await pause();
      await _key(tester, LogicalKeyboardKey.keyO);
      expect(_held(tester), 'Open', reason: 'and round');
      // Within the run (no settle, so no time passes): "op" still fits Open.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(_held(tester), 'Open', reason: '"op", not P alone');
      await pause();
      await _key(tester, LogicalKeyboardKey.keyP);
      expect(_held(tester), 'Print', reason: 'P alone, after a pause');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(ran, ['Print']);
    });
  }
}
