/// The gallery's words in Arabic, for its right-to-left mode: the pages a
/// reader checks right to left (Harbor, forms, entry, sheet, dialog, states,
/// menu) say their sample words in Arabic, so a row reads as an Arabic
/// app's would rather than as English reordered by the bidi algorithm
/// ("2 transactions" read "transactions 2"). Digits stay Western, as many
/// Arabic banking apps print them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

import 'kit.dart';

/// Whether the gallery is showing its right-to-left mode.
bool get kitArabic => kitShownDirection == TextDirection.rtl;

/// [english] in the shown language: its Arabic in the right-to-left mode
/// (a clock time takes Arabic's ص and م), else itself.
String kitSay(String english) {
  if (!kitArabic) return english;
  final said = _arabic[english];
  if (said != null) return said;
  final time = RegExp(r'^(\d{1,2}:\d{2}) (AM|PM)$').firstMatch(english);
  if (time != null) return '${time[1]} ${time[2] == 'AM' ? 'ص' : 'م'}';
  return english;
}

/// [child] speaking Arabic in the right-to-left mode: Frosted's own words
/// and the words every design system shares (Close, Cancel, Today) take
/// their Arabic over whatever the app installed; left to right, [child] as
/// it is.
Widget kitWords(BuildContext context, Widget child) => kitArabic
    ? Localizations.override(
        context: context,
        delegates: const [_ArabicFrosted(), _ArabicShared()],
        child: child,
      )
    : child;

class _ArabicFrosted extends LocalizationsDelegate<FrostedLocalizations> {
  const _ArabicFrosted();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FrostedLocalizations> load(Locale locale) =>
      SynchronousFuture<FrostedLocalizations>(const _FrostedArabic());

  @override
  bool shouldReload(_ArabicFrosted old) => false;
}

class _ArabicShared extends LocalizationsDelegate<DesignLocalizations> {
  const _ArabicShared();

  @override
  bool isSupported(Locale locale) => true;

  // ui_core's own Arabic (it speaks 30 languages), whatever the app's
  // locale.
  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(
        DesignLocalizations.forLocale(const Locale('ar')),
      );

  @override
  bool shouldReload(_ArabicShared old) => false;
}

/// Frosted's own words in Arabic, as an app in Arabic would install them.
class _FrostedArabic extends FrostedLocalizationsEn {
  const _FrostedArabic();

