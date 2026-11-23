// Frosted's open lists: in every open list the chosen option stands on the chosen
// plate, the brighter glass every chosen part stands on (law 6), not only a
// small check; a hover and the keyboard's highlight clear the frost under a
// row that is not chosen, so neither reads as a second choice; and
// the keyboard walks a select's list as it does every list ui_core opens:
// opened by a key the chosen option takes the focus (the
// first when none is), the arrows go round at once (after a pointer opened
// it too), Home and End go to the ends, a letter jumps, Enter or Space
// chooses and closes, Escape closes and gives the field the focus back.
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:frosted_ui/src/frosted/internal/chosen_plate.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/panel.dart';

const _options = [
  FrostedSelectOption('k', 'Kitchen'),
  FrostedSelectOption('s', 'Study'),
  FrostedSelectOption('g', 'Garden', note: 'Outdoors'),
];

Widget _host(
  FrostedThemeData t,
  Widget child, {
  Map<ShortcutActivator, Intent>? shortcuts,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  shortcuts: shortcuts,
  builder: (context, page) => FrostedHost(
    theme: t,
    darkTheme: t,
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

/// The select, its value held, so a choice shows when it opens again.
class _Room extends StatefulWidget {
  const _Room({this.value = 's', this.focusNode});

  final String? value;
  final FocusNode? focusNode;

  @override
  State<_Room> createState() => _RoomState();
}

class _RoomState extends State<_Room> {
  late String? _value = widget.value;

  @override
  Widget build(BuildContext context) => FrostedSelect<String>(
    labelText: 'Room',
    focusNode: widget.focusNode,
    value: _value,
    onChanged: (v) => setState(() => _value = v),
    options: _options,
  );
}

/// The face a menu row with [label] is drawn on: its plate when chosen, its
/// face otherwise.
Finder _plate(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(FrostedChosenPlate),
);

FrostedFace _face(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(FrostedFace)).first,
);

/// Whether [label]'s row is lit: the frost under it cleared (held by the
/// keys or the pointer), or its plate washed (pressed).
bool _lit(WidgetTester tester, String label) =>
    _face(tester, label).color != null ||
    tester
        .widgetList<FrostedCleared>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(FrostedCleared),
          ),
        )
        .any((c) => c.level > 0);

/// Whether [element] is [row] or stands inside it.
bool _inside(Element element, Element row) {
  var inside = element == row;
  if (!inside) {
    element.visitAncestorElements((e) {
      inside = e == row;
      return !inside;
    });
  }
  return inside;
}

/// The words of the list row the keyboard holds, or null (none held, or the
/// focus on the menu itself or on the field).
String? _focusedRow(WidgetTester tester) {
  final focus = FocusManager.instance.primaryFocus?.context as Element?;
  if (focus == null) return null;
  for (final label in ['Kitchen', 'Study', 'Garden']) {
    final rows = find.ancestor(
      of: find.text(label),
      matching: find.byType(FrostedPressable),
    );
    for (final row in rows.evaluate()) {
      // The field says its value too; it alone says whether it is open.
      if ((row.widget as FrostedPressable).expanded != null) continue;
      if (_inside(focus, row)) return label;
    }
  }
  return null;
}

/// The select's field.
FrostedPressable _field(WidgetTester tester) => tester
    .widgetList<FrostedPressable>(find.byType(FrostedPressable))
    .firstWhere((p) => p.expanded != null);

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  String? character,
}) async {
  await tester.sendKeyEvent(key, character: character);
  await tester.pumpAndSettle();
}

