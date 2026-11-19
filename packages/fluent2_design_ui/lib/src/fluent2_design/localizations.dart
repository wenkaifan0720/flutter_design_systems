// The words only Fluent 2's parts say on their own: a retry, a send, a picker's hint, a page count. The words every
// look shares (Cancel, Close, Today, Loading) come from ui_core's DesignLocalizations, and so do English's time words
// (a time picker's hour and minute, AM and PM), so they follow the app's locale in ui_core's 30 languages. A part takes the caller's words
// when given and these otherwise, so an app in another language installs a delegate for each and every part speaks it.
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The words only Fluent 2's parts say when the caller gives none; the words
/// every look shares (Cancel, Close, Today) are `DesignLocalizations`'.
/// English ships ([Fluent2LocalizationsEn]); another language is a subclass
/// and a delegate that loads it, listed before [delegate] (the first delegate
/// for a locale wins). With no delegate installed, the parts speak English.
///
/// ```dart
/// MaterialApp(localizationsDelegates: const [Fluent2Localizations.delegate], home: home)
/// ```
abstract class Fluent2Localizations {
  /// Const constructor, for subclasses.
  const Fluent2Localizations();

  /// The words in force at [context]: the installed delegate's, else English.
  /// English's time words ([hour], [minute], [am], [pm]) are those of the
  /// `DesignLocalizations` in force at [context], so a time picker speaks the
  /// app's language wherever ui_core has it.
  static Fluent2Localizations of(BuildContext context) {
    final words = Localizations.of<Fluent2Localizations>(
      context,
      Fluent2Localizations,
    );
    if (words != null && !identical(words, const Fluent2LocalizationsEn())) {
      return words;
    }
    return Fluent2LocalizationsEn._time(DesignLocalizations.of(context));
  }

  /// Loads Fluent 2's English words in any locale, so an app in another
  /// language installs it without a warning and its parts speak English
  /// until it gives them words of its own.
  static const LocalizationsDelegate<Fluent2Localizations> delegate =
      _Fluent2LocalizationsDelegate();

  /// What goes back to the page called [where].
  String backTo(String where);

  /// What dismisses a notice or a bar.
  String get dismiss;

  /// The error state's way to try again.
  String get tryAgain;

  /// A message's send button.
  String get send;

  /// A composer's attachment button.
  String get attachFile;

  /// A composer's emoji button.
  String get emoji;

  /// The overflow half of a split button for [label].
  String moreOptionsFor(String label);

  /// A button's hint that it opens a menu.
  String get opensMenu;

  /// A select's hint that it opens a list.
  String get opensList;

  /// A date field's hint that it opens a calendar.
  String get opensCalendar;

  /// A search bar's hint that it opens search.
  String get opensSearch;

  /// A search bar's filter button.
  String get filters;

  /// A removable tag's button for [label].
  String remove(String label);

  /// A removable tag's screen-reader action.
  String get removeAction;

  /// An info button beside the field [label].
  String informationAbout(String label);

  /// A new item's dot, to a screen reader.
  String get newItem;

  /// A table's select-all box.
  String get selectAllRows;

  /// A table row's box, for the row called [label].
  String selectRow(String label);

  /// A table's generic word for an unnamed row.
  String get row;

  /// A sortable column's header.
  String sortBy(String column);

  /// A folded breadcrumb's button.
  String get morePlaces;

  /// A folded breadcrumb's name, with how many places it holds.
  String morePlacesCount(int count);

  /// A breadcrumb's last item.
  String currentPage(String label);

  /// A teaching popover's step.
  String stepOf(int step, int steps);

  /// The notifications region (F6 reaches it).
  String get notifications;

  /// A nav pane's account button, named [name].
  String accountSettings(String name);

  /// An app bar's account button.
  String get profileAndSettings;

  /// A page's number in a pager.
  String pageNumber(int page);

  /// A pager's or stepper's place, [page] of [count].
  String pageOf(int page, int count);

  /// A number stepper's more button.
  String get increase;

  /// A number stepper's less button.
  String get decrease;

  /// A time picker's title.
  String get chooseTime;

  /// A date picker's title.
  String get chooseDate;

  /// A date range picker's title.
  String get chooseDates;

  /// A time picker's hour.
  String get hour;

  /// A time picker's minute.
  String get minute;

  /// The morning half of a twelve-hour clock.
  String get am;

  /// The afternoon half of a twelve-hour clock.
  String get pm;

  /// A file drop zone's words.
  String get dropFiles;

