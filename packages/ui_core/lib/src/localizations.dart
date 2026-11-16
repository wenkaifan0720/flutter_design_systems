import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color_picker.dart' show DesignColorChannel;
import 'data_table.dart' show DesignSortDirection;
import 'internal/localizations_data.dart';

/// The words a design system says on its own. The behaviours' words: the
/// names a screen reader hears for a part with no text of its own (a
/// carousel, a sheet's barrier, a split view's handle) and the messages they
/// announce (a slide turned, a row moved, the results found), each also a
/// parameter on its behaviour, which a null leaves to this. And the general
/// words a look shows or says by itself (Cancel, Close, Today, Next month,
/// "2 of 5"), under `MaterialLocalizations`' names where Flutter has the
/// word, so a look built on any app (`MaterialApp`, `CupertinoApp`,
/// `WidgetsApp`) has them.
///
/// [of] reads the nearest [Localizations]' instance, and English
/// ([DefaultDesignLocalizations]) when there is none, so nothing needs
/// setting up.
///
/// ui_core speaks 30 languages ([supportedLocales]): an app adds [delegate]
/// to its `localizationsDelegates`, beside `GlobalMaterialLocalizations`'
/// or its own, and its parts speak the app's language, with its dates, its
/// digits and its plurals. The words ui_core shares with
/// `MaterialLocalizations` (Cancel, Today, Next month, …) are Flutter's own
/// translations; the rest are ui_core's, awaiting review by native speakers
/// (the package's README lists them). A locale it does not speak gets
/// English.
///
/// An app that words a message its own way extends
/// [DefaultDesignLocalizations], overriding the words it changes, and adds a
/// delegate for its subclass, as it does for `WidgetsLocalizations`.
/// Extending it, rather than implementing this class, keeps a word added in
/// a later minor version in English until the app words it.
///
/// ```dart
/// Localizations(locale: const Locale('en'), delegates: const [DefaultDesignLocalizations.delegate, DefaultWidgetsLocalizations.delegate], child: Builder(builder: (context) => Text(DesignLocalizations.of(context).carouselLabel)))
/// ```
abstract class DesignLocalizations {
  /// Abstract const constructor, for subclasses.
  const DesignLocalizations();

  /// The words for [context]'s locale: the nearest [Localizations]'
  /// [DesignLocalizations], else English.
  static DesignLocalizations of(BuildContext context) =>
      Localizations.of<DesignLocalizations>(context, DesignLocalizations) ??
      const DefaultDesignLocalizations();

  /// The words for [locale]: its language's (Traditional Chinese for `zh`
  /// written in Hant, or in Taiwan, Hong Kong or Macau), else English.
  static DesignLocalizations forLocale(Locale locale) {
    final data = designLocaleData[_key(locale)];
    if (data == null || locale.languageCode == 'en') {
      return const DefaultDesignLocalizations();
    }
    return _TranslatedDesignLocalizations(data);
  }

