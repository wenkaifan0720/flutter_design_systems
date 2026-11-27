/// The trip planner's words: English, or Arabic where the app reads right
/// to left, so its mirrored screens are seen with real right-to-left text
/// (joined letters, a script taller than Latin, numbers inside words)
/// rather than English laid out backwards.
///
/// [tripArabicDelegates] gives the components' own words (a dialog's
/// Cancel, a calendar's month) in Arabic too, for a host to put in its
/// `localizationsDelegates` while the trip planner reads right to left.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

/// One shared thing's words: its name, its line in a list, and its facts.
typedef TripItemWords = ({
  String name,
  String line,
  List<(String, String)> facts,
});

/// The trip planner's words in English; [of] gives Arabic right to left.
class TripWords {
  /// The English words.
  const TripWords();

  /// The words for [context]'s reading direction: Arabic right to left.
  static TripWords of(BuildContext context) => _for(Directionality.of(context));

  /// [of] without depending on the direction: for a state's first values.
  static TripWords read(BuildContext context) => _for(
    context.getInheritedWidgetOfExactType<Directionality>()?.textDirection ??
        TextDirection.ltr,
  );

  static TripWords _for(TextDirection direction) =>
      direction == TextDirection.rtl
      ? const _ArabicTripWords()
      : const TripWords();

  // Screens and navigation.
  String get homeTitle => 'Trip planner';
  String get planTitle => 'Edit trip';
  String get sharedTitle => 'Shared with you';
  String get kitTitle => 'Hike kit';
  String get preferencesTitle => 'Preferences';
  String get tabHome => 'Home';
  String get tabShared => 'Shared';
  String get tabKit => 'Kit';
  String get tabPreferences => 'Preferences';
  String get addToTrip => 'Add to this trip';
  String get backToGallery => 'Back to the gallery';
  String get lightTheme => 'Light theme';
  String get darkTheme => 'Dark theme';
  String get customize => 'Customize';

  // The trip and its people.
  String get tripName => 'Big Sur weekend';
  String get everyone => 'Maya, Sam and you';
  String get mayaAndSam => 'Maya and Sam';
  String get you => 'You';
  String get mayaFull => 'Maya Okafor';
  String get samFull => 'Sam Reyes';

  /// A packing list thing, by its id (its English name).
  String packingThing(String id) => id;

  /// A place to stay, by its id.
  String stay(String id) => switch (id) {
    'treebones' => 'Treebones Resort',
    'lodge' => 'Big Sur Lodge',
    _ => 'Kirk Creek Campground',
  };

  /// A group's name, by its id (its English name).
  String group(String id) => id;

  /// One of a group, said alone: "Booking".
  String kind(String group) => switch (group) {
    'Bookings' => 'Booking',
    'Guides' => 'Guide',
    _ => 'List',
  };

  /// A new one of a group: "New booking".
  String newKind(String group) => 'New ${kind(group).toLowerCase()}';

  /// A product of the hike kit, by its id.
  String product(String id) => switch (id) {
    'bottle' => 'Water bottle',
    'headlamp' => 'Headlamp',
    _ => 'Trail map',
  };

  // Dates and counts.
  /// "Fri 11 Dec".
  String day(DateTime d) =>
      '${ExpressiveFormat.weekday(d)} ${ExpressiveFormat.dayMonth(d)}';

  /// A date in a field half a phone wide: [day], or shorter where the
  /// language's names are long.
  String fieldDay(DateTime d) => day(d);

  /// "Fri 11 – Sun 13 Dec": a range inside the season of use.
  String range(DateTime a, DateTime b) {
    final start = a.month == b.month
        ? '${ExpressiveFormat.weekday(a)} ${a.day}'
        : day(a);
    return '$start – ${day(b)}';
  }

  String nights(int n) => n == 1 ? '1 night' : '$n nights';
  String things(int n) => n == 1 ? '1 thing' : '$n things';
  String packedOf(int packed, int all) => '$packed of $all packed';

  /// A shared thing the group starts with, by its id.
  TripItemWords item(
    String id, {
    required DateTime leave,
    required DateTime back,
    required int nights,
    required int packed,
    required int all,
  }) => switch (id) {
    'car' => (
      name: 'Car rental',
      line: 'Pick up ${day(leave)}, 9:00 · SFO',
      facts: [
        ('Pick up', '${day(leave)}, 9:00 · SFO'),
        ('Return', '${day(back)}, 18:00 · SFO'),
        ('Booked by', 'You'),
      ],
    ),
    'camp' => (
      name: 'Kirk Creek campsite',
      line: '${this.nights(nights)} · paid by Maya',
      facts: [
        ('Site', '14, above the cove'),
        ('Nights', '${day(leave)} and the night after'),
        ('Paid by', r'Maya, $70.00'),
      ],
    ),
    'packing' => (
      name: 'Packing list',
      line: packedOf(packed, all),
      facts: const [],
    ),
    'eat' => (
      name: 'Places to eat',
      line: '5 places · added by Sam',
      facts: const [
        ('First', 'Big Sur Bakery, breakfast Saturday'),
        ('Then', 'Nepenthe, for the view'),
        ('Added by', 'Sam'),
      ],
    ),
    'guide' => (
      name: 'Big Sur guide',
      line: 'Updated yesterday',
      facts: const [
        ('Covers', 'Carmel to Ragged Point'),
        ('Updated', 'Yesterday, by Maya'),
      ],
    ),
    _ => (
      name: 'Coast trails',
      line: '3 hikes · added by Maya',
      facts: const [
        ('Saturday', 'Vicente Flat, 10 miles'),
        ('Sunday', 'Partington Cove, 1 mile'),
        ('Added by', 'Maya'),
      ],
    ),
  };

