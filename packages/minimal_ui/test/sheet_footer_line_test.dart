// A sheet's footer keeps its "create another" switch and its actions on one
// line while they fit, the switch at the leading edge and the actions at the
// trailing one, in both reading directions; on a phone at twice the text they
// stack, the actions under the switch.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Future<void> _footer(
  WidgetTester tester, {
  required double view,
  required double width,
  double text = 1,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(view, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(text)),
        child: Directionality(
          textDirection: direction,
          child: MinimalHost(
            light: MinimalThemeData.preset('standard', Brightness.light),
            dark: MinimalThemeData.preset('standard', Brightness.dark),
            brightness: Brightness.light,
            child: app!,
          ),
        ),
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: MinimalSheetFooter(
              accessory: MinimalSwitch(
                value: true,
                label: 'Create another',
                showLabel: true,
                onChanged: (_) {},
              ),
              leading: const MinimalSheetAction.cancel('Cancel'),
              trailing: MinimalSheetAction(
                'Create habit',
                isDefaultAction: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _button(WidgetTester tester, String label) => tester.getRect(
  find.ancestor(of: find.text(label), matching: find.byType(MinimalButton)),
);

void main() {
  setUpAll(minimalLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('a wide sheet keeps the switch and the actions on one line, '
        '${direction.name}', (tester) async {
      await _footer(tester, view: 1440, width: 480, direction: direction);
      final footer = tester.getRect(find.byType(MinimalSheetFooter));
      final toggle = tester.getRect(find.byType(MinimalSwitch));
      final cancel = _button(tester, 'Cancel');
      final create = _button(tester, 'Create habit');
      final rtl = direction == TextDirection.rtl;
      expect(create.center.dy, moreOrLessEquals(toggle.center.dy, epsilon: 1));
      expect(cancel.center.dy, moreOrLessEquals(toggle.center.dy, epsilon: 1));
      // The switch at the leading edge, the confirming action at the trailing.
      expect(
        rtl ? toggle.right : toggle.left,
        moreOrLessEquals(rtl ? footer.right : footer.left),
      );
      expect(
        rtl ? create.left : create.right,
        moreOrLessEquals(rtl ? footer.left : footer.right),
      );
      expect(
        rtl ? cancel.left > create.right : cancel.right < create.left,
        isTrue,
      );
    });
  }

  testWidgets('a phone sheet at twice the text stacks the actions under the '
      'switch', (tester) async {
    await _footer(tester, view: 390, width: 358, text: 2);
    final toggle = tester.getRect(find.byType(MinimalSwitch));
    final create = _button(tester, 'Create habit');
    expect(create.top, greaterThanOrEqualTo(toggle.bottom));
  });
}
