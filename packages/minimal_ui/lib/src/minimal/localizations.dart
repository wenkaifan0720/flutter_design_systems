/// Every word Minimal's parts say on their own: a back and a close, a
/// loading line, a search field's hint, a date picker's months. A part
/// takes the caller's words when given and these otherwise.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

// The words every look shares are ui_core's: an app translates them by
// extending DefaultDesignLocalizations, so they are exported with the
// package.
export 'package:ui_core/ui_core.dart'
    show DefaultDesignLocalizations, DesignLocalizations;

/// The words Minimal's parts say when the caller gives none.
///
/// The words every look shares (Back, Close, Search, Today, Next month,
/// the month and weekday names, the first day of the week) come from
/// [DesignLocalizations.of]: an app in another language extends
/// [DefaultDesignLocalizations], overrides the words it translates and adds
/// a delegate for it to `localizationsDelegates`, and every part speaks
/// them. The words only Minimal says (Try again, Copy, the composer's
/// buttons) are English in 0.1.0.
///
/// ```dart
/// Text(MinimalLocalizations.of(context).back)
/// ```
abstract class MinimalLocalizations {
  /// Const constructor, for subclasses.
  const MinimalLocalizations();

  /// The words in force at [context]: the shared words of
  /// [DesignLocalizations.of], and Minimal's own in English.
  static MinimalLocalizations of(BuildContext context) =>
      MinimalLocalizationsEn(DesignLocalizations.of(context));

  /// A month and its year, as a calendar heads its grid ("August 2026").
  String monthYear(DateTime month);

  /// A day in full, as a screen reader hears a calendar's day
  /// ("Friday, 28 August 2026").
  String fullDate(DateTime day);

  /// A top bar's way back a page.
  String get back;

  /// What closes a raised card: a sheet, a page raised as one.
  String get close;

  /// What a scrim is called: a tap on it dismisses.
  String get dismiss;

  /// The loading state's line, and what a screen reader hears meanwhile.
  String get loading;

  /// The error state's way to try again.
  String get tryAgain;

  /// A search field's hint.
  String get search;

  /// A search field's clear glyph.
  String get clearSearch;

  /// A text field's clear glyph, for the field [name] names (null: "text").
  String clear(String? name);

  /// A search's or a picker's way out without a change.
  String get cancel;

  /// A picker's confirming button.
  String get done;

  /// A dialog's confirming button, when the caller names none.
  String get ok;

  /// A select's prompt.
  String get choose;

  /// A menu's trigger, when the caller names none.
  String get moreActions;

  /// An anchored menu's name, when the caller gives none.
  String get actions;

  /// The shell's create action, when the app names none.
  String get create;

  /// A stepper's name, when the caller gives none.
  String get quantity;

  /// A stepper's two buttons, for the value [name] names.
  String decrease(String name);

  /// A stepper's more button.
  String increase(String name);

  /// A swipe's destructive act.
  String get delete;

  /// An empty table's line.
  String get noRows;

  /// An empty activity feed's line.
  String get noActivity;

  /// An empty property's placeholder.
  String get empty;

  /// An action bar's busy line.
  String get working;

  /// A code block's copy button.
  String get copy;

  /// What a copy confirms.
  String get copied;

  /// A code block's name, after its [language] when given.
  String code(String? language);

  /// A key cap chord's name, its [keys] spoken.
  String shortcut(String keys);

  /// A breadcrumb trail's name.
  String get breadcrumb;

  /// A bar of a bar chart with no name, by its [position] from 1.
  String bar(int position);

  /// A heatmap legend's two ends.
  String get less;

  /// A heatmap legend's far end.
  String get more;

  /// A search scope menu's name.
  String get searchScope;

  /// A search field's filters button, with filters on or off.
  String filters({required bool active});

  /// The command palette's sheet title.
  String get commands;

  /// The command palette's search hint.
  String get commandHint;

  /// The command palette's empty title.
  String get noMatchingCommands;

  /// The command palette's empty line, for what was typed.
  String nothingMatches(String query);

  /// A composer's hint: a message, or a comment to the assistant.
  String composerHint({required bool assistant});

  /// A composer's attach button.
  String get addAttachment;

  /// An attachment's remove button.
  String get removeAttachment;

  /// A composer's stop button while the assistant answers.
  String get stopResponse;

  /// A composer's voice button.
  String get voiceMessage;

  /// A composer's dictation button.
  String get dictateMessage;

  /// A composer's send button.
  String get sendMessage;

  /// A sign-in button, for the [provider] it names.
  String continueWith(String provider);

  /// A date picker's step back a month.
  String get previousMonth;

  /// A date picker's step on a month.
  String get nextMonth;

  /// A time picker's hours column.
  String get hour;

  /// A time picker's minutes column.
  String get minute;

  /// The months, January first.
  List<String> get months;

  /// The months in three letters, January first.
  List<String> get monthsShort;

  /// The weekdays, Monday first.
  List<String> get weekdays;

