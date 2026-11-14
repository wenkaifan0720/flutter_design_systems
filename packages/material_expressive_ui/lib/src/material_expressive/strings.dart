/// The words Expressive's components say on their own: semantics labels,
/// custom accessibility actions, default placeholders and the pickers'
/// chrome. Compose keeps these in `Strings` (material3 `internal/Strings.kt`,
/// resolved per locale); here they are [ExpressiveLocalizations].
///
/// The words every look shares (Back, Close, Cancel, OK, Today, Next month,
/// "Slide 2 of 5", ...) come from ui_core's [DesignLocalizations], under
/// `MaterialLocalizations`' names, so an app translates them once for every
/// look by extending [DefaultDesignLocalizations]. The look's own words (the
/// pickers' titles and modes, a chat bubble's status, ...) are
/// [ExpressiveLocalizations]' parameters: English defaults, loaded through
/// [ExpressiveLocalizations.delegate] or a delegate of the app's own, and
/// replaced for a subtree with [ExpressiveLocalizationsScope].
///
/// A component reads them at build with [ExpressiveLocalizations.of], which
/// falls back to English with nothing registered, so an app that registers
/// nothing still reads; a caller that passes its own label (every component
/// that takes one) still wins.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

export 'package:ui_core/ui_core.dart'
    show DefaultDesignLocalizations, DesignLocalizations;

/// Every word a component says without being told.
///
/// Another language gives both kinds of words: the shared ones in a
/// [DefaultDesignLocalizations] of its own, the look's in an
/// [ExpressiveLocalizations] with its words given, each loaded by a
/// delegate:
///
/// ```dart
/// import 'package:flutter/foundation.dart';
/// import 'package:flutter/widgets.dart';
/// import 'package:material_expressive_ui/material_expressive_ui.dart';
///
/// class FrenchWords extends DefaultDesignLocalizations {
///   const FrenchWords();
///
///   @override
///   String get cancelButtonLabel => 'Annuler';
/// }
///
/// class French<T> extends LocalizationsDelegate<T> {
///   const French(this.words);
///
///   final T words;
///
///   @override
///   bool isSupported(Locale locale) => locale.languageCode == 'fr';
///
///   @override
///   Future<T> load(Locale locale) => SynchronousFuture(words);
///
///   @override
///   bool shouldReload(French<T> old) => false;
/// }
///
/// const frenchDelegates = <LocalizationsDelegate<dynamic>>[
///   French<DesignLocalizations>(FrenchWords()),
///   French<ExpressiveLocalizations>(
///     ExpressiveLocalizations(selectDate: 'Choisir une date'),
///   ),
/// ];
/// ```
@immutable
class ExpressiveLocalizations {
  /// The look's own words in English, unless given; the shared ones
  /// English until [of] reads them in context.
  const ExpressiveLocalizations({
    this.cancelSearch = 'Cancel search',
    this.showSuggestions = 'Show suggestions',
    this.hideSuggestions = 'Hide suggestions',
    this.sheetDragHandle = 'Drag handle',
    this.toolbarExpand = 'Expand toolbar',
    this.toolbarCollapse = 'Collapse toolbar',
    this.fabMenu = 'FAB menu',
    this.toastDismiss = 'Dismiss',
    this.tryAgain = 'Try again',
    this.reorder = 'Reorder',
    this.quantity = 'Quantity',
    this.messageSending = 'Sending',
    this.messageSent = 'Sent',
    this.messageRead = 'Read',
    this.messageFailed = 'Not sent',
    this.messageFromYou = 'You',
    this.removeChip = _removeChip,
    this.rated = _rated,
    this.rate = _rate,
    this.codeInput = _codeInput,
    this.decrease = _decrease,
    this.increase = _increase,
    this.stepOf = _stepOf,
    this.allStepsDone = _allStepsDone,
    this.selectDate = 'Select date',
    this.selectDates = 'Select dates',
    this.enterDates = 'Enter dates',
    this.selectedDate = 'Selected date',
    this.enteredDate = 'Entered date',
    this.startDate = 'Start date',
    this.endDate = 'End date',
    this.date = 'Date',
    this.datePattern = 'MM/DD/YYYY',
    this.inRange = 'In range',
    this.toDateInput = 'Type a date',
    this.toCalendar = 'Pick from the calendar',
    this.toYears = 'Choose a year',
    this.toDays = 'Back to the days',
    this.badDatePattern = 'Use the form MM/DD/YYYY',
    this.dateNotAllowed = "This date can't be chosen",
    this.endBeforeStart = 'The end comes before the start',
    this.outOfYears = _outOfYears,
    this.goToYear = _goToYear,
    this.selectTime = 'Select time',
    this.enterTime = 'Enter time',
    this.am = 'AM',
    this.pm = 'PM',
    this.period = 'AM or PM',
    this.hour = 'Hour',
    this.minute = 'Minute',
    this.selectHour = 'Select hour',
    this.selectMinute = 'Select minutes',
    this.toKeyboard = 'Type the time',
    this.toDial = 'Pick on the dial',
    this.toScroll = 'Scroll to the time',
    this.badHour = 'Enter a valid hour',
    this.badMinute = 'Enter a valid minute',
    this.hours = _hours,
    this.oClock = _oClock,
    this.minutes = _minutes,
    this.breadcrumbs = 'Breadcrumbs',
    this.moreBreadcrumbs = 'Show the folded steps',
    this.pagination = 'Pagination',
    this.goToPage = _goToPage,
    this.pageOf = _carouselPage,
    this.chartEmpty = 'No data yet',
    this.fileInput = 'File input',
    this.chooseFiles = 'Choose files',
    this.removeFile = _removeFile,
    this.selectPage = 'Select every row on this page',
    this.selectRow = 'Select row',
    this.colorHex = 'Hex',
  }) : _shared = const DefaultDesignLocalizations();

