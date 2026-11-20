/// Larder's goods: a small kitchen and home shop's shelves, invented for
/// the example.
library;

import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A shelf of the shop.
enum LarderCategory {
  /// Pans, pots and kettles.
  cookware('Cookware', LucideIcons.cookingPot),

  /// Coffee and tea, and what makes them.
  brewing('Coffee and tea', LucideIcons.coffee),

  /// Plates, bowls and glasses.
  tableware('Tableware', LucideIcons.utensilsCrossed),

  /// Jars, tins and boxes.
  storage('Storage', LucideIcons.package),

  /// Lamps and small things for the home.
  home('Home', LucideIcons.lampDesk);

  const LarderCategory(this.label, this.icon);

  /// Its name.
  final String label;

  /// Its glyph.
  final IconData icon;
}

/// One thing on Larder's shelves.
@immutable
class LarderProduct {
  /// A product.
  const LarderProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.pence,
    required this.icon,
    required this.blurb,
    required this.detail,
    this.inStock = true,
    this.isNew = false,
    this.finishes = const ['Chalk', 'Clay', 'Slate'],
  });

  /// Its id.
  final String id;

  /// Its name.
  final String name;

  /// Its shelf.
  final LarderCategory category;

  /// Its price in pence.
  final int pence;

  /// The glyph its picture is drawn with.
  final IconData icon;

  /// A line about it.
  final String blurb;

  /// A paragraph about it.
  final String detail;

  /// Whether it can be ordered now.
  final bool inStock;

  /// Whether it is new this season.
  final bool isNew;

  /// The finishes it comes in.
  final List<String> finishes;

  /// Its price as written.
  String get price => larderPrice(pence);
}

/// [pence] as a price: £24.00.
String larderPrice(int pence) {
  final pounds = pence ~/ 100;
  final rest = (pence % 100).toString().padLeft(2, '0');
  return '£$pounds.$rest';
}

/// Everything on the shelves.
const larderProducts = <LarderProduct>[
  LarderProduct(
    id: 'stock-pot',
    name: 'Enamel stock pot, 6 L',
    category: LarderCategory.cookware,
    pence: 6800,
    icon: LucideIcons.cookingPot,
    blurb: 'Heavy steel under a glossy enamel coat.',
    detail:
        'A deep pot for stock, soup and pasta water. The enamel cleans with '
        'a soft sponge and goes on every hob, induction too. Lid included.',
    isNew: true,
  ),
  LarderProduct(
    id: 'kettle',
    name: 'Stovetop kettle',
    category: LarderCategory.brewing,
    pence: 4200,
    icon: LucideIcons.flame,
    blurb: 'Whistles once, softly, when the water boils.',
    detail:
        'A 1.6 L kettle with a cool-touch handle and a wide mouth for '
        'filling. The whistle lifts away for a quiet pour.',
  ),
  LarderProduct(
    id: 'pour-over',
    name: 'Pour-over coffee set',
    category: LarderCategory.brewing,
    pence: 3600,
    icon: LucideIcons.coffee,
    blurb: 'A cone, a carafe and fifty papers.',
    detail:
        'A ceramic cone over a 600 ml glass carafe: two cups at a time. '
        'The carafe has a lid to keep the second cup warm.',
    isNew: true,
  ),
  LarderProduct(
    id: 'tea-tin',
    name: 'Airtight tea tin',
    category: LarderCategory.storage,
    pence: 1400,
    icon: LucideIcons.leaf,
    blurb: 'Keeps 100 g of leaves dry and fresh.',
    detail:
        'A tin with an inner lid that seats with a soft click. The outer '
        'lid slides off without a fight.',
  ),
  LarderProduct(
    id: 'bowls',
    name: 'Stoneware bowls, set of 4',
    category: LarderCategory.tableware,
    pence: 4800,
    icon: LucideIcons.soup,
    blurb: 'For breakfast, noodles and everything between.',
    detail:
        'Four 16 cm bowls in a speckled glaze, safe in the dishwasher, '
        'the microwave and the oven up to 200 °C.',
  ),
  LarderProduct(
    id: 'glasses',
    name: 'Tumblers, set of 6',
    category: LarderCategory.tableware,
    pence: 2400,
    icon: LucideIcons.glassWater,
    blurb: 'Thick-based glass that stacks.',
    detail: 'Six 300 ml tumblers that nest three high in a cupboard.',
  ),
  LarderProduct(
    id: 'jars',
    name: 'Pantry jars, set of 3',
    category: LarderCategory.storage,
    pence: 2200,
    icon: LucideIcons.wheat,
    blurb: 'Glass jars with clip-down lids.',
    detail:
        'Half a litre, a litre and two: for oats, rice and flour. The '
        'seals lift out to wash.',
  ),
  LarderProduct(
    id: 'scale',
    name: 'Kitchen scale',
    category: LarderCategory.cookware,
    pence: 2900,
    icon: LucideIcons.scale,
    blurb: 'Weighs to the gram, up to 5 kg.',
    detail:
        'A flat scale with a tare key and a backlit display. Runs a year '
        'on two batteries.',
    inStock: false,
  ),
  LarderProduct(
    id: 'timer',
    name: 'Wind-up kitchen timer',
    category: LarderCategory.cookware,
    pence: 1600,
    icon: LucideIcons.timer,
    blurb: 'Sixty minutes, one ring.',
    detail: 'A mechanical timer: twist to the minutes, and it rings once.',
  ),
  LarderProduct(
    id: 'lamp',
    name: 'Clip-on shelf lamp',
    category: LarderCategory.home,
    pence: 3400,
    icon: LucideIcons.lampDesk,
    blurb: 'A warm light over the counter.',
    detail:
        'Clips to a shelf up to 4 cm thick. Three brightness steps on one '
        'key; the head turns to where you work.',
  ),
];

