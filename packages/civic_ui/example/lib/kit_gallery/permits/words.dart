// The service's words in Arabic, keyed by their English: the app says each
// in the reader's language (`context.say('Continue')`). Civic's own parts
// take their built-in words (Back, Close) from ui_core's localizations.
import 'package:flutter/widgets.dart';

/// Says [english] in the language of the app at [context]: Arabic while it
/// reads right to left.
extension PermitsSay on BuildContext {
  /// The words in the reader's language.
  String say(String english) => Directionality.of(this) == TextDirection.rtl
      ? permitsArabic[english] ?? english
      : english;
}

/// What the reader typed (an address, a name, a file's name), each line kept
/// in its own order inside a page of either direction: "14 Ropewalk Row" on
/// an Arabic page still reads from 14. Each line is a first-strong isolate.
String permitsAsTyped(String typed) =>
    typed.split('\n').map((line) => '\u2068$line\u2069').join('\n');

/// A reference number (BRM-4821-K) as a span: in the page's own face (its
/// 0 and O, 1 and I are already told apart), left to right in a page of
/// either direction, and never broken at its hyphens. [style] sets its size
/// and weight; the words round it give the rest.
TextSpan permitsReference(
  BuildContext context,
  String reference, {
  TextStyle? style,
}) => TextSpan(
  text: '\u2066${reference.replaceAll('-', '-\u2060')}\u2069',
  style: style,
);

