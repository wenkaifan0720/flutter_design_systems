/// The Overview: the look's pitch. What it is in a sentence, a live screen
/// set in it, the app's screens, what the package holds, then the index of
/// every part's page.
library;

import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';

import 'admit.dart';
import 'data.dart';
import 'events.dart';
import 'search.dart';

/// The Overview.
class AdmitOverview extends StatelessWidget {
  /// The Overview, its index over [parts].
  const AdmitOverview({super.key, this.parts = const []});

  /// The package's parts, each with its page.
  final List<AdmitPart> parts;

  @override
  Widget build(BuildContext context) {
    final theme = context.brutalTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = AdmitFrame.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('BRUTAL_UI', style: t.caption),
        const SizedBox(height: BrutalSpacing.small),
        Semantics(
          header: true,
          child: Text('The web with its make-up off.', style: t.display),
        ),
        const SizedBox(height: BrutalSpacing.regular),
        Text(
          'Heavy black rules, square corners, a hard shadow under what you '
          'can press, cells that share their rules, and one flat colour a '
          'screen. Plain on the surface, exact underneath: everything sits on '
          'one 4 px grid.',
          style: t.body,
        ),
        const SizedBox(height: BrutalSpacing.large),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: BrutalButton.filled(
            'Open Admit',
            onPressed: () => frame.go(AdmitPlace.home),
          ),
        ),
      ],
    );
    final live = BrutalBlock(
      lead: true,
      color: c.blue,
      padding: const EdgeInsets.all(BrutalSpacing.regular),
      label: 'Live screen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ADMIT · THIS WEEK',
            style: t.caption.copyWith(color: c.onBlock),
          ),
          const SizedBox(height: BrutalSpacing.medium),
          AdmitEventTable(
            events: admitEvents.skip(2).take(4).toList(),
            onOpen: (e) => frame.push(AdmitEventPage(event: e)),
          ),
        ],
      ),
    );
    return AdmitPage(
      title: 'Brutal',
      maxWidth: wide ? 1040 : BrutalMetrics.readingWidth,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: pitch),
              const SizedBox(width: BrutalSpacing.extraLarge),
              SizedBox(width: 440, child: live),
            ],
          )
        else ...[
          pitch,
          admitGroupGap,
          live,
        ],
        admitGroupGap,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: BrutalMetrics.readingWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BrutalListGroup(
                  header: 'The app',
                  footer:
                      'Admit, a week of nights out in one city, set in Brutal.',
                  children: [
                    BrutalListTile(
                      title: 'Home',
                      subtitle: 'The next night out, then the week',
                      onTap: () => frame.go(AdmitPlace.home),
                    ),
                    BrutalListTile(
                      title: 'Events',
                      subtitle: 'The week as a table, with filters',
                      onTap: () => frame.go(AdmitPlace.events),
                    ),
                    BrutalListTile(
                      title: 'Checkout',
                      subtitle: 'Steppers, card details, the sum',
                      onTap: () => frame.push(
                        AdmitCheckoutPage(
                          event: admitEvent('low-tide'),
                          counts: const {'Standing': 2},
                        ),
                      ),
                    ),
                    BrutalListTile(
                      title: 'Payment failed',
                      subtitle: 'The bank said no; nothing charged, try again',
                      onTap: () => frame.push(
                        AdmitCheckoutPage(
                          event: admitEvent('low-tide'),
                          counts: const {'Standing': 2},
                          declined: true,
                        ),
                      ),
                    ),
                    BrutalListTile(
                      title: 'Search',
                      subtitle: 'The week by title, venue or who is on',
                      onTap: () => frame.push(const AdmitSearchPage()),
                    ),
                    BrutalListTile(
                      title: 'Tickets',
                      subtitle: 'Upcoming and past, the door code',
                      onTap: () => frame.go(AdmitPlace.tickets),
                    ),
                    BrutalListTile(
                      title: 'Settings',
                      subtitle: 'Light, dark, density, direction',
                      onTap: () => frame.go(AdmitPlace.settings),
                    ),
                  ],
                ),
                admitGroupGap,
                const BrutalListGroup(
                  header: 'In the package',
                  children: [
                    BrutalListTile(
                      title: 'The everyday parts',
                      subtitle:
                          'Buttons, fields, selects, choices, rows, blocks, '
                          'bars, tabs, dialogs, sheets and toasts',
                    ),
                    BrutalListTile(
                      title: 'Phone to desktop',
                      subtitle: 'A bottom bar, a rail from 600, a side list from 1024',
                    ),
                    BrutalListTile(
                      title: 'Light and dark',
                      subtitle:
                          'Dark inverts the rules and keeps the colour blocks',
                    ),
                    BrutalListTile(
                      title: 'For everyone',
                      subtitle:
                          'Keyboard focus you can see, screen readers, '
                          '40 px touch targets, text to 200%',
                    ),
                  ],
                ),
                if (parts.isNotEmpty) ...[
                  admitGroupGap,
                  BrutalListGroup(
                    header: 'Every part',
                    children: [
                      for (final part in parts)
                        BrutalListTile(
                          title: part.title,
                          onTap: () => frame.push(part.build(theme.brightness)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
