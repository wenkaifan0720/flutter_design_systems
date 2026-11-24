// ui_core_test 0.3.0's checks over Material Expressive's parts on a phone:
// - a field's help and its error are read on the field (DesignFieldWordsCheck);
// - a dialog's actions stand in one row, or in one column of one width with
//   the confirming one on top, at 320 and 390 wide and at 1x and 2x text
//   (DesignDialogActionsCheck);
// - each picker, menu, sheet and dialog opens whole on a 390 x 844 phone,
//   its anchor high, in the middle or low (DesignOverlayCheck).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

const _look = 'Material Expressive';

Widget _app(Widget home, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: ExpressiveHost(brightness: Brightness.light, child: child!),
  ),
  home: Material(type: MaterialType.transparency, child: home),
);

void _phone(WidgetTester tester, {double width = 390}) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);
}

const _rooms = [
  ExpressiveSelectOption('k', 'Kitchen'),
  ExpressiveSelectOption('s', 'Study'),
  ExpressiveSelectOption('b', 'Bedroom'),
  ExpressiveSelectOption('g', 'Garden'),
  ExpressiveSelectOption('h', 'Hall'),
  ExpressiveSelectOption('l', 'Loft'),
];
const _fruit = [
  ExpressiveSelectOption('Apple', 'Apple'),
  ExpressiveSelectOption('Apricot', 'Apricot'),
  ExpressiveSelectOption('Avocado', 'Avocado'),
  ExpressiveSelectOption('Banana', 'Banana'),
  ExpressiveSelectOption('Cherry', 'Cherry'),
  ExpressiveSelectOption('Damson', 'Damson'),
];

void main() {
  group('a field reads its help and its error', () {
    const help = 'We never share it', error = 'Enter a valid email';
    final fields = <String, Widget Function(String? help, String? error)>{
      'ExpressiveTextField': (h, e) =>
          ExpressiveTextField(labelText: 'Email', helperText: h, errorText: e),
      'ExpressiveTextField, outlined': (h, e) => ExpressiveTextField(
        labelText: 'Email',
        kind: ExpressiveTextFieldKind.outlined,
        helperText: h,
        errorText: e,
      ),
      'ExpressiveTextArea': (h, e) =>
          ExpressiveTextArea(labelText: 'Notes', helperText: h, errorText: e),
      'ExpressivePasswordField': (h, e) => ExpressivePasswordField(
        labelText: 'Password',
        helperText: h,
        errorText: e,
      ),
      'ExpressiveSelect': (h, e) => ExpressiveSelect<String>(
        labelText: 'Room',
        options: _rooms,
        value: null,
        onChanged: (_) {},
        helperText: h,
        errorText: e,
      ),
      'ExpressiveCombobox': (h, e) => ExpressiveCombobox<String>(
        labelText: 'Fruit',
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
  });

  group("a dialog's actions stand in one row or one column", () {
    final dialogs = <String, (Widget, List<String>)>{
      'three': (
        const ExpressiveDialog(
          title: 'Unsaved changes',
          text: 'Keep the edits to this note?',
          actions: [
            ExpressiveDialogAction('Cancel'),
            ExpressiveDialogAction('Discard', isDestructiveAction: true),
            ExpressiveDialogAction('Save changes', filled: true),
          ],
        ),
        ['Cancel', 'Discard', 'Save changes'],
      ),
      'a cancel and a confirm': (
        const ExpressiveDialog(
          title: 'Turn off backups?',
          text: 'New photos stop backing up until you turn them on.',
          actions: [
            ExpressiveDialogAction('Keep backing up'),
            ExpressiveDialogAction('Turn off backups', filled: true),
          ],
        ),
        ['Keep backing up', 'Turn off backups'],
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
            ).check(tester.element(find.byType(ExpressiveDialog))).verify();
            semantics.dispose();
          });
        }
      }
    }

    for (final direction in TextDirection.values) {
      testWidgets(
        'stacked, a text action keeps its words at the end of the column, '
        'as in a row, the filled one centred in its pill (${direction.name})',
        (tester) async {
          _phone(tester);
          await tester.pumpWidget(
            _app(
              Directionality(
                textDirection: direction,
                child: Center(child: dialogs['three']!.$1),
              ),
              textScale: 2,
            ),
          );
          await tester.pumpAndSettle();
          final dialog = tester.getRect(find.byType(ExpressiveDialog));
          final rtl = direction == TextDirection.rtl;
          double end(String label) {
            final words = tester.getRect(find.text(label));
            return rtl ? words.left - dialog.left : dialog.right - words.right;
          }

          // The text actions' words end on one line, near the dialog's end.
          expect(end('Discard'), moreOrLessEquals(end('Cancel'), epsilon: 0.5));
          expect(end('Cancel'), lessThan(dialog.width / 4));
          // The filled action fills the column, its words in the middle.
          expect(
            tester.getCenter(find.text('Save changes')).dx,
            moreOrLessEquals(dialog.center.dx, epsilon: 0.5),
          );
        },
      );
    }
  });

  group('each overlay opens whole on a phone', () {
    // What opens, from an anchor at the alignment given; the tap that opens
    // it lands on the anchor.
    final opens = <String, Widget Function(Key anchor)>{
      'a select': (k) => SizedBox(
        width: 358,
        child: ExpressiveSelect<String>(
          key: k,
          labelText: 'Room',
          options: _rooms,
          value: 'g',
          onChanged: (_) {},
        ),
      ),
      'a combobox': (k) => SizedBox(
        width: 358,
        child: ExpressiveCombobox<String>(
          key: k,
          labelText: 'Fruit',
          options: _fruit,
        ),
      ),
      'a multi-select': (k) => SizedBox(
        width: 358,
        child: ExpressiveMultiSelect<String>(
          key: k,
          labelText: 'Fruit',
          values: const [],
          onChanged: (_) {},
          options: _fruit,
        ),
      ),
      'a menu': (k) => ExpressiveMenu(
        label: 'Months',
        entries: [
          for (final m in ['November', 'October', 'September', 'August'])
            ExpressiveMenuItem('$m 2026'),
        ],
        child: ExpressiveFilledButton('More', key: k, onPressed: () {}),
      ),
      'a date picker': (k) => Builder(
        builder: (context) => ExpressiveFilledButton(
          'Due',
          key: k,
          onPressed: () => showExpressiveDatePicker(
            context: context,
            initialDate: DateTime(2026, 11, 12),
          ),
        ),
      ),
      'a dialog': (k) => Builder(
        builder: (context) => ExpressiveFilledButton(
          'Delete',
          key: k,
          onPressed: () => showExpressiveDialog<void>(
            context: context,
            builder: (_) => const ExpressiveDialog(
              title: 'Delete this note?',
              text: 'Its history goes with it.',
              actions: [
                ExpressiveDialogAction('Cancel'),
                ExpressiveDialogAction('Delete', filled: true),
              ],
            ),
          ),
        ),
      ),
      'a bottom sheet': (k) => Builder(
        builder: (context) => ExpressiveFilledButton(
          'Sort',
          key: k,
          onPressed: () => showExpressiveBottomSheet<void>(
            context,
            builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final w in ['Newest', 'Oldest', 'Largest', 'Smallest'])
                  Text(w),
              ],
            ),
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
