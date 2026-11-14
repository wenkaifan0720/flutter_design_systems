/// The package example's Orders app: Lund Bakery's back office on a Friday
/// morning, as a whole app in the window. Orders (the day's figures over
/// the orders; a list on a phone, a table from a tablet up; an order opens
/// as a page on a phone and a side sheet beside the table) and Products
/// (what the counter sells today, each one switched off when it sells out).
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../demos/screen_orders.dart';
import 'app_frame.dart';

/// The back office, standing in the window, [gallery] its way out.
class KitOrdersApp extends StatelessWidget {
  const KitOrdersApp({super.key, required this.gallery});

  final KitGalleryLink? gallery;

  @override
  Widget build(BuildContext context) => KitApp(
    name: 'Lund Bakery',
    gallery: gallery,
    destinations: [
      (
        item: const MinimalNavItem(LucideIcons.receiptText, 'Orders'),
        root: (context) => KitOrdersPage(leading: KitApp.leading(context)),
      ),
      (
        item: const MinimalNavItem(LucideIcons.croissant, 'Products'),
        root: (_) => const _Products(),
      ),
    ],
  );
}

/// One product on the counter: its name, its price in cents and how many
/// came out of the oven this morning.
typedef _Product = ({String name, int cents, int baked});

const List<_Product> _products = [
  (name: 'Cardamom bun', cents: 340, baked: 96),
  (name: 'Cinnamon roll', cents: 340, baked: 84),
  (name: 'Butter croissant', cents: 340, baked: 72),
  (name: 'Blueberry muffin', cents: 340, baked: 48),
  (name: 'Rye loaf', cents: 680, baked: 24),
  (name: 'Sourdough loaf', cents: 720, baked: 30),
];

class _Products extends StatefulWidget {
  const _Products();

  @override
  State<_Products> createState() => _ProductsState();
}

class _ProductsState extends State<_Products> {
  final Set<String> _soldOut = {'Blueberry muffin'};

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    topBar: MinimalAppBar(
      leading: KitApp.leading(context),
      title: 'Products',
      subtitle: '${_products.length - _soldOut.length} on sale',
    ),
    padding: EdgeInsets.zero,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MinimalSectionHeader('On the counter today'),
        MinimalListSection(
          children: [
            for (final p in _products)
              MinimalListTile(
                title: p.name,
                subtitle:
                    '${MinimalFormat.money(p.cents, symbol: '€')} · '
                    '${_soldOut.contains(p.name) ? 'Sold out' : '${p.baked} baked'}',
                muted: _soldOut.contains(p.name),
                trailing: MinimalSwitch(
                  value: !_soldOut.contains(p.name),
                  label: '${p.name} on sale',
                  onChanged: (on) => setState(
                    () => on ? _soldOut.remove(p.name) : _soldOut.add(p.name),
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
