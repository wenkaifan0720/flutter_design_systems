// A day to work through. Its star is the task list under RetroDesktopHeroHeader with a RetroDesktopDayTile, in an active window with
// everything else beside it. Copy it for a list of things to do today: errands, doses, a shift, a run sheet.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: 'Today'),
      body: RetroDesktopDesktop(
        active: 'Today',
        tiles: [
          RetroDesktopWindowColumn(
            span: 8,
            windows: [
              RetroDesktopWindow(
                title: 'Today',
                icon: LucideIcons.calendarCheck,
                status: const ['5 open', '2 done'],
                padding: EdgeInsets.zero,
                child: RetroDesktopColumn(
                  children: [
                    const RetroDesktopHeroHeader(
                      object: RetroDesktopDayTile(
                        month: 'MAR',
                        year: '2026',
                        day: '14',
                        weekday: 'Saturday',
                      ),
                      eyebrow: 'Good morning',
                      title: '3 left today',
                      progress: .4,
                      progressLabel: '2 of 5 done',
                    ),
                    RetroDesktopGrow(
                      child: RetroDesktopWell(
                        child: RetroDesktopList(
                          share: true,
                          children: [
                            RetroDesktopTaskRow(
                              title: 'Confirm the first thing',
                              subtitle: 'Before 15:00, it needs a yes',
                              time: '15:00',
                              bell: true,
                              priority: 1,
                              selected: true,
                              onChanged: (_) {},
                              onPressed: onOpen,
                            ),
                            RetroDesktopTaskRow(
                              title: 'Choose the second thing',
                              subtitle: 'Two to pick from',
                              time: '19:00',
                              priority: 2,
                              onChanged: (_) {},
                            ),
                            RetroDesktopTaskRow(
                              title: 'Settle the third thing',
                              subtitle: 'Any time today',
                              flexibleTime: 'any time',
                              priority: 3,
                              onChanged: (_) {},
                            ),
                            RetroDesktopTaskRow(
                              title: 'Done before breakfast',
                              subtitle: 'Done 08:10',
                              priority: 2,
                              value: true,
                              onChanged: (_) {},
                            ),
                            RetroDesktopTaskRow(
                              title: 'Also done this morning',
                              subtitle: 'Done 09:05',
                              priority: 3,
                              value: true,
                              onChanged: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 4,
            windows: [
              const RetroDesktopWindow(
                title: 'This week',
                icon: LucideIcons.calendarDays,
                child: RetroDesktopDescriptionList([
                  RetroDesktopFact('Open', '12'),
                  RetroDesktopFact('Done', '4'),
                  RetroDesktopFact('Next', 'Monday 09:00'),
                ], leaders: true),
              ),
              RetroDesktopWindow(
                title: 'Waiting on',
                icon: LucideIcons.hourglass,
                info: '3 people',
                child: RetroDesktopWell(
                  child: RetroDesktopList(
                    share: true,
                    children: [
                      RetroDesktopListTile(
                        title: 'A reply from the first person',
                        subtitle: 'Asked on Monday',
                        leading: const RetroDesktopMonogram('AB'),
                        onPressed: onOpen,
                      ),
                      RetroDesktopListTile(
                        title: 'A signature from the second',
                        subtitle: 'Asked on Tuesday',
                        leading: const RetroDesktopMonogram('CD'),
                        onPressed: onOpen,
                      ),
                      RetroDesktopListTile(
                        title: 'A date from the third',
                        subtitle: 'Asked yesterday',
                        leading: const RetroDesktopMonogram('EF'),
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ),
              ),
              const RetroDesktopWindowShade(
                title: 'Someday, 9 things',
                icon: LucideIcons.archive,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
