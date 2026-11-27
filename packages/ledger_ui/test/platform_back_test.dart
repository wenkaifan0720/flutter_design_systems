// Going back on each platform: on iOS the edge swipe still pops a
// page pushed in Ledger's own motion (Ledger's leaf drops Cupertino's slide, whose own the swipe is; ui_core's
// SwipeBackPageTransitionsBuilder puts it back round the leaf); on Android the system back closes what stands
// open over a page first (a select's list, a popover, a field's suggestions, a sheet, a dialog) and only then pops
// the page. The host alone sets the motion: the app's theme says
// nothing of it, and the platform is the ambient one, as on a device.
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoPageTransition;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

/// A first page with a push to an entry page, under [LedgerHost] alone: the host's theme stands nearest the
/// navigator, so the pushed MaterialPageRoute takes Ledger's motion from it.
Widget _app({Widget? entry, TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => Directionality(
        textDirection: direction,
        child: LedgerHost(brightness: Brightness.light, child: page!),
      ),
      home: Builder(
        builder: (context) => ColoredBox(
          color: LedgerTheme.of(context).background,
          child: Center(
            child: LedgerButton.filled(
              'Open',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ColoredBox(
                    color: LedgerTheme.of(context).background,
                    child: entry ?? const Center(child: Text('Entry')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

Future<void> _open(
  WidgetTester t, {
  Widget? entry,
  TextDirection? direction,
}) async {
  t.view.physicalSize = const Size(390, 1400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    _app(entry: entry, direction: direction ?? TextDirection.ltr),
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Open'));
  await t.pumpAndSettle();
}

/// A horizontal swipe of [across] from [from], held over a few frames as a finger moves.
Future<TestGesture> _swipe(WidgetTester t, Offset from, double across) async {
  final finger = await t.startGesture(from);
  for (var i = 0; i < 6; i++) {
    await finger.moveBy(Offset(across / 6, 0));
    await t.pump(const Duration(milliseconds: 16));
  }
  return finger;
}

double _opacity(WidgetTester t, String words) => t
    .widgetList<FadeTransition>(
      find.ancestor(
        of: find.text(words),
        matching: find.byType(FadeTransition),
      ),
    )
    .fold(1.0, (o, f) => o * f.opacity.value);

/// The system back, as Android sends it.
Future<void> _back(WidgetTester t) async {
  await t.binding.handlePopRoute();
  await t.pumpAndSettle();
}

const _payees = ['Corner Market', 'Cedar Books', 'Blue Fern Café'];

/// An entry page holding each thing that opens over a page.
class _Everything extends StatelessWidget {
  const _Everything();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const Text('Entry'),
        LedgerSelect<String>(
          labelText: 'Currency',
          value: 'USD',
          items: const [
            LedgerSelectItem(value: 'USD', label: 'US dollar'),
            LedgerSelectItem(value: 'EUR', label: 'Euro'),
          ],
          onChanged: (_) {},
        ),
        LedgerCombobox<String>(
          labelText: 'Payee',
          options: _payees,
          onSelected: (_) {},
        ),
        LedgerMultiSelect<String>(
          labelText: 'Split with',
          values: const ['Maren'],
          options: const ['Maren', 'Theo', 'Ana'],
          onChanged: (_) {},
        ),
        LedgerPopover(
          semanticLabel: 'How this is worked out',
          title: 'Safe to spend',
          anchor: (context, a) =>
              LedgerButton.text('How?', onPressed: a.toggle),
          child: const Text('Your balance less bills due before payday.'),
        ),
        LedgerButton.ink(
          'Choose a category',
          onPressed: () => LedgerSheet.show<String>(
            context,
            title: 'Category',
            builder: (context) => [const Text('Groceries')],
          ),
        ),
        LedgerButton.ink(
          'Delete',
          onPressed: () => LedgerDialog.show(
            context,
            title: 'Delete this entry?',
            body: 'It leaves your records for good.',
            type: LedgerDialogType.destructive,
            confirmLabel: 'Delete',
          ),
        ),
      ],
    ),
  );
}

/// iOS, as the device says it (the host follows the ambient platform).
final _iOS = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  testWidgets(
    'under the host alone a pushed page is Ledger\'s leaf: it fades in as it rises, never slides or zooms',
    (t) async {
      await _open(t);
      final settled = t.getRect(find.text('Entry'));
      await _back(t);
      await t.tap(find.text('Open'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(find.byType(CupertinoPageTransition), findsNothing);
      expect(
        _opacity(t, 'Entry'),
        inExclusiveRange(0, 1),
        reason: 'it fades in',
      );
      final mid = t.getRect(find.text('Entry'));
      expect(
        mid.center.dx,
        moreOrLessEquals(settled.center.dx, epsilon: 0.5),
        reason: 'no slide',
      );
      expect(
        mid.width,
        moreOrLessEquals(settled.width, epsilon: 0.5),
        reason: 'no zoom',
      );
      expect(
        mid.top,
        greaterThan(settled.top),
        reason: 'it rises onto the page',
      );
      await t.pumpAndSettle();
    },
    variant: TargetPlatformVariant.all(),
  );

  group('iOS: the edge swipe back, in Ledger\'s motion', () {
    testWidgets('a swipe from the leading edge past half way pops the page; under the finger the page follows it, '
        'and Ledger\'s leaf rests', (t) async {
      await _open(t);
      expect(find.text('Entry'), findsOneWidget);
      final finger = await _swipe(t, const Offset(6, 600), 260);
      expect(
        find.byType(CupertinoPageTransition),
        findsNothing,
        reason:
            'the swipe is ui_core\'s round the leaf, not Cupertino\'s slide',
      );
      expect(
        t.getRect(find.text('Entry')).center.dx,
        greaterThan(195 + 150),
        reason: 'the page follows the finger',
      );
      expect(
        _opacity(t, 'Entry'),
        1,
        reason: 'the leaf rests while a finger holds the page',
      );
      await finger.up();
      await t.pumpAndSettle();
      expect(find.text('Entry'), findsNothing, reason: 'past half way it pops');
      expect(find.text('Open'), findsOneWidget);
    }, variant: _iOS);

    testWidgets('a short swipe lays the page back down', (t) async {
      await _open(t);
      final finger = await _swipe(t, const Offset(6, 600), 90);
      expect(t.getRect(find.text('Entry')).center.dx, greaterThan(195 + 45));
      await finger.up();
      await t.pumpAndSettle();
      expect(find.text('Entry'), findsOneWidget);
      expect(
        t.getRect(find.text('Entry')).center.dx,
        moreOrLessEquals(195, epsilon: 0.5),
      );
      expect(_opacity(t, 'Entry'), 1);
    }, variant: _iOS);

    testWidgets('right to left, the swipe starts on the right edge', (t) async {
      await _open(t, direction: TextDirection.rtl);
      final finger = await _swipe(t, const Offset(384, 600), -260);
      await finger.up();
      await t.pumpAndSettle();
      expect(find.text('Entry'), findsNothing);
    }, variant: _iOS);

    testWidgets(
      'a swipe that starts inside the page is the page\'s, not a back',
      (t) async {
        await _open(t);
        final finger = await _swipe(t, const Offset(60, 600), 260);
        await finger.up();
        await t.pumpAndSettle();
        expect(find.text('Entry'), findsOneWidget);
      },
      variant: _iOS,
    );

    testWidgets('on Android the edge is no back: its system back is', (
      t,
    ) async {
      await _open(t);
      final finger = await _swipe(t, const Offset(6, 600), 260);
      await finger.up();
      await t.pumpAndSettle();
      expect(find.text('Entry'), findsOneWidget);
      await _back(t);
      expect(find.text('Entry'), findsNothing);
    });
  });

  group('Android: the system back closes what is open first', () {
    Future<void> closesFirst(
      WidgetTester t,
      Future<void> Function() open,
      Finder shown,
    ) async {
      await _open(t, entry: const _Everything());
      await open();
      await t.pumpAndSettle();
      expect(shown, findsWidgets, reason: 'open over the page');
      await _back(t);
      expect(shown, findsNothing, reason: 'the back closes it');
      expect(find.text('Entry'), findsOneWidget, reason: 'and leaves the page');
      await _back(t);
      expect(
        find.text('Entry'),
        findsNothing,
        reason: 'the next back pops the page',
      );
    }

    testWidgets('a select\'s list', (t) async {
      await closesFirst(
        t,
        () => t.tap(
          find
              .descendant(
                of: find.byType(LedgerSelect<String>),
                matching: find.byType(LedgerPressable),
              )
              .first,
        ),
        find.text('Euro'),
      );
    });

    testWidgets('a combobox\'s suggestions', (t) async {
      await closesFirst(
        t,
        () => t.tap(
          find.descendant(
            of: find.byType(LedgerCombobox<String>),
            matching: find.byType(EditableText),
          ),
        ),
        find.text('Cedar Books'),
      );
    });

    testWidgets('a tag field\'s suggestions', (t) async {
      await closesFirst(
        t,
        () => t.tap(
          find.descendant(
            of: find.byType(LedgerMultiSelect<String>),
            matching: find.byType(EditableText),
          ),
        ),
        find.text('Theo'),
      );
    });

    testWidgets('a popover', (t) async {
      await closesFirst(
        t,
        () => t.tap(find.text('How?')),
        find.text('Your balance less bills due before payday.'),
      );
    });

    testWidgets('a sheet', (t) async {
      await closesFirst(
        t,
        () => t.tap(find.text('Choose a category')),
        find.text('Groceries'),
      );
    });

    testWidgets('a dialog', (t) async {
      await closesFirst(
        t,
        () => t.tap(find.text('Delete')),
        find.text('Delete this entry?'),
      );
    });
  });
}