/// The product called [id].
LarderProduct larderProduct(String id) =>
    larderProducts.firstWhere((p) => p.id == id);

/// A line of the basket.
@immutable
class LarderLine {
  /// [count] of [product].
  const LarderLine(this.product, this.count, {this.finish = 'Chalk'});

  /// What.
  final LarderProduct product;

  /// How many.
  final int count;

  /// In which finish.
  final String finish;

  /// The line's total in pence.
  int get pence => product.pence * count;

  /// The rounded price before tax for each unit on this line.
  int get netPence => larderNetPence(product.pence) * count;
}

/// The basket the example opens with.
final larderBasket = <LarderLine>[
  LarderLine(larderProduct('pour-over'), 1, finish: 'Clay'),
  LarderLine(larderProduct('tea-tin'), 2),
  LarderLine(larderProduct('bowls'), 1, finish: 'Slate'),
];

/// Delivery's price in pence: free over £40.
int larderDelivery(int subtotal) => subtotal >= 4000 ? 0 : 450;

/// The shop's sample prices include 20% tax. Round a unit to pence.
int larderNetPence(int gross) => (gross * 5 / 6).round();

/// Delivery details and the last four digits used for an order.
@immutable
class LarderDetails {
  const LarderDetails({
    required this.name,
    required this.address,
    required this.postcode,
    required this.cardLast4,
  });

  final String name;
  final String address;
  final String postcode;
  final String cardLast4;

  LarderDetails copyWith({
    String? name,
    String? address,
    String? postcode,
    String? cardLast4,
  }) => LarderDetails(
    name: name ?? this.name,
    address: address ?? this.address,
    postcode: postcode ?? this.postcode,
    cardLast4: cardLast4 ?? this.cardLast4,
  );
}

/// The sample account used to open the shop.
const larderShopper = LarderDetails(
  name: 'Rosa Lind',
  address: '14 Orchard Row, Leith',
  postcode: 'EH6 4QT',
  cardLast4: '4421',
);

/// Where an order stands.
enum LarderOrderStage {
  /// Taken, not yet packed.
  ordered('Ordered'),

  /// Packed at the depot.
  packed('Packed'),

  /// With the courier.
  onItsWay('On its way'),

  /// At the door.
  delivered('Delivered');

  const LarderOrderStage(this.label);

  /// Its name.
  final String label;
}

/// One step of an order's tracking.
typedef LarderTrack = ({String what, String? where, String when});

