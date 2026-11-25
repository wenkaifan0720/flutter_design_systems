// Which side of its field a list opens on, as Material's menus place theirs:
// the side it asks for (below) while that side holds the list, or holds a
// sensible least (the placement's preferred extent) of a longer one, which
// then shrinks to the room and scrolls; the other side only when it has
// more room and the asked side can't. For a popover's list, a combobox's
// and a tag input's, near the top, the middle and the foot of a phone and a
// desk, at 1x and 2x text, with the phone's keyboard up.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');
const _listKey = ValueKey('list');
const _phone = Size(390, 844);
const _desk = Size(1440, 900);
const _names = [
  'Maya Reed',
  'Sam Okafor',
  'Noor Haddad',
  'Inez Park',
  'Leo Silva',
];

// A view of [size] logical pixels, with the keyboard's [keyboard] height.
void _view(WidgetTester tester, Size size, {double keyboard = 0}) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size
    ..viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

// [child] with its top [top] px down the page, [textScale] text.
Widget _at(double top, Widget child, {double textScale = 1}) => harness(
  Align(
    alignment: Alignment.topLeft,
    child: Padding(
      padding: EdgeInsets.only(top: top, left: 16),
      child: SizedBox(width: 320, child: child),
    ),
  ),
  textScale: textScale,
);

// Rows that grow with the text, as a look's do.
Widget _row(BuildContext context, String label) => SizedBox(
  height: MediaQuery.textScalerOf(context).scale(40),
  child: Text(label),
);

Widget _combobox({
  List<String> options = _names,
  OptionsViewOpenDirection direction = OptionsViewOpenDirection.down,
}) => RawCombobox<String>(
  options: options,
  optionsViewOpenDirection: direction,
  fieldBuilder: (context, field) => plainField(
    key: _fieldKey,
    controller: field.controller,
    focusNode: field.focusNode,
    onSubmitted: field.submit,
    width: 320,
  ),
  optionBuilder: (context, option, states) => _row(context, option),
  surfaceBuilder: (context, list) => KeyedSubtree(key: _listKey, child: list),
);

late RawPopoverInfo _info;

// A select's list: the field opens a column of [count] rows under it.
Widget _select({int count = 5}) => RawPopover(
  anchorBuilder: (context, anchor) => RawButton(
    onPressed: anchor.toggle,
    builder: (context, states, _) =>
        const SizedBox(key: _fieldKey, height: 44, child: Text('Assignee')),
  ),
  overlayBuilder: (context, info) {
    _info = info;
    return ConstrainedBox(
      key: _listKey,
      constraints: BoxConstraints(maxHeight: info.maxSize.height),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in _names.take(count)) _row(context, name),
          ],
        ),
      ),
    );
  },
);

enum _Side { above, below }

_Side _sideOf(WidgetTester tester) {
  final field = tester.getRect(find.byKey(_fieldKey));
  final list = tester.getRect(find.byKey(_listKey));
  if (list.top >= field.bottom - 0.5) return _Side.below;
  if (list.bottom <= field.top + 0.5) return _Side.above;
  fail('the list ($list) lies over its field ($field)');
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byKey(_fieldKey));
  await tester.pumpAndSettle();
}