  /// The locales ui_core speaks: English, and 29 more.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('de'),
    Locale('el'),
    Locale('es'),
    Locale('fa'),
    Locale('fil'),
    Locale('fr'),
    Locale('he'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// Loads the words for an app's locale ([forLocale]), for its
  /// `localizationsDelegates`.
  ///
  /// It takes every locale: one ui_core does not speak loads English, so a
  /// look's parts are never left without words, and Flutter warns of no
  /// missing delegate (the words fall back as `WidgetsLocalizations`' do).
  static const LocalizationsDelegate<DesignLocalizations> delegate =
      _DesignLocalizationsDelegate();

  static String _key(Locale locale) => switch (locale.languageCode) {
    'zh'
        when locale.scriptCode == 'Hant' ||
            const ['TW', 'HK', 'MO'].contains(locale.countryCode) =>
      'zh_TW',
    // Older codes for Hebrew, Indonesian and Filipino.
    'iw' => 'he',
    'in' => 'id',
    'tl' => 'fil',
    final language => language,
  };

  // The general words: what a look shows or says on its own, under
  // MaterialLocalizations' names where Flutter has the word.

  /// A button that abandons what a dialog, a sheet or a picker was doing
  /// ("Cancel").
  String get cancelButtonLabel;

  /// A button that accepts a dialog's or a picker's choice ("OK").
  String get okButtonLabel;

  /// A button that closes a dialog, a sheet or a banner ("Close").
  String get closeButtonLabel;

  /// A field's button that empties it ("Clear").
  String get clearButtonTooltip;

  /// A button that goes back to the screen before ("Back").
  String get backButtonTooltip;

  /// A button that deletes or removes its item ("Delete").
  String get deleteButtonTooltip;

  /// A button that opens more actions ("More").
  String get moreButtonTooltip;

  /// A button that opens a menu ("Show menu").
  String get showMenuTooltip;

  /// A search field's label or hint ("Search").
  String get searchFieldLabel;

  /// What a screen reader calls the barrier behind a dialog or a popup,
  /// whose tap dismisses it ("Dismiss").
  String get modalBarrierDismissLabel;

  /// Today, as a calendar or a date picker marks it ("Today").
  String get currentDateLabel;

  /// A calendar's button to the month before ("Previous month").
  String get previousMonthTooltip;

  /// A calendar's button to the month after ("Next month").
  String get nextMonthTooltip;

  /// A pager's button to the page before ("Previous page").
  String get previousPageTooltip;

  /// A pager's button to the page after ("Next page").
  String get nextPageTooltip;

  /// The hint on a collapsed part's toggle: what a tap does ("Expand").
  String get collapsedIconTapHint;

  /// The hint on an expanded part's toggle: what a tap does ("Collapse").
  String get expandedIconTapHint;

  /// A button that shows the rest of a list or a text ("Show more").
  String get showMoreLabel;

  /// A button that shows less again ("Show less").
  String get showLessLabel;

  /// A mark that an item is chosen, where a look writes it out
  /// ("Selected").
  String get selectedLabel;

  /// What a screen reader calls a spinner or a placeholder while content
  /// loads ("Loading").
  String get loadingLabel;

  /// What a search or a filter shows when nothing matches ("No results").
  String get noResultsLabel;

  /// A button that tries again what failed, in an error state ("Try
  /// again").
  String get retryButtonLabel;

  /// A button that commits a picker's or a sheet's choice and closes it
  /// ("Done").
  String get doneButtonLabel;

  /// A dialog's yes, when the caller names no action of its own
  /// ("Confirm").
  String get confirmButtonLabel;

  /// How many items are chosen ("3 items selected").
  String selectedRowCountTitle(int count);

  /// Where an item stands among [count]: [position] from 1 ("2 of 5"),
  /// for a step, a page or a slide a look numbers itself.
  String positionLabel(int position, int count);

  /// What a screen reader calls a carousel (`DesignCarousel.semanticLabel`).
  String get carouselLabel;

  /// What a screen reader calls slide [index] (from 0) of [count], and
  /// what it hears when the reader turns to it
  /// (`DesignCarousel.slideLabel`).
  String carouselSlideLabel(int index, int count);

  /// What a screen reader calls a colour picker's area
  /// (`DesignColorArea.semanticLabel`).
  String get colorAreaLabel;

  /// What a screen reader calls a colour slider for [channel]
  /// (`DesignColorSlider.semanticLabel`).
  String colorChannelLabel(DesignColorChannel channel);

  /// What a screen reader calls the command palette
  /// (`DesignCommandPalette.semanticLabel`).
  String get commandPaletteLabel;

  /// The barrier's label behind a shown command palette
  /// (`showDesignCommandPalette`'s `barrierLabel`).
  String get commandPaletteBarrierLabel;

  /// What is announced when the palette's results change to [count]
  /// (`DesignCommandPalette.resultsMessage`).
  String commandPaletteResultsMessage(int count);

  /// A sorted column header's hint (`DesignDataTable.sortedHint`).
  String dataTableSortedHint(DesignSortDirection direction);

  /// A calendar day's full name, read and announced as focus moves to it
  /// (`DesignCalendar.dayLabel`).
  String formatFullDate(DateTime date);

  /// The name of [date]'s month and year (`DesignCalendar.monthLabel`).
  String formatMonthYear(DateTime date);

  /// The calendar's short name for [weekday] ([DateTime.monday] is 1)
  /// (`DesignCalendar.weekdayLabel`).
  String formatShortWeekday(int weekday);

  /// The day a week starts on in this locale ([DateTime.monday] …
  /// [DateTime.sunday]), which a calendar shows first
  /// (`DesignCalendar.firstWeekday`).
  int get firstDayOfWeek;

  /// The hint a required field adds (`DesignField.requiredHint`).
  String get requiredHint;

  /// What is announced when a form's submit finds [count] fields wrong
  /// (`DesignForm.problemsMessage`).
  String formProblemsMessage(int count);

  /// The label of a password field's reveal toggle while the text is
  /// hidden (`DesignPasswordReveal.showLabel`).
  String get showPasswordLabel;

  /// The label of a password field's reveal toggle while the text shows
  /// (`DesignPasswordReveal.hideLabel`).
  String get hidePasswordLabel;

  /// What a screen reader calls a menu bar
  /// (`DesignMenuBar.semanticLabel`).
  String get menuBarLabel;

  /// The refresh action's label (`DesignPullToRefresh.refreshLabel`).
  String get refreshLabel;

  /// What is announced as a refresh starts
  /// (`DesignPullToRefresh.refreshingMessage`).
  String get refreshingMessage;

  /// What is announced when a refresh ends
  /// (`DesignPullToRefresh.doneMessage`).
  String get refreshedMessage;

  /// What a screen reader calls a range slider's start thumb
  /// (`DesignRangeSlider.startLabel`).
  String get rangeSliderStartLabel;

  /// What a screen reader calls a range slider's end thumb
  /// (`DesignRangeSlider.endLabel`).
  String get rangeSliderEndLabel;

  /// What is announced when the item called [label] moves to [position]
  /// (from 1) of [count] (`DesignReorderableList.movedMessage`).
  String reorderableListMovedMessage(String label, int position, int count);

  /// The barrier's label behind a side sheet
  /// (`DesignSideSheetRoute.barrierLabel`).
  String get sideSheetBarrierLabel;

  /// The label of a split button's menu part
  /// (`DesignSplitButton.menuLabel`).
  String get splitButtonMenuLabel;

  /// What a screen reader calls a split view's handle
  /// (`DesignSplitView.semanticLabel`).
  String get splitViewHandleLabel;

  /// The custom action that removes a tag (`DesignTagInput.deleteLabel`).
  String get tagInputDeleteLabel;

  /// What a screen reader calls the toasts' region
  /// (`DesignToaster.regionLabel`).
  String get toasterRegionLabel;

  /// A tree row's hint: [level] (from 1), and [position] (from 1) of the
  /// [count] rows beside it (`DesignTree.levelHint`).
  String treeLevelHint(int level, int position, int count);
}

/// The words in English, with no localizations package.
///
/// ```dart
/// const DefaultDesignLocalizations().carouselSlideLabel(0, 3)
/// ```
class DefaultDesignLocalizations implements DesignLocalizations {
  /// English, the words [DesignLocalizations.of] falls back to.
  const DefaultDesignLocalizations();

