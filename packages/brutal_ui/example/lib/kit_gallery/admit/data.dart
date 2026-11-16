/// Admit's world: a city's week of nights out, from Tuesday 17 to Sunday
/// 22 November 2026, and the tickets one person holds. Every figure agrees
/// with the others: a ticket's lines add up to its total, an event's date in
/// the list is its date in the detail.
library;

/// What kind of night an event is.
enum AdmitKind {
  music('Music'),
  talks('Talks'),
  film('Film'),
  art('Art');

  const AdmitKind(this.label);

  /// Its name.
  final String label;
}

/// A way in to an event, at a price.
typedef AdmitTicketType = ({String name, String note, int cents, bool soldOut});

/// One event.
typedef AdmitEvent = ({
  String id,
  String title,
  String byline,
  AdmitKind kind,
  DateTime starts,
  String doors,
  String venue,
  String address,
  String blurb,
  List<AdmitTicketType> types,
});

/// The week's events, by date.
final List<AdmitEvent> admitEvents = [
  (
    id: 'northern-lines',
    title: 'Northern Lines',
    byline: 'Prints by Ines Hart, opening night',
    kind: AdmitKind.art,
    starts: DateTime(2026, 11, 17, 18),
    doors: '18:00',
    venue: 'Gallery Nine',
    address: '9 Mill Lane',
    blurb:
        'Forty woodcut prints of the coast road, cut over two winters. The '
        'artist talks at 19:00; the bar is open until 21:00.',
    types: [
      (name: 'Entry', note: 'Free, ticket needed', cents: 0, soldOut: false),
    ],
  ),
  (
    id: 'field-notes',
    title: 'Field Notes',
    byline: 'Marta Kos on mapping a river by ear',
    kind: AdmitKind.talks,
    starts: DateTime(2026, 11, 18, 19),
    doors: '18:30',
    venue: 'Library Hall',
    address: '2 Market Square',
    blurb:
        'A sound recordist walks the Vel from its source to the sea and '
        'plays what she found. An hour, then questions.',
    types: [(name: 'Seated', note: 'Unreserved', cents: 800, soldOut: false)],
  ),
  (
    id: 'short-film-night',
    title: 'Short Film Night',
    byline: 'Seven films from the autumn open call',
    kind: AdmitKind.film,
    starts: DateTime(2026, 11, 19, 19, 30),
    doors: '19:00',
    venue: 'Kino 2',
    address: '41 Arch Street',
    blurb:
        'Seven shorts, 94 minutes in all, picked from 212 entries. The '
        'directors of three are in the room.',
    types: [(name: 'General', note: 'Any seat', cents: 1200, soldOut: false)],
  ),
  (
    id: 'static-bloom',
    title: 'Static Bloom',
    byline: 'Live, with Paper Moth',
    kind: AdmitKind.music,
    starts: DateTime(2026, 11, 20, 21),
    doors: '20:00',
    venue: 'The Cellar',
    address: '17 Canal Row',
    blurb:
        'Loud guitars in a low room. Paper Moth open at 21:00, Static Bloom '
        'play from 22:00 to midnight.',
    types: [(name: 'Standing', note: 'Floor', cents: 1800, soldOut: false)],
  ),
  (
    id: 'low-tide',
    title: 'Low Tide',
    byline: 'The Harbour Sessions, night two',
    kind: AdmitKind.music,
    starts: DateTime(2026, 11, 21, 20),
    doors: '19:00',
    venue: 'Hall 4',
    address: 'Dock Road',
    blurb:
        'A six-piece from the coast, playing the new record start to end, '
        'then the old songs. Two hours, no support.',
    types: [
      (
        name: 'Standing',
        note: 'Floor, first come',
        cents: 3200,
        soldOut: false,
      ),
      (
        name: 'Balcony',
        note: 'Seated, row A to F',
        cents: 4400,
        soldOut: false,
      ),
      (
        name: 'Front row',
        note: 'Standing, by the stage',
        cents: 5600,
        soldOut: true,
      ),
    ],
  ),
  (
    id: 'quiet-hours',
    title: 'Quiet Hours',
    byline: 'A long DJ set in the basement',
    kind: AdmitKind.music,
    starts: DateTime(2026, 11, 21, 23),
    doors: '23:00',
    venue: 'Basement 3',
    address: '3 Foundry Yard',
    blurb: 'Six hours, one DJ, slow to fast. Phones in pouches at the door.',
    types: [(name: 'Entry', note: 'Before 01:00', cents: 1500, soldOut: false)],
  ),
  (
    id: 'concrete-choir',
    title: 'Concrete Choir',
    byline: 'Forty voices, no instruments',
    kind: AdmitKind.music,
    starts: DateTime(2026, 11, 22, 18),
    doors: '17:30',
    venue: "St Anne's",
    address: 'Church Street',
    blurb:
        'Songs written for the building, sung from its four corners. Bring '
        'a coat: the nave is cold.',
    types: [
      (name: 'Nave', note: 'Pews, unreserved', cents: 2200, soldOut: false),
    ],
  ),
];

/// The event called [id].
AdmitEvent admitEvent(String id) => admitEvents.firstWhere((e) => e.id == id);

/// A held ticket: an order for one event.
typedef AdmitHeld = ({
  String order,
  String eventId,
  String type,
  int count,
  int eachCents,
  bool past,
});

/// The tickets the owner holds, upcoming then past.
final List<AdmitHeld> admitHeld = [
  (
    order: 'A-2291',
    eventId: 'short-film-night',
    type: 'General',
    count: 1,
    eachCents: 1200,
    past: false,
  ),
  (
    order: 'A-2318',
    eventId: 'low-tide',
    type: 'Standing',
    count: 2,
    eachCents: 3200,
    past: false,
  ),
];

/// Past nights: what the owner went to.
final List<({String title, String venue, DateTime date, String line})>
admitPast = [
  (
    title: 'Velvet Static',
    venue: 'The Cellar',
    date: DateTime(2026, 10, 30, 21),
    line: '2 × Standing',
  ),
  (
    title: 'Harbour Lights',
    venue: 'Hall 4',
    date: DateTime(2026, 9, 12, 20),
    line: '1 × Balcony',
  ),
  (
    title: 'Open Archive',
    venue: 'Kino 2',
    date: DateTime(2026, 8, 27, 19, 30),
    line: '1 × General',
  ),
];

/// The owner.
const admitOwner = (
  name: 'Ada Park',
  email: 'ada.park@example.com',
  card: '4417',
);

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
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

/// "Sat 21 Nov".
String admitDay(DateTime d) =>
    '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "Sat".
String admitWeekday(DateTime d) => _days[d.weekday - 1];

/// "20:00".
String admitTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "€32.00", or "Free".
String admitMoney(int cents) => cents == 0
    ? 'Free'
    : '€${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

/// "From €18.00", "€12.00" or "Free": an event's cheapest way in.
String admitFrom(AdmitEvent e) {
  final open = e.types.where((t) => !t.soldOut).toList();
  if (open.isEmpty) return 'Sold out';
  final least = open.map((t) => t.cents).reduce((a, b) => a < b ? a : b);
  return e.types.length > 1 ? 'From ${admitMoney(least)}' : admitMoney(least);
}

/// The booking fee on an order: €1.50 a ticket, none on free ones.
int admitFee(int count, int eachCents) => eachCents == 0 ? 0 : 150 * count;
