// A swipe row shows its keyboard focus: the double rule a focused row
// draws under its face is not cut by the row's slide, which clips at the
// row's sides only (an open row is still cut where the list ends).
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

final _key = GlobalKey();

Future<Uint8List> _frame(WidgetTester t) async {
  final boundary =
      _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await t.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

int _differ(Uint8List a, Uint8List b) {
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if ((a[i] - b[i]).abs() > 2 ||
        (a[i + 1] - b[i + 1]).abs() > 2 ||
        (a[i + 2] - b[i + 2]).abs() > 2) {
      n++;
    }
  }
  return n;
}

void main() {
  for (final swipe in [false, true]) {
    testWidgets('a focused row draws its rule (in a swipe row: $swipe)', (
      t,
    ) async {
      final row = LedgerRow(
        title: 'Route note',
        subtitle: 'Unread',
        onTap: () {},
      );
      // WidgetsApp gives Tab its traversal, as an app does.
      await t.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          debugShowCheckedModeBanner: false,
          builder: (context, _) => MediaQuery(
            data: const MediaQueryData(),
            child: LedgerTheme(
              data: LedgerThemeData.light(),
              child: FocusScope(
                autofocus: true,
                child: RepaintBoundary(
                  key: _key,
                  child: ColoredBox(
                    color: const Color(0xFFFFFFFF),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: 340,
                          child: swipe
                              ? LedgerSwipeActions(
                                  trailing: [
                                    LedgerSwipeAction(
                                      'Archive',
                                      onPressed: () {},
                                    ),
                                  ],
                                  child: row,
                                )
                              : row,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final rest = await _frame(t);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      final focused = await _frame(t);
      // Two rules a hairline each across most of the row.
      expect(_differ(rest, focused), greaterThan(300));
    });
  }
}
