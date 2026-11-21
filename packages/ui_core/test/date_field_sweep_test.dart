// Every locale × field (a date; a time on the locale's clock, on 24 hours,
// with seconds): each segment drawn and named in the locale's words, typed
// in tab order to a whole value the field reads back in the locale's
// format, and each run of digits drawn left to right.
@Tags(['sweep'])
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/segments.dart';

import 'behaviour_harness.dart';

const _rtl = {'ar', 'fa', 'he', 'ur'};

enum _Field { date, time, time24, seconds }

Object? _value;

Widget _segment(BuildContext context, RawDateSegmentDetails d) =>
    SizedBox(width: 40, height: 40, child: Text(d.text, key: ValueKey(d.type)));

Widget _field(_Field field) => switch (field) {
  _Field.date => RawDateField(
    value: null,
    onChanged: (v) => _value = v,
    segmentBuilder: _segment,
  ),
  _ => RawTimeField(
    value: null,
    onChanged: (v) => _value = v,
    alwaysUse24HourFormat: field == _Field.time ? false : true,
    showSeconds: field == _Field.seconds,
    segmentBuilder: _segment,
  ),
};

RawDateSegmentType? _focused() {
  final label = FocusManager.instance.primaryFocus?.debugLabel ?? '';
  if (!label.startsWith('date segment ')) return null;
  final name = label.substring('date segment '.length);
  return RawDateSegmentType.values.firstWhere((t) => t.name == name);
}

void main() {
  for (final locale in RawWidgetsLocalizations.supportedLocales) {
    for (final field in _Field.values) {
      testWidgets('${locale.toLanguageTag()} ${field.name}', (tester) async {
        _value = null;
        final direction = _rtl.contains(locale.languageCode)
            ? TextDirection.rtl
            : TextDirection.ltr;
        await tester.pumpWidget(
          harness(
            Localizations(
              locale: locale,
              delegates: const [
                RawWidgetsLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
              ],
              child: Directionality(
                textDirection: direction,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _field(field),
                ),
              ),
            ),
          ),
        );
        final context = tester.element(find.byType(Align).last);
        final l = RawWidgetsLocalizations.of(context);
        final pattern = field == _Field.date
            ? l.dateFieldPattern
            : l.timeFieldPattern(
                alwaysUse24HourFormat: field != _Field.time,
                showSeconds: field == _Field.seconds,
              );
        final parts = parsePattern(pattern);
        final segments = parts.where((p) => p.type != null).toList();
        final types = segments.map((p) => p.type!).toSet();
        final where = '$locale ${field.name} "$pattern"';

        // Each segment drawn, empty, and named in the locale's words.
        expect(
          find.byWidgetPredicate(
            (w) => w is Text && w.key is ValueKey<RawDateSegmentType>,
          ),
          findsNWidgets(segments.length),
          reason: where,
        );
        if (field == _Field.date) {
          expect(types, {
            RawDateSegmentType.year,
            RawDateSegmentType.month,
            RawDateSegmentType.day,
          }, reason: where);
        } else {
          expect(
            types.contains(RawDateSegmentType.second),
            field == _Field.seconds,
            reason: where,
          );
          if (field != _Field.time) {
            expect(
              types,
              isNot(contains(RawDateSegmentType.dayPeriod)),
              reason: where,
            );
          }
        }
        for (final word in [
          if (field == _Field.date) ...[
            l.dateFieldYearLabel,
            l.dateFieldMonthLabel,
            l.dateFieldDayLabel,
          ] else ...[
            l.timePickerHourLabel,
            l.timePickerMinuteLabel,
          ],
        ]) {
          expect(
            find.bySemanticsLabel(word),
            findsOneWidget,
            reason: '$where: "$word"',
          );
        }

        // Typed in tab order, ASCII digits, to a whole value.
        final hour = segments
            .where((p) => p.type == RawDateSegmentType.hour)
            .firstOrNull
            ?.letter;
        String keysFor(RawDateSegmentType type) => switch (type) {
          RawDateSegmentType.year => '2026',
          RawDateSegmentType.month => '11',
          RawDateSegmentType.day => '16',
          RawDateSegmentType.hour => hour == 'h' || hour == 'K' ? '03' : '15',
          RawDateSegmentType.minute => '05',
          RawDateSegmentType.second => '09',
          RawDateSegmentType.dayPeriod => 'p',
        };
        final visited = <RawDateSegmentType>[];
        for (var i = 0; i < segments.length; i++) {
          if (_focused() == null) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
          }
          final at = _focused();
          expect(at, isNotNull, reason: '$where: a segment has the focus');
          visited.add(at!);
          for (final c in keysFor(at).split('')) {
            await tester.sendKeyEvent(
              c == 'p'
                  ? LogicalKeyboardKey.keyP
                  : LogicalKeyboardKey(
                      LogicalKeyboardKey.digit0.keyId + int.parse(c),
                    ),
              character: c,
            );
            await tester.pump();
          }
        }
        expect(visited, [for (final p in segments) p.type], reason: where);
        final whole = switch (field) {
          _Field.date => DateTime(2026, 11, 16),
          _Field.seconds => const RawTimeOfDay(hour: 15, minute: 5, second: 9),
          _ => const RawTimeOfDay(hour: 15, minute: 5),
        };
        expect(_value, whole, reason: where);
        final read = whole is DateTime
            ? l.formatFullDate(whole)
            : l.formatTimeOfDay(
                whole as RawTimeOfDay,
                alwaysUse24HourFormat:
                    field != _Field.time ||
                    !types.contains(RawDateSegmentType.dayPeriod),
                showSeconds: field == _Field.seconds,
              );
        final root = tester.getSemantics(
          find.byWidgetPredicate((w) => w is RawDateField || w is RawTimeField),
        );
        expect(root.getSemanticsData().value, read, reason: where);

        // Each run of digits draws left to right, in any direction.
        final centre = <RawDateSegmentType, double>{
          for (final p in segments)
            p.type!: tester.getCenter(find.byKey(ValueKey(p.type!))).dx,
        };
        for (final run in numberRuns(parts)) {
          final xs = [
            for (final i in run)
              if (parts[i].type != null) centre[parts[i].type]!,
          ];
          for (var i = 1; i < xs.length; i++) {
            expect(xs[i], greaterThan(xs[i - 1]), reason: '$where: run $run');
          }
        }
      });
    }
  }
}
