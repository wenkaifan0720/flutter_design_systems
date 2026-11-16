/// Admit's Events: the week as a table with its filters, an event's page,
/// and the checkout. From 1024 the table and the open event stand side by
/// side, on one rule.
library;

import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'admit.dart';
import 'data.dart';
import 'home.dart';
import 'search.dart';

/// Events as a table: each row led by its day in a cell of its own, the
/// title and the place, the price at the end. A pressed (or [selected]) row
/// turns over to ink.
class AdmitEventTable extends StatelessWidget {
  /// A table of [events].
  const AdmitEventTable({
    super.key,
    required this.events,
    required this.onOpen,
    this.selected,
  });

  /// The rows.
  final List<AdmitEvent> events;

  /// Called with the row pressed.
  final ValueChanged<AdmitEvent> onOpen;

  /// The open event's id, its row inverted.
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    return BrutalSurface(
      face: BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in events.indexed) ...[
            if (i > 0) const BrutalRule(),
            _EventRow(
              event: e,
              chosen: e.id == selected,
              onTap: () => onOpen(e),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.chosen,
    required this.onTap,
  });

  final AdmitEvent event;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final c = theme.colors;
    final t = theme.textTheme;
    final price = admitFrom(event);
    return DesignPressable(
      onPressed: onTap,
      selected: chosen,
      semanticSelected: chosen ? true : null,
      semanticLabel:
          '${event.title}, ${admitDay(event.starts)} ${admitTime(event.starts)}, '
          '${event.venue}, $price',
      builder: (context, states, _) {
        final lit = chosen || states.contains(WidgetState.pressed);
        final ink = lit ? c.paper : c.ink;
        final muted = lit ? c.paper : c.inkMuted;
        return AnimatedBrutalSurface(
          stiffness: BrutalMotion.colorStiffness,
          face: BrutalFace(
            fill: lit ? c.ink : c.ink.withValues(alpha: 0),
            border: c.ink.withValues(alpha: 0),
            foreground: ink,
            borderWidth: 0,
          ),
          child: CustomPaint(
            foregroundPainter: states.contains(WidgetState.focused)
                ? BrutalInsetFocusPainter(ink)
                : null,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          admitWeekday(event.starts).toUpperCase(),
                          style: t.caption.copyWith(color: ink),
                        ),
                        Text(
                          '${event.starts.day}',
                          style: t.headline.copyWith(
                            color: ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  BrutalRule(vertical: true, color: lit ? c.paper : c.ink),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BrutalSpacing.regular,
                        vertical: BrutalSpacing.medium,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: t.label.copyWith(
                                    color: ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${admitTime(event.starts)} · ${event.venue}',
                                  style: t.secondary.copyWith(color: muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: BrutalSpacing.medium),
                          Text(
                            price,
                            style: t.secondary.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Events: the week, filtered by kind, with a sheet for more.
class AdmitEvents extends StatefulWidget {
  /// Events; [showFilter] opens with the filter sheet up, [openFirst] with
  /// Low Tide open.
  const AdmitEvents({
    super.key,
    this.showFilter = false,
    this.openFirst = false,
  });

  /// Whether the filter sheet is up at first.
  final bool showFilter;

  /// Whether Low Tide is open at first.
  final bool openFirst;

  @override
  State<AdmitEvents> createState() => _AdmitEventsState();
}

class _AdmitEventsState extends State<AdmitEvents> {
  AdmitKind? _kind;
  String _when = 'week';
  bool _freeOnly = false;
  late String? _open = widget.openFirst ? 'low-tide' : null;

  @override
  void initState() {
    super.initState();
    if (widget.showFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _filter();
      });
    }
  }

  List<AdmitEvent> get _shown => [
    for (final e in admitEvents)
      if ((_kind == null || e.kind == _kind) &&
          (!_freeOnly || admitFrom(e) == 'Free') &&
          (_when != 'weekend' || e.starts.weekday >= DateTime.friday))
        e,
  ];

  void _filter() => showBrutalBottomSheet<void>(
    context: context,
    title: 'Filter',
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final t = context.brutalTheme.textTheme;
        void set(void Function() f) {
          setSheet(f);
          setState(f);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('When', style: t.label.copyWith(fontSize: 14)),
            const SizedBox(height: BrutalSpacing.small),
            BrutalSegmentedButton<String>(
              segments: const [
                BrutalSegment(value: 'week', label: 'This week'),
                BrutalSegment(value: 'weekend', label: 'Weekend'),
              ],
              value: _when,
              onChanged: (v) => set(() => _when = v),
              semanticLabel: 'When',
            ),
            const SizedBox(height: BrutalSpacing.large),
            Row(
              children: [
                BrutalCheckbox(
                  value: _freeOnly,
                  onChanged: (v) => set(() => _freeOnly = v!),
                  semanticLabel: 'Free events only',
                ),
                const SizedBox(width: BrutalSpacing.medium),
                Expanded(child: Text('Free events only', style: t.body)),
              ],
            ),
            const SizedBox(height: BrutalSpacing.large),
            BrutalButton.filled(
              _shown.isEmpty
                  ? 'No events match'
                  : 'Show ${_shown.length} events',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= 1024;
    final frame = AdmitFrame.of(context);
    final shown = _shown;
    final list = AdmitPage(
      title: 'Events',
      actions: [
        BrutalAppBarAction(
          icon: const Icon(LucideIcons.search),
          semanticLabel: 'Search',
          onPressed: () => AdmitFrame.of(context).push(const AdmitSearchPage()),
        ),
        BrutalAppBarAction(
          icon: const Icon(LucideIcons.slidersHorizontal),
          semanticLabel: 'Filter',
          onPressed: _filter,
        ),
      ],
      children: [
        BrutalSegmentedButton<AdmitKind?>(
          segments: const [
            BrutalSegment(value: null, label: 'All'),
            BrutalSegment(value: AdmitKind.music, label: 'Music'),
            BrutalSegment(value: AdmitKind.talks, label: 'Talks'),
            BrutalSegment(value: AdmitKind.film, label: 'Film'),
          ],
          value: _kind,
          onChanged: (v) => setState(() => _kind = v),
          semanticLabel: 'Kind',
        ),
        const SizedBox(height: BrutalSpacing.large),
        Text(
          '${shown.length} ${shown.length == 1 ? 'event' : 'events'}, '
          '${_when == 'weekend' ? 'Fri 20 to Sun 22 Nov' : 'Tue 17 to Sun 22 Nov'}',
          style: context.brutalTheme.textTheme.secondary,
        ),
        const SizedBox(height: BrutalSpacing.small),
        AdmitEventTable(
          events: shown,
          selected: split ? (_open ?? shown.firstOrNull?.id) : null,
          onOpen: (e) => split
              ? setState(() => _open = e.id)
              : frame.push(AdmitEventPage(event: e)),
        ),
      ],
    );
    if (!split) return list;
    final open =
        shown.where((e) => e.id == _open).firstOrNull ?? shown.firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 480, child: list),
        const BrutalRule(vertical: true),
        Expanded(
          child: open == null
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: ValueKey(open.id),
                  child: AdmitEventPage(event: open, inPane: true),
                ),
        ),
      ],
    );
  }
}

/// An event's page: what, when and where, its ticket types with their
/// prices, and Buy tickets.
class AdmitEventPage extends StatelessWidget {
  /// The page for [event]; [inPane] when it stands beside the table.
  const AdmitEventPage({super.key, required this.event, this.inPane = false});

  /// The event.
  final AdmitEvent event;

  /// Whether it stands beside the table (no back cell).
  final bool inPane;

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final open = event.types.where((x) => !x.soldOut).toList();
    final frame = AdmitFrame.of(context);
    void buy() => frame.push(
      AdmitCheckoutPage(event: event, counts: {open.first.name: 1}),
    );
    final buyButton = BrutalButton.filled(
      open.isEmpty ? 'Sold out' : 'Buy tickets',
      onPressed: open.isEmpty ? null : buy,
    );
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return AdmitPage(
      title: inPane ? event.title : 'Event',
      actions: [
        BrutalAppBarAction(
          icon: const Icon(LucideIcons.share2),
          semanticLabel: 'Share',
          onPressed: () => showBrutalToast(context, 'Link copied.'),
        ),
      ],
      bottom: narrow
          ? Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(admitFrom(event), style: t.title),
                      Text(admitDay(event.starts), style: t.secondary),
                    ],
                  ),
                ),
                buyButton,
              ],
            )
          : null,
      children: [
        BrutalBlock(
          lead: true,
          color: c.blue,
          padding: const EdgeInsets.all(BrutalSpacing.large),
          label: 'Event',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.kind.label.toUpperCase(),
                style: t.caption.copyWith(color: c.onBlock),
              ),
              const SizedBox(height: BrutalSpacing.small),
              Semantics(
                header: true,
                child: Text(
                  event.title,
                  style: t.display.copyWith(color: c.onBlock),
                ),
              ),
              const SizedBox(height: BrutalSpacing.tight),
              Text(event.byline, style: t.body.copyWith(color: c.onBlock)),
            ],
          ),
        ),
        const SizedBox(height: BrutalSpacing.large),
        BrutalListGroup(
          children: [
            BrutalListTile(
              leading: const Icon(LucideIcons.calendarDays),
              title: '${admitDay(event.starts)}, ${admitTime(event.starts)}',
              subtitle: 'Doors ${event.doors}',
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.mapPin),
              title: event.venue,
              subtitle: event.address,
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.large),
        Text(event.blurb, style: t.body),
        admitGroupGap,
        BrutalListGroup(
          header: 'Tickets',
          children: [
            for (final type in event.types)
              BrutalListTile(
                title: type.name,
                subtitle: type.note,
                enabled: !type.soldOut,
                trailing: type.soldOut
                    ? const BrutalTag('Sold out', tone: BrutalTagTone.strong)
                    : Text(
                        admitMoney(type.cents),
                        style: t.label.copyWith(fontWeight: FontWeight.w700),
                      ),
              ),
          ],
        ),
        if (!narrow) ...[
          const SizedBox(height: BrutalSpacing.large),
          Align(alignment: AlignmentDirectional.centerStart, child: buyButton),
        ],
      ],
    );
  }
}