/// The service's words in Arabic.
const Map<String, String> permitsArabic = {
  'Brindlemere parking permits': 'تصاريح الوقوف في برندلمير',
  'Overview': 'نظرة عامة',
  'Apply': 'تقديم طلب',
  'Applications': 'الطلبات',
  'Settings': 'الإعدادات',
  'Skip to main content': 'انتقل إلى المحتوى الرئيسي',
  'Your account': 'حسابك',
  'Step 1 of 3': 'الخطوة 1 من 3',
  'Step 2 of 3': 'الخطوة 2 من 3',
  'Step 3 of 3': 'الخطوة 3 من 3',
  'Apply for a resident parking permit': 'التقديم على تصريح وقوف للمقيمين',
  'Use this service to apply for a permit to park on your street in a Brindlemere permit zone.': 'استخدم هذه الخدمة للتقديم على تصريح يسمح لك بالوقوف في شارعك ضمن مناطق التصاريح في برندلمير.',
  'Applying takes around 10 minutes.': 'يستغرق التقديم نحو 10 دقائق.',
  'Before you start': 'قبل أن تبدأ',
  'You will need:': 'ستحتاج إلى:',
  'your address and date of birth': 'عنوانك وتاريخ ميلادك',
  'proof of your address, such as a tenancy agreement':
      'إثبات عنوانك، مثل عقد الإيجار',
  'Start now': 'ابدأ الآن',
  'A permit costs €60 a year. A motorcycle permit costs €30.':
      'يكلّف التصريح 60 يورو في السنة، وتصريح الدراجة النارية 30 يورو.',
  'What kind of vehicle is the permit for?': 'لأي نوع من المركبات هذا التصريح؟',
  'You can apply for one permit at a time.':
      'يمكنك التقديم على تصريح واحد في كل مرة.',
  'Car or van': 'سيارة أو شاحنة صغيرة',
  'Motorcycle': 'دراجة نارية',
  'Includes mopeds and scooters.': 'بما في ذلك الدراجات الصغيرة والسكوترات.',
  'Motorhome or campervan': 'منزل متنقل أو عربة تخييم',
  'Up to 3.5 tonnes.': 'حتى 3.5 طن.',
  'Continue': 'متابعة',
  'Select the kind of vehicle the permit is for':
      'اختر نوع المركبة التي تريد التصريح لها',
  'There is a problem': 'هناك مشكلة',
  'Your details': 'بياناتك',
  'What is your full name?': 'ما اسمك الكامل؟',
  'What is your date of birth?': 'ما تاريخ ميلادك؟',
  'What is your address?': 'ما عنوانك؟',
  'Address line 1': 'سطر العنوان 1',
  'Town or city': 'البلدة أو المدينة',
  'Postcode': 'الرمز البريدي',
  'Date of birth': 'تاريخ الميلاد',
  'For example, 27 3 1987': 'مثال: 27 3 1987',
  'Day': 'اليوم',
  'Month': 'الشهر',
  'Year': 'السنة',
  'Proof of address': 'إثبات العنوان',
  'A council tax bill or a tenancy agreement, as a PDF or a photo.':
      'فاتورة ضريبة البلدية أو عقد إيجار، بصيغة PDF أو صورة.',
  'Choose file': 'اختر ملفًا',
  'Choose another file': 'اختر ملفًا آخر',
  'No file chosen': 'لم يتم اختيار ملف',
  'Remove': 'إزالة',
  'Enter your full name': 'أدخل اسمك الكامل',
  'Enter the first line of your address': 'أدخل السطر الأول من عنوانك',
  'Enter your town or city': 'أدخل بلدتك أو مدينتك',
  'Enter a postcode': 'أدخل رمزًا بريديًا',
  'Enter your date of birth': 'أدخل تاريخ ميلادك',
  'Date of birth must be a real date':
      'يجب أن يكون تاريخ الميلاد تاريخًا صحيحًا',
  'Upload proof of your address': 'حمّل إثبات عنوانك',
  'Check your answers before sending your application':
      'راجع إجاباتك قبل إرسال طلبك',
  'Vehicle': 'المركبة',
  'Name': 'الاسم',
  'Address': 'العنوان',
  'Change': 'تغيير',
  'Now send your application': 'أرسل طلبك الآن',
  'By sending this application you confirm that, to the best of your knowledge, the details you are providing are correct.':
      'بإرسال هذا الطلب، تؤكد أن البيانات التي تقدمها صحيحة على حد علمك.',
  'Accept and send': 'موافقة وإرسال',
  'Application sent': 'تم إرسال الطلب',
  'Your reference number': 'رقمك المرجعي',
  'We have sent you a confirmation email.':
      'أرسلنا إليك رسالة تأكيد بالبريد الإلكتروني.',
  'What happens next': 'ماذا يحدث بعد ذلك',
  'We will check your proof of address and decide within 5 working days. We will email you when we have decided.': 'سنتحقق من إثبات عنوانك ونتخذ قرارًا خلال 5 أيام عمل، وسنراسلك بالبريد الإلكتروني عند اتخاذ القرار.',
  'View your applications': 'عرض طلباتك',
  'What did you think of this service?': 'ما رأيك في هذه الخدمة؟',
  'Your applications': 'طلباتك',
  'Resident permit, Zone\u00A0B': 'تصريح مقيم، المنطقة\u00A0ب',
  'Visitor permits, 10\u00A0days': 'تصاريح زوار، 10\u00A0أيام',
  'Second permit, Zone\u00A0B': 'تصريح ثانٍ، المنطقة\u00A0ب',
  'Sent 3\u00A0November': 'أُرسل في 3\u00A0نوفمبر',
  'Sent 12\u00A0October': 'أُرسل في 12\u00A0أكتوبر',
  'Sent 2\u00A0September': 'أُرسل في 2\u00A0سبتمبر',
  'In review': 'قيد المراجعة',
  'Approved': 'موافق عليه',
  'Refused': 'مرفوض',
  'Status': 'الحالة',
  'Filter': 'تصفية',
  'Apply for another permit': 'التقديم على تصريح آخر',
  'Showing 3 applications': 'عرض 3 طلبات',
  'Showing 1 application': 'عرض طلب واحد',
  'No applications match': 'لا توجد طلبات مطابقة',
  'Clear the filters to see every application.':
      'امسح عوامل التصفية لرؤية كل الطلبات.',
  'Contact preferences': 'تفضيلات التواصل',
  'Select all that apply.': 'اختر كل ما ينطبق.',
  'Email': 'البريد الإلكتروني',
  'Text message': 'رسالة نصية',
  'Post': 'البريد',
  'Language': 'اللغة',
  'Accessibility': 'إمكانية الوصول',
  'Larger text': 'نص أكبر',
  'Reminders': 'التذكيرات',
  'Text size': 'حجم النص',
  'Makes the words on every page bigger.': 'يكبّر الكلمات في كل الصفحات.',
  'Appearance': 'المظهر',
  'Light': 'فاتح',
  'Dark': 'داكن',
  'Match this device': 'مطابقة هذا الجهاز',
  'Renewal reminders': 'تذكيرات التجديد',
  'We will remind you a month before your permit ends.':
      'سنذكّرك قبل انتهاء تصريحك بشهر.',
  'Save settings': 'حفظ الإعدادات',
  'Your settings have been saved': 'تم حفظ إعداداتك',
  'Success': 'تم بنجاح',
  'Zone\u00A0B: Harbourside': 'المنطقة\u00A0ب: الواجهة البحرية',
  'January': 'يناير',
  'February': 'فبراير',
  'March': 'مارس',
  'April': 'أبريل',
  'May': 'مايو',
  'June': 'يونيو',
  'July': 'يوليو',
  'August': 'أغسطس',
  'September': 'سبتمبر',
  'October': 'أكتوبر',
  'November': 'نوفمبر',
  'December': 'ديسمبر',
  'Completed': 'مكتملة',
  'In progress': 'قيد التنفيذ',
  'Not yet started': 'لم تبدأ بعد',
  'Cannot start yet': 'لا يمكن البدء بعد',
  'You have completed 1 of 3 tasks.': 'أكملت 1 من 3 مهام.',
  '1. Prepare your application': '1. جهّز طلبك',
  '2. Apply': '2. قدّم الطلب',
  'What kind of vehicle the permit is for': 'نوع المركبة التي تريد التصريح لها',
  'Your name, address and proof of address': 'اسمك وعنوانك وإثبات العنوان',
  'Check and send': 'المراجعة والإرسال',
  'Check your answers, then send them to us': 'راجع إجاباتك ثم أرسلها إلينا',
  'Not sure of your zone?': 'لست متأكدًا من منطقتك؟',
  'Takes around 10 minutes': 'يستغرق نحو 10 دقائق',
  '€60 a year': '60 يورو في السنة',
  'A motorcycle permit costs €30.': 'تصريح الدراجة النارية 30 يورو.',
  'You will need': 'ستحتاج إلى',
  'Your address and date of birth': 'عنوانك وتاريخ ميلادك',
  'Proof of your address': 'إثبات عنوانك',
  'Such as a tenancy agreement': 'مثل عقد إيجار',
  'Find your permit zone': 'اعثر على منطقة تصريحك',
  'Reference': 'الرقم المرجعي',
  'Sent': 'تاريخ الإرسال',
  'Documents': 'المستندات',
  'History': 'السجل',
  'Open': 'فتح',
  'What you can do': 'ما يمكنك فعله',
  'Your permit application': 'طلب تصريحك',
  'We have sent you a link to withdraw it.': 'أرسلنا إليك رابطًا لسحبه.',
  'Withdraw this application?': 'هل تريد سحب هذا الطلب؟',
  'You will need to apply again to park in your zone.':
      'ستحتاج إلى التقديم مرة أخرى لتركن سيارتك في منطقتك.',
  'Withdraw application': 'سحب الطلب',
  'Keep it': 'الإبقاء عليه',
  'Contact the parking team': 'تواصل مع فريق المواقف',
  'Proof of address checked': 'تم التحقق من إثبات العنوان',
  'Application received': 'تم استلام الطلب',
  'Permit approved': 'تمت الموافقة على التصريح',
  'Application refused': 'تم رفض الطلب',
  'We matched your tenancy agreement to your address.':
      'طابقنا عقد إيجارك مع عنوانك.',
  'We will decide within 5 working days.': 'سنتخذ قرارنا خلال 5 أيام عمل.',
  'Your visitor permits are ready to use.': 'تصاريح الزوار جاهزة للاستخدام.',
  'A household in Zone\u00A0B can hold two resident permits.':
      'يحق للأسرة في المنطقة\u00A0ب تصريحان للمقيمين.',
  '3 November 2026': '3 نوفمبر 2026',
  '5 November 2026': '5 نوفمبر 2026',
  '12 October 2026': '12 أكتوبر 2026',
  '14 October 2026': '14 أكتوبر 2026',
  '2 September 2026': '2 سبتمبر 2026',
  '9 September 2026': '9 سبتمبر 2026',
  'You have no applications yet': 'ليس لديك طلبات بعد',
  'When you apply for a permit, it will show here.':
      'عندما تقدّم طلبًا للحصول على تصريح، سيظهر هنا.',
  'Clear filters': 'مسح عوامل التصفية',
  'Tick statuses to narrow the list.': 'اختر حالات لتضييق القائمة.',
  'Tick zones to narrow the list.': 'اختر مناطق لتضييق القائمة.',
  'Filter by status': 'التصفية حسب الحالة',
  'Filter by zone': 'التصفية حسب المنطقة',
  'Apply for a permit': 'التقديم على تصريح',
  'Sorry, we cannot show your applications right now':
      'عذرًا، لا يمكننا عرض طلباتك الآن',
  'Sorry, street search is not working right now':
      'عذرًا، البحث عن الشوارع لا يعمل الآن',
  'Choose a file that proves your address': 'اختر ملفًا يثبت عنوانك',
  'Your applications are safe: nothing has been lost.':
      'طلباتك محفوظة ولم يُفقد منها شيء.',
  'You can still apply: we will find your zone from your address.':
      'لا يزال بإمكانك التقديم، وسنحدد منطقتك من عنوانك.',
  'Search for a street': 'ابحث عن شارع',
  'For example, Ropewalk\u00A0Row': 'مثال: Ropewalk\u00A0Row',
  'Zone': 'المنطقة',
  '1 street': 'شارع واحد',
  '23 streets': '23 شارعًا',
  'No streets match “Quillon”': 'لا توجد شوارع تطابق "Quillon"',
  'To find more streets:': 'للعثور على شوارع أكثر:',
  'check the spelling of the street': 'تحقق من تهجئة اسم الشارع',
  'search for its name without the house number': 'ابحث باسمه دون رقم المنزل',
  'clear the zone filters': 'امسح عوامل تصفية المناطق',
  'Zone\u00A0A: Old Town': 'المنطقة\u00A0أ: البلدة القديمة',
  'Zone\u00A0C: Millbrook': 'المنطقة\u00A0ج: ميلبروك',
  'Zone D: Fernlea': 'المنطقة د: فيرنلي',
  'Permits every day, 8am to 8pm':
      'التصاريح مطلوبة كل يوم، من 8 صباحًا إلى 8 مساءً',
  'Permits Monday to Saturday, 8am to 6pm':
      'التصاريح مطلوبة من الاثنين إلى السبت، من 8 صباحًا إلى 6 مساءً',
  'Permits Monday to Friday, 9am to 5pm':
      'التصاريح مطلوبة من الاثنين إلى الجمعة، من 9 صباحًا إلى 5 مساءً',
};
