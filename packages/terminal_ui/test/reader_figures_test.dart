// The figures and words Terminal's own parts write are the reader's: a
// date, a time and a counter in Arabic's digits, nothing English beside
// them; the number field one keyboard stop.
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// An app in [locale], with ui_core's words and Flutter's for it.
Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  supportedLocales: const [Locale('en'), Locale('ar')],
  localizationsDelegates: const [
    DesignLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: TermTheme(
    data: TermThemeData.dark(),
    child: Directionality(
      textDirection: locale.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Center(child: SizedBox(width: 360, child: child)),
    ),
  ),
);

// Every word a part paints or says.
Iterable<String> _words(WidgetTester tester) sync* {
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    if (text.data != null) yield text.data!;
  }
  for (final field in tester.widgetList<EditableText>(
    find.byType(EditableText),
  )) {
    yield field.controller.text;
  }
}

// Whether a screen reader hears [words] in any node's label or value.
bool _said(WidgetTester tester, String words) {
  var found = false;
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.contains(words) || data.value.contains(words)) found = true;
    node.visitChildren(visit);
    return !found;
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return found;
}

// Whether the keyboard's focus is inside what [finder] finds.
bool _focusIn(Finder finder) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final targets = finder.evaluate().toSet();
  if (targets.contains(focused)) return true;
  var found = false;
  focused.visitAncestorElements((e) {
    found = targets.contains(e);
    return !found;
  });
  return found;
}

const _english = ['less', 'more', '24-hour', 'hh:mm', 'step', 'month', 'from'];

void main() {
  const ar = Locale('ar');

  testWidgets('in Arabic a date field writes the date in Arabic digits', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TermDatePicker(
          labelText: 'تاريخ الاستحقاق',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
        locale: ar,
      ),
    );
    expect(find.text('٢٠٢٦-١١-٢٠'), findsOneWidget);
    expect(find.text('2026-11-20'), findsNothing);
    final semantics = tester.ensureSemantics();
    expect(_said(tester, '٢٠٢٦-١١-٢٠'), isTrue);
    expect(_said(tester, '2026'), isFalse);
    semantics.dispose();
  });

  testWidgets('in Arabic an empty date field hints in the reader\'s words', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            TermDatePicker(
              value: null,
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              onChanged: (_) {},
            ),
            TermDateRangePicker(
              value: null,
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              onChanged: (_) {},
            ),
          ],
        ),
        locale: ar,
      ),
    );
    final l = DesignLocalizations.forLocale(ar);
    final form =
        '${l.dateFieldYearPlaceholder}-${l.dateFieldMonthPlaceholder}-'
        '${l.dateFieldDayPlaceholder}';
    expect(find.text(form), findsOneWidget);
    expect(find.text('$form → $form'), findsOneWidget);
    for (final word in _words(tester)) {
      for (final english in _english) {
        expect(word.contains(english), isFalse, reason: word);
      }
    }
  });

  testWidgets('in Arabic the calendar numbers its days in Arabic digits', (
    tester,
  ) async {
    final calendar = DesignCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      selectedDate: DateTime(2026, 11, 20),
      currentDate: DateTime(2026, 11, 18),
    );
    addTearDown(calendar.dispose);
    await tester.pumpWidget(
      _host(TermCalendar(controller: calendar), locale: ar),
    );
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
    final l = DesignLocalizations.forLocale(ar);
    expect(
      find.bySemanticsLabel(l.previousMonthTooltip.toLowerCase()),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('previous month'), findsNothing);
  });

  group('a time field in Arabic', () {
    late List<TermTime> heard;

    Future<void> pump(WidgetTester tester, TermTime? value) {
      heard = [];
      return tester.pumpWidget(
        _host(
          TermTimeField(
            labelText: 'وقت التذكير',
            value: value,
            onChanged: heard.add,
          ),
          locale: ar,
        ),
      );
    }

    testWidgets('writes its time and its help in Arabic digits, no English', (
      tester,
    ) async {
      await pump(tester, const TermTime(hour: 9, minute: 30));
      expect(find.text('٠٩:٣٠'), findsOneWidget);
      expect(find.text('٠٠:٠٠–٢٣:٥٩ · ↑↓'), findsOneWidget);
      for (final word in _words(tester)) {
        for (final english in _english) {
          expect(word.contains(english), isFalse, reason: word);
        }
        expect(RegExp('[0-9]').hasMatch(word), isFalse, reason: word);
      }
    });

    testWidgets('reads Arabic digits and ASCII ones alike', (tester) async {
      await pump(tester, null);
      await tester.enterText(find.byType(EditableText), '١٤:٣٠');
      expect(heard, [const TermTime(hour: 14, minute: 30)]);
      await tester.enterText(find.byType(EditableText), '07:05');
      expect(heard.last, const TermTime(hour: 7, minute: 5));
    });

    testWidgets('says what it takes when a time does not read', (tester) async {
      await pump(tester, null);
      await tester.enterText(find.byType(EditableText), '٢٤:٠٠');
      await tester.pump();
      expect(heard, isEmpty);
      // The help line turns to the error, in the same figures.
      expect(find.text('٠٠:٠٠–٢٣:٥٩'), findsOneWidget);
    });

    testWidgets('steps in Arabic digits', (tester) async {
      await pump(tester, const TermTime(hour: 23, minute: 50));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(heard.last, const TermTime(hour: 0, minute: 5));
      expect(find.text('٠٠:٠٥'), findsOneWidget);
    });
  });

  group('a number field', () {
    late int value;

    Widget field({Locale locale = const Locale('en')}) => StatefulBuilder(
      builder: (context, setState) => TermNumberField(
        semanticLabel: locale.languageCode == 'ar'
            ? 'التقدير بالدقائق'
            : 'estimate',
        value: value,
        min: 0,
        max: 240,
        step: 15,
        onChanged: (v) => setState(() => value = v),
      ),
    );

    testWidgets('in Arabic writes its number in Arabic digits and says it so', (
      tester,
    ) async {
      value = 45;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_host(field(locale: ar), locale: ar));
      expect(find.text('٤٥'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('التقدير بالدقائق')),
        matchesSemantics(
          label: 'التقدير بالدقائق',
          value: '٤٥',
          increasedValue: '٦٠',
          decreasedValue: '٣٠',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
          isFocusable: false,
        ),
      );
      for (final word in _words(tester)) {
        for (final english in _english) {
          expect(word.contains(english), isFalse, reason: word);
        }
      }
      expect(find.bySemanticsLabel(RegExp('less|more')), findsNothing);
      semantics.dispose();
    });

    testWidgets('is one keyboard stop: Up, Down, Home and End step it', (
      tester,
    ) async {
      value = 45;
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TermButton(label: 'before', onPressed: () {}),
              field(),
              TermButton(label: 'after', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusIn(find.byType(TermNumberField)), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(value, 60);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(value, 30);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(value, 240);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(value, 0);
      // The next Tab leaves for the button after it: the keys are not stops.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusIn(find.widgetWithText(TermButton, 'after')), isTrue);
    });

    testWidgets('a press on a key steps it and leaves the focus where it was', (
      tester,
    ) async {
      value = 45;
      await tester.pumpWidget(_host(field()));
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      expect(value, 60);
      expect(_focusIn(find.byType(TermNumberField)), isFalse);
    });
  });
}