  static const _months = [
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

  static const _days = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  String get done => 'تم';
  @override
  String get tryAgain => 'حاول مجددًا';
  @override
  String get sections => 'الأقسام';
  @override
  String get profileAndSettings => 'الملف الشخصي والإعدادات';
  @override
  String get notifications => 'الإشعارات';
  @override
  String get swap => 'تبديل';
  @override
  String get send => 'إرسال';
  @override
  String get stop => 'إيقاف';
  @override
  String get dictate => 'إملاء';
  @override
  String get attach => 'إرفاق';
  @override
  String get message => 'رسالة';
  @override
  String get askAnything => 'اسأل عن أي شيء';
  @override
  String get filters => 'عوامل التصفية';
  @override
  String get month => 'الشهر';
  @override
  String get chooseMonth => 'اختر الشهر';
  @override
  String get quickActions => 'إجراءات سريعة';
  @override
  String get quickAmounts => 'مبالغ سريعة';
  @override
  String get icon => 'الأيقونة';
  @override
  String get balance => 'الرصيد';
  @override
  String get frozen => 'مجمّدة';
  @override
  String get cardNumber => 'رقم البطاقة';
  @override
  String get expires => 'تنتهي';
  @override
  String get name => 'الاسم';
  @override
  String get newGoal => 'هدف جديد';
  @override
  String get newGoalNote => 'ادّخر لشيء جديد';
  @override
  String get moneyIn => 'الأموال الواردة';
  @override
  String get spent => 'مصروف';
  @override
  String get net => 'الصافي';
  @override
  String get kept => 'المتبقي';
  @override
  String get autopay => 'دفع تلقائي';
  @override
  String get unread => 'غير مقروء';
  @override
  String get move => 'نقل';
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
  String get cardPayment => 'دفع بالبطاقة';
  @override
  String get working => 'جارٍ العمل…';
  @override
  String get previous => 'السابق';
  @override
  String get next => 'التالي';
  @override
  String page(int page, int count) => 'الصفحة $page من $count';
  @override
  String step(int step, int count) => 'الخطوة $step من $count';
  // Arabic's six plural forms (CLDR): zero, one, two, few (3 to 10 in the
  // last two digits), many (11 to 99), other.
  @override
  String visits(int count) => switch (count) {
    0 => 'لا زيارات',
    1 => 'زيارة واحدة',
    2 => 'زيارتان',
    _ when count % 100 >= 3 && count % 100 <= 10 => '$count زيارات',
    _ => '$count زيارة',
  };
  @override
  String get remove => 'إزالة';
  @override
  String get chooseFile => 'اختر ملفًا';
  @override
  String get dropFile => 'أو أفلته هنا';
  @override
  String get selectDate => 'اختر تاريخًا';
  @override
  String get selectTime => 'اختر وقتًا';
  @override
  String get select => 'اختيار';
  @override
  String get hour => 'الساعة';
  @override
  String get minute => 'الدقيقة';
  @override
  String get am => 'ص';
  @override
  String get pm => 'م';
  @override
  String monthName(int month) => _months[month - 1];
  @override
  String fullDate(DateTime date) =>
      '${_days[date.weekday - 1]}، ${date.day} ${monthName(date.month)} ${date.year}';
  @override
  String shortDate(DateTime date) =>
      '${date.day} ${monthName(date.month)} ${date.year}';
  @override
  String get noData => 'لا بيانات';
  @override
  String get oneTimeCode => 'رمز لمرة واحدة';
  @override
  String get searchCommands => 'اكتب أمرًا أو ابحث';
  @override
  String get pullToRefresh => 'اسحب للتحديث';
  @override
  String get releaseToRefresh => 'أفلت للتحديث';
  @override
  String get pending => 'معلّقة';
}

/// How many transactions a day holds, in the shown language (Arabic counts
/// one, two, three to ten and eleven up each in its own form).
String kitTransactions(int n) {
  if (!kitArabic) return '$n ${n == 1 ? 'transaction' : 'transactions'}';
  return switch (n) {
    1 => 'معاملة واحدة',
    2 => 'معاملتان',
    >= 3 && <= 10 => '$n معاملات',
    _ => '$n معاملة',
  };
}

const _arabic = <String, String>{
  // Harbor
  'Activity': 'النشاط',
  'Settings': 'الإعدادات',
  'Harbor': 'هاربر',
  'Light appearance': 'المظهر الفاتح',
  'Dark appearance': 'المظهر الداكن',
  'Back to the gallery': 'العودة إلى المعرض',
  'Harbor Card': 'بطاقة هاربر',
  'Today': 'اليوم',
  'Blue Fern Café': 'مقهى السرخس الأزرق',
  'Dining out': 'مطاعم',
  'Harbor Transit': 'نقل هاربر',
  'Transport': 'مواصلات',
  'Everyday': 'الحساب اليومي',
  'Fri, Oct 23': 'الجمعة، 23 أكتوبر',
  'Northwind Studio': 'استوديو الريح الشمالية',
  'Paycheck': 'راتب',
  'Larder & Co.': 'لاردر وشركاه',
  'Groceries': 'بقالة',
  'Cinema Lumen': 'سينما لومن',
  'Going out': 'ترفيه',
  'Thu, Oct 22': 'الخميس، 22 أكتوبر',
  'Pine Street Books': 'مكتبة شارع الصنوبر',
  'Shopping': 'تسوق',
  'Maren Holt': 'مارين هولت',
  'From a friend': 'من صديق',
  'Wed, Oct 21': 'الأربعاء، 21 أكتوبر',
  'Gridline Energy': 'طاقة الشبكة',
  'Bills': 'فواتير',
  'Tidewater Gym': 'نادي المد الرياضي',
  'Health': 'صحة',
  'Tue, Oct 20': 'الثلاثاء، 20 أكتوبر',
  'Streamline': 'ستريملاين',
  'Subscriptions': 'اشتراكات',
  'Saltwater Ramen': 'رامن الماء المالح',
  'Mon, Oct 19': 'الاثنين، 19 أكتوبر',
  'Coastline Rail': 'قطار الساحل',
  'Travel': 'سفر',
  'Interest': 'فائدة',
  'Savings': 'التوفير',
  'Sun, Oct 18': 'الأحد، 18 أكتوبر',
  'Farmers Market': 'سوق المزارعين',
  'Split': 'تقسيم',
  'Split transaction': 'تقسيم المعاملة',
  'Save split': 'حفظ التقسيم',
  'People': 'عدد الأشخاص',
  'people': 'أشخاص',
  'No matching transactions': 'لا توجد معاملات مطابقة',
  'Try another merchant, category or account.':
      'جرّب تاجرًا أو فئة أو حسابًا آخر.',
  'Transaction help': 'مساعدة بشأن المعاملة',
  'Check the merchant, date and amount in this transaction before contacting your bank.':
      'تحقّق من التاجر والتاريخ والمبلغ قبل التواصل مع مصرفك.',
  'Save limit': 'حفظ الحد',
  'Limit in dollars': 'الحد بالدولار',
  'Done': 'تم',
  'Search activity': 'ابحث في النشاط',
  'Show': 'عرض',
  'All': 'الكل',
  'Spending': 'الإنفاق',
  'Income': 'الدخل',
  'Pending': 'معلّقة',
  'October': 'أكتوبر',
  'October 2026': 'أكتوبر 2026',
  'Get help': 'طلب المساعدة',
  'Received': 'مستلم',
  'Spent': 'مصروف',
  'Category': 'الفئة',
  'Account': 'الحساب',
  'When': 'الوقت',
  'Status': 'الحالة',
  'Settled': 'مكتملة',
  'Notifications': 'الإشعارات',
  'Money in and out': 'الأموال الواردة والصادرة',
  'The moment it moves': 'لحظة تحرّكها',
  'Bills before they are due': 'الفواتير قبل موعد استحقاقها',
  'Three days ahead': 'قبلها بثلاثة أيام',
  'Weekly summary': 'ملخص أسبوعي',
  'Sunday evenings': 'مساء كل أحد',
  'Security': 'الأمان',
  'Unlock with Face ID': 'الفتح بـ Face ID',
  'Passcode': 'رمز المرور',
  'Changed in August': 'تغيّر في أغسطس',
  'Signed-in devices': 'الأجهزة المسجّلة',
  'Appearance': 'المظهر',
  'Theme': 'السمة',
  'Light': 'فاتح',
  'Dark': 'داكن',
  'Backdrop': 'الخلفية',
  'Dawn': 'الفجر',
  'Night sky': 'سماء الليل',
  'Plain': 'سادة',
  'Limits': 'الحدود',
  'Monthly spending limit': 'حد الإنفاق الشهري',
  'Close account': 'إغلاق الحساب',
  'Close your account?': 'هل تريد إغلاق حسابك؟',
  'Your balance moves to the account you choose, and your cards stop '
          'working today.':
      'ينتقل رصيدك إلى الحساب الذي تختاره، وتتوقف بطاقاتك عن العمل اليوم.',
  'Keep it': 'الإبقاء عليه',
  // Forms
  'Forms': 'النماذج',
  'A switch row on and one with no callback; a way in and a row off':
      'صف مفتاح مفعّل وآخر بلا استجابة؛ ومدخل وصف معطّل',
  'Settings: switches in rows, flipped by their words':
      'الإعدادات: مفاتيح في صفوف تُقلب بكلماتها',
  'Settings: a switch, a way in, and a limit the frozen card cannot change':
      'الإعدادات: مفتاح ومدخل وحدّ لا تغيّره البطاقة المجمّدة',
  'Form rows: a value, a control, a way in, each with its glyph':
      'صفوف النموذج: قيمة وعنصر تحكم ومدخل، لكلٍّ رمزه',
  'A form in its tile: a field, a pair, the icons':
      'نموذج في بطاقته: حقل وزوج والأيقونات',
  'A few days before each is due': 'قبل موعد استحقاق كلٍّ منها بأيام',
  'Budgets': 'الميزانيات',
  'When a category goes over': 'عندما تتجاوز فئةٌ حدّها',
  'Every Sunday evening': 'مساء كل أحد',
  'Change passcode': 'تغيير رمز المرور',
  'To open the app and approve payments':
      'لفتح التطبيق والموافقة على المدفوعات',
  'Currency': 'العملة',
  'USD': 'دولار أمريكي',
  'Member since': 'عضو منذ',
  'October 2023': 'أكتوبر 2023',
  'Round-ups': 'التقريب',
  'Save the change from Harbor Card': 'ادّخر الفكّة من بطاقة هاربر',
  'Card freeze': 'تجميد البطاقة',
  'Data': 'البيانات',
  'Linked accounts': 'الحسابات المرتبطة',
  'Export statements': 'تصدير الكشوف',
  'New goal': 'هدف جديد',
  'Name': 'الاسم',
  'What are you saving for?': 'لأي شيء تدّخر؟',
  'Lisbon': 'لشبونة',
  'Target': 'المبلغ المستهدف',
  'Date': 'التاريخ',
  'May 2027': 'مايو 2027',
  'Plane': 'طائرة',
  'Shield': 'درع',
  'Bike': 'دراجة',
  'Home': 'المنزل',
  'Car': 'سيارة',
  'Gift': 'هدية',
  'Amount': 'المبلغ',
  'Note': 'ملاحظة',
  'November top-up': 'تعبئة نوفمبر',
  'Tomorrow': 'غدًا',
  'Choose a date': 'اختر تاريخًا',
  // Entry
  'Entry': 'الإدخال',
  'Password': 'كلمة المرور',
  'New password': 'كلمة مرور جديدة',
  'At least 12 characters': '12 حرفًا على الأقل',
  'Too short': 'قصيرة جدًا',
  'Input group': 'مجموعة إدخال',
  'Website': 'الموقع الإلكتروني',
  'Weight': 'الوزن',
  'One-time code': 'رمز لمرة واحدة',
  'Code from your text': 'الرمز من رسالتك النصية',
  'PIN': 'الرمز السري',
  'Form field': 'حقل نموذج',
  'Email': 'البريد الإلكتروني',
  'Notify me by': 'أبلغني عبر',
  'Pick at least one': 'اختر واحدًا على الأقل',
  'Text': 'رسالة نصية',
  'Push': 'إشعار فوري',
  'Notify me': 'أبلغني',
  'Rent & home': 'الإيجار والمنزل',
  'Fun': 'الترفيه',
  // Sheet
  'Sheet': 'الورقة',
  'Raised': 'مرفوعة',
  'Freeze card': 'تجميد البطاقة',
  'Freeze your card?': 'هل تريد تجميد بطاقتك؟',
  'Cancel': 'إلغاء',
  'Freeze': 'تجميد',
  'Side sheet': 'ورقة جانبية',
  'Filters': 'عوامل التصفية',
  'Only unread': 'غير المقروءة فقط',
  'From': 'من',
  'Apply': 'تطبيق',
  'In place': 'في مكانها',
  'A dialog closed by its own acts': 'حوار يُغلق بأفعاله',
  'New purchases and cash withdrawals are declined.':
      'تُرفض المشتريات الجديدة والسحوبات النقدية.',
  'Autopay, refunds and payments still go through.':
      'يستمر الدفع التلقائي والمبالغ المستردة والمدفوعات.',
  'Unfreeze any time; it takes effect at once.':
      'ألغِ التجميد متى شئت؛ يسري فورًا.',
  // Dialog
  'Dialog': 'الحوار',
  'Raised over the app': 'مرفوع فوق التطبيق',
  'Freeze this card?': 'هل تريد تجميد هذه البطاقة؟',
  'Payments stop until you unfreeze it. Subscriptions on it will fail.':
      'تتوقف المدفوعات حتى تلغي التجميد، وتفشل الاشتراكات المرتبطة بها.',
  'Delete goal': 'حذف الهدف',
  'Delete Lisbon in May?': 'هل تريد حذف «لشبونة في مايو»؟',
  r'Its $2,840.00 moves back to Everyday.':
      r'يعود مبلغه $2,840.00 إلى الحساب اليومي.',
  'Delete': 'حذف',
  'Keep': 'إبقاء',
  'A decision': 'قرار',
  'A loss': 'خسارة',
  'An acknowledgement': 'إقرار',
  'Payments stop until you unfreeze it.': 'تتوقف المدفوعات حتى تلغي التجميد.',
  'Transfer sent': 'تم إرسال التحويل',
  r'$500.00 reaches Jonah Reyes on Thursday.':
      r'يصل $500.00 إلى جونا رييس يوم الخميس.',
  // States
  'States & toast': 'الحالات والإشعارات',
  'Toast, raised': 'إشعار مرفوع',
  'Move to Groceries': 'نقل إلى البقالة',
  'Moved to Groceries': 'نُقل إلى البقالة',
  'Undo': 'تراجع',
  'Copy card number': 'نسخ رقم البطاقة',
  'Card number copied': 'تم نسخ رقم البطاقة',
  'Toast, in place': 'إشعار في مكانه',
  'Loading': 'التحميل',
  'Error': 'خطأ',
  'Empty': 'فارغ',
  'Request sent to Jonah': 'تم إرسال الطلب إلى جونا',
  'Loading your accounts': 'جارٍ تحميل حساباتك',
  'Check your connection, then try again.': 'تحقق من اتصالك ثم حاول مجددًا.',
  'No results for “sushi”': 'لا نتائج لـ«سوشي»',
  'Nothing in October matches the Money in filter. Clear filters to search '
          'every transaction.':
      'لا شيء في أكتوبر يطابق عامل تصفية الأموال الواردة. امسح عوامل التصفية '
      'للبحث في كل المعاملات.',
  'Clear filters': 'مسح عوامل التصفية',
  // Menu
  'May 2026': 'مايو 2026',
  'June 2026': 'يونيو 2026',
  'July 2026': 'يوليو 2026',
  'August 2026': 'أغسطس 2026',
  'September 2026': 'سبتمبر 2026',
  'Menu': 'القائمة',
  'Anchored to its control': 'مثبّتة بعنصر التحكم',
  'Options': 'الخيارات',
  'Spent by month': 'الإنفاق حسب الشهر',
  'Months': 'الأشهر',
  // Left in English until self-review round 3.
  r'Large purchases over $200': r'المشتريات الكبيرة فوق $200',
  r'$1,259.82 spent in October': r'أُنفق $1,259.82 في أكتوبر',
  "That code didn't match": 'الرمز غير مطابق',
  "Couldn't load your accounts": 'تعذّر تحميل حساباتك',
  r'$500.00 to Jonah Reyes arrives Thursday.':
      r'يصل $500.00 إلى جونا ريس يوم الخميس.',
};
