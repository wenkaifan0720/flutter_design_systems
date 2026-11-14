// The first dashboard. Star: NeumorphicDayTray, a day as a pressed tray of raised tiles, under a compact NeumorphicSpanDial that counts what's on now.
// Copy it for a page about time: what's on, what's next, what's still free. The dial is a band on a phone and whole on a desktop; the tray is the page.
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    const head = NeumorphicPageHead(
      overline: 'Today, 13:05',
      title: 'Wednesday 11 November',
    );
    final view = NeumorphicLatchGroup(
      options: const [
        NeumorphicLatch('Day'),
        NeumorphicLatch('Week'),
        NeumorphicLatch('Month'),
      ],
      value: 'Day',
      onChanged: (_) {},
    );
    const now = NeumorphicSpanDial(
      compact: true,
      start: '12:30',
      end: '13:15',
      elapsed: 35,
      total: 45,
      tag: 'Now, 13:05',
      figure: '10',
      unit: 'min left',
      title: 'A review with two people',
      note: 'The small room',
      noteMark: NeumorphicShapeMark(NeumorphicMarkShape.half),
    );
    const tray = NeumorphicDayTray(
      from: 9,
      to: 18,
      now: '13:05',
      free: [NeumorphicTrayFree('15:00', '16:30', 'Free, 1 h 30 min')],
      events: [
        NeumorphicTrayEvent(
          start: '09:00',
          end: '09:30',
          title: 'A short check-in',
          subtitle: '09:00, by video',
          mark: NeumorphicMarkShape.solid,
          isPast: true,
        ),
        NeumorphicTrayEvent(
          start: '10:00',
          end: '11:30',
          title: 'A site visit',
          subtitle: '10:00 to 11:30',
          detail: 'At the north entrance',
          mark: NeumorphicMarkShape.solid,
          isPast: true,
        ),
        NeumorphicTrayEvent(
          start: '12:30',
          end: '13:15',
          title: 'A review with two people',
          subtitle: '12:30 to 13:15, 10 min left',
          mark: NeumorphicMarkShape.half,
          isCurrent: true,
        ),
        NeumorphicTrayEvent(
          start: '14:00',
          end: '15:00',
          title: 'A planning session',
          subtitle: '14:00 to 15:00, by video',
          mark: NeumorphicMarkShape.solid,
        ),
        NeumorphicTrayEvent(
          start: '16:30',
          end: '17:30',
          title: 'A longer piece of work',
          subtitle: '16:30 to 17:30',
          mark: NeumorphicMarkShape.ring,
        ),
        NeumorphicTrayEvent(
          start: '17:00',
          end: '17:15',
          title: 'A quick call',
          subtitle: '17:00',
          mark: NeumorphicMarkShape.solid,
        ),
      ],
    );
    final todo = NeumorphicCard(
      title: 'To do today',
      subtitle: '1 of 4 done',
      children: [
        NeumorphicList(
          children: [
            NeumorphicTodoRow(
              title: 'Pay the invoice, €45',
              note: 'Due today',
              live: true,
              isFirst: true,
              onChanged: (_) {},
            ),
            NeumorphicTodoRow(
              title: 'Mark up the plan',
              note: 'Before 17:00',
              onChanged: (_) {},
            ),
            NeumorphicTodoRow(
              title: 'Book the service',
              note: 'Due Friday',
              onChanged: (_) {},
            ),
            NeumorphicTodoRow(
              title: 'Reply to the message',
              note: 'Done 11:52',
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
    final free = NeumorphicCard(
      title: 'Still free',
      subtitle: '2 h 45 min',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            NeumorphicChip('13:15 to 14:00', dense: true, onPressed: () {}),
            NeumorphicChip('15:00 to 16:30', dense: true, onPressed: () {}),
          ],
        ),
      ],
    );
    return NeumorphicScaffold(
      rail: const [
        NeumorphicRailSet(
          label: 'November 2026',
          children: [
            NeumorphicMonth(
              year: 2026,
              month: 11,
              today: 11,
              dense: true,
              marked: {2, 4, 9, 11, 12, 16, 19, 23, 25},
            ),
          ],
        ),
      ],
      railAct: NeumorphicButton.filled(
        'New',
        icon: NeumorphicGlyphs.plus,
        wide: true,
        onPressed: () {},
      ),
      actions: [
        NeumorphicRoundButton(
          NeumorphicGlyphs.plus,
          label: 'New',
          selected: true,
          onPressed: () {},
        ),
      ],
      body: t.desk
          ? NeumorphicSections(
              children: [
                NeumorphicRow(
                  spans: const [7, 5],
                  children: [
                    head,
                    Align(alignment: Alignment.bottomCenter, child: view),
                  ],
                ),
                NeumorphicRow(
                  spans: const [7, 5],
                  children: [
                    tray,
                    NeumorphicColumn(
                      gap: 28,
                      children: [
                        now,
                        todo,
                        NeumorphicGrow(child: free),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : NeumorphicSections(
              children: [
                NeumorphicColumn(gap: 14, children: [head, view]),
                now,
                tray,
                todo,
                free,
              ],
            ),
    );
  }
}
