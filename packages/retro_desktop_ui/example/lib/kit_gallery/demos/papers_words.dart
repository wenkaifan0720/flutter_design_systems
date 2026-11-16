/// Papers' words: English, or Hebrew when the app reads right to left, so a
/// mirrored Papers shows a language that reads that way rather than English
/// reordered by the bidi algorithm ("2 of 6 documents" read as "of 6
/// documents 2"). Figures, sizes, money and keys stay as they are: left to
/// right inside the words, as a Hebrew desktop writes them.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

/// Papers' words in the language its reading direction asks for.
extension KitPapersWords on BuildContext {
  /// Whether Papers reads right to left here, and so speaks Hebrew.
  bool get papersHebrew => Directionality.of(this) == TextDirection.rtl;

  /// [english], or its Hebrew when Papers reads right to left.
  String say(String english) =>
      papersHebrew ? papersHebrewFor(english) : english;
}

/// [english] in Hebrew, or as it is when it has no Hebrew (a figure, a key).
String papersHebrewFor(String english) => _hebrew[english] ?? english;

const Map<String, String> _hebrew = {
  // The app and its windows.
  'Papers': 'ניירות',
  'Documents': 'מסמכים',
  'Your details': 'הפרטים שלך',
  'Settings': 'הגדרות',
  'Order printed copies': 'הזמנת עותקים מודפסים',
  'Bin': 'פח',
  'Gallery': 'גלריה',
  // The documents.
  'Project notes': 'הערות הפרויקט',
  'Quarterly plan': 'תוכנית רבעונית',
  'Research log': 'יומן מחקר',
  'Meeting summary': 'סיכום פגישה',
  'Team handbook': 'מדריך הצוות',
  'Reading list': 'רשימת קריאה',
  'Document': 'מסמך',
  'Checklist': 'רשימת משימות',
  'Notebook': 'מחברת',
  'Today, 09:14': 'היום, 09:14',
  'Yesterday, 16:40': 'אתמול, 16:40',
  'Yesterday': 'אתמול',
  '4 November': '4 בנובמבר',
  '2 November': '2 בנובמבר',
  '28 October': '28 באוקטובר',
  '21 October': '21 באוקטובר',
  'The new filing plan starts on Monday. Each team keeps one folder for '
          'work in progress and one for what is finished.':
      'תוכנית התיוק החדשה מתחילה ביום שני. כל צוות שומר תיקייה אחת לעבודה '
      'שבתהליך ואחת למה שהסתיים.',
  'Morgan will send the printed handbook to the two new starters before '
          'the end of the month.':
      'המדריך המודפס יישלח לשני העובדים החדשים לפני סוף החודש.',
  'Three goals for the quarter: one place for every document, a weekly '
          'review, and printed copies on request.':
      'שלוש מטרות לרבעון: מקום אחד לכל מסמך, סקירה שבועית, ועותקים מודפסים '
      'לפי בקשה.',
  'Interviews with six teams about how they keep their papers. Most keep '
          'two copies of everything and trust neither.':
      'ראיונות עם שישה צוותים על האופן שבו הם שומרים את המסמכים שלהם. רובם '
      'שומרים שני עותקים מכל דבר ולא סומכים על אף אחד מהם.',
  'Agreed: documents move to the shared disk by Friday. Questions go to '
          'Alex.':
      'סוכם: המסמכים עוברים לדיסק המשותף עד יום שישי. שאלות אל אלכס.',
  'How we work together: where things live, who to ask, and what to do on '
          'your first day.':
      'איך אנחנו עובדים יחד: איפה כל דבר נמצא, את מי לשאול, ומה עושים ביום '
      'הראשון.',
  'Five books on keeping records, two of them out of print.':
      'חמישה ספרים על ניהול רשומות, שניים מהם אזלו מהדפוס.',
  // The documents window.
  'Name': 'שם',
  'Kind': 'סוג',
  'Changed': 'עודכן',
  'Size': 'גודל',
  'Find a document': 'חיפוש מסמך',
  'Check the spelling, or look for a kind: document, checklist or notebook.':
      'כדאי לבדוק את האיות, או לחפש לפי סוג: מסמך, רשימת משימות או מחברת.',
  'Order copies…': 'הזמנת עותקים…',
  'Open': 'פתיחה',
  '1.2 GB available': '1.2 GB פנויים',
  'Changes are kept as you make them': 'כל שינוי נשמר ברגע שהוא נעשה',
  // Your details.
  'Your name goes on the documents you share and on the copies you order.':
      'השם שלך מופיע על המסמכים שמשתפים ועל העותקים שמזמינים.',
  'Email address': 'כתובת אימייל',
  'Alex Lee': 'אלכס לי',
  'Alex Lee-Morgan': 'אלכס לי־מורגן',
  'Save new documents to': 'מקום השמירה למסמכים חדשים',
  'This computer': 'המחשב הזה',
  'The shared disk': 'הדיסק המשותף',
  'Cancel': 'ביטול',
  'Save': 'שמירה',
  'Your details are as they were': 'הפרטים שלך נשארו כפי שהיו',
  'Your details are saved': 'הפרטים שלך נשמרו',
  'Save the changes to your details?': 'לשמור את השינויים בפרטים שלך?',
  'If you close without saving, your changes are lost.':
      'סגירה בלי שמירה מוחקת את השינויים.',
  'Don’t save': 'לא לשמור',
  // Settings.
  'Save as I type': 'שמירה תוך כדי הקלדה',
  'Every change is kept as you make it.': 'כל שינוי נשמר ברגע שהוא נעשה.',
  'Keep a copy on this computer': 'שמירת עותק במחשב הזה',
  'Open your documents without a connection.':
      'אפשר לפתוח את המסמכים גם בלי חיבור.',
  'Notices': 'הודעות',
  'Tell me when a shared document changes': 'להודיע לי כשמסמך משותף משתנה',
  'Advanced': 'מתקדם',
  'Send a report when something goes wrong': 'שליחת דוח כשמשהו משתבש',
  'It holds no document, only what failed.':
      'הדוח לא כולל מסמכים, רק את מה שנכשל.',
  // An order for printed copies.
  'Item': 'פריט',
  'Copies': 'עותקים',
  'Price': 'מחיר',
  'Postage, standard': 'משלוח רגיל',
  'Postage, express': 'משלוח אקספרס',
  'Amount due': 'לתשלום',
  'Deliver to': 'משלוח אל',
  'Alex Lee, 12 Harbour Street, Leith': 'אלכס לי, רחוב הנמל 12, לית׳',
  'Postage': 'משלוח',
  'Standard, in 3 to 5 days, \$4.00': 'רגיל, תוך 3 עד 5 ימים, \$4.00',
  'Express, the next day, \$12.00': 'אקספרס, למחרת, \$12.00',
  'Pay with': 'אמצעי תשלום',
  'The card ending 4242': 'הכרטיס שמסתיים ב־4242',
  'An invoice, due in 30 days': 'חשבונית, לתשלום תוך 30 יום',
  'Place order': 'ביצוע הזמנה',
  'No copies ordered': 'לא הוזמנו עותקים',
  'Copies ordered: they arrive by post': 'העותקים הוזמנו: הם יגיעו בדואר',
  'The order wasn’t sent': 'ההזמנה לא נשלחה',
  'Papers couldn’t reach the print shop. Check your connection, then try '
          'again: your order is kept.':
      'ניירות לא הצליחה להגיע לבית הדפוס. כדאי לבדוק את החיבור ולנסות שוב: '
      'ההזמנה שמורה.',
  'Try again': 'ניסיון חוזר',
  // The bin.
  'The bin is empty': 'הפח ריק',
  'What you delete waits here for 30 days.': 'מה שנמחק נשאר כאן 30 יום.',
  // The menus.
  'About Papers': 'אודות ניירות',
  'Papers keeps your documents in one place':
      'ניירות שומרת את המסמכים שלך במקום אחד',
  'Your details…': 'הפרטים שלך…',
  'Settings…': 'הגדרות…',
  'File': 'קובץ',
  'Close window': 'סגירת החלון',
  'Find…': 'חיפוש…',
  'Order printed copies…': 'הזמנת עותקים מודפסים…',
  'Edit': 'עריכה',
  'Undo': 'ביטול פעולה',
  'Cut': 'גזירה',
  'Copy': 'העתקה',
  'Paste': 'הדבקה',
  'View': 'תצוגה',
  'By name': 'לפי שם',
  'By kind': 'לפי סוג',
  'By date changed': 'לפי תאריך עדכון',
  'By size': 'לפי גודל',
  'Night': 'לילה',
  'Window': 'חלון',
};