  /// [own]'s words, with [_shared] for the words every look shares.
  ExpressiveLocalizations._bound(ExpressiveLocalizations own, this._shared)
    : cancelSearch = own.cancelSearch,
      showSuggestions = own.showSuggestions,
      hideSuggestions = own.hideSuggestions,
      sheetDragHandle = own.sheetDragHandle,
      toolbarExpand = own.toolbarExpand,
      toolbarCollapse = own.toolbarCollapse,
      fabMenu = own.fabMenu,
      toastDismiss = own.toastDismiss,
      tryAgain = own.tryAgain,
      reorder = own.reorder,
      quantity = own.quantity,
      messageSending = own.messageSending,
      messageSent = own.messageSent,
      messageRead = own.messageRead,
      messageFailed = own.messageFailed,
      messageFromYou = own.messageFromYou,
      removeChip = own.removeChip,
      rated = own.rated,
      rate = own.rate,
      codeInput = own.codeInput,
      decrease = own.decrease,
      increase = own.increase,
      stepOf = own.stepOf,
      allStepsDone = own.allStepsDone,
      selectDate = own.selectDate,
      selectDates = own.selectDates,
      enterDates = own.enterDates,
      selectedDate = own.selectedDate,
      enteredDate = own.enteredDate,
      startDate = own.startDate,
      endDate = own.endDate,
      date = own.date,
      datePattern = own.datePattern,
      inRange = own.inRange,
      toDateInput = own.toDateInput,
      toCalendar = own.toCalendar,
      toYears = own.toYears,
      toDays = own.toDays,
      badDatePattern = own.badDatePattern,
      dateNotAllowed = own.dateNotAllowed,
      endBeforeStart = own.endBeforeStart,
      outOfYears = own.outOfYears,
      goToYear = own.goToYear,
      selectTime = own.selectTime,
      enterTime = own.enterTime,
      am = own.am,
      pm = own.pm,
      period = own.period,
      hour = own.hour,
      minute = own.minute,
      selectHour = own.selectHour,
      selectMinute = own.selectMinute,
      toKeyboard = own.toKeyboard,
      toDial = own.toDial,
      toScroll = own.toScroll,
      badHour = own.badHour,
      badMinute = own.badMinute,
      hours = own.hours,
      oClock = own.oClock,
      minutes = own.minutes,
      breadcrumbs = own.breadcrumbs,
      moreBreadcrumbs = own.moreBreadcrumbs,
      pagination = own.pagination,
      goToPage = own.goToPage,
      pageOf = own.pageOf,
      chartEmpty = own.chartEmpty,
      fileInput = own.fileInput,
      chooseFiles = own.chooseFiles,
      removeFile = own.removeFile,
      selectPage = own.selectPage,
      selectRow = own.selectRow,
      colorHex = own.colorHex;

  /// The defaults.
  static const ExpressiveLocalizations english = ExpressiveLocalizations();

