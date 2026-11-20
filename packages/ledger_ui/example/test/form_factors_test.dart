// The form-factor check on Quill's own screens: a phone's inner page has its bar with the way
// back, a desktop's its crumb over the title, and a tablet's, beside the rail where no phone bar stands, the crumb too;
// a sheet spans a phone and stands centred at its measure on a tablet, never stretched across the screen.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart' show LedgerBack, LedgerSheetShell;
import 'package:ledger_ui_example/everyday_screens.dart';

const _phone = Size(390, 844);
const _tablet = Size(768, 1024);
const _desk = Size(1440, 900);

Future<void> _open(WidgetTester t, String id, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    everydayScreens
        .firstWhere((s) => s.id == id)
        .app(Brightness.light, TextDirection.ltr),
  );
  await _settle(t);
}

// Quill's screens keep a few things moving (a caret, a ticker), so the frames are counted, not settled.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  for (final id in ['receipt', 'new-entry']) {
    for (final size in [_phone, _tablet, _desk]) {
      testWidgets(
        '$id at ${size.width.round()}: the inner page has its way back, and it goes back',
        (t) async {
          await _open(t, id, size);
          final back = find.byType(LedgerBack);
          expect(
            back,
            findsOneWidget,
            reason: 'an inner page says how to leave it',
          );
          final reach = t.getRect(back);
          expect(reach.width, greaterThanOrEqualTo(24));
          expect(reach.height, greaterThanOrEqualTo(24));
          await t.tap(back);
          await _settle(t);
          expect(
            find.byType(LedgerBack),
            findsNothing,
            reason: 'back on the page it came from',
          );
        },
      );
    }
  }

  testWidgets('a sheet spans a phone', (t) async {
    await _open(t, 'account', _phone);
    expect(t.getRect(find.byType(LedgerSheetShell)).width, _phone.width);
  });

  testWidgets(
    'a sheet on a tablet stands centred at its measure, not across the screen',
    (t) async {
      await _open(t, 'account', _tablet);
      final card = t.getRect(find.byType(LedgerSheetShell));
      expect(card.width, lessThanOrEqualTo(640));
      expect(card.center.dx, moreOrLessEquals(_tablet.width / 2, epsilon: 1));
    },
  );
}
