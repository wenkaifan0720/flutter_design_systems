/// The component themes (`component_themes.dart`): empty in every preset (no
/// pixel moves), carried, compared and lerped by the theme, and each of the
/// ten parts painting its own theme's slots for its states, over its
/// Compose defaults.
library;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final ExpressiveThemeData _base = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

/// One part's slots, told apart by [part]: the container at rest and
/// selected, the content and the outline each a colour of their own.
({
  ExpressiveComponentThemeData data,
  Color container,
  Color selected,
  Color content,
  Color outline,
})
_slots(int part) {
  final container = Color(0xFF100000 + part);
  final selected = Color(0xFF200000 + part);
  final content = Color(0xFF300000 + part);
  final outline = Color(0xFF400000 + part);
  return (
    data: ExpressiveComponentThemeData(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? selected : container,
      ),
      foregroundColor: WidgetStatePropertyAll<Color?>(content),
      outline: WidgetStatePropertyAll<Color?>(outline),
    ),
    container: container,
    selected: selected,
    content: content,
    outline: outline,
  );
}

final _button = _slots(1);
final _iconButton = _slots(2);
final _segment = _slots(3);
final _chip = _slots(4);
final _listTile = _slots(5);
final _appBar = _slots(6);
final _menu = _slots(7);
final _snackBar = _slots(8);
final _dialog = _slots(9);
final _field = _slots(10);

final ExpressiveThemeData _themed = _base.copyWith(
  buttonTheme: _button.data,
  iconButtonTheme: _iconButton.data,
  segmentedButtonTheme: _segment.data,
  chipTheme: _chip.data,
  listTileTheme: _listTile.data,
  appBarTheme: _appBar.data,
  menuTheme: _menu.data,
  snackBarTheme: _snackBar.data,
  dialogTheme: _dialog.data,
  textFieldTheme: _field.data,
);

Widget _host(WidgetBuilder builder, {ExpressiveThemeData? theme}) =>
    MaterialApp(
      builder: (context, app) => ExpressiveHost(
        light: theme ?? _themed,
        brightness: Brightness.light,
        child: app!,
      ),
      home: Builder(
        builder: (context) =>
            Center(child: SizedBox(width: 360, child: builder(context))),
      ),
    );

ExpressivePressable _pressable(WidgetTester tester, String text) =>
    tester.widget<ExpressivePressable>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(ExpressivePressable),
          )
          .first,
    );

