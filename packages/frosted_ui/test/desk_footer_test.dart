// At a desk a page's footer acts keep to the page's column: on a reading page
// (maxWidth 760) the footer's slab of glass ends where the page's fields end
// and the last act stands its inset in from it, in either reading direction,
// alone or in a button row, in an app shell or on a page of its own. The acts
// never stray to the window's far corner.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_host.dart' show FrostedChromeMetrics;
import 'package:frosted_ui/frosted_parts.dart' show FrostedFootSlab;
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void _none() {}

Widget _page(Widget footer) => FrostedScaffold(
  maxWidth: 760,
  topBar: const FrostedAppBar(title: 'New book'),
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [FrostedTextFormField(labelText: 'Title')],
  ),
  footer: footer,
);

Future<void> _pump(
  WidgetTester tester,
  Widget footer, {
  required TextDirection direction,
  required bool shell,
}) async {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => Directionality(
        textDirection: direction,
        child: FrostedHost(brightness: Brightness.light, child: app!),
      ),
      home: shell
          ? FrostedAppShell(
              destinations: const [
                RawNavigationDestination(
                  label: 'Books',
                  icon: FrostedGlyphs.house,
                ),
                RawNavigationDestination(label: 'Add', icon: FrostedGlyphs.add),
              ],
              branches: [
                (context) => _page(footer),
                (context) => _page(footer),
              ],
            )
          : _page(footer),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final footers = <String, Widget>{
    'a lone act': const FrostedButton('Save', onPressed: _none),
    'a button row': const FrostedButtonRow(
      children: [
        FrostedButton.glass('Cancel', onPressed: _none),
        FrostedButton('Save', onPressed: _none),
      ],
    ),
  };
  for (final shell in [false, true]) {
    for (final MapEntry(key: kind, value: footer) in footers.entries) {
      for (final direction in TextDirection.values) {
        testWidgets(
          '${shell ? 'in the app shell' : 'on a page of its own'}, '
          "$kind ends where the page's field ends at 1440 (${direction.name})",
          (tester) async {
            await _pump(tester, footer, direction: direction, shell: shell);
            final field = tester.getRect(find.byType(FrostedTextField));
            final slab = tester.getRect(find.byType(FrostedFootSlab));
            final save = tester.getRect(
              find.widgetWithText(FrostedButton, 'Save'),
            );
            final rtl = direction == TextDirection.rtl;
            double end(Rect r) => rtl ? -r.left : r.right;
            expect(
              end(slab),
              moreOrLessEquals(end(field), epsilon: 0.5),
              reason: 'the slab ($slab) is off the field ($field)',
            );
            expect(
              end(slab) - end(save),
              moreOrLessEquals(
                FrostedChromeMetrics.footSlabInset,
                epsilon: 0.5,
              ),
              reason: 'Save ($save) is off the slab ($slab)',
            );
          },
        );
      }
    }
  }
}