  /// Loads [english] for an English locale, as `DefaultMaterialLocalizations`
  /// does: add it to an app's `localizationsDelegates`. Another language
  /// comes from a delegate of its own (see the class's example); with
  /// neither, [of] reads English.
  static const LocalizationsDelegate<ExpressiveLocalizations> delegate =
      _ExpressiveLocalizationsDelegate();

  /// The words in force at [context]: the look's own from the nearest
  /// [ExpressiveLocalizationsScope], else the app's localizations for its
  /// locale (a delegate's), else [english]; the shared ones from
  /// [DesignLocalizations.of] (English with none registered).
  static ExpressiveLocalizations of(BuildContext context) {
    final shared = DesignLocalizations.of(context);
    final own =
        context
            .dependOnInheritedWidgetOfExactType<ExpressiveLocalizationsScope>()
            ?.strings ??
        Localizations.of<ExpressiveLocalizations>(
          context,
          ExpressiveLocalizations,
        ) ??
        english;
    if (identical(own._shared, shared)) return own;
    final last = _bindings[own];
    if (last != null && identical(last._shared, shared)) return last;
    return _bindings[own] = ExpressiveLocalizations._bound(own, shared);
  }

  /// Each set of the look's own words, bound to the shared words last read
  /// with it, so a build reads one object.
  static final Expando<ExpressiveLocalizations> _bindings =
      Expando<ExpressiveLocalizations>('ExpressiveLocalizations');

  /// The words every look shares: ui_core's.
  final DesignLocalizations _shared;

  // Chrome.

  /// The back button, when no `MaterialLocalizations` are in scope
  /// ([DesignLocalizations.backButtonTooltip]).
  String get back => _shared.backButtonTooltip;

  /// The close button, when no `MaterialLocalizations` are in scope
  /// ([DesignLocalizations.closeButtonLabel]).
  String get close => _shared.closeButtonLabel;

  /// An overflow menu or a split button's menu half
  /// ([DesignLocalizations.splitButtonMenuLabel]).
  String get moreOptions => _shared.splitButtonMenuLabel;

  /// A search bar's placeholder and its field's label
  /// ([DesignLocalizations.searchFieldLabel]).
  String get search => _shared.searchFieldLabel;

  /// The expanded search view's leading back button.
  final String cancelSearch;

  /// The expanded search view's clear button
  /// ([DesignLocalizations.clearButtonTooltip]).
  String get clearSearch => _shared.clearButtonTooltip;

  /// A password field's reveal toggle, while hidden
  /// ([DesignLocalizations.showPasswordLabel]).
  String get showPassword => _shared.showPasswordLabel;

  /// A password field's reveal toggle, while shown
  /// ([DesignLocalizations.hidePasswordLabel]).
  String get hidePassword => _shared.hidePasswordLabel;

  /// A select field's menu toggle, while closed.
  final String showSuggestions;

  /// A select field's menu toggle, while open.
  final String hideSuggestions;

  /// A sheet's drag handle (Compose `Strings.BottomSheetDragHandleDescription`).
  final String sheetDragHandle;

  /// A sheet's dismiss action (Compose `Strings.BottomSheetDismissDescription`)
  /// ([DesignLocalizations.modalBarrierDismissLabel]).
  String get sheetDismiss => _shared.modalBarrierDismissLabel;

  /// A sheet's expand action (Compose `Strings.BottomSheetExpandDescription`)
  /// ([DesignLocalizations.collapsedIconTapHint]).
  String get sheetExpand => _shared.collapsedIconTapHint;

  /// A sheet's collapse action (Compose
  /// `Strings.BottomSheetPartialExpandDescription`)
  /// ([DesignLocalizations.expandedIconTapHint]).
  String get sheetCollapse => _shared.expandedIconTapHint;

  /// A floating toolbar's expand action.
  final String toolbarExpand;

  /// A floating toolbar's collapse action.
  final String toolbarCollapse;

  /// A FAB menu's list.
  final String fabMenu;

  /// A snackbar's close button (Compose `Strings.SnackbarDismiss`).
  final String toastDismiss;

  // Feedback and content.

  /// Pull-to-refresh while it refreshes
  /// ([DesignLocalizations.refreshingMessage]).
  String get refreshing => _shared.refreshingMessage;

  /// The loading screen state's message
  /// ([DesignLocalizations.loadingLabel]).
  String get loading => _shared.loadingLabel;

