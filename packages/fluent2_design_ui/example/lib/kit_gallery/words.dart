/// The gallery's words in Arabic, for its right-to-left mode: a page read
/// right to left shows a real right-to-left language (the demos' copy, and
/// the parts' own words through their localizations), not English
/// reordered by bidi. Left to right, every word stays as the demo writes it,
/// so the specimens and their goldens never change.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import 'kit.dart';

/// Whether the gallery reads right to left, and so speaks Arabic.
bool get kitArabic => kitShownDirection == TextDirection.rtl;

/// [english] as the gallery shows it: its Arabic when the gallery reads
/// right to left and the demo's words have one, else as written.
String kitW(String english) =>
    kitArabic ? (_arabic[english] ?? english) : english;

/// Fluent 2's own words in Arabic around [child] when the gallery reads
/// right to left; [child] alone otherwise. The words every look shares are
/// ui_core's own Arabic, loaded by the gallery's apps in their Arabic locale.
/// It keeps the app's locale, so Flutter's own words stay loaded; it goes
/// above the page's Directionality, which a Localizations sets from its own
/// words.
Widget kitWordsScope(BuildContext context, Widget child) => kitArabic
    ? Localizations.override(
        context: context,
        delegates: const [_Fluent2Arabic.delegate],
        child: child,
      )
    : child;

