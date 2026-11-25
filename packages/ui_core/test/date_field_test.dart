import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<RawDateSegmentDetails> _painted = [];
Set<WidgetState> _frame = {};

// The bare reference painter: each segment's text at the tap floor, the
// frame reporting its states.
Widget _segment(BuildContext context, RawDateSegmentDetails d) {
  _painted.add(d);
  return TapTargetPadding(
    child: Text(
      d.text,
      key: ValueKey(d.type),
      style: TextStyle(
        color: d.isPlaceholder
            ? const Color(0xFF888888)
            : const Color(0xFF000000),
      ),
    ),
  );
}

Widget _framed(BuildContext context, Set<WidgetState> states, Widget s) {
  _frame = states;
  return s;
}

late _DateHostState _date;

class _DateHost extends StatefulWidget {
  const _DateHost({
    this.value,
    this.enabled = true,
    this.firstDate,
    this.lastDate,
    this.locale,
  });

  final DateTime? value;
  final bool enabled;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Locale? locale;

  @override
  State<_DateHost> createState() => _DateHostState();
}

class _DateHostState extends State<_DateHost> {
  late DateTime? value = widget.value;
  final List<DateTime?> sent = [];
  int done = 0;

  void set(DateTime? next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) {
    _date = this;
    final field = Align(
      alignment: Alignment.topLeft,
      child: RawDateField(
        value: value,
        semanticLabel: 'Due',
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        onEditingComplete: () => done++,
        onChanged: widget.enabled
            ? (next) => setState(() {
                sent.add(next);
                value = next;
              })
            : null,
        segmentBuilder: _segment,
        frameBuilder: _framed,
      ),
    );
    final locale = widget.locale;
    if (locale == null) return field;
    // Localizations sets its widgets localizations' direction (English's,
    // here): keep the app's.
    final direction = Directionality.of(context);
    return Localizations(
      locale: locale,
      delegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(textDirection: direction, child: field),
    );
  }
}

late _TimeHostState _time;

class _TimeHost extends StatefulWidget {
  const _TimeHost({
    super.key,
    this.value,
    this.enabled = true,
    this.h24,
    this.seconds = false,
    this.locale,
  });

  final RawTimeOfDay? value;
  final bool enabled;
  final bool? h24;
  final bool seconds;
  final Locale? locale;

  @override
  State<_TimeHost> createState() => _TimeHostState();
}

class _TimeHostState extends State<_TimeHost> {
  late RawTimeOfDay? value = widget.value;
  final List<RawTimeOfDay?> sent = [];
  int done = 0;

  void set(RawTimeOfDay? next) => setState(() => value = next);

  @override
  Widget build(BuildContext context) {
    _time = this;
    final field = Align(
      alignment: Alignment.topLeft,
      child: RawTimeField(
        value: value,
        semanticLabel: 'Start',
        alwaysUse24HourFormat: widget.h24,
        showSeconds: widget.seconds,
        onEditingComplete: () => done++,
        onChanged: widget.enabled
            ? (next) => setState(() {
                sent.add(next);
                value = next;
              })
            : null,
        segmentBuilder: _segment,
      ),
    );
    final locale = widget.locale;
    if (locale == null) return field;
    // Localizations sets its widgets localizations' direction (English's,
    // here): keep the app's.
    final direction = Directionality.of(context);
    return Localizations(
      locale: locale,
      delegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(textDirection: direction, child: field),
    );
  }
}

Finder _node(String label) => find.bySemanticsLabel(label);

SemanticsData _data(WidgetTester tester, String label) =>
    semanticsOf(tester, _node(label)).getSemanticsData();

bool _focusedOn(WidgetTester tester, String label) =>
    _data(tester, label).flagsCollection.isFocused == Tristate.isTrue;

// Each segment's text as drawn, left to right.
List<String> _drawn(WidgetTester tester) {
  final texts =
      tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.key is ValueKey<RawDateSegmentType>)
          .map((t) => (t.data!, tester.getCenter(find.byWidget(t)).dx))
          .toList()
        ..sort((a, b) => a.$2.compareTo(b.$2));
  return [for (final t in texts) t.$1];
}

