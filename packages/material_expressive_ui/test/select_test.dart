/// Select and combobox: Compose's `ExposedDropdownMenuBox` read-only and
/// editable — the field shows the choice, the trailing arrow turns, the
/// menu matches the field's width below it, the keyboard opens and walks
/// it, the combobox filters as you type and keeps focus in its field, the
/// system back closes its menu first — and the Cody v2 picker test ported
/// (decision F14).
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsData;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

/// An app the way a generated app runs: Expressive's host around the
/// router's navigator, a scrolling page.
Widget host(
  WidgetBuilder builder, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  builder: (context, app) =>
      ExpressiveHost(light: bloom, brightness: Brightness.light, child: app!),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: direction,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(width: 300, child: builder(context)),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

const List<ExpressiveSelectOption<String>> sizes =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption<String>('s', 'Small'),
      ExpressiveSelectOption<String>('m', 'Medium'),
      ExpressiveSelectOption<String>('l', 'Large', enabled: false),
    ];

/// A select holding its own value, reporting each choice to [chosen].
Widget liveSelect({
  String? initial,
  List<String>? chosen,
  bool enabled = true,
  ExpressiveTextFieldKind style = ExpressiveTextFieldKind.filled,
  FocusNode? focusNode,
}) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, update) => ExpressiveSelect<String>(
      options: sizes,
      value: value,
      kind: style,
      label: 'Size',
      hintText: 'Choose a size',
      enabled: enabled,
      focusNode: focusNode,
      onChanged: (v) {
        chosen?.add(v);
        update(() => value = v);
      },
    ),
  );
}

Finder get menu => find.byType(ExpressiveMenuSurface);

double arrowTurn(WidgetTester tester) {
  final rotate = tester.widget<Transform>(
    find.descendant(
      of: find.byType(ExpressiveSelectTrailingIcon),
      matching: find.byType(Transform),
    ),
  );
  return math.atan2(rotate.transform.entry(1, 0), rotate.transform.entry(0, 0));
}

const List<String> cities = <String>[
  'Lisbon',
  'London',
  'Oslo',
  'Paris',
  'Porto',
];

