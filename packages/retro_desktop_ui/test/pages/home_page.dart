// The look's home, and the only page that keeps its star whole on a phone: a day tile, what's left of the day and its tasks,
// in the one active window, with the month, the recent list and the folders tiled beside it. Its star is RetroDesktopHeroHeader on a
// RetroDesktopDayTile, in folder tabs. Copy it for the one screen a person opens to see where everything stands.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopScaffold(
      who: 'YN',
      utility: const [
        RetroDesktopUtility(
          'Saved 09:18',
          icon: LucideIcons.cloudCheck,
          highlighted: true,
        ),
        RetroDesktopUtility('Wed 09:20'),
      ],
      topBar: const RetroDesktopAppBar(title: 'Today'),
      body: RetroDesktopDesktop(
        active: 'Today',
        whole: true,
        marks: const RetroDesktopDeskMarks(
          marks: [
            (RetroDesktopDeskMark.disk, 'Your files'),
            (RetroDesktopDeskMark.floppy, 'Backups'),
            (RetroDesktopDeskMark.bin, 'Bin'),
          ],
        ),
        strip: const RetroDesktopDeskStrip(
          items: [
            RetroDesktopStripItem(
              'Saved 09:18',
              icon: LucideIcons.cloudCheck,
              highlighted: true,
            ),
            RetroDesktopStripItem('Laptop', icon: LucideIcons.laptop),
            RetroDesktopStripItem('Phone', icon: LucideIcons.smartphone),
          ],
        ),
        tiles: [
          RetroDesktopWindowColumn(
            span: 3,
            windows: [
              RetroDesktopWindow(
                title: 'Folders',
                icon: LucideIcons.folder,
                info: '6 items',
                infoEnd: '18 open',
                child: RetroDesktopFolderGrid(
                  items: [
                    RetroDesktopFolder(
                      'First folder',
                      icon: LucideIcons.star,
                      note: '12 items',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.star,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Second folder',
                      icon: LucideIcons.hammer,
                      note: '9 items',
                      selected: true,
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: true,
                        icon: LucideIcons.hammer,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Third folder',
                      icon: LucideIcons.mail,
                      note: '7 items',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.mail,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Fourth folder',
                      icon: LucideIcons.bookOpen,
                      note: '5 items',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.bookOpen,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Fifth folder',
                      icon: LucideIcons.house,
                      note: '4 items',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.house,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Sixth folder',
                      icon: LucideIcons.pencil,
                      note: '3 items',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.pencil,
                      ),
                    ),
                  ],
                ),
              ),
              RetroDesktopWindow(
                title: 'Storage',
                child: RetroDesktopSections(
                  children: [
                    const RetroDesktopSectionHeader(
                      'Your files',
                      note: 'All changes saved',
                      leading: RetroDesktopDeskArt(
                        RetroDesktopDeskMark.disk,
                        size: 40,
                      ),
                    ),
                    const RetroDesktopGaugeBlock(
                      value: '1.4 GB',
                      of: 'of 5 GB',
                      share: .28,
                      endLabel: '28%',
                      footStart: 'Used',
                      footEnd: '3.6 GB free',
                    ),
                    if (t.desk) const RetroDesktopDivider.etched(),
                    if (t.desk)
                      const RetroDesktopTreeBars(
                        rows: [
                          RetroDesktopTreeRow('Pictures', '820 MB', share: .6),
                          RetroDesktopTreeRow('Papers', '410 MB', share: .3),
                          RetroDesktopTreeRow('Other', '140 MB', share: .1),
                        ],
                        totalName: 'Total',
                        total: '1,370 MB',
                      ),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 5,
            windows: [
              RetroDesktopWindow(
                title: 'Today',
                icon: LucideIcons.calendarCheck,
                status: const ['5 open', '2 done this week'],
                padding: EdgeInsets.zero,
                toolbar: RetroDesktopToolbar(
                  children: [
                    const Expanded(
                      child: RetroDesktopTextField(
                        hint: 'Search everything',
                        leading: Icon(LucideIcons.search),
                        trailing: RetroDesktopKbd('Ctrl K'),
                      ),
                    ),
                    RetroDesktopButton(
                      'New',
                      isDefaultAction: true,
                      icon: LucideIcons.plus,
                      iconOnPhone: true,
                      onPressed: onOpen,
                    ),
                  ],
                ),
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
                      flag: '1 overdue',
                      flagNote: 'since Thursday',
                      stats: [
                        ('Open', '18', null),
                        ('This week', '4', null),
                        ('Next up', '14:00', null),
                      ],
                    ),
                    RetroDesktopGrow(
                      child: RetroDesktopTabBar(
                        tabs: const ['Today', 'Soon', 'Later'],
                        onChanged: (_) {},
                        selectedIndex: 0,
                        counts: ['3', '4', '5'],
                        child: RetroDesktopWell(
                          child: RetroDesktopList(
                            share: true,
                            children: [
                              RetroDesktopTaskRow(
                                title: 'The first thing to do',
                                overdue: '1 day late',
                                subtitle: 'First folder',
                                priority: 1,
                                onChanged: (_) {},
                                onPressed: onOpen,
                              ),
                              RetroDesktopTaskRow(
                                title: 'The next thing to do',
                                bell: true,
                                time: '14:00',
                                subtitle: 'Second folder',
                                priority: 1,
                                selected: true,
                                onChanged: (_) {},
                                onPressed: onOpen,
                              ),
                              RetroDesktopTaskRow(
                                title: 'Something for the evening',
                                time: '19:00',
                                subtitle: 'Third folder',
                                priority: 2,
                                onChanged: (_) {},
                                onPressed: onOpen,
                              ),
                              RetroDesktopTaskRow(
                                title: 'Any time before bed',
                                flexibleTime: 'any time',
                                subtitle: 'Fourth folder',
                                priority: 3,
                                onChanged: (_) {},
                                onPressed: onOpen,
                              ),
                              RetroDesktopTaskRow(
                                title: 'Done this morning',
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
                    ),
                  ],
                ),
              ),
              RetroDesktopWindowShade(
                title: 'Inbox · 4 new',
                icon: LucideIcons.inbox,
                onPressed: onOpen,
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 4,
            windows: [
              RetroDesktopWindow(
                title: 'Calendar',
                icon: LucideIcons.calendarDays,
                status: const ['*14* dated · 9 open'],
                padding: EdgeInsets.zero,
                child: RetroDesktopColumn(
                  children: [
                    RetroDesktopMonthHead(
                      'March 2026',
                      onPrevious: () {},
                      onToday: () {},
                      onNext: () {},
                    ),
                    const RetroDesktopMonthGrid(
                      year: 2026,
                      month: 3,
                      today: 14,
                      days: {
                        3: RetroDesktopDayMarks(completed: 2),
                        11: RetroDesktopDayMarks(remaining: 1, overdue: true),
                        14: RetroDesktopDayMarks(remaining: 3, completed: 2),
                        16: RetroDesktopDayMarks(remaining: 1),
                        24: RetroDesktopDayMarks(remaining: 2),
                      },
                    ),
                  ],
                ),
              ),
              RetroDesktopWindow(
                title: 'Recent',
                icon: LucideIcons.fileText,
                info: '4 of 40',
                infoEnd: '1 pinned',
                child: RetroDesktopListTable(
                  total: 40,
                  columns: const [
                    RetroDesktopListTableColumn('Name'),
                    RetroDesktopListTableColumn(
                      'Edited',
                      width: 100,
                      sorted: true,
                    ),
                  ],
                  rows: [
                    RetroDesktopListTableRow(
                      title: 'A pinned item',
                      note: 'First folder',
                      icon: LucideIcons.pin,
                      selected: true,
                      cells: const [('Pinned', null)],
                      onPressed: onOpen,
                    ),
                    RetroDesktopListTableRow(
                      title: 'The one from this morning',
                      note: 'Second folder',
                      cells: const [('09:14', 'today')],
                      onPressed: onOpen,
                    ),
                    RetroDesktopListTableRow(
                      title: 'Something from yesterday',
                      note: 'Third folder',
                      cells: const [('18:05', 'yesterday')],
                      onPressed: onOpen,
                    ),
                    RetroDesktopListTableRow(
                      title: 'One from earlier this week',
                      note: 'First folder',
                      cells: const [('16:30', 'Thursday')],
                      onPressed: onOpen,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
