// A time field's value: a TermTime, typed `hh:mm` or stepped by the arrows,
// round midnight either way.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

void main() {
  test('a TermTime is a value', () {
    const t = TermTime(hour: 9, minute: 5);
    expect(t, const TermTime(hour: 9, minute: 5));
    expect(t.hashCode, const TermTime(hour: 9, minute: 5).hashCode);
    expect(t, isNot(const TermTime(hour: 9, minute: 6)));
    expect(t.copyWith(minute: 30), const TermTime(hour: 9, minute: 30));
    expect(t.copyWith(hour: 23), const TermTime(hour: 23, minute: 5));
    expect(t.toString(), 'TermTime(09:05)');
  });

  group('a time field', () {
    late List<TermTime> heard;

    Future<void> pump(WidgetTester tester, TermTime? value) {
      heard = [];
      return tester.pumpWidget(
        MaterialApp(
          home: TermTheme(
            data: TermThemeData.dark(),
            child: Center(
              child: SizedBox(
                width: 320,
                child: TermTimeField(
                  labelText: 'deploy at',
                  value: value,
                  onChanged: heard.add,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('typed: a valid time is heard, an invalid one is not', (
      tester,
    ) async {
      await pump(tester, null);
      await tester.enterText(find.byType(EditableText), '14:30');
      expect(heard, [const TermTime(hour: 14, minute: 30)]);
      await tester.enterText(find.byType(EditableText), '24:00');
      await tester.pump();
      expect(heard, hasLength(1));
      expect(find.text('hh:mm, 00:00 to 23:59'), findsOneWidget);
    });

    testWidgets('stepped by the arrows, round midnight', (tester) async {
      await pump(tester, const TermTime(hour: 23, minute: 50));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(heard.last, const TermTime(hour: 0, minute: 5));
      expect(find.text('00:05'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(heard.last, const TermTime(hour: 23, minute: 50));
    });
  });
}