  /// The weekdays in two letters, Monday first: a calendar's head.
  List<String> get weekdaysShort;

  /// The day a week starts on here ([DateTime.monday] … [DateTime.sunday]),
  /// which a calendar and a date picker show first unless told otherwise:
  /// Sunday in English.
  int get firstDayOfWeek;

  /// A day relative to today: today, yesterday, tomorrow, or [days] on.
  String relativeDay(int days);

  /// A pagination's step back.
  String get previousPage;

  /// A pagination's step on.
  String get nextPage;

  /// A page's place: page [page] of [count] (both from 1).
  String pageOf(int page, int count);

  /// A step's place in a step progress: step [step] of [count] (from 1).
  String stepOf(int step, int count);

  /// A finished step, after its name.
  String get completed;

  /// The step being worked on, after its name.
  String get current;

  /// A rating's value: [value] of [max].
  String ratingOf(String value, int max);

  /// A file's remove button, for the file [name] names.
  String removeFile(String name);

  /// An inline alert's close button.
  String get dismissAlert;

  /// A chart's line with no data.
  String get noData;

  /// A disclosure's state, said after its title.
  String expandedState({required bool expanded});

  /// A password field's button that shows the password.
  String get showPassword;

  /// A password field's button that hides it again.
  String get hidePassword;

  /// What a screen reader calls a one-time code field.
  String get oneTimeCode;

  /// A tag's remove button, for the tag [name] names.
  String removeItem(String name);

  /// What a screen reader calls a tag's remove action.
  String get remove;

  /// A range slider's lower thumb, after its label.
  String get minimum;

  /// A range slider's upper thumb, after its label.
  String get maximum;

  /// What a screen reader calls a colour picker's hex field.
  String get hexColour;

  /// A required field's hint, after its label.
  String get required;

  /// Said when a form is sent with [count] fields still wrong.
  String fieldsNeedAttention(int count);

  /// What a screen reader calls a menu bar.
  String get menuBar;

  /// A sorted column's hint.
  String get sortedAscending;

  /// A column sorted the other way.
  String get sortedDescending;

  /// A data table's select-all box.
  String get selectAllRows;

  /// A data table's pager: rows [first] to [last] of [count].
  String rowsOf(int first, int last, int count);

  /// What a screen reader calls a divider that resizes two panes.
  String get resize;

  /// What a screen reader calls a carousel.
  String get carousel;

  /// A carousel's slide [index] (from 0) of [count].
  String slideOf(int index, int count);

  /// A carousel's step back.
  String get previousSlide;

  /// A carousel's step on.
  String get nextSlide;

  /// A carousel's pause.
  String get pause;

  /// A carousel's play.
  String get play;

  /// A reorderable row's grip.
  String get reorder;

  /// Said when [label] moved to [position] of [count] (from 1).
  String movedTo(String label, int position, int count);

  /// A list's refresh action.
  String get refresh;

  /// Said when a refresh starts.
  String get refreshing;

  /// Said when it is done.
  String get refreshed;

  /// A tree row's place: [level] (from 1), [position] of [count].
  String treeLevel(int level, int position, int count);

  /// What a screen reader calls the toasts' region.
  String get notifications;

  /// Said when a palette's results change: how many match.
  String results(int count);
}

/// Minimal's words: the [shared] ones from ui_core, Minimal's own in
/// English.
class MinimalLocalizationsEn extends MinimalLocalizations {
  /// The words over [shared], English unless given.
  const MinimalLocalizationsEn([
    this.shared = const DefaultDesignLocalizations(),
  ]);

  /// The words every look shares, in the app's language.
  final DesignLocalizations shared;

  @override
  String monthYear(DateTime month) => shared.formatMonthYear(month);
  @override
  String fullDate(DateTime day) => shared.formatFullDate(day);