  // Home.
  String get nextTrip => 'Next trip';
  String datesWithEveryone(String dates) => '$dates · $everyone';

  /// The words after the days-to-go figure.
  String daysToGo(int n) => n == 1 ? 'day to go' : 'days to go';
  String get packing => 'Packing';
  String packingProgress(int packed, int all) =>
      'Packing, ${packedOf(packed, all)}';
  String get stillToDo => 'Still to do';
  String get hikeKit => 'Hike kit';
  String get hikeKitOrdered => 'Hike kit ordered';
  String get buyHikeKit => 'Buy the hike kit';
  String kitArrives(String day) => 'Arrives $day';
  String get packingList => 'Packing list';
  String get finishPacking => 'Finish packing';
  String leftToPack(int n) => '$n still to pack';
  String get stayThing => 'Stay';
  String get checkStay => 'Check where you stay';
  String get sharedLately => 'Shared lately';

  // Adding to the trip.
  String get name => 'Name';
  String get cancel => 'Cancel';
  String get add => 'Add';
  String get addedNow => 'Added by you · just now';
  String get addedBy => 'Added by';
  String get sharedWith => 'Shared with';
  String added(String name) => 'Added $name to $sharedTitle';
  String get open => 'Open';

  // Plan.
  String get tripSaved => 'Trip saved';
  String get tripNameLabel => 'Trip name';
  String get leave => 'Leave';
  String get returnDate => 'Return';
  String get whereYouStay => 'Where you stay';
  String get remindEveryone => 'Remind everyone a week before';
  String remindLine(String day) => '$mayaAndSam get an email on $day.';
  String get saveTrip => 'Save trip';
  String get discard => 'Discard changes';
  String get discardTitle => 'Discard your edits?';
  String get keepEditing => 'Keep editing';
  String get noSharedMatches => 'No matching shared items';
  String get clearSearch => 'Clear search';
  String get dates => 'Dates';
  String get nightsLabel => 'Nights';

  // Shared with you.
  String get searchShared => 'Search shared items';
  String get backToShared => 'Back to $sharedTitle';
  String packedState(String thing, bool packed) =>
      '$thing, ${packed ? 'packed' : 'not packed'}';
  String get details => 'Details';

  // Kit.
  String get codeInvalid => 'That code is not valid.';
  String get changeCard => 'Change card';
  String get cardNumber => 'Card number';
  String get expiry => 'Expiry';
  String get expiryHint => 'MM/YY';
  String get securityCode => 'Security code';
  String get useCard => 'Use card';
  String get basket => 'Basket';
  String get delivery => 'Delivery';
  String get standard => 'Standard';
  String arrives(String day) => 'Arrives $day';
  String get express => 'Express';
  String arrivesTomorrow(String day) => 'Arrives tomorrow, $day';
  String get free => 'Free';
  String get payment => 'Payment';
  String get card => 'Card';
  String visaEnding(String last4) => 'Visa ending $last4';
  String expires(String expiry) => 'Expires $expiry';
  String get change => 'Change';
  String get promoCode => 'Promo code';
  String get code => 'Code';
  String get promoApplied => '10% off the basket.';
  String get apply => 'Apply';
  String each(String price) => '$price each';
  String get orderPlaced => 'Order placed';
  String orderText(String total, String last4, String arrives, String trip) =>
      '$total on the Visa ending $last4. It arrives $arrives, in time for '
      '$trip.';
  String get done => 'Done';
  String get total => 'Total';
  String get totalFreeDelivery => 'Total, free delivery';
  String get promoLine => 'Promo TRAIL10';
  String get ordered => 'Ordered';
  String get placeOrder => 'Place order';

  // Preferences.
  String get resetTitle => 'Reset preferences?';
  String get resetText =>
      'Notifications, display and sound go back to how they were when you '
      'joined. Your trips stay as they are.';
  String get reset => 'Reset';
  String get notifications => 'Notifications';
  String get tripReminders => 'Trip reminders';
  String get tripRemindersLine => 'The day before you travel.';
  String get tripDigest => 'Trip digest';
  String get tripDigestLine => 'An email with what the group changed.';
  String get sendDigest => 'Send the digest';
  String get daily => 'Daily';
  String get weekly => 'Weekly';
  String get display => 'Display';
  String get rowDetail => 'Row detail';
  String get compact => 'Compact';
  String get comfortable => 'Comfortable';
  String get sound => 'Sound';
  String get notificationSounds => 'Notification sounds';
  String volumeLine(int percent) => 'Volume · $percent%';
  String get volume => 'Volume';
  String get resetPreferences => 'Reset preferences';

