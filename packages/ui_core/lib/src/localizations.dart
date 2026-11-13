import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'color_picker.dart' show DesignColorChannel;
import 'data_table.dart' show DesignSortDirection;

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
/// setting up. An app in another language extends
/// [DefaultDesignLocalizations], overriding the words it translates, and
/// adds a delegate for its subclass to `localizationsDelegates`, as it does
/// for `WidgetsLocalizations`. Extending it, rather than implementing this
/// class, keeps a word added in a later minor version in English until the
/// app translates it.
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
