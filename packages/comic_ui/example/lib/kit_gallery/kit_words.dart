/// The gallery's words in a reader's own script: right to left, the ten everyday screens (Cover, List, Form, Settings,
/// Checkout, Dialogs, Feedback, Text fields, Lists, Buttons), the pages' names and every section's label read in
/// Arabic, so the direction is checked on real script, not English reordered by bidi. Words not in the book (other
/// pages' sample words, keyboard keys) stay as written.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

/// Which book the gallery's words come from, for everything under it.
class KitWords extends InheritedWidget {
  /// Arabic when [arabic], else the words as written.
  const KitWords({super.key, required this.arabic, required super.child});

  /// The gallery reads in Arabic.
  final bool arabic;

  /// Whether the gallery around [context] reads in Arabic.
  static bool arabicOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KitWords>()?.arabic ?? false;

  @override
  bool updateShouldNotify(KitWords old) => old.arabic != arabic;
}

/// [en] in the gallery's language around [context].
String kitSay(BuildContext context, String en) =>
    KitWords.arabicOf(context) ? (_arabic[en] ?? en) : en;

const _arabic = <String, String>{
  // The pages.
  'Overview': 'نظرة عامة',
  'Buttons': 'الأزرار',
  'Text fields': 'حقول النص',
  'Selection': 'الاختيار',
  'Pickers': 'المنتقيات',
  'Navigation': 'التنقل',
  'Lists and tables': 'القوائم والجداول',
  'Cards and media': 'البطاقات والوسائط',
  'Dialogs and sheets': 'الحوارات والأوراق',
  'Feedback': 'الإشعارات',
  'Charts': 'الرسوم البيانية',
  'Type and colour': 'الخط واللون',
  'Form': 'النموذج',
  'Settings': 'الإعدادات',
  'List': 'القائمة',
  'Checkout': 'الدفع',
  'Panels and captions': 'اللوحات والتعليقات',
  'Balloons and bursts': 'البالونات والانفجارات',
  'Print': 'الطباعة',
  'Cover and splash': 'الغلاف وصفحة البداية',
  // Buttons.
  'The act, one a screen': 'الفعل، واحد في كل شاشة',
  'Any other action': 'أي إجراء آخر',
  'Quiet': 'هادئ',
  'Danger': 'خطر',
  'A link': 'رابط',
  'An icon alone': 'أيقونة وحدها',
  'Send': 'إرسال',
  'Sizes': 'الأحجام',
  'Busy and unavailable': 'مشغول وغير متاح',
  'A group of buttons': 'مجموعة أزرار',
  'A toggle group': 'مجموعة تبديل',
  'A split button': 'زر مقسوم',
  'Keys': 'المفاتيح',
  'A tile of your own': 'مربع من صنعك',
  // Text fields.
  'A field': 'حقل',
  'Label, help and error': 'التسمية والمساعدة والخطأ',
  'A password': 'كلمة مرور',
  'With add-ons': 'مع إضافات',
  'Search': 'البحث',
  'A code': 'رمز',
  'A longer answer': 'إجابة أطول',
  'The plain input': 'الإدخال البسيط',
  // Lists and tables.
  'A list': 'قائمة',
  'Rows in a group': 'صفوف في مجموعة',
  'Rows that open': 'صفوف تنفتح',
  'A row with an action': 'صف مع إجراء',
  'Facts': 'حقائق',
  'Times': 'الأوقات',
  'A form group': 'مجموعة نموذج',
  'Ruled': 'مسطّر',
  'A ledger': 'دفتر حساب',
  'Amounts': 'المبالغ',
  'A table': 'جدول',
  'A data table': 'جدول بيانات',
  'A tree': 'شجرة',
  'Your own order': 'ترتيبك الخاص',
  'Slide for more': 'اسحب للمزيد',
  'Pull to refresh': 'اسحب للتحديث',
  'A scroll area': 'منطقة تمرير',
  'Two panes': 'لوحان',
  'A timeline': 'خط زمني',
  'Described': 'موصوف',
  'A divider': 'فاصل',
  'More to read': 'المزيد للقراءة',
  // Dialogs and sheets.
  'Open them for real': 'افتحها فعلًا',
  'A dialog': 'حوار',
  'A sheet': 'ورقة',
  'A menu': 'قائمة خيارات',
  'A drawer': 'درج',
  'A tooltip': 'تلميح',
  'A snack bar': 'شريط إشعار',
  'A toast': 'إشعار عابر',
  'Notices that stack': 'إشعارات متراكمة',
  'A side sheet': 'ورقة جانبية',
  'A popover': 'نافذة منبثقة',
  'A hover card': 'بطاقة تمرير',
  'Choices from below': 'خيارات من الأسفل',
  'A decision on a real screen': 'قرار على شاشة حقيقية',
  // Feedback.
  'Notices': 'إشعارات',
  'Progress': 'التقدم',
  // Cover and splash.
  'The cover': 'الغلاف',
  'A splash': 'صفحة البداية',
  // Form (the account).
  'Where do we send it?': 'إلى أين نرسله؟',
  'Full name': 'الاسم الكامل',
  'Alex Morgan': 'سارة الأحمد',
  'Email address': 'البريد الإلكتروني',
  'Street and number': 'الشارع والرقم',
  '12 Harbour Lane': '12 شارع الميناء',
  'Town': 'المدينة',
  'Brighton': 'الإسكندرية',
  'Postcode': 'الرمز البريدي',
  'Delivery': 'التوصيل',
  'Standard delivery': 'توصيل عادي',
  'Express delivery': 'توصيل سريع',
  'Collect in store': 'الاستلام من المتجر',
  'Email me delivery updates': 'راسلني بتحديثات التوصيل',
  'Save details': 'احفظ البيانات',
  'Delivery details saved.': 'حُفظت بيانات التوصيل.',
  'On file': 'في السجل',
  'Member since': 'عضو منذ',
  'March 2024': 'مارس 2024',
  'Orders': 'الطلبات',
  'Plan': 'الاشتراك',
  'Monthly, 4 issues': 'شهري، 4 أعداد',
  'We only use your address for this order and the ones after it.':
      'نستخدم عنوانك لهذا الطلب وما يليه فقط.',
  // Settings.
  'Tell me when': 'أخبرني عندما',
  'A new issue is out': 'يصدر عدد جديد',
  'On the morning it comes out': 'صباح يوم صدوره',
  'My order ships': 'يُشحن طلبي',
  'With its tracking number': 'مع رقم التتبع',
  'Weekly summary': 'ملخص أسبوعي',
  'What you read, every Monday': 'ما قرأته، كل يوم اثنين',
  'Reading': 'القراءة',
  'Download new issues': 'نزّل الأعداد الجديدة',
  'On Wi-Fi only': 'عبر الواي فاي فقط',
  'Panel by panel': 'لوحة تلو لوحة',
  'One panel at a time on a phone': 'لوحة واحدة كل مرة على الهاتف',
  'Night pages': 'صفحات ليلية',
  'Dark paper after sunset': 'ورق داكن بعد الغروب',
  'You can change these any time. Messages about your account and orders always come through.': 'يمكنك تغيير هذه الإعدادات في أي وقت. تصلك دائمًا الرسائل الخاصة بحسابك وطلباتك.',
  // List (the library).
  'The first issue': 'العدد الأول',
  'A small adventure': 'مغامرة صغيرة',
  'Making time': 'صناعة الوقت',
  'The everyday issue': 'عدد كل يوم',
  'Ready to read': 'جاهز للقراءة',
  'Saved': 'محفوظ',
  'Finished': 'مكتمل',
  'Issue': 'العدد',
  'YOUR SHELF': 'رفّك',
  'Your issues, on every device.': 'أعدادك، على كل أجهزتك.',
  'Ready': 'جاهز',
  'to read!': 'للقراءة!',
  'All': 'الكل',
  // Checkout (the shop).
  'Your order': 'طلبك',
  'Print, one copy': 'مطبوع، نسخة واحدة',
  'Bookmarks': 'فواصل كتب',
  'A set of three': 'مجموعة من ثلاثة',
  'Standard': 'عادي',
  'Express': 'سريع',
  'Collect': 'استلام',
  'Free': 'مجانًا',
  'To pay': 'المطلوب',
  'VAT included': 'شامل الضريبة',
  'Delivery and payment': 'التوصيل والدفع',
  '3 to 5 days, €3': 'من 3 إلى 5 أيام، €3',
  'Next day, €6': 'اليوم التالي، €6',
  'In store, free': 'من المتجر، مجانًا',
  'Pay with': 'الدفع عبر',
  'Card': 'بطاقة',
  'Visa, Mastercard': 'فيزا، ماستركارد',
  'Phone wallet': 'محفظة الهاتف',
  'On this device': 'على هذا الجهاز',
  'Invoice': 'فاتورة',
  'Within 14 days': 'خلال 14 يومًا',
  'Name on the card': 'الاسم على البطاقة',
  'Card number': 'رقم البطاقة',
  'Expiry': 'تاريخ الانتهاء',
  'Security code': 'رمز الأمان',
  'Pay': 'ادفع',
  'Order placed. Thank you!': 'تم الطلب. شكرًا لك!',
  // The everyday screens' own sample words: Cover, Buttons, Text fields, Lists, Dialogs, Feedback.
  'That did not load': 'لم يُحمَّل هذا',
  'Check the line and try again.': 'تحقّق من الاتصال وحاول مجددًا.',
  'Trying again.': 'نحاول مجددًا.',
  'A plain input': 'حقل بسيط',
  'Unread issues': 'أعداد غير مقروءة',
  'Remove issue': 'احذف العدد',
  'Issue removed.': 'حُذف العدد.',
  'An offset reprint of the original issue.': 'إعادة طبع للعدد الأصلي.',
  'About this edition': 'عن هذه الطبعة',
  'Pages': 'الصفحات',
  'Print run': 'عدد النسخ',
  'Publication': 'النشر',
  'Read this issue': 'اقرأ هذا العدد',
  'Issue opened.': 'فُتح العدد.',
  'pages': 'صفحة',
  'Capacity': 'السعة',
  'We could not save this issue.': 'تعذّر حفظ هذا العدد.',
  'Your issue is saved.': 'حُفظ عددك.',
  'Only a few copies remain.': 'بقيت نسخ قليلة فقط.',
  'A new issue arrives Friday.': 'يصل عدد جديد يوم الجمعة.',
  'Upload': 'الرفع',
  'Saved for later.': 'حُفظ لوقت لاحق.',
  'Later': 'لاحقًا',
  'Loading': 'جارٍ التحميل',
  'Half uploaded': 'رُفع النصف',
  'Your issue is ready to read.': 'عددك جاهز للقراءة.',
  'Thirteen': 'الثالث عشر',
  'Twelve': 'الثاني عشر',
  'Issue 12': 'العدد 12',
  'Issue 13': 'العدد 13',
  'Issue 12 opened.': 'فُتح العدد 12.',
  'The task is done.': 'انتهت المهمة.',
  'Do the thing': 'نفّذ المهمة',
  'As it should be on the list': 'كما يجب أن يظهر في القائمة',
  'Write a reply': 'اكتب ردًا',
  'Alerts': 'التنبيهات',
  'Search issues': 'ابحث في الأعداد',
  'Message sent.': 'أُرسلت الرسالة.',
  'Notes': 'ملاحظات',
  'A few words about the issue': 'بضع كلمات عن العدد',
  'to read': 'للقراءة',
  'Wed 11 Nov': '11 نوفمبر',
  'mild, 9°': 'معتدل، 9°',
  'Only': 'بقي',
  'to go!': 'فقط!',
  'Robin': 'روبن',
  'Sam': 'سام',
  'Alex': 'أليكس',
  'You': 'أنت',
  'Huzzah!': 'مرحى!',
  'A line from the cast, in a balloon.': 'سطر من الشخصيات، في فقاعة.',
  'No. 27': 'العدد 27',
  'so far': 'حتى الآن',
  'The first': 'العدد الأول',
  'issue!': 'وصل!',
  'The first one will show up here.': 'سيظهر أولها هنا.',
  'Nothing here yet': 'لا شيء هنا بعد',
  'Grade': 'الصعوبة',
  'Walkers': 'مشّاة',
  'Kilometres': 'كيلومتر',
  'In': 'بعد',
  'days!': 'يومًا!',
  'The long\nweekend': 'العطلة\nالطويلة',
  'Six': 'ستة',
  'Easy': 'سهلة',
  'Meanwhile, by the lake…': 'في هذه الأثناء، عند البحيرة…',
  'Fri 4 – Sun 6 Dec': 'الجمعة 4 – الأحد 6 ديسمبر',
  'New': 'جديد',
  'Plain': 'عادي',
  'Shade': 'ظل',
  'Yours': 'لك',
  'Ada Okafor': 'آدا أوكافور',
  'Ada Okafor inks the run from issue 12 on.':
      'تحبّر آدا أوكافور السلسلة منذ العدد 12.',
  'About Ada Okafor': 'عن آدا أوكافور',
  'Only unread issues, newest first.':
      'الأعداد غير المقروءة فقط، الأحدث أولًا.',
  'Apply': 'تطبيق',
  'From the end': 'من النهاية',
  'From the start': 'من البداية',
  'Filters': 'عوامل التصفية',
  'The run': 'السلسلة',
  'Twelve issues so far.': 'اثنا عشر عددًا حتى الآن.',
  'Show only the issues you have not read.': 'اعرض الأعداد التي لم تقرأها فقط.',
  'Filter': 'تصفية',
  'Pull this list down': 'اسحب هذه القائمة لأسفل',
  'Issues': 'الأعداد',
  'The page': 'الصفحة',
  'Letters to the editor': 'رسائل إلى المحرر',
  'Duplicate': 'تكرار',
  'Share': 'مشاركة',
  'Open as a sheet': 'افتح كورقة',
  'Text': 'النص',
  'Copy': 'نسخ',
  'Clear': 'مسح',
  'Paste': 'لصق',
  'Verification code': 'رمز التحقق',
  'Writer': 'الكاتب',
  'Nia Walker': 'نيا ووكر',
  'Ana Ruiz': 'آنا رويز',
  'Jun Sato': 'جون ساتو',
  'Inks': 'الحبر',
  'Or': 'أو',
  'USD': 'دولار',
  'Price': 'السعر',
  'At least eight letters': 'ثمانية أحرف على الأقل',
  'Password': 'كلمة المرور',
  'Letters and a number.': 'أحرف ورقم.',
  'Pencils': 'الرصاص',
  'Letters': 'الحروف',
  'Colours': 'الألوان',
  'Your collection\nIssue 12\nIssue 11': 'مجموعتك\nالعدد 12\nالعدد 11',
  'Save': 'حفظ',
  'Save and close': 'حفظ وإغلاق',
  'Save as copy': 'حفظ كنسخة',
  'Busy': 'مشغول',
  'Empty': 'فارغ',
  'Error': 'خطأ',
  'Done': 'تم',
  'No issues on this shelf': 'لا أعداد على هذا الرف',
  'It goes out on Friday.': 'يصدر يوم الجمعة.',
  'State': 'الحالة',
  'Sent to the printer': 'أُرسل إلى المطبعة',
  'Fetching your issues': 'نجلب أعدادك',
  'The issue did not load': 'لم يُحمَّل العدد',
  'Delete': 'حذف',
  'Read': 'مقروء',
  'Unread': 'غير مقروء',
  'Slide left': 'اسحب جانبًا',
  'Archive': 'أرشفة',
  'At the printer': 'في المطبعة',
  'Inked': 'حُبِّر',
  'Friday': 'الجمعة',
  'Monday': 'الاثنين',
  'Today': 'اليوم',
  'Pencilled': 'رُسم بالرصاص',
  'Italic': 'مائل',
  'Bold': 'عريض',
  'Underline': 'تسطير',
  'Style': 'النمط',
  'Cover': 'الغلاف',
  'Story': 'القصة',
  'Page 1': 'الصفحة 1',
  'Page 2': 'الصفحة 2',
  'Cover art': 'رسم الغلاف',
  'Raise a notice': 'أظهر إشعارًا',
  'The Long Night': 'الليلة الطويلة',
  'Harbor Lights': 'أضواء الميناء',
  'Second Printing': 'الطبعة الثانية',
  'The Inkwell': 'المحبرة',
  'Paper Moon': 'قمر من ورق',
  'Last Panel': 'اللوحة الأخيرة',
  'Old Newsprint': 'ورق صحف قديم',
  '2 tsp': '2 ملعقة صغيرة',
  'tins of something,': 'علب من شيء ما،',
  'drained': 'مصفّاة',
  'smoked paprika': 'بابريكا مدخنة',
  'Sun 8 Nov': 'الأحد 8 نوفمبر',
  'Tue 10 Nov': 'الثلاثاء 10 نوفمبر',
  'One line': 'سطر واحد',
  'The second': 'العدد الثاني',
  'Issue kept in your collection.': 'بقي العدد في مجموعتك.',
  'Keep this issue?': 'أتحتفظ بهذا العدد؟',
  'Keep': 'احتفظ',
  'Read it again whenever you like.': 'اقرأه مجددًا متى شئت.',
  'Share link copied.': 'نُسخ رابط المشاركة.',
  'Save this issue': 'احفظ هذا العدد',
  'Issue saved.': 'حُفظ العدد.',
  'Show details': 'اعرض التفاصيل',
  'A panel for the longer explanation, with room to read and a clear way back.':
      'لوحة للشرح الأطول، فيها متسع للقراءة وطريق واضح للعودة.',
  'Issue details': 'تفاصيل العدد',
  'Save again': 'احفظ مجددًا',
  'Issue saved to your collection': 'حُفظ العدد في مجموعتك',
  'Undo': 'تراجع',
  'Link copied': 'نُسخ الرابط',
  'Issue saved': 'حُفظ العدد',
  'Toast': 'إشعار عابر',
  'Explain': 'اشرح',
  'Announcement': 'إعلان',
  'Dialog': 'حوار',
  'Sheet': 'ورقة',
  'Page': 'صفحة',
  'Menu': 'قائمة',
  'Save this issue to your collection': 'احفظ هذا العدد في مجموعتك',
  'A longer explanation belongs in this panel.':
      'يليق الشرح الأطول بهذه اللوحة.',
  'It will stay in your collection.': 'سيبقى في مجموعتك.',
  'Save undone.': 'أُلغي الحفظ.',
  'Out Friday': 'يصدر الجمعة',
  'Reading now': 'قيد القراءة',
  'The second issue': 'العدد الثاني',
  'The third issue': 'العدد الثالث',
  'Two minutes': 'دقيقتان',
  'Confirm the first thing': 'أكّد الأمر الأول',
  'Sign the long form for the second one': 'وقّع النموذج الطويل للأمر الثاني',
  'Before 15:00, it needs a yes': 'قبل 15:00، يحتاج إلى موافقة',
  'Signed': 'موقّع',
  'Confirmed': 'مؤكَّد',
  'Confirm': 'تأكيد',
  'Sign': 'توقيع',
  'The coast walk': 'مسار الساحل',
  'Three days, one bag': 'ثلاثة أيام، حقيبة واحدة',
  'Your name': 'اسمك',
  'Each': 'للفرد',
  'Lit': 'مضاء',
  '14 of 20': '14 من 20',
  'Up to six': 'حتى ستة',
  'People': 'الأشخاص',
  'In all': 'الإجمالي',
  'The first of a kind': 'الأول من نوعه',
  'The second of a kind': 'الثاني من نوعه',
  'Under a rule': 'تحت خط',
  'Under a strong one': 'تحت خط عريض',
  'The first thing': 'الأمر الأول',
  'The thing that matters': 'الأمر المهم',
  'Its line': 'سطره',
  'Back a page.': 'رجوع صفحة.',
  'Closed.': 'أُغلق.',
  'Unavailable': 'غير متاح',
  'Saving': 'جارٍ الحفظ',
  'Open the drawer': 'افتح الدرج',
  'Amount': 'المبلغ',
  'Member number': 'رقم العضوية',
  'Write your whole name, as on your card.': 'اكتب اسمك كاملًا كما على بطاقتك.',
  'We only write about your orders.': 'لا نراسلك إلا بشأن طلباتك.',
  // The rest of the ten screens: feedback's sections, the sizes, the decision on a real screen.
  'A count badge': 'شارة عدد',
  'A meter': 'مقياس',
  'A skeleton': 'هيكل تحميل',
  'A tag': 'وسم',
  'An error': 'خطأ',
  'Tones': 'النبرات',
  'Waiting': 'انتظار',
  'Whatever the state': 'أيًّا كانت الحالة',
  'Small': 'صغير',
  'Medium': 'متوسط',
  'Large': 'كبير',
  'Saved items': 'العناصر المحفوظة',
  'Your collection has 12 saved items. You can keep them for later.':
      'في مجموعتك 12 عنصرًا محفوظًا. يمكنك الاحتفاظ بها لوقت لاحق.',
  'Review saved items': 'راجع العناصر المحفوظة',
  'Keep your saved items?': 'أتحتفظ بعناصرك المحفوظة؟',
  'Keep the collection for another day, or remove these items from your list.':
      'احتفظ بالمجموعة ليوم آخر، أو أزل هذه العناصر من قائمتك.',
  'Remove them': 'أزلها',
  'Keep them': 'احتفظ بها',
  'Your items are kept.': 'احتُفظ بعناصرك.',
  'Your items were removed.': 'أُزيلت عناصرك.',
};

