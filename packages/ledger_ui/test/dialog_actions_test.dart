// A dialog asks with as many acts as its question has: three acts share the
// card's width when their words fit and otherwise stack across it, the
// confirm on top, as the dialog rule stacks them; the slip carries one seal
// (the confirm, or failing one the loss), the loss beside it ringed in the
// vermilion; raised, it opens on the
// act that is not destructive and completes with the pressed act's value;
// the two-label form still asks as before.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

void _size(WidgetTester t, Size size) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      LedgerHost(brightness: Brightness.light, child: page!),
  home: Center(child: child),
);

const List<LedgerDialogAction> _unsaved = [
  LedgerDialogAction('Cancel', value: 'cancel'),
  LedgerDialogAction('Discard', value: 'discard', isDestructiveAction: true),
  LedgerDialogAction('Save changes', value: 'save', isDefaultAction: true),
];

LedgerButton _button(WidgetTester t, String label) => t.widget<LedgerButton>(
  find.ancestor(of: find.text(label), matching: find.byType(LedgerButton)),
);

/// The paint of the face an act's [label] stands on.
BoxDecoration _ground(WidgetTester t, String label) => t
    .widgetList<Container>(
      find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(LedgerButton),
        ),
        matching: find.byType(Container),
      ),
    )
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .first;

void main() {
  testWidgets('three acts that do not fit a row stack, the confirm on top', (
    t,
  ) async {
    _size(t, const Size(390, 844));
    await t.pumpWidget(
      _host(
        const LedgerDialog(
          title: 'Unsaved changes',
          body: 'Save your changes before leaving this task?',
          actions: [
            LedgerDialogAction('Cancel', onPressed: _noop),
            LedgerDialogAction(
              'Discard',
              onPressed: _noop,
              isDestructiveAction: true,
            ),
            LedgerDialogAction(
              'Save changes',
              onPressed: _noop,
              isDefaultAction: true,
            ),
          ],
        ),
      ),
    );
    Rect act(String label) => t.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(LedgerButton)),
    );
    final save = act('Save changes'), discard = act('Discard');
    final cancel = act('Cancel');
    expect(save.bottom, lessThanOrEqualTo(discard.top));
    expect(discard.bottom, lessThanOrEqualTo(cancel.top));
    expect({save.width, discard.width, cancel.width}, hasLength(1));
    expect(save.left, discard.left);
    // One seal, the confirm's green; the loss ringed in the vermilion, the
    // way out ringed in the ink.
    final theme = t.element(find.byType(LedgerDialog)).ledgerTheme;
    expect(_ground(t, 'Save changes').color, theme.accent);
    expect(_ground(t, 'Discard').color, isNot(theme.danger));
    expect((_ground(t, 'Discard').border! as Border).top.color, theme.danger);
    expect(_button(t, 'Discard').isDestructiveAction, isTrue);
    expect(_button(t, 'Cancel').isDestructiveAction, isFalse);
  });

  testWidgets('with no confirm among them, the loss is the slip\'s seal', (
    t,
  ) async {
    _size(t, const Size(390, 844));
    await t.pumpWidget(
      _host(
        const LedgerDialog(
          title: 'Delete this entry?',
          actions: [
            LedgerDialogAction('Keep', onPressed: _noop),
            LedgerDialogAction(
              'Delete',
              onPressed: _noop,
              isDestructiveAction: true,
            ),
          ],
        ),
      ),
    );
    final theme = t.element(find.byType(LedgerDialog)).ledgerTheme;
    expect(_ground(t, 'Delete').color, theme.danger);
    expect(_ground(t, 'Keep').color, isNot(theme.danger));
  });

  testWidgets('acts whose words fit share the row evenly', (t) async {
    _size(t, const Size(1440, 900));
    await t.pumpWidget(
      _host(
        const LedgerDialog(
          title: 'Join the call?',
          actions: [
            LedgerDialogAction('No', onPressed: _noop),
            LedgerDialogAction('Ask', onPressed: _noop),
            LedgerDialogAction('Yes', onPressed: _noop, isDefaultAction: true),
          ],
        ),
      ),
    );
    Rect act(String label) => t.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(LedgerButton)),
    );
    final no = act('No'), later = act('Ask'), yes = act('Yes');
    expect({no.top, later.top, yes.top}, hasLength(1));
    expect({no.width, later.width, yes.width}, hasLength(1));
    expect(no.right, lessThan(later.left));
    expect(later.right, lessThan(yes.left));
  });

  testWidgets('raised with its acts, it opens on the safe act and completes '
      'with the pressed act\'s value', (t) async {
    _size(t, const Size(390, 844));
    Object? result = 'unset';
    var ran = 0;
    await t.pumpWidget(
      _host(
        Builder(
          builder: (context) => LedgerButton(
            'Leave',
            onPressed: () async {
              result = await LedgerDialog.showActions<String>(
                context,
                title: 'Unsaved changes',
                body: 'Save your changes before leaving this task?',
                actions: [
                  ..._unsaved.take(2),
                  LedgerDialogAction(
                    'Save changes',
                    value: 'save',
                    isDefaultAction: true,
                    onPressed: () => ran++,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    // A destructive act among them: the focus starts on the first that
    // is not.
    expect(_button(t, 'Cancel').autofocus, isTrue);
    expect(_button(t, 'Discard').autofocus, isFalse);
    expect(_button(t, 'Save changes').autofocus, isFalse);

    await t.tap(find.text('Save changes'));
    await t.pumpAndSettle();
    expect(find.byType(LedgerDialog), findsNothing);
    expect((result, ran), ('save', 1));

    await t.tap(find.text('Leave'));
    await t.pumpAndSettle();
    await t.tap(find.text('Discard'));
    await t.pumpAndSettle();
    expect(result, 'discard');
  });

  testWidgets('the two-label form asks as before', (t) async {
    _size(t, const Size(390, 844));
    bool? answer;
    await t.pumpWidget(
      _host(
        Builder(
          builder: (context) => LedgerButton(
            'Delete',
            onPressed: () async {
              answer = await LedgerDialog.show(
                context,
                title: 'Delete this entry?',
                type: LedgerDialogType.destructive,
                confirmLabel: 'Delete entry',
              );
            },
          ),
        ),
      ),
    );
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(_button(t, 'Cancel').autofocus, isTrue);
    await t.tap(find.text('Delete entry'));
    await t.pumpAndSettle();
    expect(answer, isTrue);
  });
}

void _noop() {}