  /// The error screen state's retry action.
  final String tryAgain;

  /// A reorderable row's handle.
  final String reorder;

  /// A swipe-to-dismiss row's action
  /// ([DesignLocalizations.deleteButtonTooltip]).
  String get delete => _shared.deleteButtonTooltip;

  /// A range slider's start thumb
  /// ([DesignLocalizations.rangeSliderStartLabel]).
  String get rangeStart => _shared.rangeSliderStartLabel;

  /// A range slider's end thumb
  /// ([DesignLocalizations.rangeSliderEndLabel]).
  String get rangeEnd => _shared.rangeSliderEndLabel;

  /// A quantity stepper's value.
  final String quantity;

  /// A chat message still sending.
  final String messageSending;

  /// A chat message sent.
  final String messageSent;

  /// A chat message read.
  final String messageRead;

  /// A chat message that failed.
  final String messageFailed;

  /// Who sent an outgoing chat message.
  final String messageFromYou;

  /// An input chip's remove button, for the chip's [label].
  final String Function(String label) removeChip;

  /// A read-only rating: [value] (already formatted) of [max].
  final String Function(String value, int max) rated;

  /// A rating's star [index] of [max].
  final String Function(int index, int max) rate;

  /// A carousel's page indicator: page [page] (1-based) of [count]
  /// ([DesignLocalizations.carouselSlideLabel]).
  String carouselPage(int page, int count) =>
      _shared.carouselSlideLabel(page - 1, count);

  /// A code input of [length] characters.
  final String Function(int length) codeInput;

  /// A quantity stepper's minus button, for what it counts ([label]).
  final String Function(String label) decrease;

  /// A quantity stepper's plus button, for what it counts ([label]).
  final String Function(String label) increase;

  /// A step indicator on step [step] (1-based) of [count].
  final String Function(int step, int count) stepOf;

  /// A step indicator past its last of [count] steps.
  final String Function(int count) allStepsDone;

  // Date pickers.

  /// A date picker's title.
  final String selectDate;

  /// A date range picker's title.
  final String selectDates;

  /// A date range picker's title while typing.
  final String enterDates;

  /// The headline's label for a picked date.
  final String selectedDate;

  /// The headline's label for a typed date.
  final String enteredDate;

  /// A range's start.
  final String startDate;

  /// A range's end.
  final String endDate;

  /// The day a week starts on in this locale ([DateTime.monday] …
  /// [DateTime.sunday]; English: Sunday), which the date pickers and the
  /// calendar show first unless given their own `firstDayOfWeek`
  /// ([DesignLocalizations.firstDayOfWeek]).
  int get firstDayOfWeek => _shared.firstDayOfWeek;

  /// A date field's label.
  final String date;

  /// A date field's placeholder.
  final String datePattern;

  /// Today's cell
  /// ([DesignLocalizations.currentDateLabel]).
  String get today => _shared.currentDateLabel;

  /// A cell inside a picked range.
  final String inRange;

  /// The mode toggle to typing.
  final String toDateInput;

  /// The mode toggle to the calendar.
  final String toCalendar;

  /// The year menu, closed.
  final String toYears;

  /// The year menu, open.
  final String toDays;

  /// The previous-month button
  /// ([DesignLocalizations.previousMonthTooltip]).
  String get previousMonth => _shared.previousMonthTooltip;

  /// The next-month button
  /// ([DesignLocalizations.nextMonthTooltip]).
  String get nextMonth => _shared.nextMonthTooltip;

  /// A typed date that does not parse.
  final String badDatePattern;

  /// A typed date the picker does not allow.
  final String dateNotAllowed;

  /// A typed range that ends before it starts.
  final String endBeforeStart;

  /// A typed date outside [first]–[last].
  final String Function(int first, int last) outOfYears;

  /// A year in the year grid.
  final String Function(int year) goToYear;

  /// A picker dialog's dismiss button
  /// ([DesignLocalizations.cancelButtonLabel]).
  String get cancel => _shared.cancelButtonLabel;

  /// A picker dialog's confirm button
  /// ([DesignLocalizations.okButtonLabel]).
  String get ok => _shared.okButtonLabel;

  // Time pickers.

  /// A time picker's title.
  final String selectTime;

  /// A time picker's title while typing.
  final String enterTime;

  /// The morning period.
  final String am;

  /// The afternoon period.
  final String pm;