/// An order.
@immutable
class LarderOrder {
  /// Order [number] of [lines], at [stage].
  const LarderOrder({
    required this.number,
    required this.placed,
    required this.lines,
    required this.stage,
    required this.due,
    this.tracking = const [],
    this.delivery = 0,
    this.method = 'Standard',
    this.details = larderShopper,
    this.gift = false,
  });

  /// Its number.
  final int number;

  /// When it was placed, in words.
  final String placed;

  /// What was ordered.
  final List<LarderLine> lines;

  /// Where it stands.
  final LarderOrderStage stage;

  /// When it arrives (or arrived), in words.
  final String due;

  /// Its tracking so far, oldest first.
  final List<LarderTrack> tracking;

  /// What delivery cost, in pence.
  final int delivery;

  /// How it is delivered.
  final String method;

  /// The delivery and payment details captured when the order was placed.
  final LarderDetails details;

  /// Whether the shopper requested gift wrapping.
  final bool gift;

  /// The masked payment method on the receipt.
  String get card => 'Card ending ${details.cardLast4}';

  /// Whether it is still to arrive.
  bool get current => stage != LarderOrderStage.delivered;

  /// How many things.
  int get count => lines.fold(0, (n, l) => n + l.count);

  /// What it cost, in pence.
  int get pence => lines.fold(0, (n, l) => n + l.pence) + delivery;
}

/// The shopper's orders, newest first.
final larderOrders = <LarderOrder>[
  LarderOrder(
    number: 1048,
    placed: 'Sat 14 Nov',
    due: 'Tue 17 Nov, 10:00 to 12:00',
    stage: LarderOrderStage.onItsWay,
    lines: [
      LarderLine(larderProduct('kettle'), 1, finish: 'Clay'),
      LarderLine(larderProduct('jars'), 1),
    ],
    tracking: const [
      (what: 'Ordered', where: null, when: 'Sat 14 Nov, 09:40'),
      (what: 'Packed', where: 'Leith depot', when: 'Sat 14 Nov, 16:05'),
      (
        what: 'On its way',
        where: 'With the courier',
        when: 'Mon 16 Nov, 08:12',
      ),
    ],
  ),
  LarderOrder(
    number: 1045,
    placed: 'Thu 12 Nov',
    due: 'Fri 20 Nov',
    stage: LarderOrderStage.packed,
    lines: [LarderLine(larderProduct('lamp'), 1, finish: 'Slate')],
    delivery: 450,
    tracking: const [
      (what: 'Ordered', where: null, when: 'Thu 12 Nov, 19:22'),
      (what: 'Packed', where: 'Leith depot', when: 'Mon 16 Nov, 11:30'),
    ],
  ),
  LarderOrder(
    number: 1039,
    placed: 'Mon 2 Nov',
    due: 'Delivered Thu 5 Nov',
    stage: LarderOrderStage.delivered,
    lines: [
      LarderLine(larderProduct('bowls'), 1, finish: 'Slate'),
      LarderLine(larderProduct('glasses'), 1),
    ],
    method: 'Next day',
    delivery: 650,
    tracking: const [
      (what: 'Ordered', where: null, when: 'Mon 2 Nov, 20:01'),
      (what: 'Packed', where: 'Leith depot', when: 'Tue 3 Nov, 09:15'),
      (what: 'On its way', where: 'With the courier', when: 'Wed 4 Nov, 07:50'),
      (
        what: 'Delivered',
        where: 'Left with a neighbour',
        when: 'Thu 5 Nov, 11:42',
      ),
    ],
  ),
  LarderOrder(
    number: 1031,
    placed: 'Fri 16 Oct',
    due: 'Delivered Tue 20 Oct',
    stage: LarderOrderStage.delivered,
    lines: [
      LarderLine(larderProduct('tea-tin'), 2),
      LarderLine(larderProduct('timer'), 1),
    ],
    delivery: 450,
    tracking: const [
      (what: 'Ordered', where: null, when: 'Fri 16 Oct, 13:10'),
      (what: 'Delivered', where: 'At the door', when: 'Tue 20 Oct, 14:03'),
    ],
  ),
];
