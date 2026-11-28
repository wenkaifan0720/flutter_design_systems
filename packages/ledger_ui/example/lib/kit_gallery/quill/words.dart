/// Quill's words: English, or Hebrew when the app reads right to left, so
/// a mirrored Quill shows a language that reads that way rather than
/// English reordered by the bidi algorithm ("8 of 12 packed" read as "of
/// 12 packed 8"). Figures, codes and money stay as they are: left to
/// right inside the words, as a Hebrew ledger writes them.
library;

import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

import '../kit.dart';

/// A figure in words: a masked number's dots, a sign, a currency, digits
/// with their commas and points (ending on a digit, so a sentence's full
/// stop stays outside), a percent.
final RegExp _figure = RegExp(r'(?:··)?[+−-]?[$₪]?\d(?:[\d,.]*\d)?%?');

String _figuresHeld(String words) =>
    words.replaceAllMapped(_figure, (m) => LedgerFormat.isolated(m[0]!));

/// Quill's words in the language its reading direction asks for.
extension QuillWords on BuildContext {
  /// Whether Quill reads right to left here, and so speaks Hebrew.
  bool get quillHebrew => Directionality.of(this) == TextDirection.rtl;

  /// [english], or its Hebrew when Quill reads right to left, each figure
  /// in it then held left to right ([LedgerFormat.isolated]): "+$73.42",
  /// never "$73.42+".
  String say(String english) => quillHebrew
      ? _figuresHeld(quillHebrewWords[english] ?? english)
      : english;

  /// A day as a seal stamps it: "Oct 28", or "28 באוק׳".
  String sayDate(DateTime d) => quillHebrew
      ? '${d.day} ב${_heMonthsShort[d.month - 1]}'
      : LedgerFormat.date(d);

  /// A day in full over a page: "Wednesday, October 28", or
  /// "יום רביעי, 28 באוקטובר".
  String sayToday(DateTime d) => quillHebrew
      ? '${_heWeekdays[d.weekday % 7]}, ${d.day} ב${_heMonths[d.month - 1]}'
      : LedgerFormat.today(d);

  /// An entry's time: "8:12 AM", or "08:12" (Hebrew keeps the 24 hours).
  String sayTime(KitTx tx) => quillHebrew
      ? '${tx.at.hour.toString().padLeft(2, '0')}:'
            '${tx.at.minute.toString().padLeft(2, '0')}'
      : tx.time;

  /// [tx] in Quill's language.
  KitTx sayTx(KitTx tx) => !quillHebrew
      ? tx
      : KitTx(
          id: tx.id,
          title: say(tx.title),
          lead: tx.lead == null ? null : quillInitials(say(tx.title)),
          icon: tx.icon,
          subtitle: say(tx.subtitle),
          time: sayTime(tx),
          day: say(tx.day),
          account: say(tx.account),
          amount: tx.amount,
          at: tx.at,
          income: tx.income,
          moved: tx.moved,
          pending: tx.pending,
        );

  /// [day] in Quill's language, its entries with it.
  KitDay sayDay(KitDay day) => !quillHebrew
      ? day
      : KitDay(
          say(day.label),
          day.note == null ? null : say(day.note!),
          day.net,
          [for (final tx in day.rows) sayTx(tx)],
        );

  /// The owner, in Quill's language.
  LedgerAccount get sayOwner => !quillHebrew
      ? kitMaren
      : LedgerAccount(
          name: say(kitMaren.name),
          initials: quillInitials(say(kitMaren.name)),
          meta: say(kitMaren.meta!),
          unread: kitMaren.unread,
          onProfilePressed: kitMaren.onProfilePressed,
          onNotificationsPressed: kitMaren.onNotificationsPressed,
          searchHint: say(kitMaren.searchHint!),
          onSearchPressed: kitMaren.onSearchPressed,
        );
}

/// The first letters of [name]'s first two words: a monogram's initials.
String quillInitials(String name) {
  final words = name
      .split(RegExp(r'[\s·&]+'))
      .where((w) => w.isNotEmpty)
      .toList();
  return words.take(2).map((w) => w.characters.first).join();
}

