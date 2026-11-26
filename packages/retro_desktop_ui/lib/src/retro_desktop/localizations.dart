// The words only Retro Desktop's parts say, and its date and number formats. The words every look says (Cancel, Close,
// Today, Next month, Loading) are ui_core's RawWidgetsLocalizations, under MaterialLocalizations' names: the parts read them
// there, so an app translates them once for every look by extending DefaultRawWidgetsLocalizations.
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'format.dart';

/// The words only Retro Desktop's parts say when the caller gives none (a pager's name, a time picker's wheels, a
/// stepper's buttons), and the locale its dates and numbers are formatted in. English ships
/// ([RetroDesktopLocalizationsEn]); another language is a subclass and a delegate that loads it. [delegate] takes every
/// locale: in another language than English it loads the English words with the app's locale's dates and numbers, and
/// with no delegate installed the parts speak English. Either way, a text menu says the app's own editing words, and a
/// time picker's words ([hour], [minute], [period], [am], [pm]) are the app's `RawWidgetsLocalizations`' (ui_core's in the
/// app's language, where it installs none). The words every look shares come from `RawWidgetsLocalizations` instead.
///
/// ```dart
/// MaterialApp(localizationsDelegates: const [RetroDesktopLocalizations.delegate], home: home)
/// ```
abstract class RetroDesktopLocalizations {
  /// Const constructor, for subclasses.
  const RetroDesktopLocalizations();

  /// The words in force at [context]: the installed delegate's, else English.
  static RetroDesktopLocalizations of(BuildContext context) {
    final installed = Localizations.of<RetroDesktopLocalizations>(
      context,
      RetroDesktopLocalizations,
    );
    if (installed != null && installed is! _StockWords) return installed;
    return _WidgetWords(
      Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations),
      Localizations.of<MaterialLocalizations>(context, MaterialLocalizations),
      Localizations.of<RawWidgetsLocalizations>(
            context,
            RawWidgetsLocalizations,
          ) ??
          (installed == null
              ? null
              : RawWidgetsLocalizations.forLocale(
                  Localizations.localeOf(context),
                )),
      localeName: installed?.localeName ?? 'en_US',
    );
  }

  /// Loads Retro Desktop's words for any locale: English, with the locale's dates and numbers.
  static const LocalizationsDelegate<RetroDesktopLocalizations> delegate =
      _RetroDesktopLocalizationsDelegate();

  /// Intl locale used by the built-in number and date formatters.
  String get localeName => 'en_US';

  /// Formats a count or reading with the locale's decimal separators.
  String formatNumber(num value) =>
      RetroDesktopFormat.number(value, locale: localeName);

  /// Formats calendar and clock digits without grouping.
  String formatInteger(int value, {int digits = 1}) =>
      RetroDesktopFormat.integer(value, digits: digits, locale: localeName);

  /// A month heading in the locale's date order.
  String formatMonthYear(DateTime value) =>
      RetroDesktopFormat.monthYear(value, locale: localeName);

  /// A complete date for a calendar cell's accessible name.
  String formatDate(DateTime value) =>
      RetroDesktopFormat.date(value, locale: localeName);

  /// A ratio spoken as a localized percent.
  String formatPercent(double value) =>
      RetroDesktopFormat.percent(value, locale: localeName);

  /// Describes a priority level without relying on its bar drawing.
  String priorityLabel(int level) => 'Priority ${formatInteger(level)}';

  /// Describes a completed count and the total number of items.
  String completedCount(int done, int total) =>
      '${formatInteger(done)} of ${formatInteger(total)}';

  /// A chart with nothing to plot.
  String get noData => 'Nothing to show yet';

  /// The trail of places above the current page, as a screen reader names it.
  String get breadcrumbs => 'Breadcrumbs';

  /// A pager's name, and its buttons.
  String get pages => 'Pages';

  /// One page of [total], for a page button's accessible name.
  String pageOf(int page, int total) =>
      'Page ${formatInteger(page)} of ${formatInteger(total)}';

  /// Goes to the slide before.
  String get previousSlide => 'Previous slide';

  /// Goes to the slide after.
  String get nextSlide => 'Next slide';

  /// Starts a carousel playing.
  String get play => 'Play';

  /// Stops a playing carousel.
  String get pause => 'Pause';

  /// One slide of [total].
  String slideOf(int slide, int total) =>
      'Slide ${formatInteger(slide)} of ${formatInteger(total)}';

  /// A rating read aloud: [value] of [most].
  String ratingOf(num value, int most) =>
      '${formatNumber(value)} of ${formatInteger(most)}';

  /// What a file drop invites.
  String get dropFiles => 'Drop files here';

  /// The button that opens the system's file chooser.
  String get chooseFiles => 'Choose files';

  /// Removes a chosen file from a file drop.
  String get removeFile => 'Remove';

  /// A data table's check that chooses one row.
  String get selectRow => 'Select row';

  /// A data table's check that chooses every row on the page.
  String get selectAllRows => 'Select all rows on this page';

  /// A reorderable row's grip.
  String get reorder => 'Reorder';

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

  /// A date picker's title and its month steps; in another language, `RawWidgetsLocalizations`' `datePickerHelpText`.
  String get chooseDate;

  /// A time picker's title and its three wheels; in another language, `RawWidgetsLocalizations`'
  /// `timePickerDialHelpText`.
  String get chooseTime;

  /// A time picker's hours. With no Retro Desktop words for the app's language, `RawWidgetsLocalizations`'
  /// `timePickerHourLabel`.
  String get hour;

  /// A time picker's minutes; else `RawWidgetsLocalizations`' `timePickerMinuteLabel`.
  String get minute;

  /// A time picker's AM and PM; else `RawWidgetsLocalizations`' `timeFieldDayPeriodLabel`.
  String get period;

  /// The time picker's two halves of the day.
  String get am;

  /// The afternoon half: 'PM'.
  String get pm;

  /// The side navigation's and the tabs' names.
  String get mainNavigation;

  /// The tabs' name.
  String get tabs;

  /// The arrows of a row of tabs too wide for its room: show the tabs before, and after, those in view.
  String get earlierTabs;

  /// See [earlierTabs].
  String get laterTabs;

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

  /// The text menu's Look up.
  String get lookUp;

  /// The text menu's Search the web.
  String get searchWeb;

  /// The text menu's Share.
  String get share;

  /// The text menu's Scan text.
  String get scanText;

  /// The twelve months, January first, and the week's days as two letters, Monday first.
  List<String> get months;

  /// The week's abbreviated names, Monday first.
  List<String> get weekdays => weekdaysShort;

  /// The week's days as two letters, Monday first.
  List<String> get weekdaysShort;
}

