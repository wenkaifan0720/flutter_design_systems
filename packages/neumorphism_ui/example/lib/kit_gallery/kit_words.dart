/// The gallery's words in a reader's own script. Right to left, Hearth (the ten everyday screens), the gallery's
/// pages and its own keys read in Arabic, so the direction is checked on real script, not English reordered by bidi
/// ("8 of 12 packed" read "of 12 packed 8"). The household keeps its English names (a room is found by its name); a
/// word is put in Arabic where it is shown. Words not in the book (a part's own sample words) stay as written.
library;

import 'package:flutter/widgets.dart';

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

/// [template] in the gallery's language, its `{0}`, `{1}` … filled from [args] (already in that language).
String kitSayf(BuildContext context, String template, List<Object> args) {
  var words = kitSay(context, template);
  for (var i = 0; i < args.length; i++) {
    words = words.replaceAll('{$i}', '${args[i]}');
  }
  return words;
}

/// [en] in one of its senses: the book's '[en]#[sense]', or [en] as written. English says 'Home' for the screen and
/// for the house; Arabic needs two words.
String kitSayIn(BuildContext context, String en, String sense) =>
    KitWords.arabicOf(context)
    ? (_arabic['$en#$sense'] ?? kitSay(context, en))
    : en;

/// Whether [query] finds [en]: in its own words or, read in Arabic, in the book's.
bool kitFinds(BuildContext context, String en, String query) {
  final q = query.toLowerCase();
  return en.toLowerCase().contains(q) || kitSay(context, en).contains(query);
}

