/// The gallery's Arabic. While the gallery reads right to left it speaks
/// Arabic: the three apps' words, their people and their goods, and the
/// words Minimal says on its own (ui_core's from its own Arabic), so the right-to-left mode
/// shows real Arabic rather than English reordered by bidi ("8 of 12
/// packed" read as "of 12 packed 8"). Ids, codes, times and money stay as
/// written (ENG-142, #1042, 09:30, €3.40): they read left to right inside
/// the Arabic line, as they do in an Arabic app.
library;

import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

/// Whether the gallery speaks Arabic; the gallery sets it from its reading
/// direction before it builds a page or an app.
bool kitArabic = false;

/// [english], or [arabic] while the gallery speaks Arabic.
String ar(String english, String arabic) => kitArabic ? arabic : english;

/// A streak or a span in days, as a row's meta column prints it: `12d`,
/// `12 ي`.
String kitDays(int days) => kitArabic ? '$days ي' : '${days}d';

/// The months and weekdays in Arabic, January and Monday first.
const List<String> _arMonths = <String>[
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

const List<String> _arWeekdays = <String>[
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// The words only Minimal says, in Arabic, over ui_core's own Arabic.
class KitArabicWords extends MinimalLocalizationsEn {
  /// Minimal's words in Arabic, ui_core's from its Arabic translation.
  KitArabicWords() : super(DesignLocalizations.forLocale(const Locale('ar')));

  @override
  String get tryAgain => 'حاول مرة أخرى';
  @override
  String clear(String? name) => name == null ? 'مسح النص' : 'مسح $name';
  @override
  String get done => 'تم';
  @override
  String get choose => 'اختر';
  @override
  String get actions => 'إجراءات';
  @override
  String get create => 'جديد';
  @override
  String get quantity => 'الكمية';
  @override
  String decrease(String name) => 'إنقاص $name';
  @override
  String increase(String name) => 'زيادة $name';
  @override
  String get noRows => 'لا صفوف';
  @override
  String get noActivity => 'لا نشاط بعد';
  @override
  String get empty => 'فارغ';
  @override
  String get working => 'جارٍ العمل…';
  @override
  String get copy => 'نسخ';
  @override
  String get copied => 'نُسخ إلى الحافظة';
  @override
  String shortcut(String keys) => 'اختصار $keys';
  @override
  String get breadcrumb => 'مسار التنقل';
  @override
  String get less => 'أقل';
  @override
  String get more => 'المزيد';
  @override
  String get searchScope => 'نطاق البحث';
  @override
  String filters({required bool active}) =>
      active ? 'عوامل التصفية، مفعّلة' : 'عوامل التصفية';
  @override
  String get commandHint => 'اكتب أمرًا أو ابحث';
  @override
  String nothingMatches(String query) => 'لا شيء يطابق «$query».';
  @override
  String composerHint({required bool assistant}) =>
      assistant ? 'اترك تعليقًا…' : 'رسالة';
  @override
  String get sendMessage => 'إرسال الرسالة';
  @override
  String get hour => 'الساعة';
  @override
  String get minute => 'الدقيقة';
  @override
  List<String> get months => _arMonths;
  @override
  List<String> get monthsShort => _arMonths;
  @override
  List<String> get weekdays => _arWeekdays;
  @override
  List<String> get weekdaysShort => _arWeekdays;
  @override
  String relativeDay(int days) => switch (days) {
    -1 => 'أمس',
    1 => 'غدًا',
    2 => 'بعد يومين',
    _ when days > 2 && days < 7 => 'بعد $days أيام',
    -2 => 'قبل يومين',
    _ when days < -2 && days > -7 => 'قبل ${-days} أيام',
    _ => '',
  };
  @override
  String pageOf(int page, int count) => 'الصفحة $page من $count';
  @override
  String stepOf(int step, int count) => 'الخطوة $step من $count';
  @override
  String get completed => 'مكتملة';
  @override
  String get current => 'الحالية';
  @override
  String ratingOf(String value, int max) => '$value من $max';
  @override
  String get noData => 'لا بيانات';
  @override
  String expandedState({required bool expanded}) => expanded ? 'موسّع' : 'مطوي';
  @override
  String removeItem(String name) => 'إزالة $name';
  @override
  String rowsOf(int first, int last, int count) => '$first–$last من $count';
  @override
  String get reorder => 'إعادة الترتيب';
  @override
  String get taskBacklog => 'مؤجلة';
  @override
  String get taskTodo => 'للتنفيذ';
  @override
  String get taskActive => 'قيد التنفيذ';
  @override
  String get taskDone => 'منجزة';
  @override
  String get taskPaused => 'متوقفة';
  @override
  String get taskCancelled => 'ملغاة';
  @override
  String get priorityUrgent => 'عاجلة';
  @override
  String get priorityHigh => 'عالية';
  @override
  String get priorityMedium => 'متوسطة';
  @override
  String get priorityLow => 'منخفضة';
  @override
  String get priorityNone => 'بلا أولوية';
  @override
  String priorityNamed(String priority) => 'أولوية $priority';
}