  /// Makes the English words: what [delegate] loads for any locale.
  static Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(
        const DefaultDesignLocalizations(),
      );

  /// A delegate that loads English, for an app's
  /// `localizationsDelegates`.
  static const LocalizationsDelegate<DesignLocalizations> delegate =
      _DefaultDesignLocalizationsDelegate();

  static const List<String> _months = <String>[
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

  @override
  String get cancelButtonLabel => 'Cancel';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get closeButtonLabel => 'Close';

  @override
  String get clearButtonTooltip => 'Clear';

  @override
  String get backButtonTooltip => 'Back';

  @override
  String get deleteButtonTooltip => 'Delete';

  @override
  String get moreButtonTooltip => 'More';

  @override
  String get showMenuTooltip => 'Show menu';

  @override
  String get searchFieldLabel => 'Search';

  @override
  String get modalBarrierDismissLabel => 'Dismiss';

  @override
  String get currentDateLabel => 'Today';

  @override
  String get previousMonthTooltip => 'Previous month';

  @override
  String get nextMonthTooltip => 'Next month';

  @override
  String get previousPageTooltip => 'Previous page';

  @override
  String get nextPageTooltip => 'Next page';

  @override
  String get collapsedIconTapHint => 'Expand';

  @override
  String get expandedIconTapHint => 'Collapse';

  @override
  String get showMoreLabel => 'Show more';

  @override
  String get showLessLabel => 'Show less';

  @override
  String get selectedLabel => 'Selected';

  @override
  String get loadingLabel => 'Loading';

  @override
  String get noResultsLabel => 'No results';

  @override
  String get retryButtonLabel => 'Try again';

  @override
  String get doneButtonLabel => 'Done';

  @override
  String get confirmButtonLabel => 'Confirm';

  @override
  String selectedRowCountTitle(int count) => switch (count) {
    0 => 'No items selected',
    1 => '1 item selected',
    _ => '$count items selected',
  };

  @override
  String positionLabel(int position, int count) => '$position of $count';

  @override
  String get carouselLabel => 'Carousel';

  @override
  String carouselSlideLabel(int index, int count) =>
      'Slide ${index + 1} of $count';

  @override
  String get colorAreaLabel => 'Saturation and brightness';

  @override
  String colorChannelLabel(DesignColorChannel channel) => switch (channel) {
    DesignColorChannel.hue => 'Hue',
    DesignColorChannel.saturation => 'Saturation',
    DesignColorChannel.brightness => 'Brightness',
    DesignColorChannel.alpha => 'Alpha',
  };

  @override
  String get commandPaletteLabel => 'Commands';

  @override
  String get commandPaletteBarrierLabel => 'Close commands';

  @override
  String commandPaletteResultsMessage(int count) => switch (count) {
    0 => 'No results',
    1 => '1 result',
    _ => '$count results',
  };

  @override
  String dataTableSortedHint(DesignSortDirection direction) =>
      direction == DesignSortDirection.ascending
      ? 'sorted ascending'
      : 'sorted descending';

  @override
  String formatFullDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} '
      '${_months[date.month - 1]} ${date.year}';