const _arabic = <String, String>{
  // The gallery's pages and its own keys.
  'Pages': 'الصفحات',
  'Overview': 'نظرة عامة',
  'Hearth, an app': 'Hearth، تطبيق',
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
  'Button groups': 'مجموعات الأزرار',
  'More fields': 'حقول أخرى',
  'Tables and trees': 'الجداول والأشجار',
  'Popovers and toasts': 'النوافذ المنبثقة والتنبيهات',
  'Records and status': 'السجلات والحالة',
  'Type and colour': 'الخط واللون',
  'Relief and dials': 'النقش والأقراص',
  'Shape roles': 'أدوار الأشكال',
  'Every component': 'كل المكوّنات',
  'Gallery': 'المعرض',
  'Neumorphism gallery': 'معرض Neumorphism',
  'Appearance': 'المظهر',
  'Day': 'نهار',
  'Night': 'ليل',
  'Customize': 'تخصيص',
  'Close Customize': 'إغلاق التخصيص',
  'Back to the gallery': 'العودة إلى المعرض',

  // Hearth's screens.
  'Home': 'الرئيسية',
  'Devices': 'الأجهزة',
  'Shop': 'المتجر',
  'Account': 'الحساب',
  'Settings': 'الإعدادات',

  // The house.
  '14 Harbour Street': '14 شارع الميناء',
  'Harbour Street': 'شارع الميناء',
  'Living room': 'غرفة المعيشة',
  'Kitchen': 'المطبخ',
  'Hall': 'الردهة',
  'Bedroom': 'غرفة النوم',
  'Study': 'المكتب',
  'Ground': 'الأرضي',
  'Upper': 'العلوي',
  'Upstairs': 'الطابق العلوي',
  'Ground floor': 'الطابق الأرضي',
  'Floor lamp': 'مصباح أرضي',
  'Reading lamp': 'مصباح القراءة',
  'Ceiling light': 'ضوء السقف',
  'Pendants': 'مصابيح معلّقة',
  'Hall light': 'ضوء الردهة',
  'Bedside lamp': 'مصباح السرير',
  'Ceiling fan': 'مروحة السقف',
  'Desk lamp': 'مصباح المكتب',
  'New lamp': 'مصباح جديد',
  'Hall lamp': 'مصباح الردهة',
  'Warm white bulb, 2700\u00A0K': 'لمبة بيضاء دافئة، 2700\u00A0كلفن',
  'Warm white bulb, 2200 K': 'لمبة بيضاء دافئة، 2200 كلفن',
  'Warm white bulb, 3000 K': 'لمبة بيضاء دافئة، 3000 كلفن',
  'Daylight panel, 4000 K': 'لوح ضوء النهار، 4000 كلفن',
  'Three warm white bulbs, 2700\u00A0K':
      'ثلاث لمبات بيضاء دافئة، 2700\u00A0كلفن',
  'Three speeds, quiet at night': 'ثلاث سرعات، هادئة ليلًا',
  'On at sunset, off at 23:30': 'يعمل عند الغروب ويتوقف الساعة 23:30',
  'No schedule': 'بلا جدول',
  'On at 7:00 on weekdays': 'يعمل الساعة 7:00 في أيام العمل',
  'On when the door opens after dark': 'يعمل حين يُفتح الباب بعد حلول الظلام',
  'Off at 23:00': 'يتوقف الساعة 23:00',
  '3 March 2026': '3 مارس 2026',
  '12 January 2025': '12 يناير 2025',
  '20 June 2025': '20 يونيو 2025',
  '8 August 2025': '8 أغسطس 2025',
  'Today': 'اليوم',
  'On': 'يعمل',
  'Off': 'متوقف',
  'On · {0}%': 'يعمل · {0}%',

  // Home.
  'The lights are off.': 'الأضواء مطفأة.',
  'One light is on.': 'ضوء واحد مُضاء.',
  '{0} lights are on.': '{0} أضواء مُضاءة.',
  'Warming to': 'يُدفّئ حتى',
  'Holding at': 'ثابت عند',
  'Now {0}': 'الآن {0}',
  'Lights': 'الأضواء',
  'Rooms': 'الغرف',
  'Press one to set it': 'اضغط غرفة لضبطها',
  'Here': 'هنا',
  'Door locked': 'الباب مقفل',
  'Garden': 'الحديقة',
  '*{0} of {1}* on': '*{0} من {1}* تعمل',
  'Outside': 'في الخارج',
  'Used today': 'استُهلك اليوم',
  'Cost today': 'تكلفة اليوم',

  // Devices.
  '{0} in your home, {1} on': '{0} في منزلك، {1} تعمل',
  'Add a device': 'إضافة جهاز',
  'Search devices': 'البحث في الأجهزة',
  'Search by name or room': 'ابحث بالاسم أو بالغرفة',
  'Nothing called "{0}"': 'لا شيء باسم «{0}»',
  'Try a room: kitchen, hall or study.':
      'جرّب غرفة: المطبخ أو الردهة أو المكتب.',
  'No device open': 'لا جهاز مفتوح',
  'Choose one from the list.': 'اختر جهازًا من القائمة.',
  'Switch it on and hold its button for three seconds; it joins your home.':
      'شغّله واضغط زرّه ثلاث ثوانٍ، فينضم إلى منزلك.',
  'Cancel': 'إلغاء',
  'Add device': 'إضافة الجهاز',
  'Name': 'الاسم',
  'Room': 'الغرفة',
  '{0} joined your home.': 'انضم {0} إلى منزلك.',
  'Remove {0}?': 'إزالة {0}؟',
  'It leaves your home and its schedule stops. You can add it again later.':
      'سيغادر منزلك ويتوقف جدوله. يمكنك إضافته مرة أخرى لاحقًا.',
  'Keep it': 'إبقاؤه',
  'Remove': 'إزالة',
  'Brightness {0}%': 'السطوع {0}%',
  'Bulb': 'اللمبة',
  'Schedule': 'الجدول',
  'Fitted': 'تاريخ التركيب',
  'Remove from home': 'إزالة من المنزل',

  // Shop.
  'Deliver to': 'التوصيل إلى',
  'Street': 'الشارع',
  'Town': 'المدينة',
  'Bristol': 'بريستول',
  'Enter a street address.': 'أدخل عنوان الشارع.',
  'Enter a town or city.': 'أدخل اسم البلدة أو المدينة.',
  'Enter a postcode.': 'أدخل الرمز البريدي.',
  'Info': 'معلومة',
  'Success': 'نجاح',
  'Warning': 'تنبيه',
  'Danger': 'خطر',
  'Your plan renews on 1\u00a0December.': 'يتجدد اشتراكك في ١\u00a0ديسمبر.',
  'Your details are saved.': 'تم حفظ بياناتك.',
  'The battery is at 15%.': 'مستوى البطارية ١٥٪.',
  'The heating did not start.': 'لم يبدأ تشغيل التدفئة.',
  'Postcode': 'الرمز البريدي',
  'Delivery': 'التوصيل',
  'Standard': 'عادي',
  'Monday 16 November': 'الاثنين 16 نوفمبر',
  'Free': 'مجاني',
  'Next day': 'اليوم التالي',
  'Tomorrow by 18:00': 'غدًا قبل 18:00',
  'Pay with': 'طريقة الدفع',
  'Card': 'بطاقة',
  'Bank': 'بنك',
  'Later': 'لاحقًا',
  'Checkout': 'إتمام الشراء',
  'A desk lamp for the study, and bulbs.': 'مصباح مكتب للمكتب، ولمبات.',
  'Your order': 'طلبك',
  'Arc desk lamp': 'مصباح مكتب مقوّس',
  'Porcelain, 42 cm': 'خزف، 42 سم',
  'Bulbs': 'اللمبات',
  'Warm white, {0} each': 'أبيض دافئ، {0} للواحدة',
  'Total': 'المجموع',
  'Order placed': 'تم الطلب',
  'Your desk lamp and {0} bulbs arrive {1}. We sent the receipt to {2}.':
      'يصل مصباح مكتبك و{0} لمبات {1}. أرسلنا الإيصال إلى \u2066{2}\u2069.',
  'tomorrow by 18:00': 'غدًا قبل 18:00',
  'on Monday 16 November': 'يوم الاثنين 16 نوفمبر',
  'Done': 'تم',
  'Pay {0}': 'ادفع {0}',
  'Pay': 'ادفع',

  // Account.
  'Alex': 'أليكس',
  'Morgan': 'مورغان',
  'First name': 'الاسم الأول',
  'Last name': 'اسم العائلة',
  'Email': 'البريد الإلكتروني',
  'Receipts and the weekly summary go here.':
      'تصل الإيصالات والملخص الأسبوعي إلى هنا.',
  'Phone': 'الهاتف',
  'For the courier, on delivery days only.':
      'لمندوب التوصيل، في أيام التوصيل فقط.',
  'Country': 'البلد',
  'United Kingdom': 'المملكة المتحدة',
  'Ireland': 'أيرلندا',
  'United States': 'الولايات المتحدة',
  'Save details': 'حفظ البيانات',
  'Enter an email address, like name@example.com.':
      'أدخل عنوان بريد إلكتروني، مثل name@example.com.',
  'Saved. Your receipts go to {0}.':
      'تم الحفظ. تصل إيصالاتك إلى \u2066{0}\u2069.',
  'Member since March 2024': 'عضو منذ مارس 2024',
  'Home#house': 'المنزل',
  'Shared with': 'مشترك مع',
  'Sam and Jordan': 'سام وجوردان',
  'Plan': 'الخطة',
  'Hearth Plus, renews 1 March': 'Hearth Plus، يتجدد في 1 مارس',

  // Settings.
  'Leave 14 Harbour Street?': 'مغادرة 14 شارع الميناء؟',
  'Its devices and schedules stay with Sam and Jordan. You can be invited back.':
      'تبقى أجهزته وجداوله مع سام وجوردان، ويمكن دعوتك مجددًا.',
  'Stay': 'البقاء',
  'Leave home': 'مغادرة المنزل',
  'Notifications': 'الإشعارات',
  'Weekly summary': 'الملخص الأسبوعي',
  'What your home used, each Monday by email.':
      'ما استهلكه منزلك، كل اثنين بالبريد الإلكتروني.',
  'Alerts on this phone': 'تنبيهات على هذا الهاتف',
  'A door left open, a room too cold.': 'باب تُرك مفتوحًا، أو غرفة باردة جدًا.',
  'Sound': 'الصوت',
  'Alert volume': 'مستوى صوت التنبيه',
  'Silent': 'صامت',
  'Out of 10': 'من 10',
  'While you are away': 'أثناء غيابك',
  'Lights on at sunset': 'الأضواء عند الغروب',
  'So the house looks lived in.': 'ليبدو المنزل مأهولًا.',
  'Privacy': 'الخصوصية',
  'Share usage, without names': 'مشاركة الاستخدام، بلا أسماء',
  'Helps us make the schedules better.': 'يساعدنا على تحسين الجداول.',
  'Leave this home': 'مغادرة هذا المنزل',
};