  /// The period selector.
  final String period;

  /// The hour field.
  final String hour;

  /// The minute field.
  final String minute;

  /// The hour dial or wheel.
  final String selectHour;

  /// The minute dial or wheel.
  final String selectMinute;

  /// The mode toggle to typing.
  final String toKeyboard;

  /// The mode toggle to the dial.
  final String toDial;

  /// The mode toggle to the wheels.
  final String toScroll;

  /// A typed hour out of range.
  final String badHour;

  /// A typed minute out of range.
  final String badMinute;

  /// A 24-hour dial number.
  final String Function(int hours) hours;

  /// A 12-hour dial number.
  final String Function(int hour) oClock;

  /// A minute dial number.
  final String Function(int minutes) minutes;

  // Wayfinding.

  /// What a screen reader calls a breadcrumb trail.
  final String breadcrumbs;

  /// A breadcrumb trail's button for the steps it folds.
  final String moreBreadcrumbs;

  /// What a screen reader calls a pagination control.
  final String pagination;

  /// Pagination's previous-page button
  /// ([DesignLocalizations.previousPageTooltip]).
  String get previousPage => _shared.previousPageTooltip;

  /// Pagination's next-page button
  /// ([DesignLocalizations.nextPageTooltip]).
  String get nextPage => _shared.nextPageTooltip;

  /// Pagination's button for page [page] (1-based).
  final String Function(int page) goToPage;

  /// Where pagination stands: page [page] (1-based) of [count].
  final String Function(int page, int count) pageOf;

  // Data and files.

  /// A chart with no points.
  final String chartEmpty;

  /// What a screen reader calls a file input's drop area.
  final String fileInput;

  /// A file input's button that opens the platform's picker.
  final String chooseFiles;

  /// A chosen file's remove button, for its [name].
  final String Function(String name) removeFile;

  // Behaviours from ui_core.

  /// A search with no match (the command palette's results)
  /// ([DesignLocalizations.noResultsLabel]).
  String get noResults => _shared.noResultsLabel;

  /// A split view's divider, to assistive technology
  /// ([DesignLocalizations.splitViewHandleLabel]).
  String get resize => _shared.splitViewHandleLabel;

  /// A multi-select chip's remove action, before the chip's label
  /// ([DesignLocalizations.tagInputDeleteLabel]).
  String get removeTag => _shared.tagInputDeleteLabel;

  /// A data table's select-all checkbox.
  final String selectPage;

  /// A data table row's checkbox.
  final String selectRow;

  /// The colour picker's hex field.
  final String colorHex;
}

String _goToPage(int page) => 'Go to page $page';
String _removeFile(String name) => 'Remove $name';

String _removeChip(String label) => 'Remove $label';
String _rated(String value, int max) => 'Rated $value of $max';
String _rate(int index, int max) => 'Rate $index of $max';
String _carouselPage(int page, int count) => 'Page $page of $count';
String _codeInput(int length) => 'Code, $length characters';
String _decrease(String label) => 'Decrease $label';
String _increase(String label) => 'Increase $label';
String _stepOf(int step, int count) => 'Step $step of $count';
String _allStepsDone(int count) => 'All $count steps done';
String _outOfYears(int first, int last) => 'Pick a year from $first to $last';
String _goToYear(int year) => 'Go to $year';
String _hours(int n) => '$n hours';
String _oClock(int n) => "$n o'clock";
String _minutes(int n) => '$n minutes';

/// Gives its subtree [strings] in place of the ones above it (a host's
/// translation, or a product's own wording).
class ExpressiveLocalizationsScope extends InheritedWidget {
  /// Scopes [strings] to [child].
  const ExpressiveLocalizationsScope({
    required this.strings,
    required super.child,
    super.key,
  });

  /// The strings below this widget.
  final ExpressiveLocalizations strings;

  @override
  bool updateShouldNotify(ExpressiveLocalizationsScope oldWidget) =>
      !identical(strings, oldWidget.strings);
}

class _ExpressiveLocalizationsDelegate
    extends LocalizationsDelegate<ExpressiveLocalizations> {
  const _ExpressiveLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'en';

  @override
  Future<ExpressiveLocalizations> load(Locale locale) =>
      SynchronousFuture<ExpressiveLocalizations>(
        ExpressiveLocalizations.english,
      );

  @override
  bool shouldReload(_ExpressiveLocalizationsDelegate old) => false;
}
