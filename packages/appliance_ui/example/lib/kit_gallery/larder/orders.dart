/// Larder's Orders: the ones on their way and the ones delivered; an
/// order's page with its tracking down a seam of lamps. On a desk the list
/// and the order stand side by side, a grip between them.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';

import 'data.dart';
import 'larder.dart';
import 'words.dart';

/// An order's stage as a label plate.
ApplianceTag _stageTag(LarderOrder order) => ApplianceTag(
  order.stage.label,
  tone: switch (order.stage) {
    LarderOrderStage.delivered => ApplianceTagTone.neutral,
    LarderOrderStage.onItsWay => ApplianceTagTone.signal,
    _ => ApplianceTagTone.ready,
  },
);

/// Orders.
class LarderOrders extends StatefulWidget {
  /// Orders; [openFirst] opens the newest one's page at once (on a desk it
  /// stands beside the list already).
  const LarderOrders({super.key, this.openFirst = false});

  /// Whether the newest order's page opens over the list at first.
  final bool openFirst;

  @override
  State<LarderOrders> createState() => _LarderOrdersState();
}

class _LarderOrdersState extends State<LarderOrders> {
  String _tab = 'current';
  int? _chosen;
  bool _desk = false;

  @override
  void initState() {
    super.initState();
    if (widget.openFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _desk) return;
        final frame = LarderFrame.of(context);
        if (frame.orders.isNotEmpty) {
          frame.push(LarderOrderPage(order: frame.orders.first));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      _desk = box.maxWidth >= 720;
      return _build(context);
    },
  );

  Widget _build(BuildContext context) {
    final frame = LarderFrame.of(context);
    final prefs = LarderPrefs.of(context);
    if (prefs.account == null) {
      return LarderPage(
        title: 'Orders',
        children: [
          ApplianceEmptyState(
            title: 'Sign in to see your orders',
            message: 'Your order history and delivery details are available in your account.',
            action: ApplianceButton(
              'Sign in to demo account',
              onPressed: prefs.signIn,
            ),
          ),
        ],
      );
    }
    final orders = frame.orders;
    if (orders.isEmpty) return const SizedBox.shrink();
    if (_desk) {
      final chosen = orders.firstWhere(
        (o) => o.number == _chosen,
        orElse: () => orders.first,
      );
      return ApplianceScreen(
        scroll: false,
        maxWidth: larderDeskWidth,
        topBar: const ApplianceAppBar(title: 'Orders'),
        body: ApplianceSplitView(
          initialFraction: 0.38,
          minFirst: 260,
          minSecond: 360,
          semanticLabel: 'Resize the list',
          first: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.only(
              end: ApplianceSpacing.regular,
              bottom: ApplianceSpacing.large,
            ),
            child: _OrderList(
              orders: orders,
              chosen: chosen.number,
              onOpen: (o) => setState(() => _chosen = o.number),
            ),
          ),
          second: SingleChildScrollView(
            key: ValueKey(chosen.number),
            padding: const EdgeInsetsDirectional.only(
              start: ApplianceSpacing.large,
              end: ApplianceSpacing.regular,
              bottom: ApplianceSpacing.large,
            ),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: LarderOrderDetail(order: chosen, heading: true),
              ),
            ),
          ),
        ),
      );
    }
    final current = orders.where((o) => o.current).toList();
    final past = orders.where((o) => !o.current).toList();
    void open(LarderOrder o) => frame.push(LarderOrderPage(order: o));
    return LarderPage(
      title: 'Orders',
      barBottom: ApplianceTabBar<String>(
        tabs: [
          ApplianceSegment(
            value: 'current',
            label: 'On their way (${current.length})',
          ),
          const ApplianceSegment(value: 'past', label: 'Delivered'),
        ],
        value: _tab,
        onChanged: (t) => setState(() => _tab = t),
      ),
      children: _tab == 'current'
          ? [
              if (current.isEmpty)
                ApplianceEmptyState(
                  title: 'Nothing on its way',
                  message: 'Orders you place stand here until they arrive.',
                  action: ApplianceButton(
                    'Go to Shop',
                    onPressed: () => frame.go(LarderPlace.shop),
                  ),
                ),
              for (final (i, o) in current.indexed) ...[
                if (i > 0) const SizedBox(height: ApplianceSpacing.medium),
                _CurrentCard(order: o, onOpen: () => open(o)),
              ],
            ]
          : [
              ApplianceListGroup(
                children: [
                  for (final o in past)
                    ApplianceListTile(
                      leading: const Icon(LucideIcons.packageCheck),
                      title: 'Order ${o.number}',
                      subtitle:
                          '${o.due} · '
                          '${LarderWords.of(context).things(o.count)}',
                      trailingText: larderPrice(o.pence),
                      onTap: () => open(o),
                    ),
                ],
              ),
            ],
    );
  }
}

/// The desk's list: what is on its way, then what was delivered.
class _OrderList extends StatelessWidget {
  const _OrderList({
    required this.orders,
    required this.chosen,
    required this.onOpen,
  });

  final List<LarderOrder> orders;
  final int chosen;
  final ValueChanged<LarderOrder> onOpen;

  @override
  Widget build(BuildContext context) {
    ApplianceListTile row(LarderOrder o) => ApplianceListTile(
      title: 'Order ${o.number}',
      subtitle: o.current ? o.stage.label : o.due,
      trailingText: larderPrice(o.pence),
      selected: o.number == chosen,
      showChevron: false,
      onTap: () => onOpen(o),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ApplianceListGroup(
          header: 'On their way',
          children: [for (final o in orders.where((o) => o.current)) row(o)],
        ),
        const SizedBox(height: ApplianceSpacing.large),
        ApplianceListGroup(
          header: 'Delivered',
          children: [for (final o in orders.where((o) => !o.current)) row(o)],
        ),
      ],
    );
  }
}

