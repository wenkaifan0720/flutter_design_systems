/// Admit's Tickets: upcoming and past, a ticket's page with its door code,
/// and the question before cancelling one.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'admit.dart';
import 'data.dart';
import 'home.dart';

/// Tickets: the upcoming ones, then the past, on tabs.
class AdmitTickets extends StatefulWidget {
  /// Tickets; on a desk [open] stands beside the list from the first.
  const AdmitTickets({super.key, this.open});

  /// The ticket the desk opens on; null: the first.
  final AdmitHeld? open;

  @override
  State<AdmitTickets> createState() => _AdmitTicketsState();
}

class _AdmitTicketsState extends State<AdmitTickets> {
  int _tab = 0;
  late AdmitHeld? _open = widget.open;

  @override
  Widget build(BuildContext context) {
    final frame = AdmitFrame.of(context);
    // On a desk the list stands beside the chosen ticket, as Events stands
    // beside its event; below it a ticket opens over the list.
    final split = MediaQuery.sizeOf(context).width >= AdmitHome.deskWidth;
    final open = split && admitHeld.isNotEmpty
        ? (admitHeld.contains(_open) ? _open! : admitHeld.first)
        : null;
    final list = AdmitPage(
      title: 'Tickets',
      children: [
        BrutalTabBar(
          tabs: const ['Upcoming', 'Past'],
          selectedIndex: _tab,
          onSelected: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: BrutalSpacing.large),
        if (_tab == 0)
          BrutalListGroup(
            children: [
              for (final held in admitHeld)
                Builder(
                  builder: (context) {
                    final e = admitEvent(held.eventId);
                    return BrutalListTile(
                      leading: const Icon(LucideIcons.ticket),
                      title: e.title,
                      subtitle:
                          '${admitDay(e.starts)}, ${admitTime(e.starts)} · '
                          '${held.count} × ${held.type}',
                      selected: identical(held, open),
                      onTap: split
                          ? () => setState(() => _open = held)
                          : () => frame.push(AdmitTicketPage(held: held)),
                    );
                  },
                ),
            ],
          )
        else
          BrutalListGroup(
            footer: 'Past tickets stay here for a year.',
            children: [
              for (final p in admitPast)
                BrutalListTile(
                  title: p.title,
                  subtitle: '${admitDay(p.date)} · ${p.venue} · ${p.line}',
                ),
            ],
          ),
      ],
    );
    if (open == null || _tab != 0) return list;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 480, child: list),
        const BrutalRule(vertical: true),
        Expanded(
          child: KeyedSubtree(
            key: ObjectKey(open),
            child: AdmitTicketPage(held: open),
          ),
        ),
      ],
    );
  }
}

/// A ticket's page: the code the door scans, as the screen's one block,
/// what it admits, and a quiet way to cancel it.
class AdmitTicketPage extends StatefulWidget {
  /// The page for [held]; [askCancel] opens with the cancel question up.
  const AdmitTicketPage({
    super.key,
    required this.held,
    this.askCancel = false,
  });

  /// The ticket.
  final AdmitHeld held;

  /// Whether the cancel question is up at first.
  final bool askCancel;

  @override
  State<AdmitTicketPage> createState() => _AdmitTicketPageState();
}

