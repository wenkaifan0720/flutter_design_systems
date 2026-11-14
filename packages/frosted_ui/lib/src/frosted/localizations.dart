// The words only Frosted's parts say on their own: a card's labels, the
// composer's, the text menu's. The words every design system says (Close,
// Back, Cancel, Loading) are ui_core's DesignLocalizations. A part takes the
// caller's words when given, and these otherwise, so an app in another
// language installs a delegate for each and every part speaks it.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The words Frosted's own parts say when the caller gives none (a card's
/// number and CVC, the composer's Send, the text menu's Cut and Copy), as
/// Material's `MaterialLocalizations` are. The words every design system
/// shares (Close, Back, Cancel, Today) are ui_core's `DesignLocalizations`.
/// English ships ([FrostedLocalizationsEn]); another language is a subclass
/// and a delegate that loads it, beside a `DefaultDesignLocalizations`
/// subclass for the shared words. With no delegate installed the parts speak
/// English.
///
/// ```dart
/// MaterialApp(
///   localizationsDelegates: const [
///     FrostedLocalizations.delegate,
///     DefaultDesignLocalizations.delegate,
///   ],
///   home: home,
/// )
/// ```
abstract class FrostedLocalizations {
  /// Const constructor, for subclasses.
  const FrostedLocalizations();

  /// The words in force at [context]: the installed delegate's, else
  /// English.
  static FrostedLocalizations of(BuildContext context) =>
      Localizations.of<FrostedLocalizations>(context, FrostedLocalizations) ??
      const FrostedLocalizationsEn();

  /// Loads Frosted's English words for an English locale.
  static const LocalizationsDelegate<FrostedLocalizations> delegate =
      _FrostedLocalizationsDelegate();

  /// What a finished step says.
  String get done;

  /// The error state's way to try again.
  String get tryAgain;

  /// A tab bar's spoken name.
  String get sections;

  /// The avatar in the app bar.
  String get profileAndSettings;

  /// The bell in the app bar.
  String get notifications;

  /// The swap between two pickers (from and to).
  String get swap;

  /// A composer's send.
  String get send;

  /// A composer's stop while a reply streams.
  String get stop;

  /// A composer's microphone.
  String get dictate;

  /// A composer's attach.
  String get attach;

  /// An empty composer's hint.
  String get message;

  /// An empty composer's hint when it talks to an assistant.
  String get askAnything;

  /// A row of filter chips' spoken name.
  String get filters;

  /// A month switch's spoken name.
  String get month;

  /// A month switch's button that opens the months.
  String get chooseMonth;

  /// A row of quick actions' spoken name.
  String get quickActions;

  /// A row of quick amounts' spoken name.
  String get quickAmounts;

  /// An icon picker's spoken name.
  String get icon;

  /// A card's balance.
  String get balance;

  /// A credit card's kind.
  String get credit;

  /// A debit card's kind.
  String get debit;

  /// A frozen card's word.
  String get frozen;

  /// A card's number.
  String get cardNumber;

  /// A card's expiry.
  String get expires;

  /// A card's security code.
  String get cvc;

  /// A card's holder.
  String get name;

  /// The tile that starts a new goal.
  String get newGoal;

  /// Its second line.
  String get newGoalNote;

  /// Money in, over a split of in and out.
  String get moneyIn;

  /// Money out, over the same split.
  String get spent;

  /// What is kept, in the same split.
  String get net;

  /// The kept share of a split, named.
  String get kept;

  /// A statement's automatic payment.
  String get autopay;

  /// An unread note's dot.
  String get unread;

  /// A move between accounts.
  String get move;

  /// The menu over a selection: cut.
  String get cut;

  /// Copy.
  String get copy;

  /// Paste.
  String get paste;

  /// Select all.
  String get selectAll;

  /// Look up.
  String get lookUp;

  /// Search the web.
  String get searchWeb;

  /// Share.
  String get share;

  /// Scan text with the camera.
  String get scanText;

  /// A payment by card.
  String get cardPayment;

  /// A number field's minus, for [what].
  String lower(String what);

  /// A number field's plus, for [what].
  String raise(String what);

  /// The bell with [count] unread.
  String unreadNotifications(int count);

  /// A sign-in button for [provider].
  String continueWith(String provider);

  /// An act whose work is under way.
  String get working;

  /// A move from one account to another.
  String fromTo(String from, String to);

  /// The step back through pages.
  String get previous;

  /// The step on through pages.
  String get next;

  /// A page's place among [count].
  String page(int page, int count);

  /// A step's place among [count].
  String step(int step, int count);

  /// A chip's remove button.
  String get remove;

  /// A rating's value out of [max].
  String rating(num value, int max);

  /// A file drop's button.
  String get chooseFile;

  /// A file drop's invitation, beside its button.
  String get dropFile;

  /// A date picker's title and its field's prompt.
  String get selectDate;

  /// A time picker's title and its field's prompt.
  String get selectTime;

  /// A select's prompt before anything is chosen.
  String get select;

  /// The time wheel's columns.
  String get hour;

  /// See [hour].
  String get minute;

  /// Before and after noon.
  String get am;

  /// See [am].
  String get pm;

  /// Whether times are told on a 24-hour clock.
  bool get alwaysUse24HourFormat;

  /// A month's name, January 1 to December 12.
  String monthName(int month);

  /// A day as the calendar says it: "Monday, November 9, 2026".
  String fullDate(DateTime date);

  /// A day as a field shows it: "Nov 9, 2026".
  String shortDate(DateTime date);

  /// A time as a field shows it: "9:05 AM", or "09:05" on a 24-hour clock.
  String time(int hour, int minute);