  /// A file drop zone's button.
  String get browseFiles;

  /// A file's remove button, for the file called [name].
  String removeFile(String name);

  /// A colour picker's name for the hex field.
  String get hexColor;

  /// A carousel's previous slide.
  String get previousSlide;

  /// A carousel's next slide.
  String get nextSlide;

  /// A reorderable row's handle.
  String get reorder;

  /// A field's menu: cut the selection.
  String get cut;

  /// A field's menu: copy the selection.
  String get copy;

  /// A field's menu: paste.
  String get paste;

  /// A field's menu: select everything.
  String get selectAll;

  /// A field's menu: look the selection up.
  String get lookUp;

  /// A field's menu: search the web for the selection.
  String get searchWeb;

  /// A field's menu: share the selection.
  String get share;

  /// A field's menu: scan text with the camera.
  String get scanText;

  /// A carousel's play button.
  String get play;

  /// A carousel's pause button.
  String get pause;

  /// A chart's folded rest.
  String get other;

  /// A menu's name when it has no title.
  String get menu;

  /// A tree's and a popover's name when it has no title.
  String get popover;

  /// A select's words before anything is chosen.
  String get selectAnOption;

  /// A date field's words before a date is chosen.
  String get selectADate;

  /// A tag picker's empty words.
  String get addPeople;

  /// A composer's empty words.
  String get typeAMessage;

  /// A composer's name.
  String get message;

  /// A toolbar's name.
  String get toolbar;

  /// A breadcrumb trail's name.
  String get breadcrumb;

  /// A progress indicator's name when it has none.
  String get progress;

  /// A sparkline's name when it has none.
  String get trend;

  /// A create button's name when it has none.
  String get create;

  /// A nav pane's button that widens it.
  String get expandNavigation;

  /// A nav pane's button that narrows it.
  String get collapseNavigation;

  /// A teaching popover's acknowledging button.
  String get gotIt;

  /// A teaching popover's scrim, to a screen reader.
  String get teachingTip;

  /// The notifications button with [count] unread.
  String notificationsUnread(int count);

  /// An info message's glyph, to a screen reader.
  String get information;

  /// A success message's glyph, to a screen reader.
  String get success;

  /// A warning message's glyph, to a screen reader.
  String get warning;

  /// An error message's glyph, to a screen reader.
  String get error;

  /// The day's name, for a [DateTime.weekday] (Monday is 1).
  List<String> get months;

  /// The three-letter months, January first.
  List<String> get monthsShort;

  /// Two-letter weekdays, Monday first.
  List<String> get weekdaysShort;

  /// [date] as a month and day ("Mar 4, 2026").
  String shortDate(DateTime date) =>
      '${monthsShort[date.month - 1]} ${date.day}, ${date.year}';

  /// [date] in full ("March 4, 2026").
  String fullDate(DateTime date) =>
      '${months[date.month - 1]} ${date.day}, ${date.year}';

  /// A month and year ("March 2026").
  String monthYear(DateTime date) => '${months[date.month - 1]} ${date.year}';

  // The counts below came in 0.2.1, with English bodies here, so a language
  // written for 0.2.0 still builds (and says these in English until it adds
  // its own). Each takes the count itself, for a language that picks its
  // plural form from it.

  /// A rating's score to a screen reader: [value] of [max] stars ("Rated 4.5
  /// out of 5").
  String ratedOutOf(String value, int max) => 'Rated $value out of $max';

  /// How many scores a rating is made of ("1 rating", "1,204 ratings"):
  /// [counted] is [count] as the locale writes its numbers.
  String ratingsCount(int count, String counted) =>
      count == 1 ? '$counted rating' : '$counted ratings';

  /// A rating input's value, [value] of [max] stars ("3 of 5").
  String ratingValue(String value, int max) => '$value of $max';

  /// An avatar group to a screen reader: the [names] it shows and the [more]
  /// it folds into its "+N" ("Ana, Kai and 3 more").
  String namesAndMore(String names, int more) => '$names and $more more';
}

/// Fluent 2's English words. As [Fluent2Localizations.of] gives them, their
/// time words ([hour], [minute], [am], [pm]) are ui_core's
/// `DesignLocalizations`', in the app's language. A subclass in another
/// language gives its own time words, or `DesignLocalizations`'
/// (`timePickerHourLabel`, `timePickerMinuteLabel`,
/// `anteMeridiemAbbreviation`, `postMeridiemAbbreviation`).
class Fluent2LocalizationsEn extends Fluent2Localizations {
  /// English.
  const Fluent2LocalizationsEn() : _shared = null;

