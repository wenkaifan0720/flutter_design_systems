// The words only Comic's parts say on their own: a dismiss, a stepper's more and less, the text-editing menu, a
// file drop's prompts. The words every look shares (close, cancel, back, loading, the month steps, a time's hour,
// minute and half of the day) are ui_core's RawWidgetsLocalizations. A part takes the caller's words when given, and these
// otherwise. Comic's delegate supports every locale: English, with the words ui_core shares in the locale's language.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;

/// The words only Comic's parts say when the caller gives none; the shared ones are `RawWidgetsLocalizations`. English
/// ships ([ComicLocalizationsEn]); in any other language the parts say English but for the words ui_core says too (a
/// retry, a dismiss, a rating, the months and weekdays), which come in that language. A language of your own is a
/// subclass and a delegate that loads it.
///
/// ```dart
/// MaterialApp(localizationsDelegates: const [ComicLocalizations.delegate], home: home)
/// ```
abstract class ComicLocalizations {
  /// Const constructor, for subclasses.
  const ComicLocalizations();

  /// The words in force at [context]: the installed delegate's; else English, in another language with the words
  /// ui_core shares taken from the `RawWidgetsLocalizations` in force.
  static ComicLocalizations of(BuildContext context) {
    final installed = Localizations.of<ComicLocalizations>(
      context,
      ComicLocalizations,
    );
    if (installed != null) return installed;
    final language = Localizations.maybeLocaleOf(context)?.languageCode;
    return language == null || language == 'en'
        ? const ComicLocalizationsEn()
        : _ComicLocalizationsShared(RawWidgetsLocalizations.of(context));
  }

  /// Comic's words for [locale]: English, and in another language English but for the words ui_core shares, said in
  /// it (`RawWidgetsLocalizations.forLocale`).
  static ComicLocalizations forLocale(Locale locale) =>
      locale.languageCode == 'en'
      ? const ComicLocalizationsEn()
      : _ComicLocalizationsShared(RawWidgetsLocalizations.forLocale(locale));

  /// Loads Comic's words for any locale ([forLocale]), so an app in any language installs it without Flutter's
  /// warning that a delegate does not support its locale.
  static const LocalizationsDelegate<ComicLocalizations> delegate =
      _ComicLocalizationsDelegate();

  /// What dismisses a notice or a toast.
  String get dismiss;

  /// The error state's way to try again.
  String get tryAgain;

  /// A message's send button.
  String get send;

  /// A stepper's two buttons.
  String get less;

  /// A stepper's more button.
  String get more;

  /// A select's prompt and a picker's confirming button.
  String get choose;

  /// A date picker's title and its month steps.
  String get chooseDate;

  /// A time picker's title and its three wheels.
  String get chooseTime;

  /// A time picker's hours.
  @Deprecated(
    'Use RawWidgetsLocalizations.timePickerHourLabel: ui_core says it in its 30 languages, and ComicTimePicker reads it there. This feature was deprecated after v0.3.3.',
  )
  String get hour => 'Hour';

  /// A time picker's minutes.
  @Deprecated(
    'Use RawWidgetsLocalizations.timePickerMinuteLabel: ui_core says it in its 30 languages, and ComicTimePicker reads it there. This feature was deprecated after v0.3.3.',
  )
  String get minute => 'Minute';

  /// A time picker's AM and PM.
  @Deprecated(
    'Use RawWidgetsLocalizations.timeFieldDayPeriodLabel: ui_core says it in its 30 languages, and ComicTimePicker reads it there. This feature was deprecated after v0.3.3.',
  )
  String get period => 'AM/PM';

  /// The time picker's two halves of the day.
  @Deprecated(
    'Use RawWidgetsLocalizations.anteMeridiemAbbreviation: ui_core says it in its 30 languages, and ComicTimePicker reads it there. This feature was deprecated after v0.3.3.',
  )
  String get am => 'AM';

  /// The afternoon half: 'PM'.
  @Deprecated(
    'Use RawWidgetsLocalizations.postMeridiemAbbreviation: ui_core says it in its 30 languages, and ComicTimePicker reads it there. This feature was deprecated after v0.3.3.',
  )
  String get pm => 'PM';

  /// The side navigation's and the tabs' names.
  String get mainNavigation;

  /// The tabs' name.
  String get tabs;

  /// A chart's average line.
  String get average;

  /// The text menu's words: cut, copy, paste, select all, delete, look up, search the web, share, scan text.
  String get cut;

  /// The text menu's Copy.
  String get copy;

  /// The text menu's Paste.
  String get paste;

  /// The text menu's Select all.
  String get selectAll;

  /// The text menu's Delete.
  String get delete;

  /// The text menu's Look up.
  String get lookUp;

  /// The text menu's Search the web.
  String get searchWeb;

  /// The text menu's Share.
  String get share;

  /// The text menu's Scan text.
  String get scanText;

  /// A rating expressed as a count out of a total.
  String rating(int count, int total);

  /// What sets a rating of [count] out of [total].
  String rate(int count, int total);

  /// A page's name in a pager: page [page] of [total].
  String page(int page, int total);

  /// A trail of breadcrumbs, as a screen reader names it.
  String get breadcrumbs;