Future<void> _type(WidgetTester tester, String keys) async {
  for (final c in keys.split('')) {
    final key = switch (c) {
      '/' => LogicalKeyboardKey.slash,
      'p' => LogicalKeyboardKey.keyP,
      'a' => LogicalKeyboardKey.keyA,
      _ => LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + int.parse(c)),
    };
    await tester.sendKeyEvent(key, character: c);
    await tester.pump();
  }
}

// The input type the field's text input was last configured with.
String? _inputType(WidgetTester tester) {
  final args = tester.testTextInput.setClientArgs;
  final type = args?['inputType'] as Map<String, dynamic>?;
  return type?['name'] as String?;
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

void main() {
  setUp(() {
    _painted.clear();
    _frame = {};
  });

  behaviourContract(
    'RawDateField',
    build: (c) => _DateHost(value: DateTime(2026, 11, 16), enabled: c.enabled),
    node: () => _node('Month'),
    root: () => find.byType(RawDateField),
    semantics: isSemantics(
      label: 'Month',
      value: 'November',
      increasedValue: 'December',
      decreasedValue: 'October',
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Month',
      value: 'November',
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasTapAction: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    // The digits and the slashes are drawn; a screen reader hears each
    // segment's name and value, and the whole date.
    hidden: const ['/'],
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto();
      expect(_frame, contains(WidgetState.focused));
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(p.data.value, 'December');
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(p.data.value, 'January', reason: 'a month wraps');
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(p.data.value, 'December');
      await p.key(LogicalKeyboardKey.home);
      expect(p.data.value, 'January');
      await p.key(LogicalKeyboardKey.end);
      expect(p.data.value, 'December');
      expect(_date.value, DateTime(2026, 12, 16));
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(t, 'Day'), isTrue);
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(p.focused, isTrue);
      await p.tab();
      expect(_focusedOn(t, 'Day'), isTrue, reason: 'each segment a stop');
      await p.key(LogicalKeyboardKey.enter);
      expect(_date.done, 1);
    },
    rtl: (p) async {
      final t = p.tester;
      await p.tabInto();
      // English's M/d/y reads as one run of digits, left to right, even in
      // a right-to-left app: Right is still the day.
      expect(_drawn(t), ['11', '16', '2026']);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_focusedOn(t, 'Day'), isTrue);
    },
  );

  behaviourContract(
    'RawTimeField',
    build: (c) => _TimeHost(
      value: const RawTimeOfDay(hour: 15, minute: 5),
      enabled: c.enabled,
    ),
    node: () => _node('Hour'),
    root: () => find.byType(RawTimeField),
    semantics: isSemantics(
      label: 'Hour',
      value: '3',
      increasedValue: '4',
      decreasedValue: '2',
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Hour',
      value: '3',
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasTapAction: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_time.value, const RawTimeOfDay(hour: 14, minute: 5));
      await p.tab();
      await p.tab();
      expect(_focusedOn(t, 'AM/PM'), isTrue);
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_time.value, const RawTimeOfDay(hour: 2, minute: 5));
      expect(_data(t, 'AM/PM').value, 'AM');
    },
  );

  group('typing a date', () {
    testWidgets('digits fill a segment and move on when no more fit', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _DateHost()));
      expect(_drawn(tester), ['mm', 'dd', 'yyyy']);
      await _tab(tester);
      await _type(tester, '1');
      expect(_focusedOn(tester, 'Month'), isTrue, reason: '"1" waits');
      await _type(tester, '1');
      expect(_focusedOn(tester, 'Day'), isTrue, reason: '"11" is whole');
      await _type(tester, '4');
      expect(
        _focusedOn(tester, 'Year'),
        isTrue,
        reason: '"4" can take no more',
      );
      expect(_date.sent, isEmpty, reason: 'no year yet');
      await _type(tester, '202');
      expect(_drawn(tester), ['11', '4', '202']);
      expect(_date.sent, isEmpty, reason: 'a year half typed waits');
      await _type(tester, '6');
      expect(_date.sent, [DateTime(2026, 11, 4)]);
      expect(_data(tester, 'Due').value, contains('2026'));
    });

    testWidgets('a "3" in the month moves on; a separator moves on', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _DateHost()));
      await _tab(tester);
      await _type(tester, '3');
      expect(_focusedOn(tester, 'Day'), isTrue);
      await _type(tester, '1/');
      expect(_focusedOn(tester, 'Year'), isTrue);
      await _type(tester, '2025');
      expect(_date.value, DateTime(2025, 3));
    });

    testWidgets('a day past the month\'s end moves back to its last day', (
      tester,
    ) async {
      await tester.pumpWidget(harness(_DateHost(value: DateTime(2026, 1, 31))));
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_date.value, DateTime(2026, 2, 28));
      expect(_date.sent, hasLength(1), reason: 'one change, already whole');
      // Typing a day bounded by the month: "3" in February moves on.
      await _tab(tester);
      await _type(tester, '3');
      expect(_focusedOn(tester, 'Year'), isTrue);
      expect(_date.value, DateTime(2026, 2, 3));
    });

    testWidgets('Backspace clears, then moves back; empty sends null', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(_DateHost(value: DateTime(2026, 11, 16))),
      );
      await _tab(tester);
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(_date.sent, [null]);
      expect(_data(tester, 'Day').value, 'Empty');
      expect(_drawn(tester), ['11', 'dd', '2026']);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(_focusedOn(tester, 'Month'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(_data(tester, 'Month').value, 'Empty');
      expect(_date.sent, [null], reason: 'already empty: said once');
    });

    testWidgets('an empty segment steps from its least, or the range\'s year', (
      tester,
    ) async {
      await tester.pumpWidget(harness(_DateHost(firstDate: DateTime(2030, 6))));
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_data(tester, 'Month').value, 'January');
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_data(tester, 'Day').value, '31');
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_data(tester, 'Year').value, '2030');
      expect(_date.value, DateTime(2030, 1, 31));
    });

    testWidgets('a month left at "0" is empty', (tester) async {
      await tester.pumpWidget(harness(const _DateHost()));
      await _tab(tester);
      await _type(tester, '0');
      expect(_drawn(tester).first, '0');
      await _tab(tester);
      expect(_data(tester, 'Month').value, 'Empty');
    });

    testWidgets('a tap focuses a segment; off them, the first empty one', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(_DateHost(value: DateTime(2026, 11, 16))),
      );
      await tester.tap(find.text('2026'));
      await tester.pump();
      expect(_focusedOn(tester, 'Year'), isTrue);
      expect(tester.testTextInput.isVisible, isTrue, reason: 'the keyboard');
    });
  });

  testWidgets('a shortcut goes past a segment to the shortcuts above the '
      'field; AltGr still types', (tester) async {
    var saved = 0;
    var undone = 0;
    await tester.pumpWidget(
      harness(
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
                saved++,
            const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
                undone++,
          },
          child: const _DateHost(),
        ),
      ),
    );
    await _tab(tester);
    expect(_focusedOn(tester, 'Month'), isTrue);
    Future<void> held(
      List<LogicalKeyboardKey> modifiers,
      LogicalKeyboardKey key,
      String character,
    ) async {
      for (final m in modifiers) {
        await tester.sendKeyDownEvent(m);
      }
      await tester.sendKeyEvent(key, character: character);
      for (final m in modifiers.reversed) {
        await tester.sendKeyUpEvent(m);
      }
      await tester.pump();
    }

    await held([LogicalKeyboardKey.controlLeft], LogicalKeyboardKey.keyS, 's');
    expect(saved, 1, reason: 'Control-S');
    await held([LogicalKeyboardKey.metaLeft], LogicalKeyboardKey.keyZ, 'z');
    expect(undone, 1, reason: 'Command-Z');
    await held([LogicalKeyboardKey.altLeft], LogicalKeyboardKey.digit1, '1');
    expect(find.text('mm'), findsOneWidget, reason: 'Alt-1 types nothing');
    expect(_focusedOn(tester, 'Month'), isTrue);
    // Windows reports AltGr as right Alt with Control: it types.
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await held(
        [LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.altRight],
        LogicalKeyboardKey.digit1,
        '1',
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    await _type(tester, '1');
    expect(_focusedOn(tester, 'Day'), isTrue, reason: 'month 11 typed');
    expect(saved, 1);
  });

  testWidgets('a phone keyboard types into the segments', (tester) async {
    await tester.pumpWidget(harness(const _DateHost()));
    await tester.tap(find.text('mm'));
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isTrue);
    expect(_inputType(tester), 'TextInputType.number');
    void send(String text) => tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    send('​​12');
    await tester.pump();
    expect(_focusedOn(tester, 'Day'), isTrue);
    send('​​25');
    await tester.pump();
    send('​​2026');
    await tester.pump();
    expect(_date.value, DateTime(2026, 12, 25));
    // Fewer characters: a Backspace.
    send('​');
    await tester.pump();
    expect(_data(tester, 'Year').value, 'Empty');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(_date.done, 1);
    // Focus leaving the field closes the input.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.pump();
    expect(tester.testTextInput.hasAnyClients, isFalse);
  });

  testWidgets('out of range: error states, invalid, and said once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        _DateHost(
          value: DateTime(2026, 11, 16),
          lastDate: DateTime(2026, 12, 31),
        ),
      ),
    );
    expect(_frame, isNot(contains(WidgetState.error)));
    await _tab(tester);
    await _tab(tester);
    await _tab(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_date.value, DateTime(2027, 11, 16), reason: 'still sent');
    expect(_frame, contains(WidgetState.error));
    expect(_painted.last.states, contains(WidgetState.error));
    final field = _data(tester, 'Due');
    expect(field.validationResult, SemanticsValidationResult.invalid);
    expect(field.hint, 'Out of range.');
    expect(
      tester.takeAnnouncements().map((a) => a.message),
      contains('Out of range.'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(tester.takeAnnouncements(), isEmpty, reason: 'said once');
    handle.dispose();
  });

  testWidgets('a parent\'s new value fills the segments', (tester) async {
    await tester.pumpWidget(harness(_DateHost(value: DateTime(2026, 11, 16))));
    _date.set(DateTime(2001, 2, 3));
    await tester.pump();
    expect(_drawn(tester), ['2', '3', '2001']);
    _date.set(null);
    await tester.pump();
    expect(_drawn(tester), ['mm', 'dd', 'yyyy']);
    expect(_date.sent, isEmpty);
  });

  group('the reader\'s order and digits', () {
    testWidgets('German: day first, dots between', (tester) async {
      await tester.pumpWidget(
        harness(
          _DateHost(value: DateTime(2026, 11, 16), locale: const Locale('de')),
        ),
      );
      expect(_drawn(tester), ['16', '11', '2026']);
      expect(find.text('.'), findsNWidgets(2));
      expect(_data(tester, 'Monat').value, 'November');
      await _tab(tester);
      expect(_focusedOn(tester, 'Tag'), isTrue, reason: 'Tab: day first');
    });

    testWidgets('Arabic: right to left, in Arabic-Indic digits, typed in '
        'either', (tester) async {
      await tester.pumpWidget(
        harness(
          const _DateHost(locale: Locale('ar')),
          textDirection: TextDirection.rtl,
        ),
      );
      await _tab(tester);
      // d‏/M‏/y with right-to-left marks: the day stands rightmost.
      await _type(tester, '16');
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1, character: '١');
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1, character: '1');
      await tester.pump();
      await _type(tester, '2026');
      expect(_date.value, DateTime(2026, 11, 16));
      expect(_drawn(tester), ['٢٠٢٦', '١١', '١٦']);
      // Left moves on to the month, as drawn.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_focusedOn(tester, 'الشهر'), isTrue);
    });

    testWidgets('Hebrew: a run of digits reads left to right', (tester) async {
      await tester.pumpWidget(
        harness(
          _DateHost(value: DateTime(2026, 11, 16), locale: const Locale('he')),
          textDirection: TextDirection.rtl,
        ),
      );
      expect(_drawn(tester), ['16', '11', '2026']);
    });
  });

  group('typing a time', () {
    testWidgets('12 hours: hour, minute, then a letter for PM', (tester) async {
      await tester.pumpWidget(harness(const _TimeHost()));
      expect(_drawn(tester), ['––', '––', '––']);
      await _tab(tester);
      await _type(tester, '9');
      expect(_focusedOn(tester, 'Minute'), isTrue, reason: '"9" moves on');
      await _type(tester, '30');
      expect(_focusedOn(tester, 'AM/PM'), isTrue);
      expect(_time.sent, isEmpty, reason: 'AM or PM not chosen');
      await _type(tester, 'p');
      expect(_time.value, const RawTimeOfDay(hour: 21, minute: 30));
      expect(_data(tester, 'Start').value, '9:30 PM');
      await _type(tester, 'a');
      expect(_time.value, const RawTimeOfDay(hour: 9, minute: 30));
      expect(
        _inputType(tester),
        'TextInputType.text',
        reason: 'AM/PM takes letters',
      );
    });

    testWidgets('12 o\'clock: 12 AM is midnight, the hour wraps 12 to 1', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _TimeHost(value: RawTimeOfDay(hour: 0, minute: 0))),
      );
      expect(_drawn(tester), ['12', '00', 'AM']);
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_time.value, const RawTimeOfDay(hour: 1, minute: 0));
    });

    testWidgets('24 hours, with seconds; the platform\'s setting', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const _TimeHost(
            value: RawTimeOfDay(hour: 15, minute: 5, second: 9),
            h24: true,
            seconds: true,
          ),
        ),
      );
      expect(_drawn(tester), ['15', '05', '09']);
      expect(find.bySemanticsLabel('AM/PM'), findsNothing);
      await _tab(tester);
      await _type(tester, '23');
      expect(_time.value, const RawTimeOfDay(hour: 23, minute: 5, second: 9));
      await tester.pumpWidget(
        harness(
          const _TimeHost(
            key: ValueKey('platform'),
            value: RawTimeOfDay(hour: 15, minute: 5),
          ),
          wrap: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        ),
      );
      expect(_drawn(tester), ['15', '05']);
    });

    testWidgets('Korean puts AM/PM first; German keeps 24 hours', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const _TimeHost(
            value: RawTimeOfDay(hour: 15, minute: 5),
            locale: Locale('ko'),
          ),
        ),
      );
      expect(_drawn(tester), ['오후', '3', '05']);
      await tester.pumpWidget(
        harness(
          const _TimeHost(
            key: ValueKey('de'),
            value: RawTimeOfDay(hour: 15, minute: 5),
            locale: Locale('de'),
          ),
        ),
      );
      expect(_drawn(tester), ['15', '05']);
    });

    testWidgets('Arabic: AM/PM to the left of a left-to-right hour:minute', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(
          const _TimeHost(
            value: RawTimeOfDay(hour: 15, minute: 5),
            locale: Locale('ar'),
          ),
          textDirection: TextDirection.rtl,
        ),
      );
      expect(_drawn(tester), ['م', '٣', '٠٥']);
    });
  });

  group('the rest of a field\'s life', () {
    testWidgets('a screen reader steps a segment', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        harness(_DateHost(value: DateTime(2026, 11, 16))),
      );
      final month = semanticsOf(tester, _node('Month'));
      semanticsOwner().performAction(month.id, SemanticsAction.increase);
      await tester.pump();
      expect(_date.value, DateTime(2026, 12, 16));
      semanticsOwner().performAction(month.id, SemanticsAction.decrease);
      semanticsOwner().performAction(month.id, SemanticsAction.decrease);
      await tester.pump();
      expect(_date.value, DateTime(2026, 10, 16));
      handle.dispose();
    });

    testWidgets('a pointer over the field hovers it', (tester) async {
      await tester.pumpWidget(harness(const _DateHost()));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('dd')));
      await tester.pump();
      expect(_frame, contains(WidgetState.hovered));
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_frame, isNot(contains(WidgetState.hovered)));
      await mouse.removePointer();
    });

    testWidgets('a tap between segments goes to the first empty one; a '
        'second tap on a segment brings the keyboard back', (tester) async {
      await tester.pumpWidget(
        harness(_DateHost(value: DateTime(2026, 11, 16))),
      );
      _date.set(null);
      await tester.pump();
      await tester.tap(find.text('/').last);
      await tester.pump();
      expect(_focusedOn(tester, 'Month'), isTrue);
      await tester.tap(find.text('/').last);
      await tester.pump();
      expect(_focusedOn(tester, 'Month'), isTrue, reason: 'already in');
      tester.testTextInput.hide();
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.text('mm'));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
    });

    testWidgets('turned off while typing: the focus and the keyboard go', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _DateHost()));
      await tester.tap(find.text('mm'));
      await tester.pump();
      expect(tester.testTextInput.hasAnyClients, isTrue);
      await tester.pumpWidget(harness(const _DateHost(enabled: false)));
      await tester.pump();
      expect(tester.testTextInput.hasAnyClients, isFalse);
      expect(_painted.last.states, contains(WidgetState.disabled));
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1, character: '1');
      await tester.pump();
      expect(_date.sent, isEmpty);
    });

    testWidgets('a phone keyboard\'s other calls change nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(_DateHost(value: DateTime(2026, 11, 16))),
      );
      final client = tester.state(find.byType(RawDateField)) as TextInputClient;
      expect(client.currentTextEditingValue!.text, '​​');
      expect(client.currentAutofillScope, isNull);
      expect(client.onFocusReceived(), isFalse);
      client
        ..performPrivateCommand('x', const {})
        ..updateFloatingCursor(
          RawFloatingCursorPoint(state: FloatingCursorDragState.Start),
        )
        ..showAutocorrectionPromptRect(0, 1)
        ..insertTextPlaceholder(Size.zero)
        ..removeTextPlaceholder()
        ..showToolbar()
        ..didChangeInputControl(null, null)
        ..performSelector('noop')
        ..insertContent(const KeyboardInsertedContent(mimeType: 'x', uri: 'y'))
        ..updateEditingValue(client.currentTextEditingValue!)
        ..connectionClosed();
      await tester.pump();
      expect(_date.sent, isEmpty);
      expect(_date.value, DateTime(2026, 11, 16));
    });

    testWidgets('a time field: Enter, a parent\'s new time, the clock '
        'changing under it', (tester) async {
      await tester.pumpWidget(
        harness(const _TimeHost(value: RawTimeOfDay(hour: 15, minute: 5))),
      );
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(_time.done, 1);
      _time.set(const RawTimeOfDay(hour: 8, minute: 0));
      await tester.pump();
      expect(_drawn(tester), ['8', '00', 'AM']);
      // The platform's 24-hour setting turning on keeps the time.
      await tester.pumpWidget(
        harness(
          const _TimeHost(value: RawTimeOfDay(hour: 15, minute: 5)),
          wrap: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        ),
      );
      expect(_drawn(tester), ['08', '00']);
      expect(_time.sent, isEmpty);
    });

    testWidgets('PM by the letter where the words differ: Korean 오후 by 후', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _TimeHost(locale: Locale('ko'))));
      await _tab(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: '후');
      await tester.pump();
      expect(_drawn(tester).first, '오후');
    });
  });

  group('the segments in a frame narrower than them', () {
    const widths = {
      RawDateSegmentType.day: 30.0,
      RawDateSegmentType.month: 30.0,
      RawDateSegmentType.year: 50.0,
      RawDateSegmentType.hour: 30.0,
      RawDateSegmentType.minute: 30.0,
      RawDateSegmentType.dayPeriod: 30.0,
    };
    // Each segment's face 20 px tall, each piece of text between them a
    // 10 px square.
    Widget face(BuildContext context, RawDateSegmentDetails d) => SizedBox(
      key: ValueKey(d.type),
      width: widths[d.type],
      height: 20,
      child: Text(d.text),
    );
    Widget text(BuildContext context, String literal) => SizedBox(
      key: const ValueKey('text'),
      width: 10,
      height: 10,
      child: Text(literal),
    );
    Widget host(
      double width,
      Widget field, {
      Locale? locale,
      TextDirection direction = TextDirection.ltr,
    }) {
      Widget shown = Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: field,
        ),
      );
      if (locale != null) {
        shown = Localizations(
          locale: locale,
          delegates: const [
            RawWidgetsLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Directionality(textDirection: direction, child: shown),
        );
      }
      return harness(shown, textDirection: direction);
    }

    Widget date({double? minHeight}) => RawDateField(
      value: DateTime(2026, 11, 16),
      semanticLabel: 'Due',
      onChanged: (_) {},
      segmentBuilder: face,
      literalBuilder: text,
      frameBuilder: minHeight == null
          ? null
          : (context, states, segments) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: segments,
            ),
    );
    // Where each segment and each piece of text lies in the field.
    Rect at(WidgetTester tester, Finder piece) {
      final origin = tester.getTopLeft(
        find.byType(RawDateField).evaluate().isEmpty
            ? find.byType(RawTimeField)
            : find.byType(RawDateField),
      );
      return tester.getRect(piece).shift(-origin);
    }

    Rect segment(WidgetTester tester, RawDateSegmentType type) =>
        at(tester, find.byKey(ValueKey(type)));
    List<Rect> texts(WidgetTester tester) => [
      for (final e in find.byKey(const ValueKey('text')).evaluate())
        at(tester, find.byWidget(e.widget)),
    ];

    testWidgets('when they fit, one line, as a row lays them', (tester) async {
      await tester.pumpWidget(host(800, date()));
      expect(segment(tester, RawDateSegmentType.month), _ltrb(0, 0, 30, 20));
      expect(segment(tester, RawDateSegmentType.day), _ltrb(40, 0, 70, 20));
      expect(segment(tester, RawDateSegmentType.year), _ltrb(80, 0, 130, 20));
      expect(texts(tester), [_ltrb(30, 5, 40, 15), _ltrb(70, 5, 80, 15)]);
      // In a frame taller than them, centred in it as a row centres them.
      await tester.pumpWidget(host(800, date(minHeight: 48)));
      expect(segment(tester, RawDateSegmentType.month), _ltrb(0, 14, 30, 34));
      expect(texts(tester).first, _ltrb(30, 19, 40, 29));
    });

    testWidgets('narrower, they wrap between parts, each segment kept with '
        'the text after it', (tester) async {
      await tester.pumpWidget(host(100, date()));
      expect(segment(tester, RawDateSegmentType.day), _ltrb(40, 0, 70, 20));
      expect(segment(tester, RawDateSegmentType.year), _ltrb(0, 20, 50, 40));
      expect(texts(tester), [_ltrb(30, 5, 40, 15), _ltrb(70, 5, 80, 15)]);
      expect(tester.getSize(find.byType(RawDateField)), const Size(80, 40));
      await tester.pumpWidget(host(50, date()));
      expect(segment(tester, RawDateSegmentType.day), _ltrb(0, 20, 30, 40));
      expect(segment(tester, RawDateSegmentType.year), _ltrb(0, 40, 50, 60));
      expect(texts(tester), [_ltrb(30, 5, 40, 15), _ltrb(30, 25, 40, 35)]);
    });

    testWidgets('a time: no line starts with the space before AM/PM', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          85,
          RawTimeField(
            value: const RawTimeOfDay(hour: 15, minute: 5),
            semanticLabel: 'Start',
            alwaysUse24HourFormat: false,
            onChanged: (_) {},
            segmentBuilder: face,
            literalBuilder: text,
          ),
        ),
      );
      expect(segment(tester, RawDateSegmentType.minute), _ltrb(40, 0, 70, 20));
      expect(
        segment(tester, RawDateSegmentType.dayPeriod),
        _ltrb(0, 20, 30, 40),
      );
      expect(texts(tester), [_ltrb(30, 5, 40, 15), _ltrb(70, 5, 80, 15)]);
    });

    testWidgets('Hebrew: a run of digits wraps left to right within itself, '
        'its lines kept to the right', (tester) async {
      await tester.pumpWidget(
        host(
          100,
          date(),
          locale: const Locale('he'),
          direction: TextDirection.rtl,
        ),
      );
      expect(segment(tester, RawDateSegmentType.day), _ltrb(0, 0, 30, 20));
      expect(segment(tester, RawDateSegmentType.month), _ltrb(40, 0, 70, 20));
      expect(segment(tester, RawDateSegmentType.year), _ltrb(30, 20, 80, 40));
      expect(texts(tester), [_ltrb(30, 5, 40, 15), _ltrb(70, 5, 80, 15)]);
    });

    testWidgets('Arabic: the day first on the right, the year on the next '
        'line', (tester) async {
      await tester.pumpWidget(
        host(
          100,
          date(),
          locale: const Locale('ar'),
          direction: TextDirection.rtl,
        ),
      );
      expect(segment(tester, RawDateSegmentType.day), _ltrb(50, 0, 80, 20));
      expect(segment(tester, RawDateSegmentType.month), _ltrb(10, 0, 40, 20));
      expect(segment(tester, RawDateSegmentType.year), _ltrb(30, 20, 80, 40));
      expect(texts(tester), [_ltrb(40, 5, 50, 15), _ltrb(0, 5, 10, 15)]);
    });

    testWidgets('wrapped, the focus and a screen reader keep their order, and '
        'a tap off the segments still goes to one', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host(100, date()));
      final field = semanticsOf(tester, _node('Due'));
      expect(
        [
          for (final n in field.debugListChildrenInOrder(
            DebugSemanticsDumpOrder.traversalOrder,
          ))
            n.label,
        ],
        ['Month', 'Day', 'Year'],
      );
      await _tab(tester);
      expect(_focusedOn(tester, 'Month'), isTrue);
      await _tab(tester);
      await _tab(tester);
      expect(_focusedOn(tester, 'Year'), isTrue, reason: 'on the next line');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      // Beside the year, on its line.
      await tester.tapAt(
        tester.getTopLeft(find.byType(RawDateField)) + const Offset(65, 30),
      );
      await tester.pump();
      expect(_focusedOn(tester, 'Month'), isTrue);
      semantics.dispose();
    });
  });

  group('RawTimeOfDay', () {
    test('its parts, its period and its order', () {
      const t = RawTimeOfDay(hour: 15, minute: 5);
      expect(t.hourOfPeriod, 3);
      expect(t.isPm, isTrue);
      expect(const RawTimeOfDay(hour: 0, minute: 1).hourOfPeriod, 12);
      expect(const RawTimeOfDay(hour: 12, minute: 0).isPm, isTrue);
      expect(t.replacing(minute: 6), const RawTimeOfDay(hour: 15, minute: 6));
      expect(t.isBefore(t.replacing(second: 1)), isTrue);
      expect(t.isAfter(t.replacing(hour: 14)), isTrue);
      expect(t.hashCode, const RawTimeOfDay(hour: 15, minute: 5).hashCode);
      expect(t.toString(), 'RawTimeOfDay(15:05:00)');
      expect(
        RawTimeOfDay.fromDateTime(DateTime(2026, 1, 1, 7, 8, 9)),
        const RawTimeOfDay(hour: 7, minute: 8, second: 9),
      );
    });
  });

  testWidgets('diagnostics name what each field was given', (tester) async {
    await tester.pumpWidget(harness(const _DateHost()));
    final date = tester.widget<RawDateField>(find.byType(RawDateField));
    expect(
      date.toDiagnosticsNode().getProperties().map((p) => p.name),
      containsAll(['value', 'onChanged', 'semanticLabel']),
    );
    await tester.pumpWidget(harness(const _TimeHost()));
    final time = tester.widget<RawTimeField>(find.byType(RawTimeField));
    expect(
      time.toDiagnosticsNode().getProperties().map((p) => p.name),
      containsAll(['value', 'onChanged', 'showSeconds']),
    );
  });
}

Matcher _ltrb(double l, double t, double r, double b) =>
    rectMoreOrLessEquals(Rect.fromLTRB(l, t, r, b));