  @override
  String formatMonthYear(DateTime date) =>
      '${_months[date.month - 1]} ${date.year}';

  @override
  String formatShortWeekday(int weekday) =>
      _weekdays[weekday - 1].substring(0, 2);

  @override
  int get firstDayOfWeek => DateTime.sunday;

  @override
  String get requiredHint => 'required';

  @override
  String formProblemsMessage(int count) =>
      count == 1 ? '1 field needs attention' : '$count fields need attention';

  @override
  String get showPasswordLabel => 'Show password';

  @override
  String get hidePasswordLabel => 'Hide password';

  @override
  String get menuBarLabel => 'Menu bar';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get refreshingMessage => 'Refreshing';

  @override
  String get refreshedMessage => 'Refreshed';

  @override
  String get rangeSliderStartLabel => 'Minimum';

  @override
  String get rangeSliderEndLabel => 'Maximum';

  @override
  String reorderableListMovedMessage(String label, int position, int count) =>
      'Moved $label to position $position of $count';

  @override
  String get sideSheetBarrierLabel => 'Close sheet';

  @override
  String get splitButtonMenuLabel => 'More options';

  @override
  String get splitViewHandleLabel => 'Resize';

  @override
  String get tagInputDeleteLabel => 'Remove';

  @override
  String get toasterRegionLabel => 'Notifications';

  @override
  String treeLevelHint(int level, int position, int count) =>
      'level $level, $position of $count';
}

class _DesignLocalizationsDelegate
    extends LocalizationsDelegate<DesignLocalizations> {
  const _DesignLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(
        DesignLocalizations.forLocale(locale),
      );

  @override
  bool shouldReload(_DesignLocalizationsDelegate old) => false;

  @override
  String toString() => 'DesignLocalizations.delegate(30 locales)';
}

// One locale's words from its table (designLocaleData), English for a word
// the table lacks.
class _TranslatedDesignLocalizations extends DefaultDesignLocalizations {
  const _TranslatedDesignLocalizations(this._data);