const List<String> _heMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', //
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

const List<String> _heMonthsShort = [
  'ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יוני', //
  'יולי', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳',
];

/// Sunday first (DateTime.weekday % 7).
const List<String> _heWeekdays = [
  'יום ראשון', 'יום שני', 'יום שלישי', 'יום רביעי', //
  'יום חמישי', 'יום שישי', 'שבת',
];

/// Every English word Quill shows, and its Hebrew.
const Map<String, String> quillHebrewWords = {
  // The frame.
  'Quill': 'קוויל',
  'Ledger': 'פנקס',
  'Home': 'בית',
  'Register': 'יומן',
  'Settings': 'הגדרות',
  'New entry': 'רישום חדש',
  'Maren Holt': 'מרן הולט',
  'Since Mar 2023': 'מאז מרץ 2023',
  'Search activity': 'חיפוש בפעילות',
  // The Register's searches: a payee's word, and one no entry has.
  'Blue Fern': 'שרך כחול',
  'Zanzibar': 'זנזיבר',
  'Not loaded': 'לא נטען',
  // Signed out, in place of the account.
  'You are signed out': 'התנתקת',
  'Sign in to see your accounts and entries.':
      'התחברו כדי לראות את החשבונות והרישומים שלך.',
  'Sign in': 'התחברות',
  // Home.
  'Good evening, Maren': 'ערב טוב, מרן',
  'Good evening,': 'ערב טוב,',
  'Net worth': 'שווי נקי',
  'since September': 'מאז ספטמבר',
  'Accounts': 'חשבונות',
  'Balance': 'יתרה',
  'Recent': 'אחרונים',
  'Time': 'שעה',
  'Payee': 'מוטב',
  'Category': 'קטגוריה',
  'Account': 'חשבון',
  'Amount': 'סכום',
  // The accounts.
  'Everyday': 'עו״ש',
  'Checking ··4821': 'עובר ושב ··4821',
  'Savings': 'חיסכון',
  '4.10% APY ··9015': 'תשואה 4.10% ··9015',
  r'+$73.42 in Oct': r'+$73.42 באוקטובר',
  'Lisbon fund': 'קרן ליסבון',
  'Goal pot': 'קופת יעד',
  r'71% of $4,000': r'71% מתוך $4,000',
  'Wren Card': 'כרטיס רן',
  'Credit ··7730': 'אשראי ··7730',
  'Due Nov 12 · autopay': 'לתשלום ב־12 בנוב׳ · הוראת קבע',
  'Investing': 'השקעות',
  'Brokerage': 'תיק השקעות',
  r'+$391.37 today (+0.81%)': r'+$391.37 היום (+0.81%)',
  // The register's days, payees and categories.
  'Today': 'היום',
  'Yesterday': 'אתמול',
  'Wed, Oct 28': 'יום ד׳, 28 באוק׳',
  'Tue, Oct 27': 'יום ג׳, 27 באוק׳',
  'Mon, Oct 26': 'יום ב׳, 26 באוק׳',
  'Sun, Oct 25': 'יום א׳, 25 באוק׳',
  'Alder Pharmacy': 'בית מרקחת אלדר',
  'Blue Fern Café': 'קפה שרך כחול',
  'Cinema Lumen': 'קולנוע לומן',
  'Corner Larder': 'המזווה שבפינה',
  'Field & Thread': 'שדה וחוט',
  'Green Basket Market': 'שוק הסל הירוק',
  'Harbor Transit': 'תחבורת הנמל',
  'Streamline Music': 'מוזיקה בזרם',
  'Dining out': 'מסעדות',
  'Fun': 'בילויים',
  'Groceries': 'מכולת',
  'Health': 'בריאות',
  'Shopping': 'קניות',
  'Subscriptions': 'מינויים',
  'Transport': 'תחבורה',
  // The register.
  'Show': 'הצגה',
  'All': 'הכול',
  'Money in': 'הכנסות',
  'Money out': 'הוצאות',
  'Pending': 'ממתין',
  'Nothing here': 'אין כאן כלום',
  'No entry matches this filter.': 'אין רישום שמתאים לסינון הזה.',
  'entries since': 'רישומים מאז',
  'October': 'אוקטובר',
  'Search entries': 'חיפוש ברישומים',
  'Nothing found': 'לא נמצא דבר',
  'No entry has these words. Try a payee or a category.':
      'אין רישום עם המילים האלה. נסו שם מוטב או קטגוריה.',
  'The register could not load': 'לא ניתן לטעון את היומן',
  'Quill could not reach your accounts. Your entries are safe.':
      'קוויל לא הצליח להגיע לחשבונות שלך. הרישומים שלך שמורים.',
  'Try again': 'ניסיון נוסף',
  // A receipt.
  'Quill · Money in': 'קוויל · הכנסה',
  'Quill · Entry': 'קוויל · רישום',
  'No.': 'מס׳',
  'Received': 'התקבל',
  'Posted': 'נרשם',
  'Status': 'מצב',
  'Day': 'יום',
  // An account's sheet.
  'Last entries': 'רישומים אחרונים',
  'Move money': 'העברת כסף',
  'Statement': 'דף חשבון',
  'Available': 'זמין',
  'Close': 'סגירה',
  // A new entry.
  'Who was paid': 'למי שולם',
  'Choose one': 'בחרו אחת',
  'Everyday ··4821': 'עו״ש ··4821',
  'Wren Card ··7730': 'כרטיס רן ··7730',
  'Savings ··9015': 'חיסכון ··9015',
  'Today, Oct 28': 'היום, 28 באוק׳',
  'Yesterday, Oct 27': 'אתמול, 27 באוק׳',
  'Monday, Oct 26': 'יום שני, 26 באוק׳',
  'Repeat': 'חזרה',
  'Never': 'אף פעם',
  'Every week': 'כל שבוע',
  'Every month': 'כל חודש',
  'Note': 'הערה',
  'What it was for': 'על מה',
  'Keep the receipt with the entry': 'לשמור את הקבלה עם הרישום',
  'Count it against the budget': 'לחשב אותו בתקציב',
  'Save entry': 'שמירת רישום',
  'Enter what was paid': 'הזינו כמה שולם',
  'Enter an amount such as 17.43': 'הזינו סכום כמו 17.43',
  'Say who was paid': 'ציינו למי שולם',
  'Choose a category': 'בחרו קטגוריה',
  'Entry saved to the register': 'הרישום נשמר ביומן',
  'As it will print': 'כפי שיודפס',
  'Quill · New entry': 'קוויל · רישום חדש',
  'No category': 'ללא קטגוריה',
  'Draft': 'טיוטה',
  // Settings.
  'Quill 1.0': 'קוויל 1.0',
  'Profile': 'פרופיל',
  'Name': 'שם',
  'Email': 'דוא״ל',
  'Phone': 'טלפון',
  'Change name': 'שינוי השם',
  'Change email': 'שינוי הדוא״ל',
  'Change phone': 'שינוי הטלפון',
  'Save': 'שמירה',
  'Alerts': 'התראות',
  'What Quill tells you': 'על מה קוויל מודיע',
  'Bills': 'חשבונות לתשלום',
  'A reminder before each bill is due': 'תזכורת לפני מועד כל חשבון',
  'Budgets': 'תקציבים',
  'When a category goes over': 'כשקטגוריה חורגת',
  'Large purchases': 'רכישות גדולות',
  r'Over $200': r'מעל $200',
  'Weekly summary': 'סיכום שבועי',
  'Mondays, the week in one note': 'בימי שני, השבוע בהודעה אחת',
  'Currency': 'מטבע',
  'US dollar': 'דולר אמריקאי',
  'Accounts are kept in dollars': 'החשבונות מנוהלים בדולרים',
  'Week starts on': 'השבוע מתחיל ביום',
  'The first day of each week': 'היום הראשון בכל שבוע',
  'Monday': 'שני',
  'Sunday': 'ראשון',
  'Density': 'צפיפות',
  'Compact fits more entries on a screen': 'דחוסה מציגה יותר רישומים במסך',
  'Standard': 'רגילה',
  'Comfortable': 'מרווחת',
  'Compact': 'דחוסה',
  'Preferences': 'העדפות',
  'This device': 'המכשיר הזה',
  'Appearance': 'מראה',
  'Paper and ink': 'נייר ודיו',
  'Light': 'בהיר',
  'Dark': 'כהה',
  'As the system is': 'כמו במערכת',
  'Reading': 'קריאה',
  'Which way the pages run': 'לאיזה כיוון הדפים רצים',
  'Right to left': 'מימין לשמאל',
  'The pages mirrored, as Arabic and Hebrew read':
      'הדפים במראה, כפי שקוראים ערבית ועברית',
  'Sign out': 'התנתקות',
  'Sign out of Quill?': 'להתנתק מקוויל?',
  'Your entries stay on this device until you sign in again.':
      'הרישומים שלך נשארים במכשיר הזה עד להתחברות הבאה.',
  'Signed out': 'ההתנתקות בוצעה',
  // The Overview.
  'Ruled lines instead of boxes, the serif for money, small capitals for '
          'every label, and paper slips for the records that matter: an app '
          'set the way a ledger is.':
      'קווי סרגל במקום תיבות, אות סריף לכסף, אותיות קטנות לכל תווית, ופתקי '
      'נייר לרשומות החשובות: אפליקציה ערוכה כמו פנקס.',
  'Screens': 'מסכים',
  'Quill, built on it': 'קוויל, בנוי עליו',
  'The figure, the accounts, the last of the register':
      'הסכום, החשבונות, אחרוני היומן',
  'Every entry by day, filtered; each opens its receipt':
      'כל רישום לפי יום, מסונן; כל אחד פותח את הקבלה שלו',
  'A form on the rule, checked as it is filled':
      'טופס על הסרגל, נבדק בזמן המילוי',
  'Profile, alerts, preferences and the appearance':
      'פרופיל, התראות, העדפות ומראה',
  'In the package': 'בחבילה',
  'Parts': 'רכיבים',
  'Fields to slips': 'משדות ועד פתקים',
  'Forms, rows, the register, receipts, charts, navigation':
      'טפסים, שורות, היומן, קבלות, תרשימים, ניווט',
  'Widths': 'רוחבים',
  '320 to 1440': '320 עד 1440',
  'A tab bar, then a rail, then the side bar':
      'סרגל לשוניות, אחריו מסילה, ואז סרגל צד',
  'Light and dark': 'בהיר וכהה',
  'Both': 'שניהם',
  'Or your own paper, ink and accent': 'או נייר, דיו והדגשה משלך',
  'Access': 'נגישות',
  '40 targets': 'יעדי מגע של 40',
  'Spoken names, a double-ruled focus, text to 200%':
      'שמות מוקראים, מיקוד בקו כפול, טקסט עד 200%',
  'Add it': 'הוספה',
  'Corners of its own': 'פינות משלו',
  'A part takes its own step at each corner from its style: this slip and '
          "its button cut two diagonal corners square, as a ticket's stub is. "
          'A corner takes square to extra large, or round.':
      'כל רכיב מקבל מהסגנון שלו מדרגה משלו בכל פינה: הפתק הזה והכפתור שלו '
      'חותכים שתי פינות אלכסוניות ישרות, כמו ספח של כרטיס. פינה מקבלת ישרה '
      'עד גדולה מאוד, או עגולה.',
  'Print the receipt': 'הדפסת הקבלה',
  "In your app's builder, under a MaterialApp, a CupertinoApp or a "
          'WidgetsApp; then any part.':
      'ב־builder של האפליקציה, מתחת ל־MaterialApp, ל־CupertinoApp או '
      'ל־WidgetsApp; ואז כל רכיב.',
  'Every part': 'כל הרכיבים',
  'pages': 'עמודים',
};