  /// A carousel's step back.
  String get previous;

  /// A carousel's step on.
  String get next;

  /// A file drop's invitation.
  String get dropFiles;

  /// A file drop's button.
  String get chooseFiles;

  /// What takes [name] off a file list.
  String removeFile(String name);

  /// A chart with no values yet.
  String get noData;

  /// The twelve months, January first, and the week's days as two letters, Monday first.
  List<String> get months;

  /// The week's days as two letters, Monday first.
  List<String> get weekdaysShort;

  /// A timeline entry that is done.
  String get stepDone;

  /// The timeline entry happening now.
  String get stepNow;

  /// A timeline entry still to come.
  String get stepUpcoming;

  /// A range slider's lower knob, for the slider called [label].
  String rangeFrom(String label);

  /// A range slider's upper knob, for the slider called [label].
  String rangeTo(String label);

  /// A command palette's prompt.
  String get searchCommands;

  /// A table row's box.
  String get selectRow;

  /// A table heading's box.
  String get selectPage;

  /// The rule between two panes.
  String get resize;

  /// What a screen reader calls the stack of notices.
  String get notifications;
}

/// Comic's English words.
class ComicLocalizationsEn extends ComicLocalizations {
  /// English, as the delegate loads it.
  const ComicLocalizationsEn();
  @override
  String get dismiss => 'Dismiss';
  @override
  String get tryAgain => 'Try again';
  @override
  String get send => 'Send';
  @override
  String get less => 'Less';
  @override
  String get more => 'More';
  @override
  String get choose => 'Choose';
  @override
  String get chooseDate => 'Choose a date';
  @override
  String get chooseTime => 'Choose a time';
  @override
  String get mainNavigation => 'Main';
  @override
  String get tabs => 'Tabs';
  @override
  String get average => 'Average';
  @override
  String get cut => 'Cut';
  @override
  String get copy => 'Copy';
  @override
  String get paste => 'Paste';
  @override
  String get selectAll => 'Select all';
  @override
  String get delete => 'Delete';
  @override
  String get lookUp => 'Look up';
  @override
  String get searchWeb => 'Search the web';
  @override
  String get share => 'Share';
  @override
  String get scanText => 'Scan text';
  @override
  String rating(int count, int total) => '$count of $total';
  @override
  String rate(int count, int total) => 'Rate $count of $total';
  @override
  String page(int page, int total) => 'Page $page of $total';
  @override
  String get breadcrumbs => 'You are here';
  @override
  String get previous => 'Previous';
  @override
  String get next => 'Next';
  @override
  String get dropFiles => 'Drop files here';
  @override
  String get chooseFiles => 'Choose files';
  @override
  String removeFile(String name) => 'Remove $name';
  @override
  String get noData => 'Nothing to show yet';
  @override
  List<String> get months => const [
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
  @override
  List<String> get weekdaysShort => const [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];
  @override
  String get stepDone => 'Done';
  @override
  String get stepNow => 'Now';
  @override
  String get stepUpcoming => 'To come';
  @override
  String rangeFrom(String label) => '$label, from';
  @override
  String rangeTo(String label) => '$label, to';
  @override
  String get searchCommands => 'Type a command';
  @override
  String get selectRow => 'Select row';
  @override
  String get selectPage => 'Select this page';
  @override
  String get resize => 'Resize';
  @override
  String get notifications => 'Notifications';
}

/// Comic's English words, but for those ui_core says too, which [_shared] says in its language.
class _ComicLocalizationsShared extends ComicLocalizationsEn {
  const _ComicLocalizationsShared(this._shared);

  final RawWidgetsLocalizations _shared;

  @override
  String get dismiss => _shared.modalBarrierDismissLabel;
  @override
  String get tryAgain => _shared.retryButtonLabel;
  @override
  String get delete => _shared.deleteButtonTooltip;
  @override
  String get notifications => _shared.toasterRegionLabel;
  @override
  String get resize => _shared.splitViewHandleLabel;
  @override
  String rating(int count, int total) =>
      _shared.ratingValueLabel(count.toDouble(), total);
  @override
  String page(int page, int total) => _shared.positionLabel(page, total);
  @override
  List<String> get months => [
    for (var month = 1; month <= 12; month++)
      _shared.formatMonth(DateTime(2000, month)),
  ];
  @override
  List<String> get weekdaysShort => [
    for (var day = DateTime.monday; day <= DateTime.sunday; day++)
      _shared.formatShortWeekday(day),
  ];
  @override
  String get hour => _shared.timePickerHourLabel;
  @override
  String get minute => _shared.timePickerMinuteLabel;
  @override
  String get period => _shared.timeFieldDayPeriodLabel;
  @override
  String get am => _shared.anteMeridiemAbbreviation;
  @override
  String get pm => _shared.postMeridiemAbbreviation;
}

class _ComicLocalizationsDelegate
    extends LocalizationsDelegate<ComicLocalizations> {
  const _ComicLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ComicLocalizations> load(Locale locale) async {
    await initializeDateFormatting(locale.toString());
    return ComicLocalizations.forLocale(locale);
  }

  @override
  bool shouldReload(_ComicLocalizationsDelegate old) => false;
}
