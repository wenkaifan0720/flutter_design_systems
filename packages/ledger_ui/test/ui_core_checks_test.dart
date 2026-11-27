// ui_core_test 0.3.0's checks over Ledger's parts on a phone:
// - a field's help and its error are read on the field (DesignFieldWordsCheck);
// - a dialog's actions stand in one row, or in one column of one width with
//   the confirming one on top, at 320 and 390 wide and at 1x and 2x text
//   (DesignDialogActionsCheck);
// - each picker, list, popover, sheet and dialog opens whole on a 390 x 844
//   phone, its anchor high, in the middle or low (DesignOverlayCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _look = 'Ledger';

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: LedgerHost(brightness: Brightness.light, child: child!),
  ),
  home: Material(type: MaterialType.transparency, child: home),
);

void _phone(WidgetTester tester, {double width = 390}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);
}

const _rooms = [
  LedgerSelectItem(value: 'k', label: 'Kitchen'),
  LedgerSelectItem(value: 's', label: 'Study'),
  LedgerSelectItem(value: 'b', label: 'Bedroom'),
  LedgerSelectItem(value: 'g', label: 'Garden'),
  LedgerSelectItem(value: 'h', label: 'Hall'),
  LedgerSelectItem(value: 'l', label: 'Loft'),
];
const _fruit = ['Apple', 'Apricot', 'Avocado', 'Banana', 'Cherry', 'Damson'];

