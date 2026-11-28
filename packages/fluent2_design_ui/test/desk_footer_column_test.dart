// On a desk a page's acts stand in its content column, not at the window's
// far corner: a form's under the form's measure, another page's at the
// column's end. The band and its hairline still span the window. On a
// phone the footer keeps the screen's gutters. Either way the keys mirror
// right to left.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:material_ui/material_ui.dart';

const _save = ValueKey('save');
const _last = ValueKey('last');

Widget _app(Widget body, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: Fluent2Host(child: child!),
      ),
      home: Fluent2Scaffold(
        topBar: const Fluent2AppBar(title: 'New book'),
        body: body,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Fluent2Button(
              'Save',
              key: _save,
              appearance: Fluent2ButtonAppearance.primary,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

const _form = Fluent2FormSection(
  children: [
    Fluent2TextFormField(labelText: 'Title'),
    Fluent2TextFormField(key: _last, labelText: 'Author'),
  ],
);

Future<void> _at(WidgetTester tester, double width, Widget app) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("on a desk a form's Save ends where the form ends", (
    tester,
  ) async {
    await _at(tester, 1440, _app(_form));
    final last = tester.getRect(find.byKey(_last));
    final save = tester.getRect(find.byKey(_save));
    expect(save.right, closeTo(last.right, 0.5));
    expect(save.left, greaterThan(last.left));
  });

  testWidgets('right to left, the same from the other side', (tester) async {
    await _at(tester, 1440, _app(_form, direction: TextDirection.rtl));
    final last = tester.getRect(find.byKey(_last));
    final save = tester.getRect(find.byKey(_save));
    expect(save.left, closeTo(last.left, 0.5));
  });

  testWidgets("another page's acts end on the content column", (tester) async {
    await _at(tester, 1440, _app(const Text('Notes', key: _last)));
    final save = tester.getRect(find.byKey(_save));
    final column = tester.getRect(find.byType(Fluent2Scaffold));
    // The column stops at 1120 from its start gutter.
    final start = tester.getRect(find.byKey(_last)).left;
    expect(save.right, closeTo(start + 1120, 0.5));
    expect(save.right, lessThan(column.right - 200));
  });

  testWidgets("on a phone Save keeps the screen's end gutter", (tester) async {
    await _at(tester, 390, _app(_form));
    final last = tester.getRect(find.byKey(_last));
    final save = tester.getRect(find.byKey(_save));
    expect(save.right, closeTo(last.right, 0.5));
  });

  testWidgets('the band and its hairline still span the window', (
    tester,
  ) async {
    await _at(tester, 1440, _app(_form));
    final band = tester.getRect(
      find
          .ancestor(of: find.byKey(_save), matching: find.byType(DecoratedBox))
          .last,
    );
    expect(band.width, 1440);
  });
}