const Map<String, String> _arabic = {
  'Uploading Launch plan.docx': 'جارٍ رفع \u2066Launch plan.docx\u2069',
  '3 of 5 files': '٣ من ٥ ملفات',
  'Team storage': 'مساحة تخزين الفريق',
  '9.4 GB of 10 GB used': 'المستخدم ٩٫٤ غيغابايت من أصل ١٠ غيغابايت',
  // Northwind: its roots and its people.
  'Northwind': 'نورثويند',
  'Home': 'الرئيسية',
  'Files': 'الملفات',
  'Requests': 'الطلبات',
  'Settings': 'الإعدادات',
  'Ines Duarte': 'إينيس دوارتي',
  'Kai Tanaka': 'كاي تاناكا',
  'Mara Okafor': 'مارا أوكافور',
  'Tomas Lindqvist': 'توماس ليندكفيست',
  'Priya Raman': 'بريا رامان',
  'Noor Haddad': 'نور حداد',
  'Ana Ruiz': 'آنا رويث',
  // Home.
  'Good afternoon, Ines': 'مساء الخير يا إينيس',
  'Three meetings and two requests need you today.':
      'لديك اليوم ثلاثة اجتماعات وطلبان بانتظارك.',
  'Today': 'اليوم',
  '3 meetings': '3 اجتماعات',
  'Calendar': 'التقويم',
  'Standup': 'الاجتماع اليومي',
  '09:30 · 15 min · Video call': '09:30 · 15 دقيقة · مكالمة فيديو',
  'Roadmap review': 'مراجعة خارطة الطريق',
  '14:00 · 1 h · Room 2': '14:00 · ساعة · القاعة 2',
  'Design crit': 'نقد التصميم',
  '16:00 · 45 min · Studio': '16:00 · 45 دقيقة · الاستوديو',
  'Waiting on you': 'بانتظارك',
  '2 requests': 'طلبان',
  'Second monitor': 'شاشة ثانية',
  'Kai Tanaka · Equipment': 'كاي تاناكا · معدات',
  'Urgent': 'عاجل',
  'Access to Finance share': 'الوصول إلى مجلد المالية',
  'Priya Raman · Access': 'بريا رامان · صلاحيات',
  'Storage': 'التخزين',
  '62 GB of 100 GB used': 'مستخدم 62 غيغابايت من 100 غيغابايت',
  'Storage used': 'التخزين المستخدم',
  'Manage storage': 'إدارة التخزين',
  'Recent files': 'الملفات الأخيرة',
  'All files': 'كل الملفات',
  'Q3 plan.docx': 'خطة الربع الثالث.docx',
  'Brand guidelines.pdf': 'دليل الهوية.pdf',
  'Offsite budget.xlsx': 'ميزانية الملتقى.xlsx',
  'Kai Tanaka · 2 h ago': 'كاي تاناكا · قبل ساعتين',
  'Mara Okafor · Yesterday': 'مارا أوكافور · أمس',
  'Tomas Lindqvist · Monday': 'توماس ليندكفيست · الاثنين',
  // Files.
  'Upload': 'رفع',
  'Search files': 'البحث في الملفات',
  'Which files': 'أي الملفات',
  'Recent': 'الأخيرة',
  'Shared': 'المشتركة',
  'Starred': 'المميّزة بنجمة',
  'Earlier this week': 'في وقت سابق هذا الأسبوع',
  'Shared with you': 'تمت مشاركتها معك',
  'Kai Tanaka edited': 'عدّلها كاي تاناكا',
  'You edited': 'عدّلتها أنت',
  'Mara Okafor shared': 'شاركتها مارا أوكافور',
  'Launch hero.png': 'صورة الإطلاق.png',
  'Noor Haddad added': 'أضافتها نور حداد',
  'Standup notes': 'ملاحظات الاجتماع اليومي',
  'Priya Raman edited': 'عدّلتها بريا رامان',
  'Hiring plan.xlsx': 'خطة التوظيف.xlsx',
  'Customer interviews': 'مقابلات العملاء',
  '2.4 MB': '2.4 ميغابايت',
  '310 KB': '310 كيلوبايت',
  '8.1 MB': '8.1 ميغابايت',
  '1.2 MB': '1.2 ميغابايت',
  '24 KB': '24 كيلوبايت',
  '96 KB': '96 كيلوبايت',
  '1.8 MB': '1.8 ميغابايت',
  'Try another name, or look in Shared and Starred.':
      'جرّب اسمًا آخر، أو ابحث في المشتركة والمميّزة بنجمة.',
  // New request.
  'New request': 'طلب جديد',
  'Ask the operations team for equipment, access or a room. '
          'Most requests are answered within a day.':
      'اطلب من فريق العمليات معدات أو صلاحيات أو قاعة. '
      'يُرَدّ على معظم الطلبات خلال يوم.',
  'What you need': 'ما تحتاج إليه',
  'Title': 'العنوان',
  'Give the request a title.': 'أعطِ الطلب عنوانًا.',
  'For example, a second monitor': 'مثلًا، شاشة ثانية',
  'Type': 'النوع',
  'Choose a type': 'اختر نوعًا',
  'Equipment': 'معدات',
  'Access': 'صلاحيات',
  'Room booking': 'حجز قاعة',
  'Something else': 'شيء آخر',
  'Priority': 'الأولوية',
  'Low': 'منخفض',
  'Normal': 'عادي',
  'Details': 'التفاصيل',
  'Size': 'الحجم',
  'Document': 'مستند',
  'Spreadsheet': 'جدول بيانات',
  'Picture': 'صورة',
  'What it is for, and anything the team should know.':
      'الغرض منه، وأي شيء ينبغي أن يعرفه الفريق.',
  'Add details': 'أضف التفاصيل',
  'When and who': 'متى ومَن',
  'Needed by': 'مطلوب بحلول',
  'Choose when you need it.': 'اختر متى تحتاج إليه.',
  'Choose a date': 'اختر موعدًا',
  'This week': 'هذا الأسبوع',
  'Next week': 'الأسبوع القادم',
  'This month': 'هذا الشهر',
  'Approver': 'المعتمِد',
  'Choose an approver': 'اختر معتمِدًا',
  'Email me when the status changes': 'راسلني عند تغيّر الحالة',
  'Submit request': 'إرسال الطلب',
  'Clear': 'مسح',
  'Request sent': 'أُرسل الطلب',
  'Operations will reply by tomorrow.': 'سيردّ فريق العمليات بحلول الغد.',
  // Settings.
  'Notifications': 'الإشعارات',
  'Quiet hours hold everything but calls.':
      'ساعات الهدوء توقف كل شيء عدا المكالمات.',
  'Push notifications': 'الإشعارات الفورية',
  'Mentions only': 'الإشارات فقط',
  'Skip the rest of a channel': 'تجاهل بقية رسائل القناة',
  'Email digest': 'ملخص البريد',
  'Weekly': 'أسبوعيًا',
  'Quiet hours': 'ساعات الهدوء',
  'General': 'عام',
  'Appearance': 'المظهر',
  'System': 'النظام',
  'Language': 'اللغة',
  'English (UK)': 'العربية',
  'Show when I’m active': 'إظهار حالة نشاطي',
  'Privacy and security': 'الخصوصية والأمان',
  'Two-step verification': 'التحقق بخطوتين',
  'On': 'مفعّل',
  'Signed-in devices': 'الأجهزة المسجَّل دخولها',
  'Sign out': 'تسجيل الخروج',
  // Dialog.
  'Dialog': 'مربع الحوار',
  'Raised over the app': 'فوق التطبيق',
  'Delete file': 'حذف الملف',
  'Delete Launch plan.docx?': 'حذف الملف «خطة الإطلاق»؟',
  'It moves to the recycle bin for 30 days.':
      'يُنقل إلى سلة المحذوفات لمدة 30 يومًا.',
  'Delete': 'حذف',
  'Leave meeting': 'مغادرة الاجتماع',
  'Leave Design review?': 'مغادرة مراجعة التصميم؟',
  'The meeting goes on without you.': 'سيستمر الاجتماع من دونك.',
  'Leave': 'مغادرة',
  'A decision': 'قرار',
  'A choice': 'اختيار',
  'An acknowledgement': 'إقرار',
  'Cancel': 'إلغاء',
  'Save changes to Q4 notes?': 'حفظ التغييرات على ملاحظات الربع الرابع؟',
  'Your edits since 14:20 are not saved yet.':
      'لم تُحفظ تعديلاتك منذ 14:20 بعد.',
  "Don't save": 'عدم الحفظ',
  'Save': 'حفظ',
  'Invite sent': 'أُرسلت الدعوة',
  'Priya Raman can join Northwind from her email.':
      'يمكن لبريا رامان الانضمام إلى نورثويند من بريدها.',
  'Done': 'تم',
  // States.
  'States': 'الحالات',
  'Loading': 'التحميل',
  'Empty': 'فارغة',
  'Error': 'خطأ',
  'Spinner sizes': 'أحجام مؤشر التحميل',
  'Spinner': 'مؤشر التحميل',
  'Toasts': 'الإشعارات المنبثقة',
  'Success': 'نجاح',
  'Info': 'معلومات',
  'Warning': 'تحذير',
  'Undo': 'تراجع',
  'File moved': 'نُقل الملف',
  'Launch plan.docx is in Archive.': '«خطة الإطلاق» في الأرشيف الآن.',
  'Syncing': 'جارٍ المزامنة',
  'Northwind files update in a minute.': 'تتحدّث ملفات نورثويند خلال دقيقة.',
  'Storage almost full': 'التخزين ممتلئ تقريبًا',
  '92% of 1 TB used.': 'استُخدم 92% من 1 تيرابايت.',
  'Upload failed': 'تعذّر الرفع',
  'Hero art.png is over 250 MB.': 'حجم «صورة الغلاف» يتجاوز 250 ميغابايت.',
  'Uploading the cover': 'جارٍ رفع الغلاف',
  'Loading files': 'جارٍ تحميل الملفات',
  'No files yet': 'لا ملفات بعد',
  'Files you create or upload to Northwind show up here.':
      'تظهر هنا الملفات التي تنشئها أو ترفعها إلى نورثويند.',
  "Couldn't load your chats": 'تعذّر تحميل محادثاتك',
  'Check your connection and try again.': 'تحقّق من اتصالك وحاول مجددًا.',
  'Invitation sent': 'أُرسلت الدعوة',
  'Ana Ruiz will get an email with a link to Budget.':
      'ستتلقى آنا رويث رسالة فيها رابط إلى الميزانية.',
  'Invite someone else': 'دعوة شخص آخر',
  // Sheet.
  'Sheet': 'اللوحة السفلية',
  'Raised': 'مرفوعة',
  'In place': 'في مكانها',
  'With its acts': 'مع إجراءاتها',
  'Launch': 'الإطلاق',
  'Research': 'البحث',
  'Design reviews': 'مراجعات التصميم',
  'Archive': 'الأرشيف',
  'Move to': 'نقل إلى',
  'Share': 'مشاركة',
  'Share Launch plan': 'مشاركة خطة الإطلاق',
  'Send': 'إرسال',
  'People in Northwind with the link can view.':
      'يمكن لمن لديه الرابط في نورثويند العرض.',
  'Can edit': 'يمكنه التعديل',
  // Composer.
  'Composer': 'محرّر الرسائل',
  'Messages, live': 'الرسائل، مباشرة',
  'Kai: the launch deck is in Files.': 'كاي: عرض الإطلاق في الملفات.',
  'Message Design': 'راسِل فريق التصميم',
  'Messages': 'الرسائل',
  'Messages, a draft': 'الرسائل، مسودة',
  'Messages, disabled': 'الرسائل، معطّلة',
  "You can't reply in this channel": 'لا يمكنك الرد في هذه القناة',
  'Assistant': 'المساعد',
  'Mara, can you check the press notes before Thursday? The launch '
          'deck is final.':
      'مارا، هل يمكنك مراجعة ملاحظات الصحافة قبل الخميس؟ عرض الإطلاق '
      'نهائي.',
  'Ask the assistant': 'اسأل المساعد',
  'Ask about your files, chats and meetings':
      'اسأل عن ملفاتك ومحادثاتك واجتماعاتك',
  'Prompts': 'اقتراحات',
  // Menu.
  'Menu': 'القائمة',
  'Opened from a control': 'تُفتح من عنصر تحكّم',
  'Checkable, under a header': 'قابلة للتحديد، تحت عنوان',
  'Open': 'فتح',
  'Rename': 'إعادة تسمية',
  'Copy link': 'نسخ الرابط',
  'Name': 'الاسم',
  'Modified': 'تاريخ التعديل',
  'File size': 'حجم الملف',
  'More options': 'خيارات إضافية',
  'Sort': 'فرز',
  'Sort by': 'فرز حسب',
  // Detail header.
  'Detail header': 'رأس التفاصيل',
  'A file': 'ملف',
  'A person': 'شخص',
  'Northwind / Planning': 'نورثويند / التخطيط',
  'Edited 2h ago by Kai Tanaka · 2.4 MB':
      'عدّلها كاي تاناكا قبل ساعتين · 2.4 ميغابايت',
  'Design lead · Northwind': 'قائدة التصميم · نورثويند',
  'Lisbon · 09:42 local time': 'لشبونة · 09:42 بالتوقيت المحلي',
  'Chat': 'محادثة',
  'Call': 'اتصال',
  'Email': 'البريد الإلكتروني',
  'Video call': 'مكالمة فيديو',
  // Top bar.
  'Top bar & screen': 'الشريط العلوي والشاشة',
  'A root': 'صفحة جذر',
  'With commands': 'مع الأوامر',
  'Pushed': 'صفحة فرعية',
  "A sheet's head": 'رأس اللوحة',
  'A pushed page and its footer': 'صفحة فرعية وتذييلها',
  'Search': 'بحث',
  'Launch plan.docx': 'خطة الإطلاق.docx',
  'Q4 forecast.xlsx': 'توقعات الربع الرابع.xlsx',
  'Mara Okafor commented': 'علّقت مارا أوكافور',
  'Mon': 'الاثنين',
  'Brand refresh.png': 'تجديد الهوية.png',
  'You shared': 'شاركتها أنت',
  'Oct 28': '28 أكتوبر',
  'Design review deck': 'عرض مراجعة التصميم',
  'Tomas Lindqvist edited': 'عدّلها توماس ليندكفيست',
  'Oct 27': '27 أكتوبر',
  'Folders': 'المجلدات',
  '14 files': '14 ملفًا',
  '32 files': '32 ملفًا',
  'Design review': 'مراجعة التصميم',
  'More': 'المزيد',
  'Decline': 'رفض',
  'Join': 'انضمام',
  'Today, 15:00–\u206015:45': 'اليوم، 15:00–\u206015:45',
  'Video call · Organizer Mara Okafor': 'مكالمة فيديو · تنظّمها مارا أوكافور',
  'Walk through the launch screens and agree the last copy '
          'changes before Friday.':
      'مراجعة شاشات الإطلاق والاتفاق على آخر تعديلات النص قبل الجمعة.',
  'November 2026': 'نوفمبر 2026',
  'New event': 'حدث جديد',
  'Filter': 'تصفية',
};