/// Comic's own words (a retry, a dismiss, the text menu, a pager) in the gallery's language: Arabic when it reads right
/// to left, else English. Synchronous, as the words are at hand.
class KitComicWords extends LocalizationsDelegate<ComicLocalizations> {
  /// Arabic when [arabic].
  const KitComicWords({required this.arabic});

  /// The gallery reads in Arabic.
  final bool arabic;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<ComicLocalizations> load(Locale locale) => SynchronousFuture(
    arabic ? const KitComicWordsArabic() : const ComicLocalizationsEn(),
  );

  @override
  bool shouldReload(KitComicWords old) => old.arabic != arabic;
}

/// Comic's own words in Arabic: how an app of yours gives Comic its language, a subclass of [ComicLocalizationsEn]
/// whose delegate loads it. Months and weekdays stay with the calendar's own.
class KitComicWordsArabic extends ComicLocalizationsEn {
  /// The words, in Arabic.
  const KitComicWordsArabic();

  @override
  String get dismiss => 'إغلاق';
  @override
  String get tryAgain => 'حاول مجددًا';
  @override
  String get send => 'إرسال';
  @override
  String get less => 'أقل';
  @override
  String get more => 'أكثر';
  @override
  String get choose => 'اختر';
  @override
  String get chooseDate => 'اختر تاريخًا';
  @override
  String get chooseTime => 'اختر وقتًا';
  @override
  String get hour => 'الساعة';
  @override
  String get minute => 'الدقيقة';
  @override
  String get period => 'صباحًا أو مساءً';
  @override
  String get am => 'ص';
  @override
  String get pm => 'م';
  @override
  String get mainNavigation => 'الرئيسية';
  @override
  String get tabs => 'علامات التبويب';
  @override
  String get average => 'المتوسط';
  @override
  String get cut => 'قص';
  @override
  String get copy => 'نسخ';
  @override
  String get paste => 'لصق';
  @override
  String get selectAll => 'تحديد الكل';
  @override
  String get delete => 'حذف';
  @override
  String get lookUp => 'بحث';
  @override
  String get searchWeb => 'البحث في الويب';
  @override
  String get share => 'مشاركة';
  @override
  String get scanText => 'مسح النص ضوئيًا';
  @override
  String rating(int count, int total) => '$count من $total';
  @override
  String rate(int count, int total) => 'قيّم $count من $total';
  @override
  String page(int page, int total) => 'الصفحة $page من $total';
  @override
  String get breadcrumbs => 'أنت هنا';
  @override
  String get previous => 'السابق';
  @override
  String get next => 'التالي';
  @override
  String get dropFiles => 'أفلت الملفات هنا';
  @override
  String get chooseFiles => 'اختر ملفات';
  @override
  String removeFile(String name) => 'أزل $name';
  @override
  String get noData => 'لا شيء لعرضه بعد';
  @override
  String get stepDone => 'تم';
  @override
  String get stepNow => 'الآن';
  @override
  String get stepUpcoming => 'لاحقًا';
  @override
  String rangeFrom(String label) => '$label، من';
  @override
  String rangeTo(String label) => '$label، إلى';
  @override
  String get searchCommands => 'اكتب أمرًا';
  @override
  String get selectRow => 'حدد الصف';
  @override
  String get selectPage => 'حدد هذه الصفحة';
  @override
  String get resize => 'تغيير الحجم';
  @override
  String get notifications => 'الإشعارات';
}
