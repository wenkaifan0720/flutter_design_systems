// Frosted's lists and toasts on ui_core 0.5.0:
// - a combobox's and a multi-select's entry says whether its list stands
//   open (expanded, then collapsed after Escape), and the combobox's and
//   the select's chevrons turn while it does;
// - a select opened from the keys focuses its chosen option;
// - a toast stands 12 over a screen's footer, which keeps it clear
//   (RawToasterKeepClear), and at the foot on a page pushed over it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, child) =>
      FrostedHost(brightness: Brightness.light, child: child!),
  home: Material(type: MaterialType.transparency, child: home),
);

void _phone(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
}

const _rooms = [
  FrostedSelectOption('k', 'Kitchen'),
  FrostedSelectOption('s', 'Study'),
  FrostedSelectOption('b', 'Bedroom'),
  FrostedSelectOption('g', 'Garden'),
];
const _fruit = ['Apple', 'Apricot', 'Avocado', 'Banana', 'Cherry'];

Widget _high(Widget child) => Align(
  alignment: const Alignment(0, -0.8),
  child: SizedBox(width: 358, child: child),
);

void main() {
  group("a list's entry says whether the list stands open", () {
    final fields = <String, Widget Function()>{
      'FrostedCombobox': () =>
          const FrostedCombobox<String>(labelText: 'Fruit', options: _fruit),
      'FrostedMultiSelect': () => FrostedMultiSelect<String>(
        labelText: 'Fruit',
        values: const [],
        onChanged: (_) {},
        options: _fruit,
      ),
    };
    for (final MapEntry(key: name, value: field) in fields.entries) {
      testWidgets(name, (tester) async {
        final semantics = tester.ensureSemantics();
        _phone(tester);
        await tester.pumpWidget(_app(_high(field())));
        final entry = find.byType(EditableText);
        expect(
          tester.getSemantics(entry),
          isSemantics(
            isTextField: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
        await tester.tap(entry);
        await tester.enterText(entry, 'A');
        await tester.pumpAndSettle();
        expect(find.text('Apricot'), findsWidgets);
        expect(
          tester.getSemantics(entry),
          isSemantics(
            isTextField: true,
            hasExpandedState: true,
            isExpanded: true,
          ),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(entry),
          isSemantics(
            isTextField: true,
            hasExpandedState: true,
            isExpanded: false,
          ),
        );
        semantics.dispose();
      });
    }

    testWidgets("the combobox's chevron turns while its list stands open", (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _high(
            const FrostedCombobox<String>(labelText: 'Fruit', options: _fruit),
          ),
        ),
      );
      double turns() => tester
          .widget<AnimatedRotation>(
            find.descendant(
              of: find.byType(FrostedCombobox<String>),
              matching: find.byType(AnimatedRotation),
            ),
          )
          .turns;
      expect(turns(), 0);
      await tester.enterText(find.byType(EditableText), 'A');
      await tester.pumpAndSettle();
      expect(turns(), .5);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(turns(), 0);
    });

    testWidgets("the select's chevron turns while its list stands open", (
      tester,
    ) async {
      _phone(tester);
      await tester.pumpWidget(
        _app(
          _high(
            FrostedSelect<String>(
              labelText: 'Room',
              options: _rooms,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      double turns() => tester
          .widget<AnimatedRotation>(
            find.descendant(
              of: find.byType(FrostedSelect<String>),
              matching: find.byType(AnimatedRotation),
            ),
          )
          .turns;
      expect(turns(), 0);
      await tester.tap(find.byType(FrostedSelect<String>));
      await tester.pumpAndSettle();
      expect(turns(), .5);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(turns(), 0);
    });
  });

  testWidgets('a select opened from the keys focuses its chosen option', (
    tester,
  ) async {
    _phone(tester);
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _app(
        _high(
          FrostedSelect<String>(
            labelText: 'Room',
            options: _rooms,
            value: 'b',
            focusNode: focus,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Bedroom');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  group('a toast keeps clear of the foot', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump(FrostedChromeMetrics.toastDwell);
      await tester.pumpAndSettle();
    }

    testWidgets("over a screen's footer, then at the foot of a page pushed "
        'over it', (tester) async {
      _phone(tester);
      late BuildContext screen;
      const bar = SizedBox(key: ValueKey('bar'), height: 48);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              screen = context;
              return const FrostedScaffold(
                footer: bar,
                body: SizedBox(height: 100),
              );
            },
          ),
        ),
      );
      final barTop = tester.getTopLeft(find.byKey(const ValueKey('bar'))).dy;
      final standTop = barTop - FrostedScaffold.footerInsets.top;
      double toastBottom() =>
          tester.getBottomLeft(find.byType(FrostedSnackBar)).dy;

      FrostedToast.show(screen, 'Moved to Groceries');
      await tester.pumpAndSettle();
      expect(
        toastBottom(),
        moreOrLessEquals(standTop - FrostedChromeMetrics.toastOverBar),
      );
      await settle(tester);

      late BuildContext pushed;
      Navigator.of(screen).push(
        MaterialPageRoute<void>(
          builder: (context) {
            pushed = context;
            return const FrostedScaffold(body: SizedBox(height: 100));
          },
        ),
      );
      await tester.pumpAndSettle();
      FrostedToast.show(pushed, 'Saved');
      await tester.pumpAndSettle();
      expect(
        toastBottom(),
        moreOrLessEquals(844 - FrostedChromeMetrics.toastOverBar),
      );
      await settle(tester);

      Navigator.of(pushed).pop();
      await tester.pumpAndSettle();
      FrostedToast.show(screen, 'Moved back');
      await tester.pumpAndSettle();
      expect(
        toastBottom(),
        moreOrLessEquals(standTop - FrostedChromeMetrics.toastOverBar),
      );
      await settle(tester);
    });
  });
}