/// Fluent 2's own words in Arabic: the ones a part shows or says on the
/// gallery's pages; the rest stay English.
class _Fluent2Arabic extends Fluent2LocalizationsEn {
  const _Fluent2Arabic();

  static const LocalizationsDelegate<Fluent2Localizations> delegate =
      _Delegate<Fluent2Localizations>(_Fluent2Arabic());

  @override
  String backTo(String where) => 'العودة إلى $where';
  @override
  String get dismiss => 'تجاهل';
  @override
  String get tryAgain => 'حاول مجددًا';
  @override
  String get send => 'إرسال';
  @override
  String get attachFile => 'إرفاق ملف';
  @override
  String get emoji => 'رموز تعبيرية';
  @override
  String moreOptionsFor(String label) => 'خيارات إضافية لـ $label';
  @override
  String get filters => 'عوامل التصفية';
  @override
  String remove(String label) => 'إزالة $label';
  @override
  String get removeAction => 'إزالة';
  @override
  String get newItem => 'جديد';
  @override
  String get morePlaces => 'أماكن أخرى';
  @override
  String stepOf(int step, int steps) => 'الخطوة $step من $steps';
  @override
  String get notifications => 'الإشعارات';
  @override
  String accountSettings(String name) => '$name، الملف الشخصي والإعدادات';
  @override
  String get profileAndSettings => 'الملف الشخصي والإعدادات';
  @override
  String pageOf(int page, int count) => 'الصفحة $page من $count';
  @override
  String get chooseTime => 'اختر وقتًا';
  @override
  String get chooseDate => 'اختر تاريخًا';
  @override
  String get chooseDates => 'اختر تواريخ';
  @override
  String get dropFiles => 'اسحب الملفات إلى هنا';
  @override
  String get browseFiles => 'تصفّح الملفات';
  @override
  String get cut => 'قص';
  @override
  String get copy => 'نسخ';
  @override
  String get paste => 'لصق';
  @override
  String get selectAll => 'تحديد الكل';
  @override
  String get share => 'مشاركة';
  @override
  String get other => 'أخرى';
  @override
  String get menu => 'القائمة';
  @override
  String get selectAnOption => 'اختر خيارًا';
  @override
  String get selectADate => 'اختر تاريخًا...';
  @override
  String get addPeople => 'أضف أشخاصًا';
  @override
  String get typeAMessage => 'اكتب رسالة';
  @override
  String get message => 'رسالة';
  @override
  String get create => 'إنشاء';
  @override
  String get expandNavigation => 'توسيع التنقل';
  @override
  String get collapseNavigation => 'طي التنقل';
  @override
  String get gotIt => 'فهمت';
  @override
  String notificationsUnread(int count) => 'الإشعارات، $count غير مقروءة';
  @override
  String ratedOutOf(String value, int max) => 'التقييم $value من $max';
  @override
  String ratingsCount(int count, String counted) =>
      switch (_arabicForm(count)) {
        _ArabicForm.zero => 'لا تقييمات',
        _ArabicForm.one => 'تقييم واحد',
        _ArabicForm.two => 'تقييمان',
        _ArabicForm.few => '$counted تقييمات',
        _ArabicForm.many => '$counted تقييمًا',
        _ArabicForm.other => '$counted تقييم',
      };
  @override
  String ratingValue(String value, int max) => '$value من $max';
  @override
  String namesAndMore(String names, int more) => switch (_arabicForm(more)) {
    _ArabicForm.zero || _ArabicForm.other => '$names و$more آخرين',
    _ArabicForm.one => '$names وشخص آخر',
    _ArabicForm.two => '$names وشخصان آخران',
    _ArabicForm.few => '$names و$more أشخاص آخرين',
    _ArabicForm.many => '$names و$more شخصًا آخر',
  };
  @override
  String get information => 'معلومات';
  @override
  String get success => 'نجاح';
  @override
  String get warning => 'تحذير';
  @override
  String get error => 'خطأ';
  @override
  List<String> get months => const [
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
  @override
  List<String> get monthsShort => months;
  @override
  List<String> get weekdaysShort => const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
}

class _Delegate<T> extends LocalizationsDelegate<T> {
  const _Delegate(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture<T>(words);

  @override
  bool shouldReload(_Delegate<T> old) => false;

  @override
  Type get type => T;
}

/// CLDR's Arabic plural forms.
enum _ArabicForm { zero, one, two, few, many, other }

_ArabicForm _arabicForm(int n) => switch (n % 100) {
  _ when n == 0 => _ArabicForm.zero,
  _ when n == 1 => _ArabicForm.one,
  _ when n == 2 => _ArabicForm.two,
  >= 3 && <= 10 => _ArabicForm.few,
  >= 11 && <= 99 => _ArabicForm.many,
  _ => _ArabicForm.other,
};