/// Retro Desktop's English words.
class RetroDesktopLocalizationsEn extends RetroDesktopLocalizations {
  /// English, as the delegate loads it.
  const RetroDesktopLocalizationsEn({this.localeName = 'en_US'});
  @override
  final String localeName;
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
  String get hour => 'Hour';
  @override
  String get minute => 'Minute';
  @override
  String get period => 'AM or PM';
  @override
  String get am => 'AM';
  @override
  String get pm => 'PM';
  @override
  String get mainNavigation => 'Main';
  @override
  String get tabs => 'Tabs';
  @override
  String get earlierTabs => 'Earlier tabs';
  @override
  String get laterTabs => 'Later tabs';
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
  String get lookUp => 'Look up';
  @override
  String get searchWeb => 'Search the web';
  @override
  String get share => 'Share';
  @override
  String get scanText => 'Scan text';
  @override
  List<String> get months => List.unmodifiable([
    for (var month = 1; month <= 12; month++)
      DateFormat.MMMM(localeName).format(DateTime(2024, month)),
  ]);
  @override
  List<String> get weekdays => List.unmodifiable([
    for (var day = 1; day <= 7; day++)
      DateFormat.E(localeName).format(DateTime(2024, 1, day)),
  ]);
  @override
  List<String> get weekdaysShort => List.unmodifiable([
    for (var day = 1; day <= 7; day++)
      DateFormat.E(localeName)
          .format(DateTime(2024, 1, day))
          .characters
          .take(2)
          .toString(),
  ]);
}