/// An order on its way, on a faceplate: its stage's lamps along a seam and
/// when it arrives.
class _CurrentCard extends StatelessWidget {
  const _CurrentCard({required this.order, required this.onOpen});

  final LarderOrder order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.applianceTheme.textTheme;
    return AppliancePanel(
      padding: const EdgeInsets.all(ApplianceSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Order ${order.number}', style: t.title)),
              _stageTag(order),
            ],
          ),
          const SizedBox(height: ApplianceSpacing.tight),
          Text(
            'Arrives ${order.due} · '
            '${LarderWords.of(context).things(order.count)}',
            style: t.secondary,
          ),
          const SizedBox(height: ApplianceSpacing.large),
          ApplianceStepProgress(
            steps: [for (final s in LarderOrderStage.values) s.label],
            current: order.stage.index,
          ),
          const SizedBox(height: ApplianceSpacing.large),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ApplianceButton(
              'Track the order',
              icon: const Icon(LucideIcons.mapPin),
              onPressed: onOpen,
            ),
          ),
        ],
      ),
    );
  }
}

/// An order's page.
class LarderOrderPage extends StatelessWidget {
  /// [order]'s page.
  const LarderOrderPage({super.key, required this.order});

  /// Which.
  final LarderOrder order;

  @override
  Widget build(BuildContext context) => LarderPage(
    title: 'Order ${order.number}',
    children: [LarderOrderDetail(order: order)],
  );
}

/// What an order's page holds: where it stands, its tracking, what is in
/// it and how it comes.
class LarderOrderDetail extends StatelessWidget {
  /// [order]'s detail; [heading] when no bar names it.
  const LarderOrderDetail({
    super.key,
    required this.order,
    this.heading = false,
  });

  /// Which.
  final LarderOrder order;

  /// Whether it names the order itself (beside a list on a desk).
  final bool heading;

  @override
  Widget build(BuildContext context) {
    final theme = context.applianceTheme;
    final t = theme.textTheme;
    final frame = LarderFrame.of(context);
    final steps = LarderOrderStage.values;
    final tracked = {for (final s in order.tracking) s.what};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading) ...[
          Semantics(
            header: true,
            child: Text('Order ${order.number}', style: t.heading),
          ),
          const SizedBox(height: ApplianceSpacing.small),
        ],
        Row(
          children: [
            _stageTag(order),
            const SizedBox(width: ApplianceSpacing.small),
            Expanded(child: Text('Placed ${order.placed}', style: t.secondary)),
          ],
        ),
        const SizedBox(height: ApplianceSpacing.large),
        AppliancePanel(
          padding: const EdgeInsets.all(ApplianceSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(order.current ? 'Arrives' : 'Arrived', style: t.legend),
              const SizedBox(height: ApplianceSpacing.tight),
              Text(order.due.replaceFirst('Delivered ', ''), style: t.title),
              const SizedBox(height: ApplianceSpacing.large),
              ApplianceTimeline(
                entries: [
                  for (final s in order.tracking)
                    ApplianceTimelineEntry(
                      title: s.what,
                      detail: s.where,
                      time: s.when,
                      state: order.current && s == order.tracking.last
                          ? ApplianceTimelineState.current
                          : ApplianceTimelineState.done,
                    ),
                  for (final s in steps)
                    if (!tracked.contains(s.label) && order.current)
                      ApplianceTimelineEntry(
                        title: s.label,
                        state: ApplianceTimelineState.upcoming,
                      ),
                ],
              ),
            ],
          ),
        ),
        larderGroupGap,
        const ApplianceSectionHeader('In the order'),
        AppliancePanel(
          child: ApplianceTable(
            columns: const [
              ApplianceTableColumn('Item', flex: 3),
              ApplianceTableColumn('Qty', numeric: true),
              ApplianceTableColumn('Price', numeric: true, flex: 2),
            ],
            rows: [
              for (final l in order.lines)
                [
                  '${l.product.name}, ${l.finish}',
                  '${l.count}',
                  larderPrice(l.pence),
                ],
              [
                'Delivery',
                '',
                order.delivery == 0 ? 'Free' : larderPrice(order.delivery),
              ],
              ['Total', '', larderPrice(order.pence)],
            ],
          ),
        ),
        larderGroupGap,
        const ApplianceSectionHeader('Delivery'),
        AppliancePanel(
          child: ApplianceDescriptionList(
            items: [
              (
                'To',
                '${order.details.name}, ${order.details.address}, ${order.details.postcode}',
              ),
              if (order.gift) ('Gift wrap', 'Requested'),
              ('By', order.method),
              ('Paid with', order.card),
            ],
          ),
        ),
        larderGroupGap,
        Wrap(
          spacing: ApplianceSpacing.small,
          runSpacing: ApplianceSpacing.small,
          children: [
            if (order.current)
              ApplianceButton(
                'Get help with it',
                icon: const Icon(LucideIcons.messageCircle),
                onPressed: () => showApplianceToast(
                  context,
                  'We will call you about order ${order.number}.',
                ),
              )
            else
              ApplianceButton.filled(
                'Buy again',
                icon: const Icon(LucideIcons.rotateCcw),
                onPressed: () {
                  for (final l in order.lines) {
                    frame.add(l.product, finish: l.finish, count: l.count);
                  }
                  showApplianceToast(context, 'Added to the basket');
                },
              ),
          ],
        ),
      ],
    );
  }
}
