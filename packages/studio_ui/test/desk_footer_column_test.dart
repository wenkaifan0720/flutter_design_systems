// On a desk a page's act stands at the end of the page's column, under the
// body's end, not at the window's far corner: a form's page on its 600
// measure, another page on the 1200 column. The strip of metal still spans
// the window. Right to left the act stands at the column's other end.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _save = ValueKey('save');
const _last = ValueKey('last');

Future<void> _at(
  WidgetTester tester, {
  double? maxWidth,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view
    ..physicalSize = const Size(1440, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Directionality(
        textDirection: direction,
        child: StudioHost(child: child!),
      ),
      home: StudioScreen(
        maxWidth: maxWidth ?? 1200,
        topBar: const StudioAppBar(title: 'New book'),
        body: const StudioForm(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioTextFormField(labelText: 'Title'),
              StudioTextFormField(key: _last, labelText: 'Author'),
            ],
          ),
        ),
        footer: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: StudioButton.lit('Save', key: _save, onPressed: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("a form's Save ends where its fields end", (tester) async {
    await _at(tester, maxWidth: 600);
    final last = tester.getRect(find.byKey(_last));
    final save = tester.getRect(find.byKey(_save));
    expect(save.right, closeTo(last.right, 0.5));
    expect(save.right, lessThan(1440 - 300));
  });

  testWidgets('right to left, from the other side', (tester) async {
    await _at(tester, maxWidth: 600, direction: TextDirection.rtl);
    final last = tester.getRect(find.byKey(_last));
    final save = tester.getRect(find.byKey(_save));
    expect(save.left, closeTo(last.left, 0.5));
  });

  testWidgets("another page's act ends on its column", (tester) async {
    await _at(tester);
    final last = tester.getRect(find.byKey(_last));
    final save = tester.getRect(find.byKey(_save));
    expect(save.right, closeTo(last.right, 0.5));
  });
}
