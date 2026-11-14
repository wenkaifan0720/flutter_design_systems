// Every word Neumorphism's parts say on their own: a close, a dismiss, a loading line, a picker's month names. A part takes
// the caller's words when given, and these otherwise, so an app in another language installs a delegate and every
// part speaks it.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show DesignLocalizations;
import 'package:intl/date_symbol_data_local.dart' show initializeDateFormatting;
import 'package:intl/intl.dart';

/// The words Neumorphism's parts say when the caller gives none. English ships ([NeumorphicLocalizationsEn]); another language is a
/// subclass and a delegate that loads it. With no delegate installed, the parts speak English.
///
/// ```dart
/// MaterialApp(localizationsDelegates: const [NeumorphicLocalizations.delegate], home: home)
/// ```
abstract class NeumorphicLocalizations {
  /// Const constructor, for subclasses.
  const NeumorphicLocalizations();

  /// The words in force at [context]. The words every look shares (Cancel, Close, Today, "3 of 10" and the rest) come
  /// from ui_core's [DesignLocalizations], which an app translates by extending `DefaultDesignLocalizations`; the
  /// shipped delegate adds only intl's dates and numbers in its locale. An app's own subclass speaks for itself.
  static NeumorphicLocalizations of(BuildContext context) {
    final installed = Localizations.of<NeumorphicLocalizations>(
      context,
      NeumorphicLocalizations,
    );
    if (installed != null &&
        installed.runtimeType != NeumorphicLocalizationsEn) {
      return installed;
    }
    return _FallbackLocalizations(
      Localizations.of<WidgetsLocalizations>(context, WidgetsLocalizations),
      DesignLocalizations.of(context),
      localeName: installed?.localeName ?? 'en_US',
    );
  }

  /// The intl locale used by generated dates and numbers. A custom delegate
  /// initializes its date symbols with `initializeDateFormatting` before loading.
  String get localeName => 'en_US';

  /// A number using this locale's digits, grouping and decimal separator.
  String formatNumber(num value, {int maximumFractionDigits = 1}) =>
      (NumberFormat.decimalPattern(
        localeName,
      )..maximumFractionDigits = maximumFractionDigits).format(value);

  /// A calendar day's visible number.
  String formatDay(DateTime date) => DateFormat.d(localeName).format(date);

  /// A date's full spoken label, including its month and year.
  String formatFullDate(DateTime date) =>
      DateFormat.yMMMMEEEEd(localeName).format(date);

  /// A date picker's month heading.
  String formatMonthYear(DateTime date) =>
      DateFormat.yMMMM(localeName).format(date);

  /// A value from zero to one, spoken as a percentage.
  String formatPercent(num value) =>
      NumberFormat.percentPattern(localeName).format(value);

  /// An hour and minute in the day tray's 24-hour scale.
  String formatTime(DateTime time) => DateFormat.Hm(localeName).format(time);

  /// A chart's empty-data message.
  String get nothingToShow => 'Nothing to show yet';

  /// A verification field with no caller-provided label.
  String get verificationCode => 'Verification code';

  /// Notice tone headings, when the caller supplies no title.
  String get information => 'Information';

  /// A successful notice's heading when the caller supplies none.
  String get success => 'Success';

  /// A warning notice's heading when the caller supplies none.
  String get warning => 'Warning';

  /// An error notice's heading when the caller supplies none.
  String get error => 'Error';

  /// The current calendar day.
  String get today => 'Today';

  /// The toaster's region, for a screen reader.
  String get notifications => 'Notifications';

  /// A menu bar's name, for a screen reader.
  String get menu => 'Menu';

  /// A page's spoken position.
  String pageOf(int page, int count) =>
      'Page ${formatNumber(page)} of ${formatNumber(count)}';

  /// A step's spoken position.
  String stepOf(int step, int count) =>
      'Step ${formatNumber(step)} of ${formatNumber(count)}';

  /// Pagination's step back a page.
  String get previousPage => 'Previous page';

  /// Pagination's step on a page.
  String get nextPage => 'Next page';

  /// A carousel's step back an item.
  String get previous => 'Previous';

  /// A carousel's step on an item.
  String get next => 'Next';

  /// The breadcrumb trail's name.
  String get breadcrumbs => 'Breadcrumbs';

  /// A rating's spoken value: '3 of 5'.
  String ratingOf(num value, int count) =>
      '${formatNumber(value)} of ${formatNumber(count)}';

  /// A file drop's button.
  String get chooseFiles => 'Choose files';

  /// A file drop's title when the caller supplies none.
  String get dropFiles => 'Drop files here';

  /// A file drop's title while files are held over it.
  String get releaseToAdd => 'Release to add';

