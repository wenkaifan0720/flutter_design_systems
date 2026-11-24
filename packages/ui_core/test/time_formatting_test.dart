import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

// A time's figures in the app's digits: RawTimeFormatting's formatHour and
// formatMinute (Material's names) for a look's own time picker, and the
// time field's segments, its spoken value and its typing, in English, Arabic
// and Persian, on 12- and 24-hour clocks.

const _late = RawTimeOfDay(hour: 15, minute: 7);
const _early = RawTimeOfDay(hour: 9, minute: 5);
const _midnight = RawTimeOfDay(hour: 0, minute: 0);

// A phone keyboard's text starts with the field's two zero-width spaces.
final _zws = String.fromCharCode(0x200B) * 2;

// A subclass with its own digits (Devanagari) and a padded 12-hour clock.
class _Padded extends DefaultRawWidgetsLocalizations {
  const _Padded();

  @override
  String formatDecimal(num value, {int? fractionDigits}) =>
      String.fromCharCodes(
        value.toString().codeUnits.map(
          (c) => c >= 0x30 && c <= 0x39 ? 0x0966 + c - 0x30 : c,
        ),
      );

  @override
  String timeFieldPattern({
    bool alwaysUse24HourFormat = false,
    bool showSeconds = false,
  }) => alwaysUse24HourFormat ? 'HH:mm' : 'hh:mm a';
}

// A clock of [pattern]'s.
class _Clock extends DefaultRawWidgetsLocalizations {
  const _Clock(this.pattern);

  final String pattern;

  @override
  String timeFieldPattern({
    bool alwaysUse24HourFormat = false,
    bool showSeconds = false,
  }) => pattern;
}