void main() {
  // --- Cody v2 port (F14) --------------------------------------------------

  // Cody: 'picker sheet returns a selection; disabled options do not'. An
  // Expressive picker is the exposed dropdown: its menu, not a sheet.
  testWidgets('select returns a selection; disabled options do not', (
    tester,
  ) async {
    final chosen = <String>[];
    await tester.pumpWidget(
      host((context) => liveSelect(initial: 's', chosen: chosen)),
    );
    await tester.tap(find.text('Size'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.text('Large'))
          .getSemanticsData()
          .flagsCollection
          .isEnabled
          .toBoolOrNull(),
      isFalse,
    );
    await tester.tap(find.text('Large'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen, isEmpty);
    await tester.tap(find.text('Medium').last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen, <String>['m']);
    expect(menu, findsNothing);
    expect(find.text('Medium'), findsOneWidget); // in the field
  });

  // --- Select ---------------------------------------------------------------

  testWidgets('the field shows the choice, else the placeholder', (
    tester,
  ) async {
    // Compose shows a placeholder only once the label is minimized: an
    // empty select at rest shows its label alone.
    await tester.pumpWidget(host((context) => liveSelect()));
    await tester.pumpAndSettle();
    expect(find.text('Choose a size'), findsNothing);
    expect(find.text('Size'), findsOneWidget);
    await tester.pumpWidget(host((context) => liveSelect(initial: 'm')));
    await tester.pumpAndSettle();
    expect(find.text('Medium'), findsOneWidget);
    expect(find.byIcon(ExpressiveSymbols.arrowDropDown), findsOneWidget);
  });

  testWidgets('a tap opens the menu at the field\'s width below it, the '
      'arrow turned up; a second tap closes it', (tester) async {
    for (final style in ExpressiveTextFieldKind.values) {
      await tester.pumpWidget(host((context) => liveSelect(style: style)));
      await tester.pumpAndSettle();
      expect(arrowTurn(tester), 0);
      final field = tester.getRect(find.byType(ExpressiveTextField));
      await tester.tap(find.byType(ExpressiveTextField));
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
      expect(arrowTurn(tester), closeTo(math.pi, 1e-9));
      final surface = tester.getRect(menu);
      expect(surface.width, field.width);
      expect(surface.left, field.left);
      expect(surface.top, greaterThanOrEqualTo(field.bottom));
      // The modal menu's barrier takes the second tap and closes it.
      await tester.tapAt(field.center);
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      expect(arrowTurn(tester), 0);
    }
  });

  testWidgets('Enter or Space opens the menu; the arrow keys walk it', (
    tester,
  ) async {
    final chosen = <String>[];
    final focus = FocusNode();
    await tester.pumpWidget(
      host(
        (context) => liveSelect(initial: 's', chosen: chosen, focusNode: focus),
      ),
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    // Opened from the keyboard, the menu takes it on its first item: Down
    // moves on.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, <String>['m']);
    expect(menu, findsNothing);
    focus.dispose();
  });

  testWidgets('a disabled select never opens', (tester) async {
    await tester.pumpWidget(
      host((context) => liveSelect(initial: 'm', enabled: false)),
    );
    await tester.tap(find.byType(ExpressiveTextField));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    await tester.pumpWidget(
      host(
        (context) => const ExpressiveSelect<String>(
          options: sizes,
          value: 'm',
          onChanged: null,
          label: 'Size',
        ),
      ),
    );
    await tester.tap(find.byType(ExpressiveTextField));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
  });

  testWidgets('the select announces whether it is expanded', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host((context) => liveSelect(initial: 'm')));
    await tester.pumpAndSettle();
    SemanticsData data() => tester
        .getSemantics(
          find
              .ancestor(
                of: find.byType(ExpressiveTextField),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .getSemanticsData();
    expect(data().flagsCollection.isExpanded.toBoolOrNull(), isFalse);
    await tester.tap(find.byType(ExpressiveTextField));
    await tester.pumpAndSettle();
    expect(data().flagsCollection.isExpanded.toBoolOrNull(), isTrue);
    semantics.dispose();
  });

  testWidgets('a controller opens and closes the menu from the app', (
    tester,
  ) async {
    final controller = ExpressiveMenuController();
    await tester.pumpWidget(
      host(
        (context) => ExpressiveSelect<String>(
          options: sizes,
          value: null,
          onChanged: (_) {},
          controller: controller,
          label: 'Size',
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(controller.isOpen, isTrue);
    controller.close();
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    controller.dispose();
  });

  // --- Combobox -------------------------------------------------------------

  Widget combobox({
    TextEditingController? controller,
    FocusNode? focusNode,
    List<String>? chosen,
    bool enabled = true,
  }) => Column(
    children: <Widget>[
      ExpressiveCombobox<String>(
        options: <ExpressiveSelectOption<String>>[
          for (final city in cities) ExpressiveSelectOption<String>(city, city),
        ],
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        label: 'City',
        onSelected: (option) => chosen?.add(option.value),
      ),
      const SizedBox(key: ValueKey('outside'), height: 300),
    ],
  );

  testWidgets('typing filters the menu while focus stays in the field', (
    tester,
  ) async {
    final text = TextEditingController();
    final focus = FocusNode();
    final chosen = <String>[];
    await tester.pumpWidget(
      host(
        (context) =>
            combobox(controller: text, focusNode: focus, chosen: chosen),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'po');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(focus.hasPrimaryFocus, isTrue);
    expect(find.text('Porto'), findsOneWidget);
    expect(find.text('Oslo'), findsNothing);
    // The menu is as wide as the field.
    expect(
      tester.getSize(menu).width,
      tester.getSize(find.byType(ExpressiveTextField)).width,
    );
    // Nothing matches: the menu says so; a match brings the options back.
    await tester.enterText(find.byType(EditableText), 'pox');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Porto'), findsNothing);
    await tester.enterText(find.byType(EditableText), 'l');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(find.text('Lisbon'), findsOneWidget);
    expect(find.text('Oslo'), findsOneWidget);
    expect(find.text('Porto'), findsNothing);
    // A choice fills the field, the caret at its end.
    await tester.tap(find.text('London'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chosen, <String>['London']);
    expect(text.text, 'London');
    expect(text.selection, const TextSelection.collapsed(offset: 6));
    expect(menu, findsNothing);
    focus.dispose();
    text.dispose();
  });

  testWidgets('the arrow toggles the menu without focusing the field; a tap '
      'outside closes it', (tester) async {
    final focus = FocusNode();
    await tester.pumpWidget(host((context) => combobox(focusNode: focus)));
    await tester.tap(find.byType(ExpressiveSelectTrailingIcon));
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    expect(find.text('Paris'), findsOneWidget);
    expect(focus.hasFocus, isFalse);
    await tester.tap(find.byType(ExpressiveSelectTrailingIcon));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    await tester.tap(find.byType(ExpressiveSelectTrailingIcon));
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    await tester.tapAt(
      tester.getBottomRight(find.byKey(const ValueKey('outside'))) -
          const Offset(4, 4),
    );
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    focus.dispose();
  });

  testWidgets('the system back closes the menu before it reaches the page '
      '(ExposedDropdownMenuBox\'s BackHandler)', (tester) async {
    final text = TextEditingController();
    await tester.pumpWidget(host((context) => combobox(controller: text)));
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'o');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);

    // The app's first page: this back would otherwise leave the app.
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(text.text, 'o');
    expect(find.byType(ExpressiveCombobox<String>), findsOneWidget);
    text.dispose();
  });

  testWidgets('Down hands the keyboard to the items; Escape closes', (
    tester,
  ) async {
    final text = TextEditingController();
    final focus = FocusNode();
    final chosen = <String>[];
    await tester.pumpWidget(
      host(
        (context) =>
            combobox(controller: text, focusNode: focus, chosen: chosen),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'o');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(focus.hasPrimaryFocus, isTrue);
    await tester.enterText(find.byType(EditableText), 'os');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focus.hasPrimaryFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(chosen, <String>['Oslo']);
    expect(text.text, 'Oslo');
    focus.dispose();
    text.dispose();
  });

  testWidgets('words no option fits say so in the menu, in its supporting '
      'type and ink and announced; the keys keep to the field', (tester) async {
    final semantics = tester.ensureSemantics();
    final text = TextEditingController();
    final focus = FocusNode();
    final chosen = <String>[];
    await tester.pumpWidget(
      host(
        (context) =>
            combobox(controller: text, focusNode: focus, chosen: chosen),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'xyz');
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    final said = find.text('No results');
    expect(said, findsOneWidget);
    expect(
      tester.getSemantics(said),
      isSemantics(label: 'No results', isLiveRegion: true),
    );
    final t = tester.element(said).expressiveTheme;
    final style = tester
        .widget<RichText>(
          find.descendant(of: said, matching: find.byType(RichText)),
        )
        .text
        .style!;
    expect(style.color, t.colors.onSurfaceVariant);
    expect(style.fontSize, t.type.bodyMedium.fontSize);
    // Nothing to walk to: Down stays in the field.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focus.hasPrimaryFocus, isTrue);
    expect(menu, findsOneWidget);
    // Escape hides it; more typing says it again.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    await tester.enterText(find.byType(EditableText), 'xyzw');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    // Enter takes nothing: the words stay.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    expect(chosen, isEmpty);
    expect(text.text, 'xyzw');
    // Tab closes it on its way out.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(menu, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
    // An app's own words stand in for the look's.
    await tester.pumpWidget(
      host(
        (context) => ExpressiveCombobox<String>(
          options: <ExpressiveSelectOption<String>>[
            for (final city in cities)
              ExpressiveSelectOption<String>(city, city),
          ],
          label: 'City',
          emptyBuilder: (context) => const Text('No city by that name'),
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('No city by that name'), findsOneWidget);
    expect(find.text('No results'), findsNothing);
    semantics.dispose();
    focus.dispose();
    text.dispose();
  });

  testWidgets('a disabled combobox never opens', (tester) async {
    await tester.pumpWidget(host((context) => combobox(enabled: false)));
    await tester.tap(find.byType(ExpressiveSelectTrailingIcon));
    await tester.pumpAndSettle();
    expect(menu, findsNothing);
  });

  testWidgets('selects and comboboxes fit at text scale 1.3 in both '
      'directions', (tester) async {
    for (final direction in TextDirection.values) {
      await tester.pumpWidget(
        host(
          (context) => Column(
            children: <Widget>[
              liveSelect(initial: 'm'),
              combobox(),
            ],
          ),
          scale: 1.3,
          direction: direction,
        ),
      );
      await tester.tap(find.byType(ExpressiveTextField).first);
      await tester.pumpAndSettle();
      expect(menu, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Small').last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