class _RetroDesktopLocalizationsDelegate
    extends LocalizationsDelegate<RetroDesktopLocalizations> {
  const _RetroDesktopLocalizationsDelegate();

  // Every locale: one that says only English would be skipped in a German or Arabic app, with Flutter's warning
  // that no delegate supports it.
  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RetroDesktopLocalizations> load(Locale locale) async {
    await initializeDateFormatting();
    final name =
        Intl.verifiedLocale(
          Intl.canonicalizedLocale(locale.toLanguageTag()),
          DateFormat.localeExists,
          onFailure: (_) => null,
        ) ??
        'en_US';
    return locale.languageCode == 'en'
        ? RetroDesktopLocalizationsEn(localeName: name)
        : _StockWords(localeName: name);
  }

  @override
  bool shouldReload(_RetroDesktopLocalizationsDelegate old) => false;
}

// The English words the delegate loads in another language; [RetroDesktopLocalizations.of] reads the app's own
// editing and time words over them (_WidgetWords), with their locale's dates and numbers.
class _StockWords extends RetroDesktopLocalizationsEn {
  const _StockWords({required super.localeName});
}

// The words when no look delegate was supplied, or its stock English: the text menu says the app's own editing words
// (flutter_localizations gives them in its language); where it gives none, WidgetsApp's English defaults stand in, and
// the Material words say them instead, which the look loads in the app's language (RetroDesktopTheme); else English.
// A time picker's words and a picker's title are the app's RawWidgetsLocalizations' (ui_core speaks 30 languages; the titles
// through its RawPickerWords); where they are its English ones, the look's English.
class _WidgetWords extends RetroDesktopLocalizationsEn {
  _WidgetWords(
    WidgetsLocalizations? widgets,
    this.material,
    this.design, {
    super.localeName,
  }) : widgets = widgets.runtimeType == DefaultWidgetsLocalizations
           ? null
           : widgets;
  final WidgetsLocalizations? widgets;
  final MaterialLocalizations? material;
  final RawWidgetsLocalizations? design;

  static const RawWidgetsLocalizations _english =
      DefaultRawWidgetsLocalizations();

  String _shared(String Function(RawWidgetsLocalizations) word, String own) {
    final said = design == null ? null : word(design!);
    return said == null || said == word(_english) ? own : said;
  }

  @override
  String get hour => _shared((l) => l.timePickerHourLabel, super.hour);
  @override
  String get minute => _shared((l) => l.timePickerMinuteLabel, super.minute);
  @override
  String get period => _shared((l) => l.timeFieldDayPeriodLabel, super.period);
  @override
  String get am => _shared((l) => l.anteMeridiemAbbreviation, super.am);
  @override
  String get pm => _shared((l) => l.postMeridiemAbbreviation, super.pm);
  @override
  String get chooseDate =>
      _shared((l) => l.datePickerHelpText, super.chooseDate);
  @override
  String get chooseTime =>
      _shared((l) => l.timePickerDialHelpText, super.chooseTime);
  @override
  String get cut =>
      widgets?.cutButtonLabel ?? material?.cutButtonLabel ?? super.cut;
  @override
  String get copy =>
      widgets?.copyButtonLabel ?? material?.copyButtonLabel ?? super.copy;
  @override
  String get paste =>
      widgets?.pasteButtonLabel ?? material?.pasteButtonLabel ?? super.paste;
  @override
  String get selectAll =>
      widgets?.selectAllButtonLabel ??
      material?.selectAllButtonLabel ??
      super.selectAll;
  @override
  String get lookUp =>
      widgets?.lookUpButtonLabel ?? material?.lookUpButtonLabel ?? super.lookUp;
  @override
  String get searchWeb =>
      widgets?.searchWebButtonLabel ??
      material?.searchWebButtonLabel ??
      super.searchWeb;
  @override
  String get share =>
      widgets?.shareButtonLabel ?? material?.shareButtonLabel ?? super.share;
  @override
  String get scanText => material?.scanTextButtonLabel ?? super.scanText;
}
