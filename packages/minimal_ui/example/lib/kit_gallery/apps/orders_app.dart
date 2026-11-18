/// The package example's Orders app: Lund Bakery's back office on a Friday
/// morning, as a whole app in the window. Orders (the day's figures over
/// the orders; a list on a phone, a table from a tablet up; an order opens
/// as a page on a phone and a side sheet beside the table) and Products
/// (what the counter sells today, each one switched off when it sells out).
library;

import 'package:material_ui/material_ui.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../demos/screen_orders.dart';
import '../kit_words.dart';
import 'app_frame.dart';

/// The back office, standing in the window, [gallery] its way out.
class KitOrdersApp extends StatelessWidget {
  const KitOrdersApp({super.key, required this.gallery, this.screen});

  final KitGalleryLink? gallery;

  /// The screen it opens at, one of [screens]; null opens Orders.
  final String? screen;

  /// The morning's orders; the products on the counter.
  static const screens = ['orders', 'products'];

  @override
  Widget build(BuildContext context) => KitApp(
    name: ar('Lund Bakery', 'مخبز لوند'),
    gallery: gallery,
    initial: screen == 'products' ? 1 : 0,
    destinations: [
      (
        item: MinimalNavItem(LucideIcons.receiptText, ar('Orders', 'الطلبات')),
        root: (context) => KitOrdersPage(leading: KitApp.leading(context)),
      ),
      (
        item: MinimalNavItem(LucideIcons.croissant, ar('Products', 'المنتجات')),
        root: (_) => const _Products(),
      ),
    ],
  );
}

/// One product on the counter: its name, its price in cents and how many
/// came out of the oven this morning.
typedef _Product = ({String name, int cents, int baked});

List<_Product> get _products => [
  (name: ar('Cardamom bun', 'كعكة الهيل'), cents: 340, baked: 96),
  (name: ar('Cinnamon roll', 'لفافة القرفة'), cents: 340, baked: 84),
  (name: ar('Butter croissant', 'كرواسون بالزبدة'), cents: 340, baked: 72),
  (name: ar('Blueberry muffin', 'مافن التوت الأزرق'), cents: 340, baked: 48),
  (name: ar('Rye loaf', 'رغيف الجاودار'), cents: 680, baked: 24),
  (name: ar('Sourdough loaf', 'رغيف العجين المخمّر'), cents: 720, baked: 30),
];

class _Products extends StatefulWidget {
  const _Products();

  @override
  State<_Products> createState() => _ProductsState();
}

class _ProductsState extends State<_Products> {
  final Set<String> _soldOut = {ar('Blueberry muffin', 'مافن التوت الأزرق')};

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: MinimalAppBar(
      leading: KitApp.leading(context),
      title: ar('Products', 'المنتجات'),
      subtitle: ar(
        '${_products.length - _soldOut.length} on sale',
        '${_products.length - _soldOut.length} معروضة للبيع',
      ),
    ),
    padding: EdgeInsets.zero,
    // One column of rows: the form measure on a wide window, as Settings.
    body: KitApp.measured(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MinimalSectionHeader(
            ar('On the counter today', 'على الكاونتر اليوم'),
          ),
          MinimalListSection(
            children: [
              for (final p in _products)
                MinimalListTile(
                  title: p.name,
                  subtitle:
                      '${MinimalFormat.money(p.cents, symbol: '€')} · '
                      '${_soldOut.contains(p.name) ? ar('Sold out', 'نفد') : ar('${p.baked} baked', 'خُبز ${p.baked}')}',
                  muted: _soldOut.contains(p.name),
                  trailing: MinimalSwitch(
                    value: !_soldOut.contains(p.name),
                    label: ar('${p.name} on sale', '«${p.name}» معروض للبيع'),
                    onChanged: (on) => setState(
                      () => on ? _soldOut.remove(p.name) : _soldOut.add(p.name),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
