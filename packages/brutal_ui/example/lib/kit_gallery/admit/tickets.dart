/// Admit's Tickets: upcoming and past, a ticket's page with its door code,
/// and the question before cancelling one.
library;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr/qr.dart';

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
    final account = AdmitPrefs.of(context);
    if (!account.signedIn) return const AdmitSignIn(title: 'Tickets');
    final upcoming = account.upcoming;
    // On a desk the list stands beside the chosen ticket, as Events stands
    // beside its event; below it a ticket opens over the list.
    final split = MediaQuery.sizeOf(context).width >= AdmitHome.deskWidth;
    final open = split && upcoming.isNotEmpty
        ? (upcoming.contains(_open) ? _open! : upcoming.first)
        : null;
    final list = AdmitPage(
      title: 'Tickets',
      children: [
        BrutalTabBar(
          tabs: const ['Upcoming', 'Past'],
          selectedIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
        ),
        const SizedBox(height: BrutalSpacing.large),
        if (_tab == 0 && upcoming.isEmpty)
          Text(
            'No upcoming tickets.',
            style: context.brutalTheme.textTheme.body,
          )
        else if (_tab == 0)
          BrutalListGroup(
            children: [
              for (final held in upcoming)
                Builder(
                  builder: (context) {
                    final e = admitEvent(held.eventId);
                    return BrutalListTile(
                      leading: const Icon(LucideIcons.ticket),
                      title: e.title,
                      subtitle:
                          '${admitDay(e.starts)}, ${admitTime(e.starts)} · '
                          '${held.description}',
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
    final held = widget.held;
    final total = held.subtotal;
    final sure = await showBrutalDialog<bool>(
      context: context,
      builder: (context) => BrutalDialog(
        title:
            'Cancel ${widget.held.count == 1 ? 'this ticket' : 'these tickets'}?',
        content: Text(
          '${e.title}, ${admitDay(e.starts)}. '
          '${held.description} ${held.count == 1 ? 'goes' : 'go'} back on sale'
          '${total == 0 ? '.' : ' and ${admitMoney(total)} comes back to your card ending ${held.cardEnding} in 3 to 5 days.'}',
        ),
        actions: [
          BrutalDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          BrutalDialogAction(
            label: 'Cancel tickets',
            isDefaultAction: true,
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    final frame = AdmitFrame.of(context);
    final account = AdmitPrefs.of(context);
    final index = account.upcoming.indexOf(held);
    if (!account.signedIn || index < 0) return;
    account.cancel(held);
    Navigator.of(context).popUntil((route) => route.isFirst);
    frame.go(AdmitPlace.tickets);
    showBrutalToast(
      frame.context,
      total == 0
          ? '${e.title} tickets released.'
          : '${e.title}: ${admitMoney(total)} is on its way back.',
      title: 'Tickets cancelled',
      actionLabel: 'Undo',
      onAction: () => account.restore(held, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final held = widget.held;
    final account = AdmitPrefs.of(context);
    if (!account.signedIn) return const AdmitSignIn(title: 'Ticket');
    if (!account.upcoming.contains(held)) {
      return const AdmitPage(
        title: 'Ticket',
        children: [Text('This order was cancelled.')],
      );
    }
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
          debugLabel: 'Door code',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                held.description.toUpperCase(),
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
              title: held.total == 0
                  ? 'Free ticket'
                  : 'Paid ${admitMoney(held.total)}',
              subtitle: held.total == 0
                  ? null
                  : 'Card ending ${held.cardEnding}',
            ),
            BrutalListTile(
              leading: const Icon(LucideIcons.mail),
              title: 'Ticket recipient',
              subtitle: held.recipient,
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

/// The order identifier, encoded with a four-module quiet zone on each side.
class _CodePainter extends CustomPainter {
  _CodePainter(this.order);

  final String order;
  late final _code = QrImage(
    QrCode.fromData(data: order, errorCorrectLevel: QrErrorCorrectLevel.M),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final modules = _code.moduleCount;
    final cell = size.shortestSide / (modules + 8);
    final left = (size.width - cell * modules) / 2;
    final top = (size.height - cell * modules) / 2;
    final ink = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    for (var row = 0; row < modules; row++) {
      for (var column = 0; column < modules; column++) {
        if (_code.isDark(row, column)) {
          canvas.drawRect(
            Rect.fromLTWH(left + column * cell, top + row * cell, cell, cell),
            ink,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CodePainter old) => old.order != order;
}
