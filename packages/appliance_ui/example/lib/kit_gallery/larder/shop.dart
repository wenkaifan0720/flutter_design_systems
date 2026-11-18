/// Larder's Shop: every shelf's goods, filtered and sorted, as a grid of
/// faceplates or a list of rows; a product's page; the filter sheet.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'larder.dart';
import 'search.dart';
import 'words.dart';

/// How the goods are ordered.
enum LarderSort {
  /// The shop's own order.
  featured('Featured'),

  /// Cheapest first.
  priceLow('Price, low to high'),

  /// Dearest first.
  priceHigh('Price, high to low'),

  /// A to Z.
  name('Name');

  const LarderSort(this.label);

  /// Its name.
  final String label;
}

/// What the filter sheet narrows the goods to.
@immutable
class LarderFilter {
  /// A filter.
  const LarderFilter({this.inStock = false, this.newOnly = false, this.under});

  /// Only what can be ordered now.
  final bool inStock;

  /// Only the new season's goods.
  final bool newOnly;

  /// Only what costs less than this, in pence.
  final int? under;

  /// Whether [p] passes.
  bool admits(LarderProduct p) =>
      (!inStock || p.inStock) &&
      (!newOnly || p.isNew) &&
      (under == null || p.pence < under!);

  /// How many settings narrow the goods.
  int get count =>
      (inStock ? 1 : 0) + (newOnly ? 1 : 0) + (under == null ? 0 : 1);
}

/// Shop.
class LarderShop extends StatefulWidget {
  /// Shop; [showFilter] opens the filter sheet over it.
  const LarderShop({super.key, this.showFilter = false});

  /// Whether the filter sheet opens over it at first.
  final bool showFilter;

  @override
  State<LarderShop> createState() => _LarderShopState();
}

class _LarderShopState extends State<LarderShop> {
  LarderCategory? _shelf;
  LarderSort _sort = LarderSort.featured;
  LarderFilter _filter = const LarderFilter();
  String _view = 'grid';