  /// A chart's series read aloud: its name, where it starts and ends, its
  /// high and its low (Sales: 12 to 18, high 20, low 10).
  String seriesSummary({
    required String name,
    required String first,
    required String last,
    required String high,
    required String low,
  });

  /// What a chart with nothing to plot says.
  String get noData;

  /// A slice of a pie read aloud: its name and its share (Rent, 40%).
  String sliceShare(String name, int percent);

  /// A one-time code's boxes, read as one field.
  String get oneTimeCode;

  /// The command palette's field.
  String get searchCommands;

  /// Starts a carousel turning.
  String get play;

  /// Stops a carousel turning.
  String get pause;

  /// A row's drag handle.
  String get reorder;

  /// Moves a row one place up.
  String get moveUp;

  /// Moves a row one place down.
  String get moveDown;

  /// A split view's divider.
  String get resize;

  /// A colour picker's hue slider.
  String get hue;

  /// A colour picker's opacity slider.
  String get opacity;

  /// A colour picker's hex field.
  String get hex;

  /// A data table row's check.
  String get selectRow;

  /// A list's pull, before it is armed.
  String get pullToRefresh;

  /// A list's pull, once armed.
  String get releaseToRefresh;
}

/// Frosted's English words.
class FrostedLocalizationsEn extends FrostedLocalizations {
  /// The English words.
  const FrostedLocalizationsEn();

  @override
  String get done => 'Done';

  @override
  String get tryAgain => 'Try again';

  @override
  String get sections => 'Sections';

  @override
  String get profileAndSettings => 'Profile and settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get swap => 'Swap';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get dictate => 'Dictate';

  @override
  String get attach => 'Attach';

  @override
  String get message => 'Message';

  @override
  String get askAnything => 'Ask anything';

  @override
  String get filters => 'Filters';

  @override
  String get month => 'Month';

  @override
  String get chooseMonth => 'Choose month';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get quickAmounts => 'Quick amounts';

  @override
  String get icon => 'Icon';

  @override
  String get balance => 'Balance';

  @override
  String get credit => 'Credit';

  @override
  String get debit => 'Debit';

  @override
  String get frozen => 'Frozen';

  @override
  String get cardNumber => 'Card number';

  @override
  String get expires => 'Expires';

  @override
  String get cvc => 'CVC';

  @override
  String get name => 'Name';

  @override
  String get newGoal => 'New goal';

  @override
  String get newGoalNote => 'Save toward something new';

  @override
  String get moneyIn => 'Money in';

  @override
  String get spent => 'Spent';

  @override
  String get net => 'Net';

  @override
  String get kept => 'Kept';

  @override
  String get autopay => 'Autopay';

  @override
  String get unread => 'Unread';

  @override
  String get move => 'Move';

  @override
  String get cut => 'Cut';

  @override
  String get copy => 'Copy';

  @override
  String get paste => 'Paste';

  @override
  String get selectAll => 'Select all';

  @override
  String get lookUp => 'Look up';

  @override
  String get searchWeb => 'Search the web';

  @override
  String get share => 'Share';

  @override
  String get scanText => 'Scan text';

  @override
  String get cardPayment => 'Card payment';

  @override
  String lower(String what) => 'Lower $what';

  @override
  String raise(String what) => 'Raise $what';

  @override
  String unreadNotifications(int count) =>
      count > 0 ? 'Notifications, $count unread' : 'Notifications';

  @override
  String continueWith(String provider) => 'Continue with $provider';

  @override
  String get working => 'Working…';

  @override
  String fromTo(String from, String to) => 'From $from to $to';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String page(int page, int count) => 'Page $page of $count';

  @override
  String step(int step, int count) => 'Step $step of $count';

  @override
  String get remove => 'Remove';

  @override
  String rating(num value, int max) => '$value of $max';

  @override
  String get chooseFile => 'Choose a file';

  @override
  String get dropFile => 'or drop it here';

  @override
  String get selectDate => 'Select a date';

  @override
  String get selectTime => 'Select a time';

  @override
  String get select => 'Select';

  @override
  String get hour => 'Hour';

  @override
  String get minute => 'Minute';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  bool get alwaysUse24HourFormat => false;

  static const _months = [
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

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  String monthName(int month) => _months[month - 1];

  @override
  String fullDate(DateTime date) =>
      '${_days[date.weekday - 1]}, ${monthName(date.month)} ${date.day}, ${date.year}';

  @override
  String shortDate(DateTime date) =>
      '${monthName(date.month).substring(0, 3)} ${date.day}, ${date.year}';

  @override
  String seriesSummary({
    required String name,
    required String first,
    required String last,
    required String high,
    required String low,
  }) => '$name: $first to $last, high $high, low $low';

  @override
  String get noData => 'No data';

  @override
  String sliceShare(String name, int percent) => '$name, $percent%';

  @override
  String get oneTimeCode => 'One-time code';

  @override
  String get searchCommands => 'Type a command or search';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get reorder => 'Reorder';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get resize => 'Resize';

  @override
  String get hue => 'Hue';

  @override
  String get opacity => 'Opacity';

  @override
  String get hex => 'Hex';

  @override
  String get selectRow => 'Select row';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get releaseToRefresh => 'Release to refresh';

  @override
  String time(int hour, int minute) {
    final mm = minute.toString().padLeft(2, '0');
    if (alwaysUse24HourFormat) return '${hour.toString().padLeft(2, '0')}:$mm';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$mm ${hour < 12 ? am : pm}';
  }
}

class _FrostedLocalizationsDelegate
    extends LocalizationsDelegate<FrostedLocalizations> {
  const _FrostedLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const FrostedLocalizationsEn());

  @override
  bool shouldReload(_FrostedLocalizationsDelegate old) => false;
}