  // The everyday dialog, tabs and card grid.
  String get pastTrips => 'Past trips';
  String get pastTripsLine => 'The trips you have been on with your group.';
  String get portoInMay => 'Porto in May';
  String get portoLine => '12–16 May · $everyone';
  String get archiveTrip => 'Archive trip';
  String get archiveTitle => 'Archive Porto in May?';
  String get archiveText =>
      'The trip leaves your trips. You can restore it from the archive whenever you need it.';
  String get keepTrip => 'Keep trip';
  String get archive => 'Archive';
  String get tripArchived => 'Trip archived.';
  String get tripKept => 'Trip kept.';
  String get myTrips => 'My trips';
  String get myTripsLine =>
      'A clear place for the next plan and the places you remember.';
  String get upcoming => 'Upcoming';
  String get saved => 'Saved';
  String get past => 'Past';
  List<(String, String)> get myTripRows => const [
    ('Lisbon weekend', '18–21 September · 3 travelers'),
    ('Kyoto idea', 'Saved for next spring'),
    ('Porto in May', '12–16 May · Trip completed'),
  ];
  String get savedPlaces => 'Saved places';
  String get savedPlacesLine => 'Ideas for your next free weekend.';
  String placeChosen(String place) => '$place is selected for your next plan.';
  List<(String, String)> get places => const [
    ('Lisbon', 'Hills and trams'),
    ('Porto', 'Riverside walks'),
    ('Kyoto', 'Quiet gardens'),
    ('Copenhagen', 'Food and bicycles'),
    ('Oslo', 'Forest and fjord'),
    ('Marrakesh', 'Courtyards and cafés'),
  ];

  // The feedback page.
  String get feedbackBanner => 'Banner';
  String get offlineTitle => 'You are offline';
  String get offlineText =>
      'Edits are saved on this phone and sync when you reconnect.';
  String get dismiss => 'Dismiss';
  String get retry => 'Retry';
  String get confirmEmail => 'Confirm your email to share lists with friends.';
  String get later => 'Later';
  String get sendLink => 'Send link';
  String get paymentDeclined => 'Payment declined';
  String get paymentText =>
      'Your plan renews on 1 October. Update the card to keep it.';
  String get updateCard => 'Update card';
  String get showAllBanners => 'Show all banners';
  String get skeleton => 'Skeleton';
  String get posterInitials => 'JR';
  String get posterName => 'June Rivera';
  String get posterLine => 'Harbour walk · 2 h';
  String get postText =>
      'Low tide this morning — the whole bay was ours. The café on the pier finally reopened too.';
  String get loadAgain => 'Load again';
  String get finishLoading => 'Finish loading';
  String get emptyState => 'Empty state';
  String get noSavedWalks => 'No saved walks yet';
  String get noSavedWalksText =>
      'Save a route from the map and it will wait for you here.';
  String get openMap => 'Open the map';
  String get errorState => 'Error state';
  String get walksFailed => 'Could not load your walks';
  String get checkConnection => 'Check your connection and try again.';
  String get successState => 'Success state';
  String get tableBooked => 'Table booked';
  String get tableBookedText => 'We sent the details to your inbox.';
  String get statusSection =>
      'Status view · error, retry to loading, then success';
  String get loadingWalks => 'Loading your walks';
  String get walksUpToDate => 'Walks are up to date';
  String get walksSaved => 'Twelve routes, saved on this phone.';
  String get startOver => 'Start over';
  String get longerEmptyCaption => 'Empty state, a longer message';
  String get noWalksThisWeek => 'No walks this week';
  String get noWalksThisWeekText =>
      'Your next walk shows here once you finish it, with the trail it took '
      'and how far you went.';
  String get plainErrorCaption => 'Error state without its icon';
  String get mapFailed => 'The map did not load';
  String get mapFailedText =>
      'Check you are online, then try again in a minute.';

  // The overview.
  String get overviewPitch =>
      "Material's newest look for Flutter: the components you know, "
      'with springs, shapes and emphasis, and the parts Material added for '
      'it. Light and dark, phone to desktop, built for screen readers and '
      'the keyboard.';
  String get openTripPlanner => 'Open the trip planner';
  String get materialLacks => "What Flutter's Material doesn't have";
  String get buttonGroups => 'Button groups';
  String get buttonGroupsText =>
      'Press one: it widens and its neighbours make room.';
  String get splitButton => 'Split button';
  String get splitButtonText => 'One act and its options, in one button.';
  String get loadingIndicator => 'Loading indicator';
  String get loadingIndicatorText =>
      'Shapes that morph while you wait, open or contained.';
  String get floatingToolbar => 'Floating toolbar';
  String get floatingToolbarText =>
      "A screen's tools in a pill over its content.";
  String get wavyProgress => 'Wavy progress';
  String get wavyProgressText => 'For the one moment a screen celebrates.';
  String get twoThirdsDone => 'Two thirds done';
  String get toggleGroups => 'Toggle groups';
  String get toggleGroupsText => 'A choice of a few, the chosen one rounder.';
  String get everyComponent => 'Every component';

  /// A gallery destination's [title] and [about], by its English title.
  ({String title, String about}) destination(String title, String about) =>
      (title: title, about: about);
}

/// Arabic's counted noun: [one] alone for 1, [two] (the dual) alone for 2,
/// then the number with [few] (3 to 10), [many] (11 to 99) or [other].
String _arabicCount(
  int n, {
  required String one,
  required String two,
  required String few,
  required String many,
  required String other,
}) {
  final rest = n % 100;
  if (n == 1) return one;
  if (n == 2) return two;
  if (rest >= 3 && rest <= 10) return '$n $few';
  if (rest >= 11) return '$n $many';
  return '$n $other';
}

