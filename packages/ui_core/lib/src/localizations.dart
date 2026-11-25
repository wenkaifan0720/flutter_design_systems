import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color_picker.dart' show RawColorChannel;
import 'data_table.dart' show RawSortDirection;
import 'date_field.dart' show RawDateSegmentType, RawTimeOfDay;
import 'internal/decimal.dart' as decimal;
import 'internal/localizations_data.dart';
import 'internal/segments.dart';

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
/// ([DefaultRawWidgetsLocalizations]) when there is none, so nothing needs
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
/// [DefaultRawWidgetsLocalizations], overriding the words it changes, and adds a
/// delegate for its subclass, as it does for `WidgetsLocalizations`.
/// Extending it, rather than implementing this class, keeps a word added in
/// a later minor version in English until the app words it.
///
/// ```dart
/// Localizations(locale: const Locale('en'), delegates: const [DefaultRawWidgetsLocalizations.delegate, DefaultWidgetsLocalizations.delegate], child: Builder(builder: (context) => Text(RawWidgetsLocalizations.of(context).carouselLabel)))
/// ```
abstract class RawWidgetsLocalizations {
  /// Abstract const constructor, for subclasses.
  const RawWidgetsLocalizations();

  /// The words for [context]'s locale: the nearest [Localizations]'
  /// [RawWidgetsLocalizations], else English.
  static RawWidgetsLocalizations of(BuildContext context) =>
      Localizations.of<RawWidgetsLocalizations>(
        context,
        RawWidgetsLocalizations,
      ) ??
      const DefaultRawWidgetsLocalizations();