void main() {
  group('a popover\'s list (a select)', () {
    testWidgets('a short list that fits under its field opens below, though '
        'the room there is under the preferred extent', (tester) async {
      _view(tester, _phone);
      // 160 px under the field; three rows are 120.
      await tester.pumpWidget(_at(844 - 44 - 160, _select(count: 3)));
      await _open(tester);
      expect(_sideOf(tester), _Side.below);
      expect(_info.side, RawPopoverSide.below);
    });

    testWidgets('a list that can\'t fit and has under the preferred extent '
        'below flips above', (tester) async {
      _view(tester, _phone);
      await tester.pumpWidget(_at(844 - 44 - 160, _select()));
      await _open(tester);
      expect(_sideOf(tester), _Side.above);
      expect(_info.side, RawPopoverSide.above);
    });

    testWidgets('a list with the preferred extent below stays there, shrunk '
        'to the room, though above has more', (tester) async {
      _view(tester, _phone);
      await tester.pumpWidget(_at(844 - 44 - 230, _select(), textScale: 2));
      await _open(tester);
      expect(_sideOf(tester), _Side.below);
      final list = tester.getRect(find.byKey(_listKey));
      expect(list.bottom, lessThanOrEqualTo(844 - 8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('it is never painted on the wrong side, even in the frame it '
        'opens', (tester) async {
      _view(tester, _phone);
      await tester.pumpWidget(_at(844 - 44 - 160, _select(count: 3)));
      await tester.tap(find.byKey(_fieldKey));
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final shown = find.byKey(_listKey).hitTestable();
        if (shown.evaluate().isNotEmpty) {
          expect(_sideOf(tester), _Side.below, reason: 'frame $frame');
        }
      }
    });
  });

  group('a combobox\'s list', () {
    for (final (name, size) in [('390', _phone), ('1440', _desk)]) {
      for (final scale in [1.0, 2.0]) {
        final round = '$name, ${scale}x text';
        testWidgets('near the top: below ($round)', (tester) async {
          _view(tester, size);
          await tester.pumpWidget(_at(120, _combobox(), textScale: scale));
          await _open(tester);
          expect(_sideOf(tester), _Side.below);
        });

        testWidgets('in the middle, with room below and more above: below '
            '($round)', (tester) async {
          _view(tester, size);
          // A field low in a form: 300 to 430 px under the field.
          final top = size.height - 48 - (scale == 1 ? 330 : 430);
          await tester.pumpWidget(_at(top, _combobox(), textScale: scale));
          await _open(tester);
          expect(_sideOf(tester), _Side.below);
        });

        testWidgets('at the foot: above ($round)', (tester) async {
          _view(tester, size);
          await tester.pumpWidget(
            _at(size.height - 48 - 100, _combobox(), textScale: scale),
          );
          await _open(tester);
          expect(_sideOf(tester), _Side.above);
        });
      }
    }

    testWidgets('a short list that fits under the field at the foot stays '
        'below', (tester) async {
      _view(tester, _phone);
      await tester.pumpWidget(
        _at(
          844 - 48 - 110,
          _combobox(options: const ['Open studio', 'Field guide']),
        ),
      );
      await _open(tester);
      expect(_sideOf(tester), _Side.below);
    });

    testWidgets('a phone\'s keyboard up leaves too little below: above', (
      tester,
    ) async {
      _view(tester, _phone, keyboard: 336);
      await tester.pumpWidget(_at(360, _combobox()));
      await _open(tester);
      expect(_sideOf(tester), _Side.above);
      final list = tester.getRect(find.byKey(_listKey));
      expect(list.top, greaterThanOrEqualTo(0));
    });

    testWidgets('the same field without the keyboard: below', (tester) async {
      _view(tester, _phone);
      await tester.pumpWidget(_at(360, _combobox()));
      await _open(tester);
      expect(_sideOf(tester), _Side.below);
    });

    testWidgets('asked for above, it opens above while above holds it', (
      tester,
    ) async {
      _view(tester, _phone);
      await tester.pumpWidget(
        _at(500, _combobox(direction: OptionsViewOpenDirection.up)),
      );
      await _open(tester);
      expect(_sideOf(tester), _Side.above);
      // Near the top, above can't hold it: below.
      await tester.pumpWidget(
        _at(60, _combobox(direction: OptionsViewOpenDirection.up)),
      );
      await tester.pumpAndSettle();
      expect(_sideOf(tester), _Side.below);
    });

    testWidgets('most space keeps Flutter\'s meaning: the larger side', (
      tester,
    ) async {
      _view(tester, _phone);
      await tester.pumpWidget(
        _at(
          844 - 48 - 330,
          _combobox(direction: OptionsViewOpenDirection.mostSpace),
        ),
      );
      await _open(tester);
      expect(_sideOf(tester), _Side.above);
    });

    testWidgets('it is never painted on the wrong side, even in the frame it '
        'opens', (tester) async {
      _view(tester, _phone);
      await tester.pumpWidget(_at(844 - 48 - 100, _combobox()));
      await tester.tap(find.byKey(_fieldKey));
      for (var frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byKey(_listKey).hitTestable().evaluate().isNotEmpty) {
          expect(_sideOf(tester), _Side.above, reason: 'frame $frame');
        }
      }
    });

    test('below is the default', () {
      expect(
        RawCombobox<String>(
          fieldBuilder: (context, field) => const SizedBox(),
          optionBuilder: (context, option, states) => const SizedBox(),
        ).optionsViewOpenDirection,
        OptionsViewOpenDirection.down,
      );
    });
  });

  testWidgets('a tag input\'s suggestions, in the middle with room below: '
      'below', (tester) async {
    _view(tester, _phone);
    await tester.pumpWidget(
      _at(
        844 - 48 - 330,
        RawTagInput<String>(
          values: const [],
          options: _names,
          onChanged: (_) {},
          fieldBuilder: (context, field) => plainField(
            key: _fieldKey,
            controller: field.controller,
            focusNode: field.focusNode,
            onSubmitted: field.submit,
          ),
          optionBuilder: (context, option, states) => _row(context, option),
          surfaceBuilder: (context, list) =>
              KeyedSubtree(key: _listKey, child: list),
          tagBuilder: (context, value, tag) => Text(value),
        ),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'a');
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(RawAutocomplete<Object>));
    expect(
      tester.getRect(find.byKey(_listKey)).top,
      greaterThanOrEqualTo(field.bottom),
    );
  });
}
