/// Admit's Home: the next night out, as the screen's one colour block, then
/// the week's events as a table of rows, each led by its day in a cell.
library;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'admit.dart';
import 'data.dart';
import 'events.dart';
import 'search.dart';
import 'tickets.dart';

/// Home.
class AdmitHome extends StatelessWidget {
  /// Home.
  const AdmitHome({super.key});

  /// From this width Home stands in two columns: the night and the week,
  /// then the tickets and the month beside them.
  static const double deskWidth = 1024;

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final c = theme.colors;
    final t = theme.textTheme;
    final account = AdmitPrefs.of(context);
    final upcoming = account.signedIn ? account.upcoming : const <AdmitHeld>[];
    final next = upcoming.isEmpty
        ? null
        : upcoming.reduce(
            (a, b) =>
                admitEvent(b.eventId).starts
                    .isBefore(admitEvent(a.eventId).starts)
                ? b
                : a,
          );
    final event = next == null ? null : admitEvent(next.eventId);
    final frame = AdmitFrame.of(context);
    final desk = MediaQuery.sizeOf(context).width >= deskWidth;
    final night = <Widget>[
      if (next != null && event != null) ...[
        const BrutalSectionHeader('Your next night out'),
        BrutalBlock(
          lead: true,
          color: c.lead,
          padding: const EdgeInsets.all(BrutalSpacing.large),
          onTap: () => frame.push(AdmitTicketPage(held: next)),
          semanticLabel: 'Show ticket for ${event.title}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${admitDay(event.starts).toUpperCase()} · ${admitTime(event.starts)}',
                style: t.caption.copyWith(color: c.onBlock),
              ),
              const SizedBox(height: BrutalSpacing.small),
              Text(event.title, style: t.display.copyWith(color: c.onBlock)),
              const SizedBox(height: BrutalSpacing.tight),
              Text(
                '${event.venue}, ${event.address}',
                style: t.body.copyWith(color: c.onBlock),
              ),
              const SizedBox(height: BrutalSpacing.large),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Show ticket',
                    style: t.label.copyWith(
                      color: c.onBlock,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: BrutalSpacing.tight),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? LucideIcons.arrowLeft
                        : LucideIcons.arrowRight,
                    size: 18,
                    color: c.onBlock,
                  ),
                ],
              ),
            ],
          ),
        ),
        admitGroupGap,
      ],
    ];
    final week = <Widget>[
      BrutalSectionHeader(
        'This week',
        trailing: BrutalButton.text(
          'All events',
          onPressed: () => frame.go(AdmitPlace.events),
        ),
      ),
      AdmitEventTable(
        events: admitEvents.take(desk ? admitEvents.length : 5).toList(),
        onOpen: (e) => frame.push(AdmitEventPage(event: e)),
      ),
    ];
    final actions = [
      BrutalAppBarAction(
        icon: const Icon(LucideIcons.search),
        semanticLabel: 'Search',
        onPressed: () => frame.push(const AdmitSearchPage()),
      ),
    ];
    if (!desk || !account.signedIn) {
      return AdmitPage(
        title: 'Home',
        actions: actions,
        children: [...night, ...week],
      );
    }
    final tickets = upcoming.fold(0, (n, h) => n + h.count);
    final paid = upcoming.fold(0, (n, h) => n + h.total);
    return AdmitPage(
      title: 'Home',
      actions: actions,
      maxWidth: admitDeskWidth,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...night, ...week],
              ),
            ),
            const SizedBox(width: BrutalSpacing.extraLarge),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrutalListGroup(
                    header: 'Your tickets',
                    children: [
                      for (final held in upcoming)
                        BrutalListTile(
                          leading: const Icon(LucideIcons.ticket),
                          title: admitEvent(held.eventId).title,
                          subtitle:
                              '${admitDay(admitEvent(held.eventId).starts)} · '
                              '${held.description}',
                          onTap: () => frame.push(AdmitTicketPage(held: held)),
                        ),
                    ],
                  ),
                  admitGroupGap,
                  BrutalListGroup(
                    header: 'This week, booked',
                    children: [
                      BrutalListTile(
                        title: 'Nights out',
                        trailingText: '${upcoming.length}',
                      ),
                      BrutalListTile(
                        title: 'Tickets',
                        trailingText: '$tickets',
                      ),
                      BrutalListTile(
                        title: 'Paid, fees in',
                        trailingText: admitMoney(paid),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
