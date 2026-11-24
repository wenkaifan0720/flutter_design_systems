// A multi-select's text entry under its tags. On a run of its own it is as
// tall as a tag (the touch floor), as each run of the line is: its node and
// a tap reach a target's size. Beside a tag, and with no tags, its line keeps
// its place.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _categories = ['Rent', 'Groceries', 'Transit', 'Utilities'];

// Ledger's touch floor, on a phone and on the desktop alike.
const _floor = 44.0;

Widget _app(Widget field) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      LedgerHost(brightness: Brightness.light, child: child!),
  home: Material(
    type: MaterialType.transparency,
    child: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 340, child: field),
      ),
    ),
  ),
);

Widget _select(int tags) => LedgerMultiSelect<String>(
  labelText: 'Categories',
  values: _categories.take(tags).toList(),
  options: _categories,
  onChanged: (_) {},
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

// A node's rectangle on the screen: its own and every parent's transform.
Rect _onScreen(SemanticsNode node) {
  var rect = node.rect;
  for (SemanticsNode? n = node; n != null; n = n.parent) {
    final transform = n.transform;
    if (transform != null) rect = MatrixUtils.transformRect(transform, rect);
  }
  return rect;
}

void main() {
  // At 340 wide, two tags and four tags fill their runs, so the entry wraps
  // to a run of its own; at one and three it stands beside a tag.
  for (final tags in [0, 1, 2, 3, 4]) {
    testWidgets("with $tags tags, the entry's node is a touch target", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      _phone(tester);
      await tester.pumpWidget(_app(_select(tags)));
      await tester.pumpAndSettle();
      final node = _onScreen(tester.getSemantics(find.byType(EditableText)));
      expect(node.height, greaterThanOrEqualTo(_floor));
      expect(node.width, greaterThanOrEqualTo(_floor));
      semantics.dispose();
    });
  }

  for (final tags in [2, 4]) {
    testWidgets(
      'with $tags tags, a tap under the typed line, in its run, writes in it',
      (tester) async {
        _phone(tester);
        await tester.pumpWidget(_app(_select(tags)));
        await tester.pumpAndSettle();
        final text = tester.getRect(find.byType(EditableText));
        await tester.tapAt(Offset(text.center.dx, text.bottom + 6));
        await tester.pump();
        final entry = tester.widget<EditableText>(find.byType(EditableText));
        expect(entry.focusNode.hasFocus, isTrue);
      },
    );
  }

  testWidgets(
    'a run of its own is as tall as a run of tags: the entry beside a tag '
    'and the entry under two take the same room',
    (tester) async {
      _phone(tester);
      Future<double> height(int tags) async {
        await tester.pumpWidget(_app(_select(tags)));
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(LedgerMultiSelect<String>)).height;
      }

      final two = await height(2);
      final three = await height(3);
      expect(three, two);
    },
  );

  testWidgets("with no tags, the line is a text field's line", (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            _select(0),
            const LedgerTextField(labelText: 'Categories'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final select = tester.getRect(find.byType(LedgerMultiSelect<String>));
    final field = tester.getRect(find.byType(LedgerTextField));
    expect(select.height, field.height);
    // The typed line stands at the top of the line, under the label.
    final line = find.descendant(
      of: find.byType(LedgerMultiSelect<String>),
      matching: find.byType(Wrap),
    );
    expect(
      tester.getRect(find.byType(EditableText).first).top,
      tester.getRect(line).top,
    );
  });
}
