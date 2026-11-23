import 'package:appliance_ui/appliance_ui.dart';
import 'package:appliance_ui_example/kit_gallery/larder/larder.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(
  WidgetTester t,
  LarderPlace place, {
  LarderScene? scene,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(1440, 900);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    LarderApp(key: UniqueKey(), initialPlace: place, initialScene: scene),
  );
  await t.pumpAndSettle();
}

Finder _row(String title) =>
    find.byWidgetPredicate((w) => w is ApplianceListTile && w.title == title);
Finder _field(String label) => find.descendant(
  of: find.byWidgetPredicate(
    (w) => w is ApplianceTextField && w.labelText == label,
  ),
  matching: find.byType(EditableText),
);
Future<void> _tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.tap(f.first);
  await t.pumpAndSettle();
}

Future<void> _write(WidgetTester t, String label, String value) async {
  final f = _field(label);
  await t.ensureVisible(f);
  await t.enterText(f, value);
  await t.pump();
}

void main() {
  setUpAll(applianceLoadFonts);
  for (final edit in [
    (row: 'Name', field: 'Full name', value: 'Alex Reed'),
    (row: 'Address', field: 'Street address', value: '9 Cedar Lane'),
    (row: 'Cards', field: 'Card number', value: '1234567890129876'),
  ]) {
    testWidgets('Settings saves the ${edit.row} choice', (t) async {
      await _open(t, LarderPlace.settings);
      await _tap(t, _row(edit.row));
      await _write(t, edit.field, edit.value);
      if (edit.row == 'Address') await _write(t, 'Postcode', 'EH7 2AA');
      await _tap(t, find.text('Save changes'));
      if (edit.row == 'Cards') {
        await _tap(t, _row('Cards'));
        expect(find.text('Saved card ending 9876'), findsOneWidget);
        expect(find.text(edit.value), findsNothing);
      } else {
        expect(
          find.descendant(of: _row(edit.row), matching: find.text(edit.value)),
          findsOneWidget,
        );
      }
    });
  }
  testWidgets('help explains delivery and keeps a message in the demo', (
    t,
  ) async {
    await _open(t, LarderPlace.settings);
    await _tap(t, _row('Delivery and returns'));
    expect(find.textContaining('3 to 5 days.'), findsOneWidget);
    await _tap(t, find.text('Write to the shop'));
    await _write(t, 'Message', 'Can I exchange my kettle?');
    await _tap(t, find.text('Save message'));
    expect(
      find.byWidgetPredicate(
        (w) => w is ApplianceSectionHeader && w.text == 'Saved messages',
      ),
      findsOneWidget,
    );
    expect(find.text('Can I exchange my kettle?'), findsOneWidget);
  });
  testWidgets('Settings opens the contact form directly', (t) async {
    await _open(t, LarderPlace.settings);
    await _tap(t, _row('Write to the shop'));
    expect(_field('Message'), findsOneWidget);
  });
  testWidgets(
    'the tax preference changes shop prices and itemizes the checkout total',
    (t) async {
      await _open(t, LarderPlace.settings);
      await _tap(
        t,
        find.byWidgetPredicate(
          (w) =>
              w is ApplianceSwitch && w.semanticLabel == 'Show prices with tax',
        ),
      );
      await _tap(t, find.text('Shop'));
      expect(find.text('£56.67'), findsWidgets);
      expect(find.text('£35.00'), findsWidgets);
      expect(find.text('£68.00'), findsNothing);
      await _tap(t, find.text('Basket'));
      expect(find.text('Tax'), findsOneWidget);
      expect(find.textContaining('Checkout · £112.00'), findsOneWidget);
    },
  );
  testWidgets(
    'sign out hides the profile, order history and previous purchases',
    (t) async {
      await _open(t, LarderPlace.settings);
      await _tap(t, _row('Sign out'));
      expect(find.text('Rosa Lind'), findsNothing);
      expect(find.text('14 Orchard Row, Leith'), findsNothing);
      await _tap(t, find.text('Orders'));
      expect(find.text('Sign in to see your orders'), findsOneWidget);
      expect(find.textContaining('1048'), findsNothing);
      await _tap(t, find.text('Basket'));
      expect(find.text('Bought before'), findsNothing);
      await _tap(t, find.text('Orders'));
      await _tap(t, find.text('Sign in to demo account'));
      expect(find.textContaining('1048'), findsWidgets);
    },
  );
  testWidgets(
    'a payment retry uses the submitted card, recipient and address',
    (t) async {
      await _open(t, LarderPlace.basket, scene: LarderScene.checkout);
      await _write(t, 'Full name', 'Alex Reed');
      await _write(t, 'Address', '9 Cedar Lane');
      await _write(t, 'Postcode', 'EH7 2AA');
      await _write(t, 'Card number', '1234567890129876');
      await _tap(t, find.text('Pay £112.00'));
      expect(find.textContaining('card ending 9876'), findsOneWidget);
      expect(find.textContaining('card ending 4421'), findsNothing);
      await _tap(t, find.text('Try again'));
      expect(find.textContaining('1049'), findsWidgets);
      expect(find.text('Alex Reed, 9 Cedar Lane, EH7 2AA'), findsOneWidget);
      expect(find.text('Card ending 9876'), findsOneWidget);
      expect(find.text('1234567890129876'), findsNothing);
    },
  );
  testWidgets('changing a declined card preserves the rest of the order', (
    t,
  ) async {
    await _open(t, LarderPlace.basket, scene: LarderScene.checkout);
    await _write(t, 'Full name', 'Alex Reed');
    await _write(t, 'Address', '9 Cedar Lane');
    await _write(t, 'Postcode', 'EH7 2AA');
    await _tap(
      t,
      find.byWidgetPredicate(
        (w) => w is ApplianceRadio<String> && w.value == 'next',
      ),
    );
    await _tap(t, find.byType(ApplianceCheckbox));
    await _tap(t, find.text('Pay £118.50'));
    expect(find.textContaining('card ending 4421'), findsOneWidget);
    await _tap(t, find.text('Use another card'));
    await _write(t, 'Card number', '1234567890129876');
    await _tap(t, find.text('Pay £118.50'));
    expect(find.text('Alex Reed, 9 Cedar Lane, EH7 2AA'), findsOneWidget);
    expect(find.text('Card ending 9876'), findsOneWidget);
    expect(find.text('Next day'), findsOneWidget);
    expect(find.text('Requested'), findsOneWidget);
  });
}