  /// The words for [locale]: its language's (Traditional Chinese for `zh`
  /// written in Hant, or in Taiwan, Hong Kong or Macau), else English.
  static RawWidgetsLocalizations forLocale(Locale locale) {
    final data = rawLocaleData[_key(locale)];
    if (data == null || locale.languageCode == 'en') {
      return const DefaultRawWidgetsLocalizations();
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
  static const LocalizationsDelegate<RawWidgetsLocalizations> delegate =
      _RawLocalizationsDelegate();

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

  /// What a screen reader calls a carousel (`RawCarousel.semanticLabel`).
  String get carouselLabel;

  /// What a screen reader calls slide [index] (from 0) of [count], and
  /// what it hears when the reader turns to it
  /// (`RawCarousel.slideLabel`).
  String carouselSlideLabel(int index, int count);

  /// What a screen reader calls a colour picker's area
  /// (`RawColorArea.semanticLabel`).
  String get colorAreaLabel;

  /// What a screen reader calls a colour slider for [channel]
  /// (`RawColorSlider.semanticLabel`).
  String colorChannelLabel(RawColorChannel channel);

  /// What a screen reader calls the command palette
  /// (`RawCommandPalette.semanticLabel`).
  String get commandPaletteLabel;

  /// The barrier's label behind a shown command palette
  /// (`showRawCommandPalette`'s `barrierLabel`).
  String get commandPaletteBarrierLabel;

  /// What is announced when the palette's results change to [count]
  /// (`RawCommandPalette.resultsMessage`).
  String commandPaletteResultsMessage(int count);

  /// A sorted column header's hint (`RawDataTable.sortedHint`).
  String dataTableSortedHint(RawSortDirection direction);

  /// A calendar day's full name, read and announced as focus moves to it
  /// (`RawCalendarDatePicker.dayLabel`).
  String formatFullDate(DateTime date);

  /// The name of [date]'s month and year (`RawCalendarDatePicker.monthLabel`).
  String formatMonthYear(DateTime date);

  /// The calendar's short name for [weekday] ([DateTime.monday] is 1)
  /// (`RawCalendarDatePicker.weekdayLabel`).
  String formatShortWeekday(int weekday);

  /// The day a week starts on in this locale ([DateTime.monday] …
  /// [DateTime.sunday]), which a calendar shows first
  /// (`RawCalendarDatePicker.firstWeekday`).
  int get firstDayOfWeek;

  /// The hint a required field adds (`RawInputDecorator.requiredHint`).
  String get requiredHint;

  /// What is announced when a form's submit finds [count] fields wrong
  /// (`RawForm.problemsMessage`).
  String formProblemsMessage(int count);

  /// The label of a password field's reveal toggle while the text is
  /// hidden (`RawPasswordReveal.showLabel`).
  String get showPasswordLabel;

  /// The label of a password field's reveal toggle while the text shows
  /// (`RawPasswordReveal.hideLabel`).
  String get hidePasswordLabel;

  /// What a screen reader calls a menu bar
  /// (`RawMenuBar.semanticLabel`).
  String get menuBarLabel;

  /// The refresh action's label (`RawRefreshIndicator.refreshLabel`).
  String get refreshLabel;

  /// What is announced as a refresh starts
  /// (`RawRefreshIndicator.refreshingMessage`).
  String get refreshingMessage;

  /// What is announced when a refresh ends
  /// (`RawRefreshIndicator.doneMessage`).
  String get refreshedMessage;

  /// What a screen reader calls a range slider's start thumb
  /// (`RawRangeSlider.startLabel`).
  String get rangeSliderStartLabel;

  /// What a screen reader calls a range slider's end thumb
  /// (`RawRangeSlider.endLabel`).
  String get rangeSliderEndLabel;

  /// What is announced when the item called [label] moves to [position]
  /// (from 1) of [count] (`RawReorderableList.movedMessage`).
  String reorderableListMovedMessage(String label, int position, int count);

  /// The barrier's label behind a side sheet
  /// (`RawSideSheetRoute.barrierLabel`).
  String get sideSheetBarrierLabel;

  /// The label of a split button's menu part
  /// (`RawSplitButton.menuLabel`).
  String get splitButtonMenuLabel;

  /// What a screen reader calls a split view's handle
  /// (`RawSplitView.semanticLabel`).
  String get splitViewHandleLabel;

  /// The custom action that removes a tag (`RawTagInput.deleteLabel`).
  String get tagInputDeleteLabel;

  /// What a screen reader calls the toasts' region
  /// (`RawToaster.regionLabel`).
  String get toasterRegionLabel;

  /// A tree row's hint: [level] (from 1), and [position] (from 1) of the
  /// [count] rows beside it (`RawTree.levelHint`).
  String treeLevelHint(int level, int position, int count);

  // A shortcut's keys (rawShortcutKeys).

  /// The Alt key, in a shortcut's label (Material's `keyboardKeyAlt`).
  String get keyboardKeyAlt;

  /// The Control key, in a shortcut's label (Material's `keyboardKeyControl`).
  String get keyboardKeyControl;

  /// The Shift key, in a shortcut's label (Material's `keyboardKeyShift`).
  String get keyboardKeyShift;

  /// The Meta key (Android, Linux), in a shortcut's label (Material's `keyboardKeyMeta`).
  String get keyboardKeyMeta;

  /// The Windows key, in a shortcut's label (Material's `keyboardKeyMetaWindows`).
  String get keyboardKeyMetaWindows;

  /// The Command key, spelled out, in a shortcut's label (Material's `keyboardKeyMetaMacOs`).
  String get keyboardKeyMetaMacOs;

  /// The Backspace key, in a shortcut's label (Material's `keyboardKeyBackspace`).
  String get keyboardKeyBackspace;

  /// The Delete key, in a shortcut's label (Material's `keyboardKeyDelete`).
  String get keyboardKeyDelete;

  /// The End key, in a shortcut's label (Material's `keyboardKeyEnd`).
  String get keyboardKeyEnd;

  /// The Escape key, in a shortcut's label (Material's `keyboardKeyEscape`).
  String get keyboardKeyEscape;

  /// The Home key, in a shortcut's label (Material's `keyboardKeyHome`).
  String get keyboardKeyHome;

  /// The Insert key, in a shortcut's label (Material's `keyboardKeyInsert`).
  String get keyboardKeyInsert;

  /// The Page Down key, in a shortcut's label (Material's `keyboardKeyPageDown`).
  String get keyboardKeyPageDown;

  /// The Page Up key, in a shortcut's label (Material's `keyboardKeyPageUp`).
  String get keyboardKeyPageUp;

  /// The Space bar, in a shortcut's label (Material's `keyboardKeySpace`).
  String get keyboardKeySpace;

  /// The Option key (⌥), spelled out on macOS and iOS: Material has no word for it, in a shortcut's label (ui_core's own).
  String get keyboardKeyOption;

  /// The Enter (Return) key, spelled out where its symbol (↵) is not drawn, in a shortcut's label (ui_core's own).
  String get keyboardKeyEnter;

  /// The Tab key, in a shortcut's label (ui_core's own).
  String get keyboardKeyTab;

  // A search that failed (RawCombobox.errorBuilder).

  /// What a screen reader hears as a combobox's or a tag input's search fails (RawCombobox.errorBuilder), in a shortcut's label (ui_core's own).
  String get searchFailedMessage;

  // The words ui_core's routes, tabs and shell say, under
  // MaterialLocalizations' names.

  /// What a screen reader calls an alert that names itself no other way
  /// (`RawModalDialogRoute` with `isAlert`) ("Alert").
  String get alertDialogLabel;

  /// What a screen reader calls a bottom sheet that names itself no other
  /// way (`RawBottomSheetRoute.semanticLabel`) ("Bottom Sheet").
  String get bottomSheetLabel;

  /// What a screen reader calls a dialog that names itself no other way
  /// (`RawModalDialogRoute`) ("Dialog").
  String get dialogLabel;

  /// What a screen reader calls a side navigation
  /// (`RawAdaptiveShell`'s sidebar) ("Navigation menu").
  String get drawerLabel;

  /// What a screen reader calls a bottom sheet's drag handle
  /// (`RawBottomSheetDragHandle`) ("Drag handle"). ui_core's own word.
  String get dragHandleLabel;

  /// Where a tab stands among [tabCount], [tabIndex] from 1 ("Tab 2 of 5"):
  /// a tab's, and a navigation destination's, place as a screen reader
  /// reads it.
  String tabLabel({required int tabIndex, required int tabCount});

  // The value behaviours' words, and numbers, dates and times
  // in the reader's symbols, digits and patterns (CLDR's).

  /// The abbreviation for a time before noon ("AM"), as
  /// `MaterialLocalizations`' (a time field's day period).
  String get anteMeridiemAbbreviation;

  /// The abbreviation for a time after noon ("PM").
  String get postMeridiemAbbreviation;

  /// A time field's hour segment, as a screen reader names it ("Hour"), as
  /// `MaterialLocalizations`'.
  String get timePickerHourLabel;

  /// A time field's minute segment ("Minute").
  String get timePickerMinuteLabel;

  /// A date field's year segment ("Year").
  String get dateFieldYearLabel;

  /// A date field's month segment ("Month").
  String get dateFieldMonthLabel;

  /// A date field's day segment ("Day").
  String get dateFieldDayLabel;

  /// A time field's seconds segment ("Second").
  String get timeFieldSecondLabel;

  /// A time field's day-period segment ("AM/PM").
  String get timeFieldDayPeriodLabel;

  /// An empty year segment's text ("yyyy").
  String get dateFieldYearPlaceholder;

  /// An empty month segment's text ("mm").
  String get dateFieldMonthPlaceholder;

  /// An empty day segment's text ("dd").
  String get dateFieldDayPlaceholder;

  /// A date outside the field's first and last dates ("Out of range."), as
  /// `MaterialLocalizations`'.
  String get dateOutOfRangeLabel;

  /// What a screen reader says for a field or segment with no value
  /// ("Empty").
  String get emptyValueLabel;

  /// A rating's name when its caller gives none ("Rating").
  String get ratingLabel;

  /// A rating's value: [value] of [count] items ("3.5 of 5").
  String ratingValueLabel(double value, int count);

  /// How many series a chart draws ("2 series").
  String chartSeriesCountLabel(int count);

  /// How many data points a chart draws ("12 points").
  String chartPointCountLabel(int count);

  /// How many slices a pie chart draws ("4 slices").
  String chartSliceCountLabel(int count);

  /// A chart's x axis from [from] to [to], both formatted ("Jan to Dec").
  String chartRangeLabel(String from, String to);

  /// A chart's least and greatest values, formatted ("lowest 820, highest
  /// 1,640").
  String chartExtremesLabel(String lowest, String highest);

  /// One data point: [x], its [series]' name and its value [y], formatted
  /// ("Mar 2026, Revenue: 1,240").
  String chartPointLabel(String x, String series, String y);

  /// A chart's screen-reader action that shows its data as a table ("Show
  /// data table").
  String get chartShowTableLabel;

  /// Joins the parts of a spoken summary (", ").
  String get listSeparator;

  /// [value] in the reader's digits and separators ("1,240.5"; German's
  /// "1.240,5"; Arabic's in Arabic-Indic digits, U+0660 to U+0669, grouped
  /// by U+066C with U+066B for the point), with [fractionDigits] decimals,
  /// or as many as it has up to three when null.
  String formatDecimal(num value, {int? fractionDigits});

  /// [text] read as a number the reader wrote, in their digits and
  /// separators (or ASCII digits); null when it does not read.
  double? parseDecimal(String text);

  /// [fraction] as a percentage ("40%"; French's "40 %").
  String formatPercent(double fraction, {int fractionDigits = 0});

  /// [date]'s year on its own ("2026"; Japanese's 2026 and its year mark,
  /// U+5E74).
  String formatYear(DateTime date);

  /// [date]'s month's short name on its own ("Nov").
  String formatShortMonth(DateTime date);

  /// [date]'s month's name on its own ("November"), as a date field's month
  /// segment is read.
  String formatMonth(DateTime date);

  /// [date]'s month and day, short ("Nov 16"; German's "16. Nov.").
  String formatShortMonthDay(DateTime date);

  /// [time] on the locale's clock ("3:05 PM"; German's "15:05"), on a
  /// 24-hour clock when [alwaysUse24HourFormat], with its seconds when
  /// [showSeconds].
  String formatTimeOfDay(
    RawTimeOfDay time, {
    bool alwaysUse24HourFormat = false,
    bool showSeconds = false,
  });

  /// A date field's order and the text between its segments (CLDR's yMd:
  /// "M/d/y"; German's "d.M.y"; Japanese's "y/M/d").
  String get dateFieldPattern;

  /// A time field's segments and the text between (CLDR's jm: "h:mm a";
  /// Korean's "a h:mm"; or Hm, "HH:mm", when [alwaysUse24HourFormat]),
  /// with seconds when [showSeconds].
  String timeFieldPattern({
    bool alwaysUse24HourFormat = false,
    bool showSeconds = false,
  });
}

/// The words in English, with no localizations package.
///
/// ```dart
/// const DefaultRawWidgetsLocalizations().carouselSlideLabel(0, 3)
/// ```
class DefaultRawWidgetsLocalizations implements RawWidgetsLocalizations {
  /// English, the words [RawWidgetsLocalizations.of] falls back to.
  const DefaultRawWidgetsLocalizations();

  /// Makes the English words: what [delegate] loads for any locale.
  static Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<RawWidgetsLocalizations>(
        const DefaultRawWidgetsLocalizations(),
      );

  /// A delegate that loads English, for an app's
  /// `localizationsDelegates`.
  static const LocalizationsDelegate<RawWidgetsLocalizations> delegate =
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
  String colorChannelLabel(RawColorChannel channel) => switch (channel) {
    RawColorChannel.hue => 'Hue',
    RawColorChannel.saturation => 'Saturation',
    RawColorChannel.brightness => 'Brightness',
    RawColorChannel.alpha => 'Alpha',
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
  String dataTableSortedHint(RawSortDirection direction) =>
      direction == RawSortDirection.ascending
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

  // A shortcut's keys (rawShortcutKeys).

  @override
  String get keyboardKeyAlt => 'Alt';

  @override
  String get keyboardKeyControl => 'Ctrl';

  @override
  String get keyboardKeyShift => 'Shift';

  @override
  String get keyboardKeyMeta => 'Meta';

  @override
  String get keyboardKeyMetaWindows => 'Win';

  @override
  String get keyboardKeyMetaMacOs => 'Command';

  @override
  String get keyboardKeyBackspace => 'Backspace';

  @override
  String get keyboardKeyDelete => 'Del';

  @override
  String get keyboardKeyEnd => 'End';

  @override
  String get keyboardKeyEscape => 'Esc';

  @override
  String get keyboardKeyHome => 'Home';

  @override
  String get keyboardKeyInsert => 'Insert';

  @override
  String get keyboardKeyPageDown => 'PgDown';

  @override
  String get keyboardKeyPageUp => 'PgUp';

  @override
  String get keyboardKeySpace => 'Space';

  @override
  String get keyboardKeyOption => 'Option';

  @override
  String get keyboardKeyEnter => 'Enter';

  @override
  String get keyboardKeyTab => 'Tab';

  // A search that failed (RawCombobox.errorBuilder).

  @override
  String get searchFailedMessage => "Couldn't load results";

  @override
  String get alertDialogLabel => 'Alert';

  @override
  String get bottomSheetLabel => 'Bottom Sheet';

  @override
  String get dialogLabel => 'Dialog';

  @override
  String get drawerLabel => 'Navigation menu';

  @override
  String get dragHandleLabel => 'Drag handle';

  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      'Tab $tabIndex of $tabCount';

  // The data the numbers, dates and times read: English's here, a
  // translation's own in _TranslatedDesignLocalizations.
  RawLocaleData get _valueData => rawLocaleData['en']!;

  decimal.DecimalSymbols get _symbols => decimal.DecimalSymbols.of(_valueData);

  String _pattern(String pattern, DateTime when) => formatPattern(
    pattern,
    when,
    data: _valueData,
    am: anteMeridiemAbbreviation,
    pm: postMeridiemAbbreviation,
  );

  @override
  String get anteMeridiemAbbreviation => 'AM';

  @override
  String get postMeridiemAbbreviation => 'PM';

  @override
  String get timePickerHourLabel => 'Hour';

  @override
  String get timePickerMinuteLabel => 'Minute';

  /// A date picker's title, as `MaterialLocalizations.datePickerHelpText`
  /// words it: Select date. [RawPickerWords] reads it from any
  /// [RawWidgetsLocalizations].
  String get datePickerHelpText => 'Select date';

  /// A time picker's title, as `MaterialLocalizations.timePickerDialHelpText`
  /// words it: Select time. [RawPickerWords] reads it from any
  /// [RawWidgetsLocalizations].
  String get timePickerDialHelpText => 'Select time';

  @override
  String get dateFieldYearLabel => 'Year';

  @override
  String get dateFieldMonthLabel => 'Month';

  @override
  String get dateFieldDayLabel => 'Day';

  @override
  String get timeFieldSecondLabel => 'Second';

  @override
  String get timeFieldDayPeriodLabel => 'AM/PM';

  @override
  String get dateFieldYearPlaceholder => 'yyyy';

  @override
  String get dateFieldMonthPlaceholder => 'mm';

  @override
  String get dateFieldDayPlaceholder => 'dd';

  @override
  String get dateOutOfRangeLabel => 'Out of range.';

  @override
  String get emptyValueLabel => 'Empty';

  @override
  String get ratingLabel => 'Rating';

  @override
  String ratingValueLabel(double value, int count) =>
      '${formatDecimal(value)} of ${formatDecimal(count)}';

  @override
  String chartSeriesCountLabel(int count) => '${formatDecimal(count)} series';

  @override
  String chartPointCountLabel(int count) =>
      '${formatDecimal(count)} ${count == 1 ? 'point' : 'points'}';

  @override
  String chartSliceCountLabel(int count) =>
      '${formatDecimal(count)} ${count == 1 ? 'slice' : 'slices'}';

  @override
  String chartRangeLabel(String from, String to) => '$from to $to';

  @override
  String chartExtremesLabel(String lowest, String highest) =>
      'lowest $lowest, highest $highest';

  @override
  String chartPointLabel(String x, String series, String y) =>
      '$x, $series: $y';

  @override
  String get chartShowTableLabel => 'Show data table';

  @override
  String get listSeparator => ', ';

  @override
  String formatDecimal(num value, {int? fractionDigits}) =>
      decimal.formatDecimal(value, _symbols, fractionDigits: fractionDigits);

  @override
  double? parseDecimal(String text) => decimal.parseDecimal(text, _symbols);

  @override
  String formatPercent(double fraction, {int fractionDigits = 0}) =>
      decimal.formatPercent(fraction, _symbols, fractionDigits: fractionDigits);

  @override
  String formatYear(DateTime date) => _pattern(_valueData.year, date);

  @override
  String formatShortMonth(DateTime date) =>
      _pattern(_valueData.shortMonth, date);

  @override
  String formatMonth(DateTime date) => _pattern('LLLL', date);

  @override
  String formatShortMonthDay(DateTime date) =>
      _pattern(_valueData.monthDay, date);

  @override
  String formatTimeOfDay(
    RawTimeOfDay time, {
    bool alwaysUse24HourFormat = false,
    bool showSeconds = false,
  }) => _pattern(
    timeFieldPattern(
      alwaysUse24HourFormat: alwaysUse24HourFormat,
      showSeconds: showSeconds,
    ),
    DateTime(2000, 1, 1, time.hour, time.minute, time.second),
  );

  @override
  String get dateFieldPattern => _valueData.shortDate;

  @override
  String timeFieldPattern({
    bool alwaysUse24HourFormat = false,
    bool showSeconds = false,
  }) {
    final data = _valueData;
    return switch ((alwaysUse24HourFormat, showSeconds)) {
      (true, true) => data.time24WithSeconds,
      (true, false) => data.time24,
      (false, true) => data.timeWithSeconds,
      (false, false) => data.time,
    };
  }
}

/// A time's hour and minute as a look's time picker writes them, in the
/// app's digits, as `MaterialLocalizations.formatHour` and `formatMinute`
/// write Material's: a dial's numbers, a picker's hour and minute fields, a
/// wheel's rows. A look builds its figures from these rather than from
/// `n.toString().padLeft(2, '0')`, which stays in ASCII digits in every
/// language. [RawWidgetsLocalizations.formatTimeOfDay] writes the whole time;
/// [RawWidgetsLocalizations.anteMeridiemAbbreviation] and
/// [RawWidgetsLocalizations.postMeridiemAbbreviation] the day period.
///
/// They follow the locale's clock ([RawWidgetsLocalizations.timeFieldPattern])
/// and its digits ([RawWidgetsLocalizations.formatDecimal]), so an app's
/// subclass that changes either changes them too.
///
/// ```dart
/// Text(RawWidgetsLocalizations.of(context).formatMinute(const RawTimeOfDay(hour: 9, minute: 5)))
/// ```
extension RawTimeFormatting on RawWidgetsLocalizations {
  /// [time]'s hour on the locale's clock, in the app's digits: 1 to 12 on a
  /// 12-hour clock (English's 3 for 15:00, Arabic's ٣), 0 to 23 on a 24-hour
  /// one (Persian's ۱۵), two digits where the locale's clock writes two (09
  /// for 9:00 on English's 24-hour `HH:mm`). [alwaysUse24HourFormat] asks for
  /// a 24-hour clock, as `MediaQuery.alwaysUse24HourFormatOf` does.
  String formatHour(RawTimeOfDay time, {bool alwaysUse24HourFormat = false}) {
    final hour = parsePattern(
      timeFieldPattern(alwaysUse24HourFormat: alwaysUse24HourFormat),
    ).where((part) => part.type == RawDateSegmentType.hour).firstOrNull;
    final value = switch (hour?.letter) {
      'h' => time.hourOfPeriod,
      'K' => time.hour % 12,
      'k' => time.hour == 0 ? 24 : time.hour,
      _ => time.hour,
    };
    return digitsFrom(
      formatDecimal(0),
      value,
      width: (hour?.width ?? 1) >= 2 ? 2 : 1,
    );
  }

  /// [time]'s minute, two digits in the app's digits (05, Arabic's ٠٥).
  String formatMinute(RawTimeOfDay time) =>
      digitsFrom(formatDecimal(0), time.minute, width: 2);
}

/// A date or time picker's title, in the app's language: Material's words
/// (Select date, Select time) and their translations in the 30 languages
/// ui_core speaks.
///
/// [DefaultRawWidgetsLocalizations] holds them: an app or a look words them
/// its own way, or in a language ui_core does not speak, in its subclass,
/// overriding [DefaultRawWidgetsLocalizations.datePickerHelpText] and
/// [DefaultRawWidgetsLocalizations.timePickerDialHelpText] as it overrides
/// any word. Words of a [RawWidgetsLocalizations] that is not one are
/// English. A later minor version makes them [RawWidgetsLocalizations]'
/// own, and reading them stays the same.
///
/// ```dart
/// Text(RawWidgetsLocalizations.of(context).datePickerHelpText)
/// ```
extension RawPickerWords on RawWidgetsLocalizations {
  /// A date picker's title: Select date, in the app's language.
  String get datePickerHelpText => switch (this) {
    final DefaultRawWidgetsLocalizations words => words.datePickerHelpText,
    _ => const DefaultRawWidgetsLocalizations().datePickerHelpText,
  };

  /// A time picker's title: Select time, in the app's language.
  String get timePickerDialHelpText => switch (this) {
    final DefaultRawWidgetsLocalizations words => words.timePickerDialHelpText,
    _ => const DefaultRawWidgetsLocalizations().timePickerDialHelpText,
  };
}

class _RawLocalizationsDelegate
    extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _RawLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<RawWidgetsLocalizations>(
        RawWidgetsLocalizations.forLocale(locale),
      );

  @override
  bool shouldReload(_RawLocalizationsDelegate old) => false;

  @override
  String toString() => 'RawWidgetsLocalizations.delegate(30 locales)';
}

// One locale's words from its table (rawLocaleData), English for a word
// the table lacks.
class _TranslatedDesignLocalizations extends DefaultRawWidgetsLocalizations {
  const _TranslatedDesignLocalizations(this._data);

  final RawLocaleData _data;

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
  String colorChannelLabel(RawColorChannel channel) => _word(switch (channel) {
    RawColorChannel.hue => 'colorChannelHue',
    RawColorChannel.saturation => 'colorChannelSaturation',
    RawColorChannel.brightness => 'colorChannelBrightness',
    RawColorChannel.alpha => 'colorChannelAlpha',
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
  String dataTableSortedHint(RawSortDirection direction) => _word(
    direction == RawSortDirection.ascending
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

  // A shortcut's keys (rawShortcutKeys).

  @override
  String get keyboardKeyAlt => _word('keyboardKeyAlt', super.keyboardKeyAlt);

  @override
  String get keyboardKeyControl =>
      _word('keyboardKeyControl', super.keyboardKeyControl);

  @override
  String get keyboardKeyShift =>
      _word('keyboardKeyShift', super.keyboardKeyShift);

  @override
  String get keyboardKeyMeta => _word('keyboardKeyMeta', super.keyboardKeyMeta);

  @override
  String get keyboardKeyMetaWindows =>
      _word('keyboardKeyMetaWindows', super.keyboardKeyMetaWindows);

  @override
  String get keyboardKeyMetaMacOs =>
      _word('keyboardKeyMetaMacOs', super.keyboardKeyMetaMacOs);

  @override
  String get keyboardKeyBackspace =>
      _word('keyboardKeyBackspace', super.keyboardKeyBackspace);

  @override
  String get keyboardKeyDelete =>
      _word('keyboardKeyDelete', super.keyboardKeyDelete);

  @override
  String get keyboardKeyEnd => _word('keyboardKeyEnd', super.keyboardKeyEnd);

  @override
  String get keyboardKeyEscape =>
      _word('keyboardKeyEscape', super.keyboardKeyEscape);

  @override
  String get keyboardKeyHome => _word('keyboardKeyHome', super.keyboardKeyHome);

  @override
  String get keyboardKeyInsert =>
      _word('keyboardKeyInsert', super.keyboardKeyInsert);

  @override
  String get keyboardKeyPageDown =>
      _word('keyboardKeyPageDown', super.keyboardKeyPageDown);

  @override
  String get keyboardKeyPageUp =>
      _word('keyboardKeyPageUp', super.keyboardKeyPageUp);

  @override
  String get keyboardKeySpace =>
      _word('keyboardKeySpace', super.keyboardKeySpace);

  @override
  String get keyboardKeyOption =>
      _word('keyboardKeyOption', super.keyboardKeyOption);

  @override
  String get keyboardKeyEnter =>
      _word('keyboardKeyEnter', super.keyboardKeyEnter);

  @override
  String get keyboardKeyTab => _word('keyboardKeyTab', super.keyboardKeyTab);

  // A search that failed (RawCombobox.errorBuilder).

  @override
  String get searchFailedMessage =>
      _word('searchFailedMessage', super.searchFailedMessage);

  @override
  String get alertDialogLabel =>
      _word('alertDialogLabel', super.alertDialogLabel);

  @override
  String get bottomSheetLabel =>
      _word('bottomSheetLabel', super.bottomSheetLabel);

  @override
  String get dialogLabel => _word('dialogLabel', super.dialogLabel);

  @override
  String get drawerLabel => _word('drawerLabel', super.drawerLabel);

  @override
  String get dragHandleLabel => _word('dragHandleLabel', super.dragHandleLabel);

  @override
  String tabLabel({required int tabIndex, required int tabCount}) => _message(
    'tabLabel',
    super.tabLabel(tabIndex: tabIndex, tabCount: tabCount),
    {'tabIndex': tabIndex, 'tabCount': tabCount},
  );

  @override
  RawLocaleData get _valueData => _data;

  // A counted value message: as _plural, its count grouped as a number.
  String _countedValue(String key, int count, String english) {
    final forms = _data.plurals[key];
    if (forms == null) return english;
    final form =
        forms['=$count'] ??
        forms[_pluralCategory(_data.plural, count)] ??
        forms['other']!;
    return _fill(form, {'count': formatDecimal(count)});
  }

  @override
  String get anteMeridiemAbbreviation =>
      _word('anteMeridiemAbbreviation', super.anteMeridiemAbbreviation);

  @override
  String get postMeridiemAbbreviation =>
      _word('postMeridiemAbbreviation', super.postMeridiemAbbreviation);

  @override
  String get timePickerHourLabel =>
      _word('timePickerHourLabel', super.timePickerHourLabel);

  @override
  String get timePickerMinuteLabel =>
      _word('timePickerMinuteLabel', super.timePickerMinuteLabel);

  @override
  String get datePickerHelpText =>
      _word('datePickerHelpText', super.datePickerHelpText);

  @override
  String get timePickerDialHelpText =>
      _word('timePickerDialHelpText', super.timePickerDialHelpText);

  @override
  String get dateFieldYearLabel =>
      _word('dateFieldYearLabel', super.dateFieldYearLabel);

  @override
  String get dateFieldMonthLabel =>
      _word('dateFieldMonthLabel', super.dateFieldMonthLabel);

  @override
  String get dateFieldDayLabel =>
      _word('dateFieldDayLabel', super.dateFieldDayLabel);

  @override
  String get timeFieldSecondLabel =>
      _word('timeFieldSecondLabel', super.timeFieldSecondLabel);

  @override
  String get timeFieldDayPeriodLabel =>
      _word('timeFieldDayPeriodLabel', super.timeFieldDayPeriodLabel);

  @override
  String get dateFieldYearPlaceholder =>
      _word('dateFieldYearPlaceholder', super.dateFieldYearPlaceholder);

  @override
  String get dateFieldMonthPlaceholder =>
      _word('dateFieldMonthPlaceholder', super.dateFieldMonthPlaceholder);

  @override
  String get dateFieldDayPlaceholder =>
      _word('dateFieldDayPlaceholder', super.dateFieldDayPlaceholder);

  @override
  String get dateOutOfRangeLabel =>
      _word('dateOutOfRangeLabel', super.dateOutOfRangeLabel);

  @override
  String get emptyValueLabel => _word('emptyValueLabel', super.emptyValueLabel);

  @override
  String get ratingLabel => _word('ratingLabel', super.ratingLabel);

  @override
  String ratingValueLabel(double value, int count) => _message(
    'ratingValueLabel',
    super.ratingValueLabel(value, count),
    {'value': formatDecimal(value), 'count': formatDecimal(count)},
  );

  @override
  String chartSeriesCountLabel(int count) => _countedValue(
    'chartSeriesCountLabel',
    count,
    super.chartSeriesCountLabel(count),
  );

  @override
  String chartPointCountLabel(int count) => _countedValue(
    'chartPointCountLabel',
    count,
    super.chartPointCountLabel(count),
  );

  @override
  String chartSliceCountLabel(int count) => _countedValue(
    'chartSliceCountLabel',
    count,
    super.chartSliceCountLabel(count),
  );

  @override
  String chartRangeLabel(String from, String to) => _message(
    'chartRangeLabel',
    super.chartRangeLabel(from, to),
    {'from': from, 'to': to},
  );

  @override
  String chartExtremesLabel(String lowest, String highest) => _message(
    'chartExtremesLabel',
    super.chartExtremesLabel(lowest, highest),
    {'lowest': lowest, 'highest': highest},
  );

  @override
  String chartPointLabel(String x, String series, String y) => _message(
    'chartPointLabel',
    super.chartPointLabel(x, series, y),
    {'x': x, 'series': series, 'y': y},
  );

  @override
  String get chartShowTableLabel =>
      _word('chartShowTableLabel', super.chartShowTableLabel);

  @override
  String get listSeparator => _word('listSeparator', super.listSeparator);
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
    extends LocalizationsDelegate<RawWidgetsLocalizations> {
  const _DefaultDesignLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<RawWidgetsLocalizations> load(Locale locale) =>
      DefaultRawWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(_DefaultDesignLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultRawWidgetsLocalizations.delegate(en)';
}