  final DesignLocaleData _data;

  String _word(String key, String english) => _data.words[key] ?? english;

  // [template] with each {name} replaced: a number in the locale's digits.
  String _fill(String template, Map<String, Object> values) =>
      template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
        final value = values[m[1]];
        return switch (value) {
          final int n => _digits(n),
          null => m[0]!,
          _ => '$value',
        };
      });

  String _message(String key, String english, Map<String, Object> values) {
    final template = _data.words[key];
    return template == null ? english : _fill(template, values);
  }

  // A counted message: the form for exactly [count], else its plural
  // category's, else the other form.
  String _plural(String key, int count, String english) {
    final forms = _data.plurals[key];
    if (forms == null) return english;
    final form =
        forms['=$count'] ??
        forms[_pluralCategory(_data.plural, count)] ??
        forms['other']!;
    return _fill(form, {'count': count});
  }

  String _digits(int n) {
    final zero = _data.zeroDigit;
    if (zero == null) return '$n';
    final base = zero.codeUnitAt(0);
    return String.fromCharCodes(
      '$n'.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? base + c - 0x30 : c),
    );
  }

  String _padded(int n) => n < 10 ? _digits(0) + _digits(n) : _digits(n);

  // [date] in a CLDR [pattern]: the fields the locales' full-date and
  // month-and-year patterns use (y, M, L, d, E, c, G), quoted text as is.
  String _formatDate(String pattern, DateTime date) {
    final out = StringBuffer();
    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];
      if (c == "'") {
        if (i + 1 < pattern.length && pattern[i + 1] == "'") {
          out.write("'");
          i += 2;
          continue;
        }
        final end = pattern.indexOf("'", i + 1);
        out.write(pattern.substring(i + 1, end < 0 ? pattern.length : end));
        i = end < 0 ? pattern.length : end + 1;
        continue;
      }
      var j = i;
      while (j < pattern.length && pattern[j] == c) {
        j++;
      }
      final n = j - i;
      final month = date.month - 1;
      final day = date.weekday % 7;
      out.write(switch (c) {
        'y' => n == 2 ? _padded(date.year % 100) : _digits(date.year),
        'M' when n >= 4 => _data.months[month],
        'M' when n == 3 => _data.shortMonths[month],
        'L' when n >= 4 => _data.standaloneMonths[month],
        'L' when n == 3 => _data.standaloneShortMonths[month],
        'M' || 'L' => n == 2 ? _padded(date.month) : _digits(date.month),
        'd' => n == 2 ? _padded(date.day) : _digits(date.day),
        'E' => n >= 4 ? _data.weekdays[day] : _data.shortWeekdays[day],
        'c' =>
          n >= 4
              ? _data.standaloneWeekdays[day]
              : _data.standaloneShortWeekdays[day],
        'G' => _data.eras[date.year > 0 ? 1 : 0],
        _ => pattern.substring(i, j),
      });
      i = j;
    }
    return out.toString();
  }

  @override
  String get cancelButtonLabel =>
      _word('cancelButtonLabel', super.cancelButtonLabel);

  @override
  String get okButtonLabel => _word('okButtonLabel', super.okButtonLabel);

  @override
  String get closeButtonLabel =>
      _word('closeButtonLabel', super.closeButtonLabel);

  @override
  String get clearButtonTooltip =>
      _word('clearButtonTooltip', super.clearButtonTooltip);

  @override
  String get backButtonTooltip =>
      _word('backButtonTooltip', super.backButtonTooltip);

  @override
  String get deleteButtonTooltip =>
      _word('deleteButtonTooltip', super.deleteButtonTooltip);

  @override
  String get moreButtonTooltip =>
      _word('moreButtonTooltip', super.moreButtonTooltip);

  @override
  String get showMenuTooltip => _word('showMenuTooltip', super.showMenuTooltip);

  @override
  String get searchFieldLabel =>
      _word('searchFieldLabel', super.searchFieldLabel);

  @override
  String get modalBarrierDismissLabel =>
      _word('modalBarrierDismissLabel', super.modalBarrierDismissLabel);

  @override
  String get currentDateLabel =>
      _word('currentDateLabel', super.currentDateLabel);

  @override
  String get previousMonthTooltip =>
      _word('previousMonthTooltip', super.previousMonthTooltip);

  @override
  String get nextMonthTooltip =>
      _word('nextMonthTooltip', super.nextMonthTooltip);

  @override
  String get previousPageTooltip =>
      _word('previousPageTooltip', super.previousPageTooltip);

  @override
  String get nextPageTooltip => _word('nextPageTooltip', super.nextPageTooltip);

  @override
  String get collapsedIconTapHint =>
      _word('collapsedIconTapHint', super.collapsedIconTapHint);

  @override
  String get expandedIconTapHint =>
      _word('expandedIconTapHint', super.expandedIconTapHint);

  @override
  String get showMoreLabel => _word('showMoreLabel', super.showMoreLabel);

  @override
  String get showLessLabel => _word('showLessLabel', super.showLessLabel);

  @override
  String get selectedLabel => _word('selectedLabel', super.selectedLabel);

  @override
  String get loadingLabel => _word('loadingLabel', super.loadingLabel);

  @override
  String get noResultsLabel => _word('noResultsLabel', super.noResultsLabel);

  @override
  String get retryButtonLabel =>
      _word('retryButtonLabel', super.retryButtonLabel);

  @override
  String get doneButtonLabel => _word('doneButtonLabel', super.doneButtonLabel);

  @override
  String get confirmButtonLabel =>
      _word('confirmButtonLabel', super.confirmButtonLabel);

  @override
  String selectedRowCountTitle(int count) => _plural(
    'selectedRowCountTitle',
    count,
    super.selectedRowCountTitle(count),
  );

  @override
  String positionLabel(int position, int count) => _message(
    'positionLabel',
    super.positionLabel(position, count),
    {'position': position, 'count': count},
  );

  @override
  String get carouselLabel => _word('carouselLabel', super.carouselLabel);

  @override
  String carouselSlideLabel(int index, int count) => _message(
    'carouselSlideLabel',
    super.carouselSlideLabel(index, count),
    {'slide': index + 1, 'count': count},
  );

  @override
  String get colorAreaLabel => _word('colorAreaLabel', super.colorAreaLabel);

  @override
  String colorChannelLabel(DesignColorChannel channel) =>
      _word(switch (channel) {
        DesignColorChannel.hue => 'colorChannelHue',
        DesignColorChannel.saturation => 'colorChannelSaturation',
        DesignColorChannel.brightness => 'colorChannelBrightness',
        DesignColorChannel.alpha => 'colorChannelAlpha',
      }, super.colorChannelLabel(channel));

  @override
  String get commandPaletteLabel =>
      _word('commandPaletteLabel', super.commandPaletteLabel);

  @override
  String get commandPaletteBarrierLabel =>
      _word('commandPaletteBarrierLabel', super.commandPaletteBarrierLabel);

  @override
  String commandPaletteResultsMessage(int count) => _plural(
    'commandPaletteResultsMessage',
    count,
    super.commandPaletteResultsMessage(count),
  );

  @override
  String dataTableSortedHint(DesignSortDirection direction) => _word(
    direction == DesignSortDirection.ascending
        ? 'sortedAscendingHint'
        : 'sortedDescendingHint',
    super.dataTableSortedHint(direction),
  );

  @override
  String formatFullDate(DateTime date) => _formatDate(_data.fullDate, date);

  @override
  String formatMonthYear(DateTime date) => _formatDate(_data.monthYear, date);

  @override
  String formatShortWeekday(int weekday) => _data.calendarWeekdays[weekday % 7];

  @override
  int get firstDayOfWeek => _data.firstDayOfWeek;

  @override
  String get requiredHint => _word('requiredHint', super.requiredHint);

  @override
  String formProblemsMessage(int count) =>
      _plural('formProblemsMessage', count, super.formProblemsMessage(count));

  @override
  String get showPasswordLabel =>
      _word('showPasswordLabel', super.showPasswordLabel);

  @override
  String get hidePasswordLabel =>
      _word('hidePasswordLabel', super.hidePasswordLabel);

  @override
  String get menuBarLabel => _word('menuBarLabel', super.menuBarLabel);

  @override
  String get refreshLabel => _word('refreshLabel', super.refreshLabel);

  @override
  String get refreshingMessage =>
      _word('refreshingMessage', super.refreshingMessage);

  @override
  String get refreshedMessage =>
      _word('refreshedMessage', super.refreshedMessage);

  @override
  String get rangeSliderStartLabel =>
      _word('rangeSliderStartLabel', super.rangeSliderStartLabel);

  @override
  String get rangeSliderEndLabel =>
      _word('rangeSliderEndLabel', super.rangeSliderEndLabel);

  @override
  String reorderableListMovedMessage(String label, int position, int count) =>
      _message(
        'reorderableListMovedMessage',
        super.reorderableListMovedMessage(label, position, count),
        {'label': label, 'position': position, 'count': count},
      );

  @override
  String get sideSheetBarrierLabel =>
      _word('sideSheetBarrierLabel', super.sideSheetBarrierLabel);

  @override
  String get splitButtonMenuLabel =>
      _word('splitButtonMenuLabel', super.splitButtonMenuLabel);

  @override
  String get splitViewHandleLabel =>
      _word('splitViewHandleLabel', super.splitViewHandleLabel);

  @override
  String get tagInputDeleteLabel =>
      _word('tagInputDeleteLabel', super.tagInputDeleteLabel);

  @override
  String get toasterRegionLabel =>
      _word('toasterRegionLabel', super.toasterRegionLabel);

  @override
  String treeLevelHint(int level, int position, int count) => _message(
    'treeLevelHint',
    super.treeLevelHint(level, position, count),
    {'level': level, 'position': position, 'count': count},
  );
}