void main() {
  for (final t in [
    FrostedThemeData.opal(),
    FrostedThemeData.opal(Brightness.dark),
  ]) {
    final night = t.isDark ? 'night' : 'day';

    testWidgets("$night: a select's chosen option stands on the chosen plate; "
        'a hover clears the frost under another row, never the plate', (
      tester,
    ) async {
      await tester.pumpWidget(_host(t, const _Room()));
      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();
      expect(find.text('Kitchen'), findsOneWidget);
      expect(_plate('Study'), findsOneWidget);
      expect(_plate('Kitchen'), findsNothing);
      expect(_lit(tester, 'Kitchen'), isFalse);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Kitchen')));
      await tester.pumpAndSettle();
      expect(_lit(tester, 'Kitchen'), isTrue);
      expect(_plate('Kitchen'), findsNothing);
      expect(_plate('Study'), findsOneWidget);

      // Over the chosen row, the plate stays as it is.
      // The list's row, laid over the field that says it too.
      await mouse.moveTo(tester.getCenter(find.text('Study').last));
      await tester.pumpAndSettle();
      expect(_plate('Study'), findsOneWidget);
      expect(_lit(tester, 'Kitchen'), isFalse);
    });

    testWidgets('$night: opened by a pointer, the arrows go round from the '
        'chosen row at once, Home, End and a letter jump, Enter chooses; '
        'the arrows mapped as a web app maps them', (tester) async {
      // A web app's shortcuts scroll with the arrows (WidgetsApp's web set):
      // only the menu's own may walk its rows.
      await tester.pumpWidget(
        _host(
          t,
          const _Room(),
          shortcuts: {
            ...WidgetsApp.defaultShortcuts,
            const SingleActivator(LogicalKeyboardKey.arrowDown):
                const ScrollIntent(direction: AxisDirection.down),
            const SingleActivator(LogicalKeyboardKey.arrowUp):
                const ScrollIntent(direction: AxisDirection.up),
          },
        ),
      );
      await tester.tap(find.text('Study'));
      await tester.pumpAndSettle();
      expect(_field(tester).expanded, isTrue);
      expect(_focusedRow(tester), isNull);

      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedRow(tester), 'Garden', reason: 'the one after Study');
      expect(_lit(tester, 'Garden'), isTrue);
      expect(_lit(tester, 'Kitchen'), isFalse);
      expect(_plate('Study'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedRow(tester), 'Kitchen', reason: 'round the end');
      expect(_lit(tester, 'Kitchen'), isTrue);
      expect(_lit(tester, 'Garden'), isFalse);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusedRow(tester), 'Garden', reason: 'round the start');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focusedRow(tester), 'Kitchen');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focusedRow(tester), 'Garden');
      await _key(tester, LogicalKeyboardKey.keyS, character: 's');
      expect(_focusedRow(tester), 'Study');
      expect(_plate('Study'), findsOneWidget, reason: 'held, still chosen');
      // No item starts "sk": the letter alone jumps.
      await _key(tester, LogicalKeyboardKey.keyK, character: 'k');
      expect(_focusedRow(tester), 'Kitchen');

      await _key(tester, LogicalKeyboardKey.enter);
      expect(find.text('Garden'), findsNothing, reason: 'the list closed');
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Study'), findsNothing);
      expect(_field(tester).expanded, isFalse);
    });

    testWidgets('$night: opened by a key, the chosen option takes the focus; '
        'Escape gives it back to the field; Space chooses', (tester) async {
      final field = FocusNode();
      addTearDown(field.dispose);
      await tester.pumpWidget(_host(t, _Room(focusNode: field)));
      field.requestFocus();
      await tester.pump();

      for (final (key, character) in [
        (LogicalKeyboardKey.enter, null),
        (LogicalKeyboardKey.space, ' '),
        (LogicalKeyboardKey.arrowDown, null),
        (LogicalKeyboardKey.arrowUp, null),
      ]) {
        await _key(tester, key, character: character);
        expect(_field(tester).expanded, isTrue, reason: '$key opens it');
        expect(_focusedRow(tester), 'Study', reason: '$key: the chosen one');
        expect(_plate('Study'), findsOneWidget);
        await _key(tester, LogicalKeyboardKey.arrowDown);
        expect(_focusedRow(tester), 'Garden');
        await _key(tester, LogicalKeyboardKey.escape);
        expect(find.text('Garden'), findsNothing, reason: 'Escape closed it');
        expect(_field(tester).expanded, isFalse);
        expect(field.hasPrimaryFocus, isTrue, reason: 'back on the field');
      }

      await _key(tester, LogicalKeyboardKey.enter);
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusedRow(tester), 'Kitchen');
      await _key(tester, LogicalKeyboardKey.space, character: ' ');
      expect(find.text('Garden'), findsNothing, reason: 'Space chose');
      expect(find.text('Kitchen'), findsOneWidget);
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('$night: opened by a key with nothing chosen, the first '
        'option takes the focus', (tester) async {
      final field = FocusNode();
      addTearDown(field.dispose);
      await tester.pumpWidget(_host(t, _Room(value: null, focusNode: field)));
      field.requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_focusedRow(tester), 'Kitchen');
      expect(_plate('Kitchen'), findsNothing);
      expect(_lit(tester, 'Kitchen'), isTrue);
    });

    testWidgets('$night: a list row ui_core opens: chosen on the plate; held '
        '(by the keys, or a pointer that moves the hold), cleared, or '
        'pressed, the wash; both, the plate (menus_test: a resting pointer '
        'lights none)', (tester) async {
      Future<void> row(Set<WidgetState> states) => tester.pumpWidget(
        _host(t, FrostedPanelRow(label: 'Lisbon', states: states)),
      );
      await row({});
      expect(_plate('Lisbon'), findsNothing);
      expect(_lit(tester, 'Lisbon'), isFalse);
      await row({WidgetState.selected});
      expect(_plate('Lisbon'), findsOneWidget);
      for (final lit in [WidgetState.focused, WidgetState.pressed]) {
        await row({lit});
        expect(_plate('Lisbon'), findsNothing, reason: '$lit');
        expect(_lit(tester, 'Lisbon'), isTrue, reason: '$lit');
        await row({lit, WidgetState.selected});
        expect(_plate('Lisbon'), findsOneWidget, reason: '$lit');
      }
    });
  }
}