const List<String> _arabicMonths = [
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

/// Monday first, as [DateTime.weekday] counts.
const List<String> _arabicWeekdays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

/// Each weekday's letter, as Arabic calendars head their columns.
const List<String> _arabicWeekdayLetters = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

class _ArabicTripWords extends TripWords {
  const _ArabicTripWords();

  @override
  String get homeTitle => 'مخطط الرحلات';
  @override
  String get planTitle => 'تعديل الرحلة';
  @override
  String get sharedTitle => 'مشترك معك';
  @override
  String get kitTitle => 'عُدّة المشي';
  @override
  String get preferencesTitle => 'التفضيلات';
  @override
  String get tabHome => 'الرئيسية';
  @override
  String get tabShared => 'المشترك';
  @override
  String get tabKit => 'العُدّة';
  @override
  String get tabPreferences => 'التفضيلات';
  @override
  String get addToTrip => 'أضف إلى هذه الرحلة';
  @override
  String get backToGallery => 'العودة إلى المعرض';
  @override
  String get lightTheme => 'المظهر الفاتح';
  @override
  String get darkTheme => 'المظهر الداكن';
  @override
  String get customize => 'تخصيص';

  @override
  String get tripName => 'عطلة بيغ سور';
  @override
  String get everyone => 'مايا وسام وأنت';
  @override
  String get mayaAndSam => 'مايا وسام';
  @override
  String get you => 'أنت';
  @override
  String get mayaFull => 'مايا أوكافور';
  @override
  String get samFull => 'سام رييس';

  @override
  String packingThing(String id) => switch (id) {
    'Tent' => 'خيمة',
    'Sleeping bags' => 'أكياس النوم',
    'Camp stove' => 'موقد التخييم',
    'Water filter' => 'فلتر الماء',
    'Rain jackets' => 'سترات المطر',
    'First-aid kit' => 'حقيبة الإسعافات الأولية',
    'Trail snacks' => 'وجبات خفيفة للطريق',
    'Sunscreen' => 'واقي الشمس',
    'Trail map' => 'خريطة المسار',
    'Water bottles' => 'قوارير الماء',
    'Headlamps' => 'مصابيح الرأس',
    'Firewood' => 'حطب',
    _ => id,
  };

  @override
  String stay(String id) => switch (id) {
    'treebones' => 'منتجع تريبونز',
    'lodge' => 'نُزُل بيغ سور',
    _ => 'مخيم كيرك كريك',
  };

  @override
  String group(String id) => switch (id) {
    'Bookings' => 'الحجوزات',
    'Guides' => 'الأدلة',
    _ => 'القوائم',
  };

  @override
  String kind(String group) => switch (group) {
    'Bookings' => 'حجز',
    'Guides' => 'دليل',
    _ => 'قائمة',
  };

  @override
  String newKind(String group) => switch (group) {
    'Bookings' => 'حجز جديد',
    'Guides' => 'دليل جديد',
    _ => 'قائمة جديدة',
  };

  @override
  String product(String id) => switch (id) {
    'bottle' => 'قارورة ماء',
    'headlamp' => 'مصباح رأس',
    _ => 'خريطة المسار',
  };

  @override
  String day(DateTime d) =>
      '${_arabicWeekdays[d.weekday - 1]} ${d.day} ${_arabicMonths[d.month - 1]}';

  // The weekday's name and the month's take more than half a phone: the
  // day and the month.
  @override
  String fieldDay(DateTime d) => '${d.day} ${_arabicMonths[d.month - 1]}';

  @override
  String range(DateTime a, DateTime b) {
    final start = a.month == b.month
        ? '${_arabicWeekdays[a.weekday - 1]} ${a.day}'
        : day(a);
    return '$start – ${day(b)}';
  }

  @override
  String nights(int n) => _arabicCount(
    n,
    one: 'ليلة واحدة',
    two: 'ليلتان',
    few: 'ليالٍ',
    many: 'ليلة',
    other: 'ليلة',
  );

  @override
  String things(int n) => _arabicCount(
    n,
    one: 'غرض واحد',
    two: 'غرضان',
    few: 'أغراض',
    many: 'غرضًا',
    other: 'غرض',
  );

  @override
  String packedOf(int packed, int all) => 'تم توضيب $packed من $all';

  @override
  TripItemWords item(
    String id, {
    required DateTime leave,
    required DateTime back,
    required int nights,
    required int packed,
    required int all,
  }) => switch (id) {
    'car' => (
      name: 'استئجار سيارة',
      line: 'الاستلام ${day(leave)}، 9:00 · SFO',
      facts: [
        ('الاستلام', '${day(leave)}، 9:00 · SFO'),
        ('الإرجاع', '${day(back)}، 18:00 · SFO'),
        ('حجزها', 'أنت'),
      ],
    ),
    'camp' => (
      name: 'موقع تخييم كيرك كريك',
      line: '${this.nights(nights)} · دفعت مايا',
      facts: [
        ('الموقع', '14، فوق الخليج'),
        ('الليالي', '${day(leave)} والليلة التالية'),
        ('دفع', r'مايا، $70.00'),
      ],
    ),
    'packing' => (
      name: 'قائمة التوضيب',
      line: packedOf(packed, all),
      facts: const [],
    ),
    'eat' => (
      name: 'أماكن للأكل',
      line: '5 أماكن · أضافها سام',
      facts: const [
        ('أولًا', 'مخبز بيغ سور، فطور السبت'),
        ('ثم', 'نيبنثي، من أجل الإطلالة'),
        ('أضافها', 'سام'),
      ],
    ),
    'guide' => (
      name: 'دليل بيغ سور',
      line: 'حُدِّث أمس',
      facts: const [
        ('يغطي', 'من كارمل إلى راغد بوينت'),
        ('آخر تحديث', 'أمس، بواسطة مايا'),
      ],
    ),
    _ => (
      name: 'مسارات الساحل',
      line: '3 مسارات · أضافتها مايا',
      facts: const [
        ('السبت', 'فيسنتي فلات، 10 أميال'),
        ('الأحد', 'بارتينغتون كوف، ميل واحد'),
        ('أضافتها', 'مايا'),
      ],
    ),
  };

  @override
  String get nextTrip => 'الرحلة القادمة';
  @override
  String daysToGo(int n) => switch (n % 100) {
    _ when n == 1 => 'يوم متبقٍّ',
    _ when n == 2 => 'يومان متبقيان',
    >= 3 && <= 10 => 'أيام متبقية',
    >= 11 => 'يومًا متبقيًا',
    _ => 'يوم متبقٍّ',
  };
  @override
  String get packing => 'التوضيب';
  @override
  String packingProgress(int packed, int all) =>
      'التوضيب، ${packedOf(packed, all)}';
  @override
  String get stillToDo => 'ما زال عليك';
  @override
  String get hikeKit => 'عُدّة المشي';
  @override
  String get hikeKitOrdered => 'طُلبت عُدّة المشي';
  @override
  String get buyHikeKit => 'اشترِ عُدّة المشي';
  @override
  String kitArrives(String day) => 'تصل $day';
  @override
  String get packingList => 'قائمة التوضيب';
  @override
  String get finishPacking => 'أكمل التوضيب';
  @override
  String leftToPack(int n) =>
      n == 0 ? 'لم يبقَ شيء للتوضيب' : 'بقي ${things(n)} للتوضيب';
  @override
  String get stayThing => 'الإقامة';
  @override
  String get checkStay => 'راجع مكان إقامتك';
  @override
  String get sharedLately => 'شورك مؤخرًا';

  @override
  String get name => 'الاسم';
  @override
  String get cancel => 'إلغاء';
  @override
  String get add => 'إضافة';
  @override
  String get addedNow => 'أضفته أنت · الآن';
  @override
  String get addedBy => 'أضافه';
  @override
  String get sharedWith => 'مشترك مع';
  @override
  String added(String name) => 'أُضيف «$name» إلى «$sharedTitle»';
  @override
  String get open => 'فتح';

  @override
  String get tripSaved => 'حُفظت الرحلة';
  @override
  String get tripNameLabel => 'اسم الرحلة';
  @override
  String get leave => 'المغادرة';
  @override
  String get returnDate => 'العودة';
  @override
  String get whereYouStay => 'مكان الإقامة';
  @override
  String get remindEveryone => 'ذكّر الجميع قبل أسبوع';
  @override
  String remindLine(String day) => 'تصل رسالة إلى $mayaAndSam يوم $day.';
  @override
  String get saveTrip => 'حفظ الرحلة';
  @override
  String get discard => 'تجاهل التغييرات';
  @override
  String get discardTitle => 'هل تريد تجاهل تعديلاتك؟';
  @override
  String get keepEditing => 'متابعة التعديل';
  @override
  String get noSharedMatches => 'لا توجد عناصر مشتركة مطابقة';
  @override
  String get clearSearch => 'مسح البحث';
  @override
  String get dates => 'التواريخ';
  @override
  String get nightsLabel => 'الليالي';

  @override
  String get searchShared => 'ابحث في العناصر المشتركة';
  @override
  String get backToShared => 'العودة إلى «$sharedTitle»';
  @override
  String packedState(String thing, bool packed) =>
      '$thing، ${packed ? 'موضَّب' : 'غير موضَّب'}';
  @override
  String get details => 'التفاصيل';

  @override
  String get codeInvalid => 'هذا الرمز غير صالح.';
  @override
  String get changeCard => 'تغيير البطاقة';
  @override
  String get cardNumber => 'رقم البطاقة';
  @override
  String get expiry => 'تاريخ الانتهاء';
  @override
  String get securityCode => 'رمز الأمان';
  @override
  String get useCard => 'استخدام البطاقة';
  @override
  String get basket => 'السلة';
  @override
  String get delivery => 'التوصيل';
  @override
  String get standard => 'عادي';
  @override
  String arrives(String day) => 'يصل $day';
  @override
  String get express => 'سريع';
  @override
  String arrivesTomorrow(String day) => 'يصل غدًا، $day';
  @override
  String get free => 'مجاني';
  @override
  String get payment => 'الدفع';
  @override
  String get card => 'بطاقة';
  @override
  String visaEnding(String last4) => 'فيزا تنتهي بـ $last4';
  @override
  String expires(String expiry) => 'تنتهي في $expiry';
  @override
  String get change => 'تغيير';
  @override
  String get promoCode => 'رمز الخصم';
  @override
  String get code => 'الرمز';
  @override
  String get promoApplied => 'خصم 10% على السلة.';
  @override
  String get apply => 'تطبيق';
  @override
  String each(String price) => '$price للقطعة';
  @override
  String get orderPlaced => 'تم الطلب';
  @override
  String orderText(String total, String last4, String arrives, String trip) =>
      '$total على بطاقة الفيزا المنتهية بـ $last4. يصل الطلب $arrives، '
      'في الوقت المناسب لـ«$trip».';
  @override
  String get done => 'تم';
  @override
  String get total => 'المجموع';
  @override
  String get totalFreeDelivery => 'المجموع، والتوصيل مجاني';
  @override
  String get promoLine => 'خصم TRAIL10';
  @override
  String get ordered => 'تم الطلب';
  @override
  String get placeOrder => 'إتمام الطلب';

  @override
  String get resetTitle => 'إعادة ضبط التفضيلات؟';
  @override
  String get resetText =>
      'تعود الإشعارات والعرض والصوت إلى ما كانت عليه عند انضمامك. تبقى '
      'رحلاتك كما هي.';
  @override
  String get reset => 'إعادة الضبط';
  @override
  String get notifications => 'الإشعارات';
  @override
  String get tripReminders => 'تذكيرات الرحلة';
  @override
  String get tripRemindersLine => 'قبل يوم من سفرك.';
  @override
  String get tripDigest => 'ملخص الرحلة';
  @override
  String get tripDigestLine => 'رسالة بما غيّرته المجموعة.';
  @override
  String get sendDigest => 'إرسال الملخص';
  @override
  String get daily => 'يوميًا';
  @override
  String get weekly => 'أسبوعيًا';
  @override
  String get display => 'العرض';
  @override
  String get rowDetail => 'تفاصيل الصفوف';
  @override
  String get compact => 'مضغوط';
  @override
  String get comfortable => 'مريح';
  @override
  String get sound => 'الصوت';
  @override
  String get notificationSounds => 'أصوات الإشعارات';
  @override
  String volumeLine(int percent) => 'مستوى الصوت · $percent%';
  @override
  String get volume => 'مستوى الصوت';
  @override
  String get resetPreferences => 'إعادة ضبط التفضيلات';

  @override
  String get pastTrips => 'رحلات سابقة';
  @override
  String get pastTripsLine => 'الرحلات التي قمت بها مع مجموعتك.';
  @override
  String get portoInMay => 'بورتو في مايو';
  @override
  String get portoLine => '12–16 مايو · $everyone';
  @override
  String get archiveTrip => 'أرشفة الرحلة';
  @override
  String get archiveTitle => 'أتؤرشف رحلة بورتو في مايو؟';
  @override
  String get archiveText =>
      'تخرج الرحلة من رحلاتك، ويمكنك استعادتها من الأرشيف متى احتجت إليها.';
  @override
  String get keepTrip => 'إبقاء الرحلة';
  @override
  String get archive => 'أرشفة';
  @override
  String get tripArchived => 'أُرشفت الرحلة.';
  @override
  String get tripKept => 'بقيت الرحلة.';
  @override
  String get myTrips => 'رحلاتي';
  @override
  String get myTripsLine => 'مكان واضح للخطة القادمة وللأماكن التي تتذكرها.';
  @override
  String get upcoming => 'القادمة';
  @override
  String get saved => 'المحفوظة';
  @override
  String get past => 'السابقة';
  @override
  List<(String, String)> get myTripRows => const [
    ('عطلة لشبونة', '18–21 سبتمبر · 3 مسافرين'),
    ('فكرة كيوتو', 'محفوظة للربيع القادم'),
    ('بورتو في مايو', '12–16 مايو · اكتملت الرحلة'),
  ];
  @override
  String get savedPlaces => 'أماكن محفوظة';
  @override
  String get savedPlacesLine => 'أفكار لعطلتك القادمة.';
  @override
  String placeChosen(String place) => 'اخترت $place لخطتك القادمة.';
  @override
  List<(String, String)> get places => const [
    ('لشبونة', 'تلال وترام'),
    ('بورتو', 'نزهات على ضفة النهر'),
    ('كيوتو', 'حدائق هادئة'),
    ('كوبنهاغن', 'طعام ودراجات'),
    ('أوسلو', 'غابة ومضيق'),
    ('مراكش', 'أفنية ومقاهٍ'),
  ];
  @override
  String get feedbackBanner => 'شريط التنبيه';
  @override
  String get offlineTitle => 'أنت غير متصل';
  @override
  String get offlineText =>
      'تُحفظ تعديلاتك على هذا الهاتف وتُزامَن حين يعود الاتصال.';
  @override
  String get dismiss => 'تجاهل';
  @override
  String get retry => 'إعادة المحاولة';
  @override
  String get confirmEmail => 'أكّد بريدك الإلكتروني لتشارك القوائم مع أصدقائك.';
  @override
  String get later => 'لاحقًا';
  @override
  String get sendLink => 'إرسال الرابط';
  @override
  String get paymentDeclined => 'رُفض الدفع';
  @override
  String get paymentText =>
      'يتجدد اشتراكك في 1 أكتوبر. حدّث البطاقة لتحتفظ به.';
  @override
  String get updateCard => 'تحديث البطاقة';
  @override
  String get showAllBanners => 'عرض كل الأشرطة';
  @override
  String get skeleton => 'هيكل التحميل';
  @override
  String get posterInitials => 'ج';
  @override
  String get posterName => 'جون ريفيرا';
  @override
  String get posterLine => 'نزهة الميناء · منذ ساعتين';
  @override
  String get postText =>
      'جَزر هذا الصباح، وكان الخليج كله لنا. وأخيرًا عاد مقهى الرصيف يفتح أبوابه.';
  @override
  String get loadAgain => 'التحميل من جديد';
  @override
  String get finishLoading => 'إنهاء التحميل';
  @override
  String get emptyState => 'الحالة الفارغة';
  @override
  String get noSavedWalks => 'لا نزهات محفوظة بعد';
  @override
  String get noSavedWalksText => 'احفظ مسارًا من الخريطة وسيبقى هنا بانتظارك.';
  @override
  String get openMap => 'فتح الخريطة';
  @override
  String get errorState => 'حالة الخطأ';
  @override
  String get walksFailed => 'تعذّر تحميل نزهاتك';
  @override
  String get checkConnection => 'تحقّق من اتصالك وحاول مرة أخرى.';
  @override
  String get successState => 'حالة النجاح';
  @override
  String get tableBooked => 'حُجزت الطاولة';
  @override
  String get tableBookedText => 'أرسلنا التفاصيل إلى بريدك الوارد.';
  @override
  String get statusSection =>
      'عرض الحالة · خطأ، فإعادة المحاولة إلى التحميل، ثم النجاح';
  @override
  String get loadingWalks => 'جارٍ تحميل نزهاتك';
  @override
  String get walksUpToDate => 'نزهاتك محدَّثة';
  @override
  String get walksSaved => 'اثنا عشر مسارًا محفوظة على هذا الهاتف.';
  @override
  String get startOver => 'البدء من جديد';
  @override
  String get longerEmptyCaption => 'حالة فارغة برسالة أطول';
  @override
  String get noWalksThisWeek => 'لا نزهات هذا الأسبوع';
  @override
  String get noWalksThisWeekText =>
      'ستظهر نزهتك التالية هنا حين تنهيها، مع المسار الذي سلكته والمسافة التي قطعتها.';
  @override
  String get plainErrorCaption => 'حالة خطأ بلا رمزها';
  @override
  String get mapFailed => 'لم تُحمَّل الخريطة';
  @override
  String get mapFailedText => 'تأكّد أنك متصل، ثم حاول مرة أخرى بعد دقيقة.';
  @override
  String get overviewPitch =>
      'أحدث مظهر من Material لـ Flutter: المكوّنات التي تعرفها، بنوابض وأشكال وإبراز، ومعها الأجزاء التي أضافتها Material له. فاتح وداكن، من الهاتف إلى سطح المكتب، ومصمَّم لقارئات الشاشة ولوحة المفاتيح.';
  @override
  String get openTripPlanner => 'افتح مخطط الرحلات';
  @override
  String get materialLacks => 'ما لا يقدّمه Material في Flutter';
  @override
  String get buttonGroups => 'مجموعات الأزرار';
  @override
  String get buttonGroupsText => 'اضغط أحدها: يتّسع ويُفسح له جيرانه.';
  @override
  String get splitButton => 'الزر المنقسم';
  @override
  String get splitButtonText => 'فعل واحد وخياراته، في زر واحد.';
  @override
  String get loadingIndicator => 'مؤشر التحميل';
  @override
  String get loadingIndicatorText =>
      'أشكال تتحوّل وأنت تنتظر، مكشوفة أو داخل حاوية.';
  @override
  String get floatingToolbar => 'شريط الأدوات العائم';
  @override
  String get floatingToolbarText => 'أدوات الشاشة في كبسولة فوق محتواها.';
  @override
  String get wavyProgress => 'التقدّم المتموّج';
  @override
  String get wavyProgressText => 'للحظة الوحيدة التي تحتفي بها الشاشة.';
  @override
  String get twoThirdsDone => 'اكتمل الثلثان';
  @override
  String get toggleGroups => 'مجموعات التبديل';
  @override
  String get toggleGroupsText => 'اختيار من قليل، والمختار أكثر استدارة.';
  @override
  String get everyComponent => 'كل المكوّنات';
  @override
  ({String title, String about}) destination(String title, String about) =>
      _arabicDestinations[title] ?? (title: title, about: about);
}

/// The gallery's destinations in Arabic, by their English titles.
const Map<String, ({String title, String about})> _arabicDestinations = {
  'Overview': (
    title: 'نظرة عامة',
    about: 'ما تضيفه الحزمة إلى Material، ومخطط الرحلات.',
  ),
  'Trip planner': (
    title: 'مخطط الرحلات',
    about: 'تطبيق صغير مبني بهذا المظهر: شاشة رئيسية ونموذج وقائمة بجانب تفاصيلها ودفع وتفضيلات، بكل المقاسات.',
  ),
  'Buttons': (
    title: 'الأزرار',
    about: 'من الأزرار الممتلئة إلى النصية بخمسة مقاسات، ومجموعات التبديل والأزرار المنقسمة والزر العائم وأشرطة الأدوات.',
  ),
  'Text fields': (
    title: 'حقول النص',
    about: 'حقول ممتلئة ومحدَّدة، وكلمات المرور ومجموعات الإدخال وحقول النماذج بعناوينها والقائمة المنسدلة.',
  ),
  'Selection': (
    title: 'الاختيار',
    about: 'مربعات الاختيار وأزرار الراديو والمفاتيح، وبطاقات الاختيار والشرائح والمنزلقات.',
  ),
  'Pickers': (
    title: 'المنتقيات',
    about: 'منتقيات التاريخ والنطاق والوقت، والتقويم وعجلات التمرير ومنتقي الألوان.',
  ),
  'Navigation': (
    title: 'التنقّل',
    about: 'شريط التنقّل والشريط الجانبي والدرج، وأشرطة التطبيق وعلامات التبويب والهيكل والشاشات والصفحات.',
  ),
  'Lists and tables': (
    title: 'القوائم والجداول',
    about: 'عناصر قوائم يُعاد ترتيبها وتُسحب، والجداول وجدول البيانات ومناطق التمرير والألواح القابلة لتغيير حجمها واللوحة الجانبية.',
  ),
  'Cards and media': (
    title: 'البطاقات والوسائط',
    about: 'البطاقات والعرض الدوّار والصور والنصوص والأرقام ولحظة الإبراز والشارات.',
  ),
  'Dialogs and sheets': (
    title: 'مربعات الحوار واللوحات',
    about: 'مربع حوار والطبقات العلوية واللوحة السفلية والقوائم وشريط القوائم.',
  ),
  'Feedback': (
    title: 'التنبيهات والحالات',
    about: 'الإشعارات المؤقتة ومؤشرات التقدّم والتحميل وشاشات الحالة وشاشة البداية.',
  ),
  'Charts': (
    title: 'المخططات البيانية',
    about: 'المخططات الخطية والمساحية والشريطية والدائرية، والخطوط المصغّرة.',
  ),
  'Type and colour': (
    title: 'الخط واللون',
    about: 'أدوار الألوان وسلّم الخطوط والأشكال والرموز والحركة والتباعد والارتفاع والحالات.',
  ),
};

/// The components' shared words in Arabic, where the trip planner reaches
/// them (a dialog's buttons, a calendar's month and weekdays, a field's
/// clear button); English elsewhere.
class _ArabicDesignWords extends DefaultRawWidgetsLocalizations {
  const _ArabicDesignWords();

  @override
  String get cancelButtonLabel => 'إلغاء';
  @override
  String get okButtonLabel => 'حسنًا';
  @override
  String get closeButtonLabel => 'إغلاق';
  @override
  String get clearButtonTooltip => 'مسح';
  @override
  String get backButtonTooltip => 'رجوع';
  @override
  String get deleteButtonTooltip => 'حذف';
  @override
  String get moreButtonTooltip => 'المزيد';
  @override
  String get showMenuTooltip => 'عرض القائمة';
  @override
  String get searchFieldLabel => 'بحث';
  @override
  String get modalBarrierDismissLabel => 'إغلاق';
  @override
  String get currentDateLabel => 'اليوم';
  @override
  String get previousMonthTooltip => 'الشهر السابق';
  @override
  String get nextMonthTooltip => 'الشهر التالي';
  @override
  String get previousPageTooltip => 'الصفحة السابقة';
  @override
  String get nextPageTooltip => 'الصفحة التالية';
  @override
  String get selectedLabel => 'محدد';
  @override
  String get loadingLabel => 'جارٍ التحميل';
  @override
  String get noResultsLabel => 'لا توجد نتائج';
  @override
  String positionLabel(int position, int count) => '$position من $count';
  @override
  String formatFullDate(DateTime date) =>
      '${_arabicWeekdays[date.weekday - 1]}، ${date.day} '
      '${_arabicMonths[date.month - 1]} ${date.year}';
  @override
  String formatMonthYear(DateTime date) =>
      '${_arabicMonths[date.month - 1]} ${date.year}';
  @override
  String formatShortWeekday(int weekday) => _arabicWeekdayLetters[weekday - 1];
  @override
  int get firstDayOfWeek => DateTime.saturday;
  @override
  String get requiredHint => 'مطلوب';
}

String _arabicDecrease(String label) => 'إنقاص $label';
String _arabicIncrease(String label) => 'زيادة $label';
String _arabicRemove(String label) => 'إزالة $label';
String _arabicOutOfYears(int first, int last) => 'اختر سنة من $first إلى $last';
String _arabicGoToYear(int year) => 'الانتقال إلى $year';

const ExpressiveLocalizations _arabicExpressiveWords = ExpressiveLocalizations(
  cancelSearch: 'إلغاء البحث',
  showSuggestions: 'عرض الاقتراحات',
  sheetDragHandle: 'مقبض السحب',
  fabMenu: 'قائمة الإضافة',
  toastDismiss: 'إغلاق',
  tryAgain: 'أعد المحاولة',
  quantity: 'الكمية',
  removeChip: _arabicRemove,
  decrease: _arabicDecrease,
  increase: _arabicIncrease,
  selectDate: 'اختر التاريخ',
  selectDates: 'اختر التواريخ',
  enterDates: 'أدخل التواريخ',
  selectedDate: 'التاريخ المحدد',
  enteredDate: 'التاريخ المُدخل',
  startDate: 'تاريخ البدء',
  endDate: 'تاريخ الانتهاء',
  date: 'التاريخ',
  inRange: 'ضمن النطاق',
  toDateInput: 'اكتب تاريخًا',
  toCalendar: 'اختر من التقويم',
  toYears: 'اختر سنة',
  toDays: 'العودة إلى الأيام',
  badDatePattern: 'استخدم الصيغة MM/DD/YYYY',
  dateNotAllowed: 'لا يمكن اختيار هذا التاريخ',
  endBeforeStart: 'النهاية قبل البداية',
  outOfYears: _arabicOutOfYears,
  goToYear: _arabicGoToYear,
);

/// Loads [words] for any locale: the trip planner's Arabic, while it reads
/// right to left, whatever the app's locale.
class _Words<T> extends LocalizationsDelegate<T> {
  const _Words(this.words);

  final T words;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => SynchronousFuture<T>(words);

  @override
  bool shouldReload(_Words<T> old) => false;
}

/// The components' words in Arabic, for a host's `localizationsDelegates`
/// (before Flutter's own) while the trip planner reads right to left.
const List<LocalizationsDelegate<Object?>> tripArabicDelegates = [
  _Words<RawWidgetsLocalizations>(_ArabicDesignWords()),
  _Words<ExpressiveLocalizations>(_arabicExpressiveWords),
];