void main() {
  group('a field reads its help and its error', () {
    const help = 'We never share it', error = 'Enter a valid email';
    final fields = <String, Widget Function(String? help, String? error)>{
      'LedgerTextField': (h, e) =>
          LedgerTextField(labelText: 'Email', helperText: h, errorText: e),
      'LedgerTextArea': (h, e) =>
          LedgerTextArea(labelText: 'Notes', helperText: h, errorText: e),
      'LedgerPasswordField': (h, e) => LedgerPasswordField(
        labelText: 'Password',
        helperText: h,
        errorText: e,
      ),
      'LedgerInputGroup': (h, e) => LedgerInputGroup(
        labelText: 'Website',
        before: 'https://',
        helperText: h,
        errorText: e,
      ),
      'LedgerCombobox': (h, e) => LedgerCombobox<String>(
        labelText: 'Fruit',
        options: _fruit,
        helperText: h,
        errorText: e,
      ),
      'LedgerMultiSelect': (h, e) => LedgerMultiSelect<String>(
        labelText: 'Fruit',
        values: const [],
        onChanged: (_) {},
        options: _fruit,
        helperText: h,
        errorText: e,
      ),
      // Its tags are controls of their own beside the entry; the field's
      // words are still read on the entry.
      'LedgerMultiSelect holding a tag': (h, e) => LedgerMultiSelect<String>(
        labelText: 'Fruit',
        values: const ['Apple'],
        onChanged: (_) {},
        options: _fruit,
        helperText: h,
        errorText: e,
      ),
    };
    for (final MapEntry(key: name, value: field) in fields.entries) {
      for (final (kind, h, e) in const [
        ('help', help, null),
        ('error', null, error),
      ]) {
        testWidgets('$name ($kind)', (tester) async {
          final semantics = tester.ensureSemantics();
          _phone(tester);
          await tester.pumpWidget(
            _app(Center(child: SizedBox(width: 358, child: field(h, e)))),
          );
          await tester.pumpAndSettle();
          DesignFieldWordsCheck(
            look: _look,
            words: [?h, ?e],
          ).check(tester.element(find.byType(Center).first)).verify();
          semantics.dispose();
        });
      }
    }

    // A select is a button, not a text field (the check reads text
    // fields): its help and error are read on the button's own node, the
    // drawn words left out of the tree.
    for (final (kind, h, e) in const [
      ('help', help, null),
      ('error', null, error),
    ]) {
      testWidgets('LedgerSelect ($kind)', (tester) async {
        final semantics = tester.ensureSemantics();
        _phone(tester);
        await tester.pumpWidget(
          _app(
            Center(
              child: SizedBox(
                width: 358,
                child: LedgerSelect<String>(
                  labelText: 'Room',
                  items: _rooms,
                  value: null,
                  onChanged: (_) {},
                  helperText: h,
                  errorText: e,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final words = (h ?? e)!;
        final saying = <SemanticsData>[];
        void visit(SemanticsNode node) {
          if (!node.isMergedIntoParent) {
            final data = node.getSemanticsData();
            if ('${data.label} ${data.hint}'.contains(words)) {
              saying.add(data);
            }
          }
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
        );
        expect(saying, hasLength(1));
        expect(saying.single.label, contains('Room'));
        expect(saying.single.flagsCollection.isButton, isTrue);
        semantics.dispose();
      });
    }
  });

  group("a dialog's actions stand in one row or one column", () {
    final dialogs = <String, (Widget, List<String>)>{
      'its own three': (
        LedgerDialog(
          title: 'Unsaved changes',
          body: 'Keep the edits to this goal?',
          actions: [
            LedgerDialogAction('Cancel', onPressed: () {}),
            LedgerDialogAction(
              'Discard',
              onPressed: () {},
              isDestructiveAction: true,
            ),
            LedgerDialogAction(
              'Save changes',
              onPressed: () {},
              isDefaultAction: true,
            ),
          ],
        ),
        ['Cancel', 'Discard', 'Save changes'],
      ),
      'a cancel and a confirm': (
        LedgerDialog(
          title: 'Freeze this card?',
          body: 'Payments stop until you unfreeze it.',
          cancelLabel: 'Keep it working',
          confirmLabel: 'Freeze the card',
          onCancelPressed: () {},
          onConfirmPressed: () {},
        ),
        ['Keep it working', 'Freeze the card'],
      ),
    };
    for (final MapEntry(key: name, value: (dialog, actions))
        in dialogs.entries) {
      for (final width in [320.0, 390.0]) {
        for (final scale in [1.0, 2.0]) {
          testWidgets('$name at $width wide, ${scale}x', (tester) async {
            final semantics = tester.ensureSemantics();
            _phone(tester, width: width);
            await tester.pumpWidget(
              _app(Center(child: dialog), textScale: scale),
            );
            await tester.pumpAndSettle();
            DesignDialogActionsCheck(
              look: _look,
              actions: actions,
            ).check(tester.element(find.byType(LedgerDialog))).verify();
            semantics.dispose();
          });
        }
      }
    }
  });

  group('each overlay opens whole on a phone', () {
    // What opens, from an anchor at the alignment given; the tap that opens
    // it lands on the anchor.
    final opens = <String, Widget Function(Key anchor)>{
      'a select': (k) => SizedBox(
        width: 358,
        child: LedgerSelect<String>(
          key: k,
          labelText: 'Room',
          items: _rooms,
          value: 'g',
          onChanged: (_) {},
        ),
      ),
      'a combobox': (k) => SizedBox(
        width: 358,
        child: LedgerCombobox<String>(
          key: k,
          labelText: 'Fruit',
          options: _fruit,
        ),
      ),
      'a multi-select': (k) => SizedBox(
        width: 358,
        child: LedgerMultiSelect<String>(
          key: k,
          labelText: 'Fruit',
          values: const [],
          onChanged: (_) {},
          options: _fruit,
        ),
      ),
      'a menu': (k) => LedgerPopover(
        semanticLabel: 'Months',
        anchor: (context, a) =>
            LedgerButton('More', key: k, onPressed: a.toggle),
        child: LedgerMenu(
          head: 'Spent by month',
          items: [
            for (final m in ['November', 'October', 'September', 'August'])
              LedgerMenuItem('$m 2026', onTap: () {}),
          ],
        ),
      ),
      'a date picker': (k) => Builder(
        builder: (context) => LedgerButton(
          'Due',
          key: k,
          onPressed: () => LedgerSheet.show<void>(
            context,
            title: 'Due',
            builder: (context) => [
              LedgerDatePicker(
                labelText: 'Due',
                value: DateTime(2026, 11, 12),
                presentation: LedgerDatePickerPresentation.inline,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
      'a dialog': (k) => Builder(
        builder: (context) => LedgerButton(
          'Delete',
          key: k,
          onPressed: () => LedgerDialog.show(
            context,
            title: 'Delete this goal?',
            body: 'Its history goes with it.',
            cancelLabel: 'Cancel',
            confirmLabel: 'Delete',
          ),
        ),
      ),
      'a sheet': (k) => Builder(
        builder: (context) => LedgerButton(
          'Sort',
          key: k,
          onPressed: () => LedgerSheet.show<void>(
            context,
            title: 'Sort by',
            builder: (context) => [
              for (final w in ['Newest', 'Oldest', 'Largest', 'Smallest'])
                Text(w),
            ],
          ),
        ),
      ),
      'an action sheet': (k) => Builder(
        builder: (context) => LedgerButton(
          'Photo',
          key: k,
          onPressed: () => showLedgerActionSheet<String>(
            context,
            title: 'This photo',
            acts: const [
              LedgerSheetAct('Share', value: 'share'),
              LedgerSheetAct(
                'Delete',
                value: 'delete',
                isDestructiveAction: true,
              ),
            ],
          ),
        ),
      ),
    };
    for (final MapEntry(key: name, value: open) in opens.entries) {
      for (final (where, y) in const [
        ('high', -.92),
        ('in the middle', 0.0),
        ('low', .92),
      ]) {
        testWidgets('$name, its anchor $where', (tester) async {
          _phone(tester);
          const anchor = ValueKey('anchor');
          await tester.pumpWidget(
            _app(Align(alignment: Alignment(0, y), child: open(anchor))),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(anchor));
          await tester.pumpAndSettle();
          const DesignOverlayCheck(look: _look)
              .check(tester.element(find.byKey(anchor)))
              .verify();
        });
      }
    }
  });
}