/// The checkout: how many of each, who and how to pay, the sum, Pay.
class AdmitCheckoutPage extends StatefulWidget {
  /// The checkout for [event], starting at [counts] by ticket type.
  const AdmitCheckoutPage({
    super.key,
    required this.event,
    required this.counts,
    this.declined = false,
  });

  /// The event.
  final AdmitEvent event;

  /// How many of each type, by name, at first.
  final Map<String, int> counts;

  /// Whether it opens on a card the bank just declined (the security code
  /// typed, the notice up, Pay become Try again).
  final bool declined;

  @override
  State<AdmitCheckoutPage> createState() => _AdmitCheckoutPageState();
}

class _AdmitCheckoutPageState extends State<AdmitCheckoutPage> {
  late final Map<String, int> _counts = {...widget.counts};
  final _email = TextEditingController(text: admitOwner.email);
  final _card = TextEditingController(text: '4242 4242 4242 4417');
  final _expiry = TextEditingController(text: '08/28');
  late final _code = TextEditingController(text: widget.declined ? '123' : '');
  String? _codeError;
  late bool _declined = widget.declined;
  bool _paying = false;

  @override
  void dispose() {
    _email.dispose();
    _card.dispose();
    _expiry.dispose();
    _code.dispose();
    super.dispose();
  }

