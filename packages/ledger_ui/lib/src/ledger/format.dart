/// Ledger's display formatting: the money, days, clock times and counts a
/// finance screen prints, in the shapes the Keel pilot writes them
/// ("−$1,326.44", "Mon, Oct 26", "8:12 AM", "In 4 days").
///
/// PURE AND DETERMINISTIC, no intl. A generated app renders inside
/// walkthroughs and golden frames, and a locale-aware formatter makes the
/// same record read differently on two machines, which turns a diff into a
/// false failure. The vocabulary here is US English and the shapes are
/// fixed, so a screen's text is a function of its data and nothing else.
///
/// Nothing here touches [DateTime.now]: the day words take the moment to
/// measure against as an argument, because a formatter that reads the clock
/// cannot be tested. Money is in dollars, to the cent: an amount is rounded
/// to whole cents once, then printed from those.
///
/// ```dart
/// Text(LedgerFormat.money(-1326.44), style: t.amount)
/// ```
abstract final class LedgerFormat {
  /// The true minus (U+2212) every negative amount carries.
  static const String minus = '−';

  static const List<String> _monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// An amount in the three parts a hung figure prints: its sign (the
  /// true minus for a negative; "+" for a positive only with [showSign];
  /// else none), its whole dollars with thousands commas and its two cents:
  /// `moneyParts(-1326.44)` is `(sign: '−', whole: '1,326', cents: '44')`.
  static ({String sign, String whole, String cents}) moneyParts(
    num amount, {
    bool showSign = false,
  }) {
    final cents = (amount.abs() * 100).round();
    return (
      sign: _signOf(amount, showSign),
      whole: _grouped(cents ~/ 100),
      cents: (cents % 100).toString().padLeft(2, '0'),
    );
  }

  /// An amount as a line of words prints it: "$6,248.30", "−$1,326.44",
  /// "+$3,412.50" with `showSign: true`; `showCents: false` rounds to whole
  /// dollars (half to even, as the pilot's figures do): "$2,700".
  static String money(
    num amount, {
    bool showCents = true,
    bool showSign = false,
  }) {
    final lead = _signOf(amount, showSign);
    if (!showCents) return '$lead\$${_grouped(wholeDollars(amount))}';
    final parts = moneyParts(amount);
    return '$lead\$${parts.whole}.${parts.cents}';
  }

  /// [words] kept on one line wherever they fall in a paragraph, as the
  /// source's `.nowrap` keeps a figure in a sentence: a word joiner (U+2060)
  /// between each two characters and no-break spaces for spaces, so
  /// "−$1,326.44" never breaks after its sign. Readers pass the joiners over.
  ///
  /// ```dart
  /// Text('The Keel Card balance of ${LedgerFormat.unbroken(LedgerFormat.money(-1326.44))} is netted out.')
  /// ```
  static String unbroken(String words) => words
      .replaceAll(' ', '\u00A0')
      .runes
      .map(String.fromCharCode)
      .join('\u2060');

  /// The whole dollars of [amount]'s size, rounded half to even: 2.50 is 2,
  /// 3.50 is 4.
  static int wholeDollars(num amount) {
    final cents = (amount.abs() * 100).round();
    final dollars = cents ~/ 100;
    final rest = cents % 100;
    return rest > 50 || (rest == 50 && dollars.isOdd) ? dollars + 1 : dollars;
  }

  static String _signOf(num amount, bool sign) {
    if ((amount.abs() * 100).round() == 0) return '';
    if (amount < 0) return minus;
    return sign ? '+' : '';
  }

  /// A record's day against [now]: "Today", "Yesterday", else "Mon, Oct 26"
  /// (with its year when it is not [now]'s).
  static String day(DateTime d, {required DateTime now}) {
    final days = _days(d, now);
    if (days == 0) return 'Today';
    if (days == -1) return 'Yesterday';
    final s = '${weekday(d)}, ${month(d, short: true)} ${d.day}';
    return d.year == now.year ? s : '$s, ${d.year}';
  }