  /// English with [shared]'s time words.
  const Fluent2LocalizationsEn._time(DesignLocalizations shared)
    : _shared = shared;

  /// The ui_core words the time words come from; English's own when null.
  final DesignLocalizations? _shared;

  @override
  String backTo(String where) => 'Back to $where';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get tryAgain => 'Try again';
  @override
  String get send => 'Send';
  @override
  String get attachFile => 'Attach a file';
  @override
  String get emoji => 'Emoji';
  @override
  String moreOptionsFor(String label) => 'More options for $label';
  @override
  String get opensMenu => 'Opens a menu';
  @override
  String get opensList => 'Opens a list';
  @override
  String get opensCalendar => 'Opens a calendar';
  @override
  String get opensSearch => 'Opens search';
  @override
  String get filters => 'Filters';
  @override
  String remove(String label) => 'Remove $label';
  @override
  String get removeAction => 'Remove';
  @override
  String informationAbout(String label) => 'Information about $label';
  @override
  String get newItem => 'New';
  @override
  String get selectAllRows => 'Select all rows';
  @override
  String selectRow(String label) => 'Select $label';
  @override
  String get row => 'row';
  @override
  String sortBy(String column) => 'Sort by $column';
  @override
  String get morePlaces => 'More places';
  @override
  String morePlacesCount(int count) => 'More places, $count';
  @override
  String currentPage(String label) => '$label, current page';
  @override
  String stepOf(int step, int steps) {
    return 'Step $step of $steps';
  }

  @override
  String get notifications => 'Notifications';
  @override
  String accountSettings(String name) => '$name, profile and settings';
  @override
  String get profileAndSettings => 'Profile and settings';
  @override
  String pageNumber(int page) => 'Page $page';
  @override
  String pageOf(int page, int count) => 'Page $page of $count';
  @override
  String get increase => 'Increase';
  @override
  String get decrease => 'Decrease';
  @override
  String get chooseTime => 'Choose a time';
  @override
  String get chooseDate => 'Choose a date';
  @override
  String get chooseDates => 'Choose dates';
  @override
  String get hour => _shared?.timePickerHourLabel ?? 'Hour';
  @override
  String get minute => _shared?.timePickerMinuteLabel ?? 'Minute';
  @override
  String get am => _shared?.anteMeridiemAbbreviation ?? 'AM';
  @override
  String get pm => _shared?.postMeridiemAbbreviation ?? 'PM';
  @override
  String get dropFiles => 'Drag files here';
  @override
  String get browseFiles => 'Browse files';
  @override
  String removeFile(String name) => 'Remove $name';
  @override
  String get hexColor => 'Hex';
  @override
  String get previousSlide => 'Previous slide';
  @override
  String get nextSlide => 'Next slide';
  @override
  String get reorder => 'Reorder';
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
  String get play => 'Play';
  @override
  String get pause => 'Pause';
  @override
  String get other => 'Other';
  @override
  String get menu => 'Menu';
  @override
  String get popover => 'Popover';
  @override
  String get selectAnOption => 'Select an option';
  @override
  String get selectADate => 'Select a date...';
  @override
  String get addPeople => 'Add people';
  @override
  String get typeAMessage => 'Type a message';
  @override
  String get message => 'Message';
  @override
  String get toolbar => 'Toolbar';
  @override
  String get breadcrumb => 'Breadcrumb';
  @override
  String get progress => 'Progress';
  @override
  String get trend => 'Trend';
  @override
  String get create => 'Create';
  @override
  String get expandNavigation => 'Expand navigation';
  @override
  String get collapseNavigation => 'Collapse navigation';
  @override
  String get gotIt => 'Got it';
  @override
  String get teachingTip => 'Teaching tip';
  @override
  String notificationsUnread(int count) => 'Notifications, $count unread';
  @override
  String get information => 'Information';
  @override
  String get success => 'Success';
  @override
  String get warning => 'Warning';
  @override
  String get error => 'Error';
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

class _Fluent2LocalizationsDelegate
    extends LocalizationsDelegate<Fluent2Localizations> {
  const _Fluent2LocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<Fluent2Localizations> load(Locale locale) =>
      SynchronousFuture<Fluent2Localizations>(const Fluent2LocalizationsEn());

  @override
  bool shouldReload(_Fluent2LocalizationsDelegate old) => false;
}