Widget _host(
  String language, {
  required bool h24,
  RawTimeOfDay? value,
  ValueChanged<RawTimeOfDay?>? onChanged,
  Map<RawDateSegmentType, String>? shown,
}) => harness(
  Localizations(
    locale: Locale(language),
    delegates: const [
      RawWidgetsLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    child: MediaQuery(
      data: MediaQueryData(alwaysUse24HourFormat: h24),
      child: Center(
        child: RawTimeField(
          value: value,
          onChanged: onChanged ?? (_) {},
          segmentBuilder: (context, details) {
            shown?[details.type] = details.text;
            return Text(details.text, key: ValueKey(details.type));
          },
        ),
      ),
    ),
  ),
  textDirection: language == 'en' ? TextDirection.ltr : TextDirection.rtl,
);

// [n] in [language]'s digits ([local]) or in ASCII.
String _digits(String language, int n, {required bool local}) {
  final zero = RawWidgetsLocalizations.forLocale(Locale(language))
      .formatDecimal(0)
      .codeUnitAt(0);
  return local
      ? String.fromCharCodes('$n'.codeUnits.map((c) => zero + c - 0x30))
      : '$n';
}

// The ASCII digit of [c], one of ASCII's, Arabic's or Persian's digits.
int _value(String c) {
  final unit = c.codeUnitAt(0);
  for (final zero in [0x30, 0x0660, 0x06F0]) {
    if (unit >= zero && unit <= zero + 9) return unit - zero;
  }
  throw ArgumentError(c);
}

void main() {
  group('RawTimeFormatting: a time picker\'s figures in the app\'s digits', () {
    final cases = {
      // [15:07, 09:05, 00:00]: the hours, then the minutes.
      ('en', false): (['3', '9', '12'], ['07', '05', '00']),
      ('en', true): (['15', '09', '00'], ['07', '05', '00']),
      ('ar', false): (['٣', '٩', '١٢'], ['٠٧', '٠٥', '٠٠']),
      ('ar', true): (['١٥', '٠٩', '٠٠'], ['٠٧', '٠٥', '٠٠']),
      ('fa', false): (['۱۵', '۹', '۰'], ['۰۷', '۰۵', '۰۰']),
      ('fa', true): (['۱۵', '۹', '۰'], ['۰۷', '۰۵', '۰۰']),
    };
    for (final MapEntry(key: (language, h24), value: (hours, minutes))
        in cases.entries) {
      test('$language, ${h24 ? 24 : 12}-hour clock', () {
        final l = RawWidgetsLocalizations.forLocale(Locale(language));
        final times = [_late, _early, _midnight];
        expect([
          for (final t in times) l.formatHour(t, alwaysUse24HourFormat: h24),
        ], hours);
        expect([for (final t in times) l.formatMinute(t)], minutes);
        // The figures are the whole time's, as formatTimeOfDay writes it.
        for (final t in times) {
          final whole = l.formatTimeOfDay(t, alwaysUse24HourFormat: h24);
          final hour = l.formatHour(t, alwaysUse24HourFormat: h24);
          final minute = l.formatMinute(t);
          expect(whole, startsWith(hour));
          expect(whole.substring(hour.length), contains(minute));
        }
      });
    }

    test('a subclass\'s own digits and clock', () {
      const l = _Padded();
      expect(l.formatHour(_early), '०९');
      expect(l.formatHour(_late), '०३');
      expect(l.formatHour(_late, alwaysUse24HourFormat: true), '१५');
      expect(l.formatMinute(_early), '०५');
    });

    test('the other clocks: K (0 to 11) and k (1 to 24)', () {
      for (final (pattern, hours) in [
        ('K:mm a', ['3', '9', '0']),
        ('k:mm', ['15', '9', '24']),
      ]) {
        final l = _Clock(pattern);
        expect([
          for (final t in [_late, _early, _midnight]) l.formatHour(t),
        ], hours);
      }
    });
  });

  group('RawTimeField writes and reads the app\'s digits', () {
    for (final language in ['en', 'ar', 'fa']) {
      for (final h24 in [false, true]) {
        testWidgets('$language, ${h24 ? 24 : 12}-hour clock: its segments are '
            'formatHour\'s and formatMinute\'s, its value the whole time', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          final shown = <RawDateSegmentType, String>{};
          await tester.pumpWidget(
            _host(language, h24: h24, value: _late, shown: shown),
          );
          final l = RawWidgetsLocalizations.forLocale(Locale(language));
          expect(
            shown[RawDateSegmentType.hour],
            l.formatHour(_late, alwaysUse24HourFormat: h24),
          );
          expect(shown[RawDateSegmentType.minute], l.formatMinute(_late));
          final twelve = shown.containsKey(RawDateSegmentType.dayPeriod);
          expect(
            twelve,
            language != 'fa' && !h24,
            reason: 'Persian keeps its 24-hour clock',
          );
          if (twelve) {
            expect(
              shown[RawDateSegmentType.dayPeriod],
              l.postMeridiemAbbreviation,
            );
          }
          expect(
            tester.getSemantics(find.byType(RawTimeField)).value,
            l.formatTimeOfDay(_late, alwaysUse24HourFormat: h24),
          );
          semantics.dispose();
        });
      }

      for (final local in [false, true]) {
        final script = local ? 'its own' : 'ASCII';
        testWidgets('$language: keys typing $script digits', (tester) async {
          RawTimeOfDay? got;
          await tester.pumpWidget(
            _host(language, h24: true, onChanged: (t) => got = t),
          );
          await tester.tap(find.byKey(const ValueKey(RawDateSegmentType.hour)));
          await tester.pump();
          for (final c in _digits(language, 1435, local: local).split('')) {
            await tester.sendKeyEvent(
              LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + _value(c)),
              character: c,
            );
            await tester.pump();
          }
          expect(got, const RawTimeOfDay(hour: 14, minute: 35));
        });

        testWidgets('$language: a phone keyboard typing $script digits', (
          tester,
        ) async {
          RawTimeOfDay? got;
          await tester.pumpWidget(
            _host(language, h24: true, onChanged: (t) => got = t),
          );
          await tester.tap(find.byKey(const ValueKey(RawDateSegmentType.hour)));
          await tester.pump();
          expect(tester.testTextInput.hasAnyClients, isTrue);
          void send(String text) => tester.testTextInput.updateEditingValue(
            TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            ),
          );
          send('$_zws${_digits(language, 14, local: local)}');
          await tester.pump();
          send('$_zws${_digits(language, 35, local: local)}');
          await tester.pump();
          expect(got, const RawTimeOfDay(hour: 14, minute: 35));
        });
      }
    }
  });
}