// The plural category of the whole number [n] under [rule] (CLDR's rules,
// for counts).
String _pluralCategory(String rule, int n) {
  final i = n.abs();
  final i10 = i % 10;
  final i100 = i % 100;
  final fewSlavic = i10 >= 2 && i10 <= 4 && (i100 < 12 || i100 > 14);
  return switch (rule) {
    'one' => i == 1 ? 'one' : 'other',
    'zeroOne' => i <= 1 ? 'one' : 'other',
    'eastSlavic' =>
      i10 == 1 && i100 != 11
          ? 'one'
          : fewSlavic
          ? 'few'
          : 'many',
    'polish' =>
      i == 1
          ? 'one'
          : fewSlavic
          ? 'few'
          : 'many',
    'czech' =>
      i == 1
          ? 'one'
          : i >= 2 && i <= 4
          ? 'few'
          : 'other',
    'arabic' =>
      i == 0
          ? 'zero'
          : i == 1
          ? 'one'
          : i == 2
          ? 'two'
          : i100 >= 3 && i100 <= 10
          ? 'few'
          : i100 >= 11
          ? 'many'
          : 'other',
    'hebrew' =>
      i == 1
          ? 'one'
          : i == 2
          ? 'two'
          : 'other',
    'romanian' =>
      i == 1
          ? 'one'
          : i == 0 || (i100 >= 1 && i100 <= 19)
          ? 'few'
          : 'other',
    'filipino' => i10 != 4 && i10 != 6 && i10 != 9 ? 'one' : 'other',
    _ => 'other',
  };
}

class _DefaultDesignLocalizationsDelegate
    extends LocalizationsDelegate<DesignLocalizations> {
  const _DefaultDesignLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      DefaultDesignLocalizations.load(locale);

  @override
  bool shouldReload(_DefaultDesignLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultDesignLocalizations.delegate(en)';
}