/// The words Retro Desktop says by itself (Cancel, Close, Clear, Search...),
/// in Hebrew: what Papers reads under them when it reads right to left.
class KitPapersHebrewDesignWords extends DefaultDesignLocalizations {
  /// The Hebrew words.
  const KitPapersHebrewDesignWords();

  /// A delegate that loads them, for [Localizations.override].
  static const LocalizationsDelegate<DesignLocalizations> delegate =
      _HebrewDelegate();

  @override
  String get cancelButtonLabel => 'ביטול';
  @override
  String get okButtonLabel => 'אישור';
  @override
  String get closeButtonLabel => 'סגירה';
  @override
  String get clearButtonTooltip => 'ניקוי';
  @override
  String get backButtonTooltip => 'חזרה';
  @override
  String get deleteButtonTooltip => 'מחיקה';
  @override
  String get moreButtonTooltip => 'עוד';
  @override
  String get showMenuTooltip => 'הצגת תפריט';
  @override
  String get searchFieldLabel => 'חיפוש';
  @override
  String get modalBarrierDismissLabel => 'סגירה';
  @override
  String get currentDateLabel => 'היום';
  @override
  String get collapsedIconTapHint => 'הרחבה';
  @override
  String get expandedIconTapHint => 'כיווץ';
  @override
  String get showMoreLabel => 'עוד';
  @override
  String get showLessLabel => 'פחות';
  @override
  String get selectedLabel => 'נבחר';
  @override
  String get loadingLabel => 'טוען';
  @override
  String get noResultsLabel => 'אין תוצאות';
  @override
  String positionLabel(int position, int count) => '$position מתוך $count';
  @override
  String get requiredHint => 'חובה';
  @override
  String get showPasswordLabel => 'הצגת הסיסמה';
  @override
  String get hidePasswordLabel => 'הסתרת הסיסמה';
  @override
  String get menuBarLabel => 'שורת התפריטים';
}

class _HebrewDelegate extends LocalizationsDelegate<DesignLocalizations> {
  const _HebrewDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<DesignLocalizations> load(Locale locale) =>
      SynchronousFuture<DesignLocalizations>(
        const KitPapersHebrewDesignWords(),
      );

  @override
  bool shouldReload(_HebrewDelegate old) => false;
}