Color? _ink(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;

Iterable<Color> _surfaces(WidgetTester tester, String text) => tester
    .widgetList<ExpressiveSurface>(
      find.ancestor(
        of: find.text(text),
        matching: find.byType(ExpressiveSurface),
      ),
    )
    .map((surface) => surface.color);

void main() {
  test(
    'stateful style overrides fall through per state and interpolate geometry',
    () {
      const fallback = ExpressiveComponentThemeData(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
        backgroundColor: WidgetStatePropertyAll(Color(0xff112233)),
        padding: WidgetStatePropertyAll(EdgeInsets.all(8)),
      );
      final override = ExpressiveComponentThemeData(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? const Color(0xff445566)
              : null,
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
      );
      final merged = fallback.merge(override);
      expect(merged.backgroundColor!.resolve({}), const Color(0xff112233));
      expect(
        merged.backgroundColor!.resolve({WidgetState.pressed}),
        const Color(0xff445566),
      );
      expect(merged.shape!.resolve({}), const RoundedRectangleBorder());
      expect(merged.padding!.resolve({}), const EdgeInsets.all(16));
      final middle = ExpressiveComponentThemeData.lerp(fallback, merged, .5);
      expect(middle.padding!.resolve({}), const EdgeInsets.all(12));
      expect(
        const ExpressiveComponentThemeData(
          shape: WidgetStatePropertyAll(CircleBorder()),
        ).isEmpty,
        isFalse,
      );
      expect(fallback.copyWith(), fallback);
    },
  );

  test('every preset carries none, light and dark', () {
    for (final id in ExpressiveThemeData.presets) {
      for (final brightness in Brightness.values) {
        final theme = ExpressiveThemeData.preset(id, brightness);
        expect(theme.buttonTheme.isEmpty, isTrue);
        expect(theme.chipTheme.isEmpty, isTrue);
      }
    }
  });

  test('the theme carries, compares and lerps them', () {
    final a = _base.copyWith(chipTheme: _chip.data);
    expect(a.chipTheme, _chip.data);
    expect(a.buttonTheme.isEmpty, isTrue);
    expect(a, _base.copyWith(chipTheme: _chip.data));
    expect(a.hashCode, _base.copyWith(chipTheme: _chip.data).hashCode);
    expect(a == _base, isFalse);
    // A component theme replaces only its own.
    final b = a.copyWith(
      chipTheme: const ExpressiveComponentThemeData(),
      buttonTheme: _button.data,
    );
    expect(b.chipTheme.isEmpty, isTrue);
    expect(b.buttonTheme, _button.data);

    final mid = ExpressiveThemeData.lerp(
      _base.copyWith(chipTheme: _chip.data),
      _base.copyWith(chipTheme: _button.data),
      0.5,
    );
    expect(
      mid.chipTheme.foregroundColor!.resolve(const <WidgetState>{}),
      Color.lerp(_chip.content, _button.content, 0.5),
    );
    expect(
      _chip.data.copyWith(outline: _button.data.outline).outline,
      _button.data.outline,
    );
    expect(
      ExpressiveComponentThemeData.resolve(null, const {}, _chip.content),
      _chip.content,
    );
    expect(
      expressiveComponentStates(
        enabled: false,
        selected: true,
        focused: true,
        error: true,
      ),
      <WidgetState>{
        WidgetState.disabled,
        WidgetState.selected,
        WidgetState.focused,
        WidgetState.error,
      },
    );
    final described = a.toDiagnosticsNode().toStringDeep();
    expect(described, contains('chipTheme'));
    expect(
      _chip.data.toDiagnosticsNode().toStringDeep(),
      allOf(contains('backgroundColor'), contains('outline')),
    );
    expect(
      _themed.toDiagnosticsNode().toStringDeep(),
      contains('segmentedButtonTheme'),
    );
  });

  testWidgets('buttons and toggle buttons paint the button theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExpressiveFilledButton('Save', onPressed: () {}),
            ExpressiveOutlinedButton('Edit', onPressed: () {}),
            ExpressiveFilledButton(
              'Delete',
              style: ExpressiveFilledButton.styleFrom(
                backgroundColor: context.expressiveTheme.colors.error,
                foregroundColor: context.expressiveTheme.colors.onError,
              ),
              onPressed: () {},
            ),
            ExpressiveToggleButton(
              value: true,
              onChanged: (_) {},
              label: 'Bold',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = _pressable(tester, 'Save');
    expect(save.color, _button.container);
    expect(save.contentColor, _button.content);
    expect(_ink(tester, 'Save'), _button.content);
    expect(_pressable(tester, 'Edit').side.color, _button.outline);
    // A danger button keeps its error tones: its own style wins over the
    // theme where the container is painted (the pressable's `color` is the
    // theme's, before the style resolves).
    expect(_surfaces(tester, 'Delete'), contains(_base.colors.error));
    expect(_ink(tester, 'Delete'), _base.colors.onError);
    expect(_pressable(tester, 'Bold').color, _button.selected);
  });

  testWidgets('icon buttons paint the icon button theme', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => ExpressiveIconButton(
          ExpressiveSymbols.close,
          onPressed: () {},
          semanticLabel: 'Close',
        ),
      ),
    );
    final pressable = tester.widget<ExpressivePressable>(
      find.byType(ExpressivePressable),
    );
    expect(pressable.color, _iconButton.container);
    expect(pressable.contentColor, _iconButton.content);
  });

  testWidgets('segments paint the segmented button theme', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => ExpressiveSegmentedButton<String>(
          segments: const <ExpressiveButtonSegment<String>>[
            ExpressiveButtonSegment('day', 'Day'),
            ExpressiveButtonSegment('week', 'Week'),
          ],
          value: 'day',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_pressable(tester, 'Day').color, _segment.selected);
    expect(_pressable(tester, 'Week').color, _segment.container);
    expect(_ink(tester, 'Week'), _segment.content);
  });

  testWidgets('chips paint the chip theme', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => Wrap(
          children: <Widget>[
            ExpressiveChip('Assist', onPressed: () {}),
            ExpressiveChip('Filter', selected: true, onPressed: () {}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final assist = _pressable(tester, 'Assist');
    expect(assist.color, _chip.container);
    expect(assist.side.color, _chip.outline);
    expect(_ink(tester, 'Assist'), _chip.content);
    expect(_pressable(tester, 'Filter').color, _chip.selected);
  });

  testWidgets('list rows paint the list tile theme; their own colour wins', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExpressiveListTile(
              title: const Text('Inbox'),
              subtitle: const Text('3 new'),
              onTap: () {},
            ),
            ExpressiveListTile.selectable(
              title: const Text('Starred'),
              selected: true,
              onTap: () {},
            ),
            ExpressiveListTile(
              title: const Text('Own'),
              tileColor: const Color(0xFF00FF00),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_pressable(tester, 'Inbox').color, _listTile.container);
    expect(_ink(tester, 'Inbox'), _listTile.content);
    expect(_ink(tester, '3 new'), _listTile.content);
    expect(_pressable(tester, 'Starred').color, _listTile.selected);
    expect(_pressable(tester, 'Own').color, const Color(0xFF00FF00));
  });

  testWidgets('the app bar paints its theme', (tester) async {
    await tester.pumpWidget(
      _host((context) => const ExpressiveAppBar(title: 'Inbox')),
    );
    await tester.pumpAndSettle();
    expect(_ink(tester, 'Inbox'), _appBar.content);
    final boxes = tester
        .widgetList<ExpressiveSurface>(
          find.ancestor(
            of: find.text('Inbox'),
            matching: find.byType(ExpressiveSurface),
          ),
        )
        .map((box) => box.color);
    expect(boxes, contains(_appBar.container));
  });

  testWidgets('menus paint the menu theme', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => ExpressiveMenu(
          entries: <ExpressiveMenuEntry>[
            ExpressiveMenuItem('Rename', onPressed: () {}),
          ],
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(_ink(tester, 'Rename'), _menu.content);
    expect(_surfaces(tester, 'Rename'), contains(_menu.container));
  });

  testWidgets('the snackbar paints its theme', (tester) async {
    await tester.pumpWidget(
      _host((context) => const ExpressiveSnackBar('Saved')),
    );
    expect(_surfaces(tester, 'Saved').first, _snackBar.container);
    expect(_ink(tester, 'Saved'), _snackBar.content);
  });

  testWidgets('the alert dialog paints its theme', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => const ExpressiveDialog(
          title: 'Rename',
          text: 'Pick a new name.',
          actions: <ExpressiveDialogAction>[ExpressiveDialogAction('Done')],
        ),
      ),
    );
    expect(_surfaces(tester, 'Rename'), contains(_dialog.container));
    expect(_ink(tester, 'Rename'), _dialog.content);
    expect(_ink(tester, 'Pick a new name.'), _dialog.content);
  });

  testWidgets('text fields paint the text field theme', (tester) async {
    for (final style in ExpressiveTextFieldKind.values) {
      await tester.pumpWidget(
        _host((context) => ExpressiveTextField(kind: style, label: style.name)),
      );
      await tester.pumpAndSettle();
      final field = find.byType(ExpressiveTextField);
      expect(
        field,
        paints
          ..path(color: _field.container)
          ..something((method, args) {
            // A paint holds its colour as floats: compare the ARGB.
            const drawn = <Symbol>{
              #drawPath,
              #drawLine,
              #drawRect,
              #drawRRect,
              #drawDRRect,
            };
            return drawn.contains(method) &&
                (args.last as Paint).color.toARGB32() ==
                    _field.outline.toARGB32();
          }),
        reason: style.name,
      );
    }
  });

  testWidgets('an empty theme leaves every part as it was', (tester) async {
    await tester.pumpWidget(
      _host(
        (context) => ExpressiveFilledButton('Save', onPressed: () {}),
        theme: _base,
      ),
    );
    final plain = _pressable(tester, 'Save');
    expect(plain.color, isNot(_button.container));
    expect(plain.color, _base.colors.primary);
  });
}
