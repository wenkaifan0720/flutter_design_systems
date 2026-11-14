import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

void main() {
  final now = DateTime(2026, 11, 3, 14, 30); // a Tuesday

  test('dates, months and weekdays', () {
    expect(Fluent2Format.date(DateTime(2026, 11, 3)), 'Nov 3');
    expect(
      Fluent2Format.date(DateTime(2026, 11, 3), weekday: true),
      'Tue, Nov 3',
    );
    expect(Fluent2Format.date(DateTime(2025, 1, 9), year: true), 'Jan 9, 2025');
    expect(Fluent2Format.longDate(now), 'Tuesday, November 3');
    expect(Fluent2Format.month(now, year: true), 'November 2026');
  });

  test('clock times and spans', () {
    expect(Fluent2Format.time(DateTime(2026, 1, 1, 0, 5)), '12:05 AM');
    expect(Fluent2Format.time(DateTime(2026, 1, 1, 21, 41)), '9:41 PM');
    expect(
      Fluent2Format.timeRange(
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 1, 9, 30),
      ),
      '9:00 – 9:30 AM',
    );
    expect(
      Fluent2Format.timeRange(
        DateTime(2026, 1, 1, 11, 30),
        DateTime(2026, 1, 1, 12, 15),
      ),
      '11:30 AM – 12:15 PM',
    );
    expect(Fluent2Format.duration(const Duration(minutes: 45)), '45 min');
    expect(Fluent2Format.duration(const Duration(minutes: 90)), '1 h 30 min');
    expect(Fluent2Format.duration(const Duration(hours: 2)), '2 h');
  });

  test('day words and how long ago', () {
    expect(Fluent2Format.day(DateTime(2026, 11, 3), now: now), 'Today');
    expect(Fluent2Format.day(DateTime(2026, 11, 2), now: now), 'Yesterday');
    expect(Fluent2Format.day(DateTime(2026, 11, 4), now: now), 'Tomorrow');
    expect(Fluent2Format.day(DateTime(2026, 11, 6), now: now), 'Friday');
    expect(Fluent2Format.day(DateTime(2025, 12, 24), now: now), 'Dec 24, 2025');
    expect(Fluent2Format.ago(now, now: now), 'Just now');
    expect(
      Fluent2Format.ago(now.subtract(const Duration(minutes: 5)), now: now),
      '5m ago',
    );
    expect(
      Fluent2Format.ago(now.subtract(const Duration(hours: 2)), now: now),
      '2h ago',
    );
    expect(Fluent2Format.ago(DateTime(2026, 11, 2, 23), now: now), 'Yesterday');
    expect(Fluent2Format.ago(DateTime(2026, 10, 1), now: now), 'Oct 1');
  });

  test('sizes, counts, money and initials', () {
    expect(Fluent2Format.bytes(512), '512 B');
    expect(Fluent2Format.bytes(18 * 1024), '18 KB');
    expect(Fluent2Format.bytes((2.4 * 1024 * 1024).round()), '2.4 MB');
    expect(Fluent2Format.count(1284), '1,284');
    expect(Fluent2Format.count(12400, compact: true), '12.4K');
    expect(Fluent2Format.count(3400000, compact: true), '3.4M');
    expect(Fluent2Format.count(-5), '-5');
    expect(Fluent2Format.plural(1, 'file'), '1 file');
    expect(Fluent2Format.plural(3, 'reply', 'replies'), '3 replies');
    expect(Fluent2Format.percent(1, 3), 33);
    expect(Fluent2Format.money(132644), r'$1,326.44');
    expect(Fluent2Format.money(-1200), r'-$12.00');
    expect(Fluent2Format.initials('Ines Duarte'), 'ID');
    expect(Fluent2Format.initials('Noor'), 'N');
  });
}