  /// DateTime weekday of the locale's first day of the week, Monday 1 to Sunday 7.
  int get firstDayOfWeek =>
      DateFormat.E(localeName).dateSymbols.FIRSTDAYOFWEEK + 1;

  // The words of the parts round 4 added (coverage, 11-10). Concrete, so a delegate written before them still builds.

  /// A bar chart's key for its highlighted bar.
  String get now => 'Now';

  /// A bar chart's key for its dashed forecast cap.
  String get forecast => 'Forecast';

  /// A tag's remove button: 'Remove Design'.
  String remove(String label) => 'Remove $label';

  /// A split button's second half, and an action sheet's or menu's opener.
  String get moreOptions => 'More options';

  /// A search or a filter field with no caller-provided hint.
  String get search => 'Search';

  /// A combobox's, command palette's or multi-select's list with nothing in it.
  String get noResults => 'No results';

  /// A multi-select's offer to add the words typed: 'Add "Design"'.
  String create(String words) => 'Add "$words"';

  /// A pull-to-refresh while it is pulled, but not far enough.
  String get pullToRefresh => 'Pull to refresh';

  /// A pull-to-refresh pulled far enough.
  String get releaseToRefresh => 'Release to refresh';

  /// A pull-to-refresh while the refresh runs.
  String get refreshing => 'Refreshing';

  /// A pull-to-refresh when the refresh has finished.
  String get refreshed => 'Up to date';

  /// A tree row's or a disclosure's opener.
  String get expand => 'Expand';

  /// A tree row's or a disclosure's closer.
  String get collapse => 'Collapse';

  /// A reorderable row's grip.
  String get reorder => 'Drag to reorder';

  /// A reorderable row's step up.
  String get moveUp => 'Move up';

  /// A reorderable row's step down.
  String get moveDown => 'Move down';

  /// A split view's divider.
  String get resize => 'Resize';

  /// A carousel's autoplay, while it is stopped.
  String get play => 'Play';

  /// A carousel's autoplay, while it runs.
  String get pause => 'Pause';

  /// A command palette's name and its field's hint.
  String get typeCommand => 'Type a command or search';

  /// A form field's required mark, spoken.
  String get requiredField => 'Required';

  /// A date range's start.
  String get startDate => 'Start';

  /// A date range's end.
  String get endDate => 'End';

  /// A colour picker's name.
  String get colour => 'Colour';

  /// A colour picker's hue slider.
  String get hue => 'Hue';

  /// A colour picker's opacity slider.
  String get opacity => 'Opacity';

  /// A colour picker's hex field.
  String get hex => 'Hex';

  /// A data table's selection of a row: 'Select Ana'.
  String select(String label) => 'Select $label';

  /// A data table's selection of every row on the page.
  String get selectAllRows => 'Select all rows';

  /// A data table's spoken sort: 'Sorted ascending'.
  String get sortedAscending => 'Sorted ascending';

  /// A data table's spoken sort, descending.
  String get sortedDescending => 'Sorted descending';

  /// A status view's success heading when the caller supplies none.
  String get done => 'Done';

  /// A range slider's lower handle, spoken.
  String get minimum => 'Minimum';

  /// A range slider's upper handle, spoken.
  String get maximum => 'Maximum';

  /// A timeline's spoken state of the stop it stands at.
  String get current => 'Current';

  /// A timeline's spoken state of a stop still ahead.
  String get upcoming => 'Upcoming';

  /// A meter's spoken note when its value is past the good range.
  String get outOfRange => 'Outside the usual range';

  /// Loads Neumorphism's English words for an English locale.
  static const LocalizationsDelegate<NeumorphicLocalizations> delegate =
      _NeumorphicLocalizationsDelegate();

  /// What closes a raised surface, and what its scrim is called.
  String get close;

  /// What goes back a page.
  String get back;

  /// What dismisses a notice or a toast.
  String get dismiss;

  /// What a screen reader hears while something loads.
  String get loading;

  /// The error state's way to try again.
  String get tryAgain;

  /// A message's send button.
  String get send;

  /// A stepper's two buttons.
  String get less;

  /// A stepper's more button.
  String get more;

  /// A search field's clear button.
  String get clearSearch;

  /// A select's prompt and a picker's confirming button.
  String get choose;

  /// A dialog's or picker's way out without a change.
  String get cancel;

  /// A password field's eye, both ways.
  String get showPassword;

  /// A password field's eye, when the letters show.
  String get hidePassword;

  /// A date picker's title and its month steps.
  String get chooseDate;

  /// A date picker's step back a month.
  String get previousMonth;

  /// A date picker's step on a month.
  String get nextMonth;

  /// A time picker's title and its three wheels.
  String get chooseTime;

  /// A time picker's hours.
  String get hour;