  @override
  void initState() {
    super.initState();
    if (widget.showFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFilter();
      });
    }
  }

  List<LarderProduct> get _shown {
    final list = [
      for (final p in larderProducts)
        if ((_shelf == null || p.category == _shelf) && _filter.admits(p)) p,
    ];
    switch (_sort) {
      case LarderSort.featured:
        break;
      case LarderSort.priceLow:
        list.sort((a, b) => a.pence.compareTo(b.pence));
      case LarderSort.priceHigh:
        list.sort((a, b) => b.pence.compareTo(a.pence));
      case LarderSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  Future<void> _openFilter() async {
    final chosen = await showApplianceSheet<LarderFilter>(
      context: context,
      semanticLabel: 'Filter',
      builder: (context) => _FilterSheet(initial: _filter),
    );
    if (chosen != null && mounted) setState(() => _filter = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final shown = _shown;
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final shelf = ApplianceSelect<LarderCategory?>(
      label: 'Shelf',
      value: _shelf,
      items: [
        const ApplianceSelectItem(value: null, label: 'All goods'),
        for (final s in LarderCategory.values)
          ApplianceSelectItem(value: s, label: s.label),
      ],
      onChanged: (v) => setState(() => _shelf = v),
    );
    final sort = ApplianceSelect<LarderSort>(
      label: 'Sort by',
      value: _sort,
      items: [
        for (final s in LarderSort.values)
          ApplianceSelectItem(value: s, label: s.label),
      ],
      onChanged: (v) => setState(() => _sort = v),
    );
    final filters = _filter.count;
    return LarderPage(
      title: 'Shop',
      maxWidth: larderDeskWidth,
      actions: [
        ApplianceIconButton(
          icon: const Icon(LucideIcons.search),
          semanticLabel: 'Search',
          onPressed: () =>
              LarderFrame.of(context).push(const LarderSearchPage()),
          style: const ApplianceStyle(
            minimumSize: WidgetStatePropertyAll(Size.square(40)),
          ),
        ),
      ],
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: 240, child: shelf),
              const SizedBox(width: ApplianceSpacing.regular),
              SizedBox(width: 240, child: sort),
              const Spacer(),
              ApplianceButton(
                filters == 0 ? 'Filter' : 'Filter ($filters)',
                icon: const Icon(LucideIcons.slidersHorizontal),
                onPressed: _openFilter,
              ),
            ],
          )
        else ...[
          shelf,
          const SizedBox(height: ApplianceSpacing.regular),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: sort),
              const SizedBox(width: ApplianceSpacing.small),
              ApplianceIconButton(
                icon: const Icon(LucideIcons.slidersHorizontal),
                semanticLabel: filters == 0 ? 'Filter' : 'Filter, $filters on',
                selected: filters > 0,
                onPressed: _openFilter,
              ),
            ],
          ),
        ],
        const SizedBox(height: ApplianceSpacing.large),
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  LarderWords.of(context).things(shown.length),
                  style: theme.textTheme.secondary,
                ),
              ),
            ),
            ApplianceSegmentedButton<String>(
              expand: false,
              semanticLabel: 'View',
              segments: const [
                ApplianceSegment(
                  value: 'grid',
                  label: 'Grid',
                  icon: Icon(LucideIcons.layoutGrid),
                ),
                ApplianceSegment(
                  value: 'list',
                  label: 'List',
                  icon: Icon(LucideIcons.list),
                ),
              ],
              value: _view,
              onChanged: (v) => setState(() => _view = v),
            ),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.regular),
        if (_view == 'grid')
          LarderProductGrid(products: shown)
        else
          ApplianceListGroup(
            children: [
              for (final p in shown)
                ApplianceListTile(
                  leading: Icon(p.icon),
                  title: p.name,
                  subtitle: p.inStock ? p.blurb : 'Back next week',
                  trailingText: p.price,
                  onTap: () =>
                      LarderFrame.of(context)
                          .push(LarderProductPage(product: p)),
                ),
            ],
          ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final LarderFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _inStock = widget.initial.inStock;
  late bool _newOnly = widget.initial.newOnly;
  late int? _under = widget.initial.under;

  LarderFilter get _filter =>
      LarderFilter(inStock: _inStock, newOnly: _newOnly, under: _under);

  @override
  Widget build(BuildContext context) {
    final count = larderProducts.where(_filter.admits).length;
    return ApplianceSheet(
      title: 'Filter',
      onClose: () => Navigator.of(context).pop(),
      footer: [
        ApplianceButton(
          'Clear',
          onPressed: () => setState(() {
            _inStock = false;
            _newOnly = false;
            _under = null;
          }),
        ),
        ApplianceButton.filled(
          'Show $count',
          onPressed: () => Navigator.of(context).pop(_filter),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApplianceListGroup(
            children: [
              ApplianceListTile(
                title: 'In stock only',
                trailing: ApplianceSwitch(
                  value: _inStock,
                  semanticLabel: 'In stock only',
                  onChanged: (v) => setState(() => _inStock = v),
                ),
              ),
              ApplianceListTile(
                title: 'New this season',
                trailing: ApplianceSwitch(
                  value: _newOnly,
                  semanticLabel: 'New this season',
                  onChanged: (v) => setState(() => _newOnly = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: ApplianceSpacing.large),
          ApplianceListGroup(
            header: 'Price',
            children: [
              for (final (label, value) in const [
                ('Any price', null),
                ('Under £25', 2500),
                ('Under £50', 5000),
              ])
                ApplianceListTile(
                  title: label,
                  trailing: ApplianceRadio<int?>(
                    value: value,
                    groupValue: _under,
                    semanticLabel: label,
                    onChanged: (v) => setState(() => _under = v),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Goods as a grid of faceplates: two across on a phone, three on a
/// tablet, four on a desk.
class LarderProductGrid extends StatelessWidget {
  /// A grid of [products].
  const LarderProductGrid({super.key, required this.products});

  /// What it shows.
  final List<LarderProduct> products;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final across = w >= 900
          ? 4
          : w >= 560
          ? 3
          : 2;
      const gap = ApplianceSpacing.medium;
      final each = (w - gap * (across - 1)) / across;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final p in products)
            SizedBox(
              width: each,
              child: LarderProductCard(product: p),
            ),
        ],
      );
    },
  );
}

/// A product on a faceplate: its picture, its name and its price; a press
/// opens its page.
class LarderProductCard extends StatelessWidget {
  /// [product]'s card.
  const LarderProductCard({super.key, required this.product});

  /// Whose.
  final LarderProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    return AppliancePanel(
      padding: const EdgeInsets.all(ApplianceSpacing.small + 2),
      semanticLabel:
          '${product.name}, ${product.price}'
          '${product.inStock ? '' : ', out of stock'}',
      onTap: () =>
          LarderFrame.of(context).push(LarderProductPage(product: product)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LarderPicture(product: product, height: 112),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.body.copyWith(
                    fontSize: 15,
                    height: 20 / 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(product.price, style: t.figure),
                    const Spacer(),
                    if (product.isNew || !product.inStock) ...[
                      ApplianceLamp(
                        lit: product.isNew,
                        color: product.inStock ? null : c.printDisabled,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.inStock ? 'NEW' : 'SOLD OUT',
                        style: t.legend.copyWith(
                          fontSize: 11,
                          height: 14 / 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A product's page: its picture, name and price, its finish on a slide
/// selector, how many on a stepper, and the main key.
class LarderProductPage extends StatefulWidget {
  /// [product]'s page.
  const LarderProductPage({super.key, required this.product});

  /// Whose.
  final LarderProduct product;

  @override
  State<LarderProductPage> createState() => _LarderProductPageState();
}

class _LarderProductPageState extends State<LarderProductPage> {
  late String _finish = widget.product.finishes.first;
  int _count = 1;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final desk = MediaQuery.sizeOf(context).width >= 1024;
    final frame = LarderFrame.of(context);
    void add() {
      frame.add(p, finish: _finish, count: _count);
      showApplianceToast(
        context,
        '$_count × ${p.name} in the basket',
        actionLabel: 'View',
        onAction: () => frame.go(LarderPlace.basket),
      );
    }

    final buy = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(p.name, style: t.title),
        const SizedBox(height: ApplianceSpacing.small),
        Text(p.price, style: t.figure.copyWith(fontSize: 22, height: 28 / 22)),
        const SizedBox(height: ApplianceSpacing.regular),
        Text(p.blurb, style: t.body.copyWith(color: c.printMuted)),
        const SizedBox(height: ApplianceSpacing.large),
        const ApplianceFieldLabel('Finish'),
        ApplianceSegmentedButton<String>(
          semanticLabel: 'Finish',
          segments: [
            for (final f in p.finishes) ApplianceSegment(value: f, label: f),
          ],
          value: _finish,
          onChanged: (v) => setState(() => _finish = v),
        ),
        const SizedBox(height: ApplianceSpacing.large),
        const ApplianceFieldLabel('How many'),
        ApplianceStepper(
          value: _count,
          min: 1,
          max: 9,
          semanticLabel: 'How many',
          onChanged: (v) => setState(() => _count = v),
        ),
        const SizedBox(height: ApplianceSpacing.large),
        ApplianceButton.filled(
          p.inStock ? 'Add to basket' : 'Out of stock',
          icon: const Icon(LucideIcons.shoppingBasket),
          onPressed: p.inStock ? add : null,
        ),
      ],
    );
    final about = ApplianceListGroup(
      header: 'Details',
      children: [
        ApplianceListTile(title: 'About it', subtitle: p.detail),
        ApplianceListTile(
          leading: const Icon(LucideIcons.truck),
          title: 'Delivery',
          subtitle: 'Free over £40, in 3 to 5 days',
        ),
        ApplianceListTile(
          leading: const Icon(LucideIcons.package),
          title: 'Returns',
          subtitle: 'Within 30 days, unused, in its box',
        ),
      ],
    );
    return LarderPage(
      title: p.category.label,
      maxWidth: desk ? larderDeskWidth : ApplianceMetrics.readingWidth,
      actions: [
        ApplianceIconButton(
          icon: const Icon(LucideIcons.heart),
          semanticLabel: 'Save for later',
          selected: _saved,
          onPressed: () => setState(() => _saved = !_saved),
          style: const ApplianceStyle(
            minimumSize: WidgetStatePropertyAll(Size.square(40)),
          ),
        ),
      ],
      children: desk
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppliancePanel(
                          padding: const EdgeInsets.all(
                            ApplianceSpacing.medium,
                          ),
                          child: LarderPicture(product: p, height: 360),
                        ),
                        larderGroupGap,
                        about,
                      ],
                    ),
                  ),
                  const SizedBox(width: ApplianceSpacing.extraLarge),
                  Expanded(
                    child: AppliancePanel(
                      padding: const EdgeInsets.all(ApplianceSpacing.large),
                      child: buy,
                    ),
                  ),
                ],
              ),
            ]
          : [
              AppliancePanel(
                padding: const EdgeInsets.all(ApplianceSpacing.medium),
                child: LarderPicture(product: p, height: 220),
              ),
              const SizedBox(height: ApplianceSpacing.large),
              AppliancePanel(
                padding: const EdgeInsets.all(ApplianceSpacing.large),
                child: buy,
              ),
              larderGroupGap,
              about,
            ],
    );
  }
}