  @override
  String get back => shared.backButtonTooltip;
  @override
  String get close => shared.closeButtonLabel;
  @override
  String get dismiss => shared.modalBarrierDismissLabel;
  @override
  String get loading => shared.loadingLabel;
  @override
  String get tryAgain => 'Try again';
  @override
  String get search => shared.searchFieldLabel;
  @override
  String get clearSearch => shared.clearButtonTooltip;
  @override
  String clear(String? name) => 'Clear ${name ?? 'text'}';
  @override
  String get cancel => shared.cancelButtonLabel;
  @override
  String get done => 'Done';
  @override
  String get ok => shared.okButtonLabel;
  @override
  String get choose => 'Choose';
  @override
  String get moreActions => shared.moreButtonTooltip;
  @override
  String get actions => 'Actions';
  @override
  String get create => 'New';
  @override
  String get quantity => 'Quantity';
  @override
  String decrease(String name) => 'Decrease $name';
  @override
  String increase(String name) => 'Increase $name';
  @override
  String get delete => shared.deleteButtonTooltip;
  @override
  String get noRows => 'No rows';
  @override
  String get noActivity => 'No activity yet';
  @override
  String get empty => 'Empty';
  @override
  String get working => 'Working…';
  @override
  String get copy => 'Copy';
  @override
  String get copied => 'Copied to clipboard';
  @override
  String code(String? language) => language == null ? 'Code' : '$language code';
  @override
  String shortcut(String keys) => 'Shortcut $keys';
  @override
  String get breadcrumb => 'Breadcrumb';
  @override
  String bar(int position) => 'Bar $position';
  @override
  String get less => 'Less';
  @override
  String get more => 'More';
  @override
  String get searchScope => 'Search scope';
  @override
  String filters({required bool active}) =>
      active ? 'Filters, active' : 'Filters';
  @override
  String get commands => shared.commandPaletteLabel;
  @override
  String get commandHint => 'Type a command or search';
  @override
  String get noMatchingCommands => shared.noResultsLabel;
  @override
  String nothingMatches(String query) => 'Nothing matches “$query”.';
  @override
  String composerHint({required bool assistant}) =>
      assistant ? 'Leave a comment…' : 'Message';
  @override
  String get addAttachment => 'Add attachment';
  @override
  String get removeAttachment => 'Remove attachment';
  @override
  String get stopResponse => 'Stop response';
  @override
  String get voiceMessage => 'Voice message';
  @override
  String get dictateMessage => 'Dictate message';
  @override
  String get sendMessage => 'Send message';
  @override
  String continueWith(String provider) => 'Continue with $provider';
  @override
  String get previousMonth => shared.previousMonthTooltip;
  @override
  String get nextMonth => shared.nextMonthTooltip;
  @override
  String get hour => 'Hour';
  @override
  String get minute => 'Minute';
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
  List<String> get monthsShort => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  @override
  List<String> get weekdays => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  @override
  List<String> get weekdaysShort => [
    for (var day = DateTime.monday; day <= DateTime.sunday; day++)
      shared.formatShortWeekday(day),
  ];
  @override
  int get firstDayOfWeek => shared.firstDayOfWeek;
  @override
  String relativeDay(int days) => switch (days) {
    0 => shared.currentDateLabel,
    -1 => 'Yesterday',
    1 => 'Tomorrow',
    _ when days > 1 && days < 7 => 'In $days days',
    _ when days < -1 && days > -7 => '${-days} days ago',
    _ => '',
  };
  @override
  String get previousPage => shared.previousPageTooltip;
  @override
  String get nextPage => shared.nextPageTooltip;
  @override
  String pageOf(int page, int count) => 'Page $page of $count';
  @override
  String stepOf(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get completed => 'completed';
  @override
  String get current => 'current';
  @override
  String ratingOf(String value, int max) => '$value of $max';
  @override
  String removeFile(String name) => 'Remove $name';
  @override
  String get dismissAlert => shared.closeButtonLabel;
  @override
  String get noData => 'No data';
  @override
  String expandedState({required bool expanded}) =>
      expanded ? 'expanded' : 'collapsed';
  @override
  String get showPassword => shared.showPasswordLabel;
  @override
  String get hidePassword => shared.hidePasswordLabel;
  @override
  String get oneTimeCode => 'One-time code';
  @override
  String removeItem(String name) => 'Remove $name';
  @override
  String get remove => shared.tagInputDeleteLabel;
  @override
  String get minimum => shared.rangeSliderStartLabel;
  @override
  String get maximum => shared.rangeSliderEndLabel;
  @override
  String get hexColour => 'Hex colour';
  @override
  String get required => shared.requiredHint;
  @override
  String fieldsNeedAttention(int count) => shared.formProblemsMessage(count);
  @override
  String get menuBar => shared.menuBarLabel;
  @override
  String get sortedAscending =>
      shared.dataTableSortedHint(DesignSortDirection.ascending);
  @override
  String get sortedDescending =>
      shared.dataTableSortedHint(DesignSortDirection.descending);
  @override
  String get selectAllRows => 'Select all rows';
  @override
  String rowsOf(int first, int last, int count) => '$first–$last of $count';
  @override
  String get resize => shared.splitViewHandleLabel;
  @override
  String get carousel => shared.carouselLabel;
  @override
  String slideOf(int index, int count) =>
      shared.carouselSlideLabel(index, count);
  @override
  String get previousSlide => 'Previous slide';
  @override
  String get nextSlide => 'Next slide';
  @override
  String get pause => 'Pause';
  @override
  String get play => 'Play';
  @override
  String get reorder => 'Reorder';
  @override
  String movedTo(String label, int position, int count) =>
      shared.reorderableListMovedMessage(label, position, count);
  @override
  String get refresh => shared.refreshLabel;
  @override
  String get refreshing => shared.refreshingMessage;
  @override
  String get refreshed => shared.refreshedMessage;
  @override
  String treeLevel(int level, int position, int count) =>
      shared.treeLevelHint(level, position, count);
  @override
  String get notifications => shared.toasterRegionLabel;
  @override
  String results(int count) => shared.commandPaletteResultsMessage(count);
}