  /// A time picker's minutes.
  String get minute;

  /// A time picker's AM and PM.
  String get period;

  /// The time picker's two halves of the day.
  String get am;

  /// The afternoon half: 'PM'.
  String get pm;

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

  /// The twelve months, January first, and the week's days as two letters, Monday first.
  List<String> get months;

  /// The week's days as two letters, Monday first.
  List<String> get weekdaysShort;
}

/// Neumorphism's English words.
class NeumorphicLocalizationsEn extends NeumorphicLocalizations {
  /// English, as the delegate loads it. The default uses intl's built-in
  /// English data, so fallback widgets work without an installed delegate.
  const NeumorphicLocalizationsEn({this.localeName = 'en_US'});
  @override
  final String localeName;
  @override
  String get close => 'Close';
  @override
  String get back => 'Back';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get loading => 'Loading';
  @override
  String get tryAgain => 'Try again';
  @override
  String get send => 'Send';
  @override
  String get less => 'Less';
  @override
  String get more => 'More';
  @override
  String get clearSearch => 'Clear search';
  @override
  String get choose => 'Choose';
  @override
  String get cancel => 'Cancel';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get chooseDate => 'Choose a date';
  @override
  String get previousMonth => 'Previous month';
  @override
  String get nextMonth => 'Next month';
  @override
  String get chooseTime => 'Choose a time';
  @override
  String get hour => 'Hour';
  @override
  String get minute => 'Minute';
  @override
  String get period => 'Morning or evening';
  @override
  String get am => 'AM';
  @override
  String get pm => 'PM';
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
}

class _NeumorphicLocalizationsDelegate
    extends LocalizationsDelegate<NeumorphicLocalizations> {
  const _NeumorphicLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<NeumorphicLocalizations> load(Locale locale) async {
    final name = Intl.canonicalizedLocale(locale.toString());
    await initializeDateFormatting(name);
    return NeumorphicLocalizationsEn(localeName: name);
  }

  @override
  bool shouldReload(_NeumorphicLocalizationsDelegate old) => false;
}

/// The shipped English, with the words every look shares read from ui_core's [DesignLocalizations] (an app translates
/// them by extending `DefaultDesignLocalizations`) and the editing words from the app's [WidgetsLocalizations].
class _FallbackLocalizations extends NeumorphicLocalizationsEn {
  const _FallbackLocalizations(this.widgets, this.design, {super.localeName});
  final WidgetsLocalizations? widgets;
  final DesignLocalizations design;
  @override
  String get cancel => design.cancelButtonLabel;
  @override
  String get close => design.closeButtonLabel;
  @override
  String get clearSearch => design.clearButtonTooltip;
  @override
  String get back => design.backButtonTooltip;
  @override
  String get delete => design.deleteButtonTooltip;
  @override
  String get moreOptions => design.splitButtonMenuLabel;
  @override
  String get resize => design.splitViewHandleLabel;
  @override
  String get refreshing => design.refreshingMessage;
  @override
  String get refreshed => design.refreshedMessage;
  @override
  String get minimum => design.rangeSliderStartLabel;
  @override
  String get maximum => design.rangeSliderEndLabel;
  @override
  String get notifications => design.toasterRegionLabel;
  @override
  String get menu => design.menuBarLabel;
  @override
  String get search => design.searchFieldLabel;
  @override
  String get dismiss => design.modalBarrierDismissLabel;
  @override
  String get today => design.currentDateLabel;
  @override
  String get previousMonth => design.previousMonthTooltip;
  @override
  String get nextMonth => design.nextMonthTooltip;
  @override
  String get previousPage => design.previousPageTooltip;
  @override
  String get nextPage => design.nextPageTooltip;
  @override
  String get expand => design.collapsedIconTapHint;
  @override
  String get collapse => design.expandedIconTapHint;
  @override
  String get loading => design.loadingLabel;
  @override
  String get noResults => design.noResultsLabel;
  @override
  String pageOf(int page, int count) => design.positionLabel(page, count);
  @override
  String get showPassword => design.showPasswordLabel;
  @override
  String get hidePassword => design.hidePasswordLabel;
  @override
  String get cut => widgets?.cutButtonLabel ?? super.cut;
  @override
  String get copy => widgets?.copyButtonLabel ?? super.copy;
  @override
  String get paste => widgets?.pasteButtonLabel ?? super.paste;
  @override
  String get selectAll => widgets?.selectAllButtonLabel ?? super.selectAll;
  @override
  String get lookUp => widgets?.lookUpButtonLabel ?? super.lookUp;
  @override
  String get searchWeb => widgets?.searchWebButtonLabel ?? super.searchWeb;
  @override
  String get share => widgets?.shareButtonLabel ?? super.share;
}
