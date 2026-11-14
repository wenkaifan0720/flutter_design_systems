// A month at a glance: what falls on each day as marks you can count, this week lit, and the chosen day's list beside it. Its
// star is RetroDesktopMonthGrid in the active window. Copy it for bookings, shifts, a habit, anything on dates. A phone keeps the
// grid whole and sets the day's list under it. Days with more than the cell can hold say so in their marks, not in words.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MonthPage extends StatelessWidget {
  const MonthPage({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: 'March 2026'),
      body: RetroDesktopDesktop(
        active: 'March 2026',
        tiles: [
          RetroDesktopWindowColumn(
            span: 8,
            windows: [
              RetroDesktopWindow(
                title: 'March 2026',
                icon: LucideIcons.calendarDays,
                status: const ['*14* dated · 9 open · 5 done'],
                padding: EdgeInsets.zero,
                child: RetroDesktopColumn(
                  children: [
                    RetroDesktopMonthHead(
                      'March 2026',
                      onPrevious: onOpen,
                      onToday: onOpen,
                      onNext: onOpen,
                    ),
                    RetroDesktopMonthGrid(
                      year: 2026,
                      month: 3,
                      today: 14,
                      onDay: (_) {},
                      days: const {
                        3: RetroDesktopDayMarks(completed: 2),
                        5: RetroDesktopDayMarks(completed: 1),
                        11: RetroDesktopDayMarks(remaining: 1, overdue: true),
                        12: RetroDesktopDayMarks(remaining: 1),
                        14: RetroDesktopDayMarks(remaining: 3, completed: 2),
                        16: RetroDesktopDayMarks(remaining: 1),
                        20: RetroDesktopDayMarks(
                          remaining: 1,
                          icon: LucideIcons.send,
                        ),
                        24: RetroDesktopDayMarks(remaining: 2),
                      },
                    ),
                    const RetroDesktopLegend([
                      (RetroDesktopLegendMark.solid, 'open'),
                      (RetroDesktopLegendMark.outline, 'done'),
                      (RetroDesktopLegendMark.tint, 'this week'),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 4,
            windows: [
              RetroDesktopWindow(
                title: 'Sat 14 March',
                icon: LucideIcons.calendarCheck,
                info: '3 open',
                infoEnd: '2 done',
                child: RetroDesktopWell(
                  child: RetroDesktopList(
                    share: true,
                    children: [
                      RetroDesktopTaskRow(
                        title: 'In the morning',
                        time: '09:00',
                        subtitle: 'First folder',
                        priority: 2,
                        onChanged: (_) {},
                        onPressed: onOpen,
                      ),
                      RetroDesktopTaskRow(
                        title: 'After lunch',
                        bell: true,
                        time: '14:00',
                        subtitle: 'Second folder',
                        priority: 1,
                        selected: true,
                        onChanged: (_) {},
                        onPressed: onOpen,
                      ),
                      RetroDesktopTaskRow(
                        title: 'Any time today',
                        flexibleTime: 'any time',
                        subtitle: 'Third folder',
                        priority: 3,
                        onChanged: (_) {},
                        onPressed: onOpen,
                      ),
                      RetroDesktopTaskRow(
                        title: 'Done before nine',
                        subtitle: 'Done 08:40',
                        priority: 2,
                        value: true,
                        onChanged: (_) {},
                        onPressed: onOpen,
                      ),
                      RetroDesktopTaskRow(
                        title: 'Done on the way',
                        subtitle: 'Done 09:05',
                        priority: 3,
                        value: true,
                        onChanged: (_) {},
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ),
              ),
              const RetroDesktopWindow(
                title: 'This month',
                child: RetroDesktopDescriptionList([
                  RetroDesktopFact('Dated', '14'),
                  RetroDesktopFact('Open', '9'),
                  RetroDesktopFact('Done', '5'),
                  RetroDesktopFact('Busiest', 'Sat 14 March'),
                ], leaders: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