  int get _count => _counts.values.fold(0, (a, b) => a + b);

  int get _subtotal =>
      [for (final t in widget.event.types) (_counts[t.name] ?? 0) * t.cents]
          .fold(0, (a, b) => a + b);

  int get _fee => [
    for (final t in widget.event.types) admitFee(_counts[t.name] ?? 0, t.cents),
  ].fold(0, (a, b) => a + b);

  Future<void> _pay() async {
    if (_paying) return;
    if (_code.text.trim().length < 3) {
      setState(
        () => _codeError = 'Enter the 3 digits on the back of the card.',
      );
      return;
    }
    setState(() => _paying = true);
    // The bank's answer.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _paying = false;
      _declined = false;
    });
    final frame = AdmitFrame.of(context);
    // The frame outlives this page: it goes to Tickets and says so.
    Navigator.of(context).popUntil((r) => r.isFirst);
    frame.go(AdmitPlace.tickets);
    showBrutalToast(
      frame.context,
      '$_count ${_count == 1 ? 'ticket' : 'tickets'} for ${widget.event.title} '
      'are in Tickets.',
      title: 'Paid ${admitMoney(_subtotal + _fee)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final t = theme.textTheme;
    final e = widget.event;
    final total = _subtotal + _fee;
    Widget sumLine(String a, String b, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BrutalSpacing.regular,
        vertical: BrutalSpacing.medium,
      ),
      child: Row(
        children: [
          Expanded(child: Text(a, style: strong ? t.title : t.body)),
          Text(
            b,
            style: (strong ? t.title : t.body).copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    final c = theme.colors;
    final pay = SizedBox(
      width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : null,
      child: BrutalButton.filled(
        _paying
            ? 'Paying ${admitMoney(total)}…'
            : _declined
            ? 'Try again · ${admitMoney(total)}'
            : 'Pay ${admitMoney(total)}',
        onPressed: _count == 0 ? null : _pay,
        icon: _paying ? const BrutalSpinner(size: 20) : null,
      ),
    );
    final head = <Widget>[
      Text(e.title, style: t.headline),
      Text(
        '${admitDay(e.starts)}, ${admitTime(e.starts)} · ${e.venue}',
        style: t.secondary,
      ),
      if (_declined) ...[
        const SizedBox(height: BrutalSpacing.large),
        BrutalNotice(
          tone: BrutalNoticeTone.danger,
          title: 'Your bank declined the card',
          message:
              'Nothing was charged. Check the card ending '
              '${admitOwner.card} and its expiry, or use another card, then '
              'try again.',
        ),
      ],
    ];
    final expiry = BrutalTextField(
      controller: _expiry,
      label: 'Expiry',
      hint: 'MM/YY',
      keyboardType: TextInputType.datetime,
      textDirection: TextDirection.ltr,
    );
    final code = BrutalTextField(
      controller: _code,
      label: 'Security code',
      hint: '3 digits',
      error: _codeError,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      obscureText: true,
      onChanged: (_) {
        if (_codeError != null) setState(() => _codeError = null);
      },
    );
    final order = <Widget>[
      BrutalListGroup(
        header: 'Tickets',
        children: [
          for (final type in e.types.where((x) => !x.soldOut))
            BrutalListTile(
              title: type.name,
              subtitle: '${admitMoney(type.cents)} each',
              trailing: BrutalStepper(
                value: _counts[type.name] ?? 0,
                max: 8,
                onChanged: (v) => setState(() => _counts[type.name] = v),
                semanticLabel: '${type.name} tickets',
              ),
            ),
        ],
      ),
      admitGroupGap,
      const BrutalSectionHeader('Payment'),
      BrutalTextField(
        controller: _email,
        label: 'Email for the tickets',
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
      ),
      const SizedBox(height: BrutalSpacing.large),
      BrutalTextField(
        controller: _card,
        label: 'Card number',
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.creditCardNumber],
      ),
      const SizedBox(height: BrutalSpacing.large),
      // Side by side at the reader's text up to 1.5; beyond, a label wraps and
      // the two boxes would stand at different heights, so they stack.
      if (MediaQuery.textScalerOf(context).scale(1) > 1.5) ...[
        expiry,
        const SizedBox(height: BrutalSpacing.large),
        code,
      ] else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: expiry),
            const SizedBox(width: BrutalSpacing.regular),
            Expanded(child: code),
          ],
        ),
    ];
    final summary = <Widget>[
      const BrutalSectionHeader('Summary'),
      BrutalSurface(
        face: BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final type in e.types)
              if ((_counts[type.name] ?? 0) > 0)
                sumLine(
                  '${_counts[type.name]} × ${type.name}',
                  admitMoney((_counts[type.name] ?? 0) * type.cents),
                ),
            if (_count == 0) sumLine('No tickets yet', admitMoney(0)),
            sumLine('Booking fee', _fee == 0 ? '€0.00' : admitMoney(_fee)),
            const BrutalRule(),
            sumLine(
              'Total',
              total == 0 ? '€0.00' : admitMoney(total),
              strong: true,
            ),
          ],
        ),
      ),
    ];
    // On a desk the order and its summary stand side by side, the pay button
    // under the summary; on a phone and a tablet, one column over the pinned
    // button.
    if (MediaQuery.sizeOf(context).width >= AdmitHome.deskWidth) {
      return AdmitPage(
        title: 'Checkout',
        maxWidth: admitDeskWidth,
        children: [
          ...head,
          admitGroupGap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: order,
                ),
              ),
              const SizedBox(width: BrutalSpacing.extraLarge),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...summary,
                    const SizedBox(height: BrutalSpacing.large),
                    pay,
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
    return AdmitPage(
      title: 'Checkout',
      bottom: pay,
      children: [...head, admitGroupGap, ...order, admitGroupGap, ...summary],
    );
  }
}