class _AdmitTicketPageState extends State<AdmitTicketPage> {
  @override
  void initState() {
    super.initState();
    if (widget.askCancel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _cancel();
      });
    }
  }

  Future<void> _cancel() async {
    final e = admitEvent(widget.held.eventId);
    final total = widget.held.count * widget.held.eachCents;
    final sure = await showBrutalDialog<bool>(
      context: context,
      builder: (context) => BrutalDialog(
        title:
            'Cancel ${widget.held.count == 1 ? 'this ticket' : 'these tickets'}?',
        content: Text(
          '${e.title}, ${admitDay(e.starts)}. '
          '${widget.held.count} × ${widget.held.type} go back on sale and '
          '${admitMoney(total)} comes back to your card ending '
          '${admitOwner.card} in 3 to 5 days.',
        ),
        actions: [
          BrutalDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          BrutalDialogAction(
            label: 'Cancel tickets',
            primary: true,
            destructive: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final frame = AdmitFrame.of(context);
    Navigator.of(context).maybePop();
    showBrutalToast(
      frame.context,
      '${e.title}: ${admitMoney(total)} is on its way back.',
      title: 'Tickets cancelled',
      actionLabel: 'Undo',
      onAction: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final held = widget.held;
    final e = admitEvent(held.eventId);
    return AdmitPage(
      title: 'Ticket',
      maxWidth: 440,
      children: [
        Text(e.title, style: t.headline),
        Text(
          '${admitDay(e.starts)}, doors ${e.doors} · ${e.venue}',
          style: t.secondary,
        ),
        const SizedBox(height: BrutalSpacing.large),
        BrutalBlock(
          lead: true,
          color: c.pink,
          padding: const EdgeInsets.all(BrutalSpacing.large),
          label: 'Door code',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${held.count} × ${held.type.toUpperCase()}',
                style: t.caption.copyWith(color: c.onBlock),
              ),
              const SizedBox(height: BrutalSpacing.medium),
              AspectRatio(
                aspectRatio: 1,
                child: Semantics(
                  label: 'Door code for order ${held.order}',
                  image: true,
                  child: ColoredBox(
                    color: const Color(0xFFFFFFFF),
                    child: Padding(
                      padding: const EdgeInsets.all(BrutalSpacing.regular),
                      child: CustomPaint(painter: _CodePainter(held.order)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: BrutalSpacing.medium),
              Text(
                'Order ${held.order}',
                style: t.label.copyWith(
                  color: c.onBlock,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Turn your screen up; the door scans it.',
                style: t.secondary.copyWith(color: c.onBlock),
              ),
            ],
          ),
        ),
        admitGroupGap,
        BrutalListGroup(
          children: [
            BrutalListTile(
              leading: const Icon(LucideIcons.mapPin),
              title: e.venue,
              subtitle: e.address,
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.receiptEuro),
              title:
                  'Paid ${admitMoney(held.count * held.eachCents + admitFee(held.count, held.eachCents))}',
              subtitle: 'Card ending ${admitOwner.card}',
            ),
          ],
        ),
        admitGroupGap,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BrutalButton.text(
            held.count == 1 ? 'Cancel ticket' : 'Cancel tickets',
            onPressed: _cancel,
            isDestructiveAction: true,
          ),
        ),
      ],
    );
  }
}

/// A square grid of modules seeded by the order number, with the three
/// corner marks a door scanner looks for: a picture of a code, drawn for the
/// example.
class _CodePainter extends CustomPainter {
  _CodePainter(this.seed);

  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 25;
    final m = size.shortestSide / n;
    final ink = Paint()..color = const Color(0xFF000000);
    final random = math.Random(
      seed.codeUnits.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff),
    );
    bool corner(int x, int y) =>
        (x < 8 && y < 8) || (x >= n - 8 && y < 8) || (x < 8 && y >= n - 8);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (corner(x, y)) continue;
        if (random.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x * m, y * m, m, m), ink);
        }
      }
    }
    void finder(double ox, double oy) {
      canvas
        ..drawRect(Rect.fromLTWH(ox, oy, 7 * m, 7 * m), ink)
        ..drawRect(
          Rect.fromLTWH(ox + m, oy + m, 5 * m, 5 * m),
          Paint()..color = const Color(0xFFFFFFFF),
        )
        ..drawRect(Rect.fromLTWH(ox + 2 * m, oy + 2 * m, 3 * m, 3 * m), ink);
    }

    finder(0, 0);
    finder((n - 7) * m, 0);
    finder(0, (n - 7) * m);
  }

  @override
  bool shouldRepaint(_CodePainter old) => old.seed != seed;
}