  /// A day as a date: "Nov 1"; with [showWeekday], "Sun, Nov 1"; with
  /// [showYear], "Nov 1, 2026".
  static String date(
    DateTime d, {
    bool showWeekday = false,
    bool showYear = false,
  }) {
    var s = '${month(d, short: true)} ${d.day}';
    if (showWeekday) s = '${weekday(d)}, $s';
    return showYear ? '$s, ${d.year}' : s;
  }

  /// A day in full: "Wednesday, October 28, 2026".
  static String longDate(DateTime d) =>
      '${weekday(d, short: false)}, ${month(d)} ${d.day}, ${d.year}';

  /// The month: "October", or "Oct" with `short: true`; with [showYear],
  /// "October 2026".
  static String month(DateTime d, {bool short = false, bool showYear = false}) {
    final name = _monthNames[d.month - 1];
    final word = short ? name.substring(0, 3) : name;
    return showYear ? '$word ${d.year}' : word;
  }

  /// "Wed", or "Wednesday" with `short: false`.
  static String weekday(DateTime d, {bool short = true}) {
    final name = _weekdays[d.weekday - 1];
    return short ? name.substring(0, 3) : name;
  }

  /// The clock on its twelve-hour face: "8:12 AM", no leading zero.
  static String time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// Whole calendar days from [now] to [d]: 4 for a bill due on the 1st when
  /// it is the 28th.
  static int daysUntil(DateTime d, {required DateTime now}) => _days(d, now);

  /// When [d] comes against [now]: "Today", "Tomorrow", "In 4 days".
  static String inDays(DateTime d, {required DateTime now}) {
    final n = _days(d, now);
    if (n == 0) return 'Today';
    if (n == 1) return 'Tomorrow';
    return 'In $n days';
  }

  /// Home's greeting for [first] at [now]: "Good morning, Maren" before
  /// noon, "Good afternoon" before five, "Good evening" after.
  static String greeting(String first, {required DateTime now}) {
    final part = now.hour < 12
        ? 'morning'
        : now.hour < 17
        ? 'afternoon'
        : 'evening';
    return 'Good $part, $first';
  }

  /// The masthead's date over a tab's title: "Wednesday, October 28".
  static String today(DateTime now) =>
      '${weekday(now, short: false)}, ${month(now)} ${now.day}';

  /// The moment over Home's greeting: "Wednesday, October 28 · 7:40 PM".
  static String nowLabel(DateTime now) => '${today(now)} · ${time(now)}';

  /// A monogram's letters: the first letters of a name's first two words,
  /// or the first two of a one-word name: "Blue Fern Café" is "BF",
  /// "Cloudbox" is "CL".
  static String initials(String name) {
    final words = name
        .replaceAll('&', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && _alnum.hasMatch(w[0]))
        .toList();
    if (words.isEmpty) return '';
    if (words.length > 1) return (words[0][0] + words[1][0]).toUpperCase();
    final w = words.first;
    return w.substring(0, w.length < 2 ? w.length : 2).toUpperCase();
  }

  static final RegExp _alnum = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// A share as a whole percent, rounded half to even: `percent(2840, 4000)`
  /// is 71. A [whole] of 0 is no share yet, and neither is a part or
  /// whole that is no number: 0 (the new goal's preview reads "0%" before
  /// its target is set).
  static int percent(num part, num whole) {
    if (whole == 0 || !part.isFinite || !whole.isFinite) return 0;
    final v = 100 * part / whole;
    final floor = v.floor();
    final rest = v - floor;
    if (rest > 0.5 || (rest == 0.5 && floor.isOdd)) return floor + 1;
    return floor;
  }

  /// A count with thousands separators: `14880` is "14,880".
  static String count(int value) =>
      '${value < 0 ? '-' : ''}${_grouped(value.abs())}';

  /// A count with its noun: `1 bill`, `3 bills`, with [many] for an
  /// irregular plural.
  static String plural(int n, String one, [String? many]) =>
      '${count(n)} ${n == 1 ? one : (many ?? '${one}s')}';

  /// Calendar days between [now] and [d], counted on UTC dates: two local
  /// midnights across a daylight-saving change are 23 or 25 hours apart.
  static int _days(DateTime d, DateTime now) => DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

  /// Thousands separators, built by hand because intl is not on the kit's
  /// dependency list.
  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index += 1) {
      final fromEnd = digits.length - index;
      if (index > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
