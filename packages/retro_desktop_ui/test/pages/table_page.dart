// How much of a whole is taken, and by what: a gauge standing against its limit, then the parts as a tree of bars and a table
// with a total. Its stars are RetroDesktopGaugeBlock in the active window and RetroDesktopTreeBars. Copy it for a budget, a quota, a
// stock level, hours on a contract, anything counted against a limit. Set figures in a table's own mono columns.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TablePage extends StatelessWidget {
  const TablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: 'This month'),
      body: const RetroDesktopDesktop(
        active: 'This month',
        tiles: [
          RetroDesktopWindowColumn(
            span: 5,
            windows: [
              RetroDesktopWindow(
                title: 'This month',
                icon: LucideIcons.gauge,
                status: ['*640* of 1,000 used'],
                child: RetroDesktopSections(
                  children: [
                    RetroDesktopSectionHeader(
                      'Where it stands',
                      note: 'Counted to the 14th',
                    ),
                    RetroDesktopGaugeBlock(
                      value: '640',
                      of: 'of 1,000',
                      share: .64,
                      endLabel: '64%',
                      footStart: 'Used',
                      footEnd: '360 left',
                    ),
                    RetroDesktopDivider.etched(),
                    RetroDesktopTreeBars(
                      rows: [
                        RetroDesktopTreeRow(
                          'First part',
                          '310',
                          share: .48,
                          open: true,
                        ),
                        RetroDesktopTreeRow(
                          'A piece of it',
                          '190',
                          share: .3,
                          level: 1,
                        ),
                        RetroDesktopTreeRow(
                          'Another piece',
                          '120',
                          share: .19,
                          level: 1,
                        ),
                        RetroDesktopTreeRow('Second part', '220', share: .34),
                        RetroDesktopTreeRow('Third part', '110', share: .17),
                      ],
                      totalName: 'Total',
                      total: '640',
                    ),
                  ],
                ),
              ),
              RetroDesktopWindow(
                title: 'Limits',
                icon: LucideIcons.ruler,
                child: RetroDesktopDescriptionList([
                  RetroDesktopFact('Each month', '1,000'),
                  RetroDesktopFact('Each week', '250'),
                  RetroDesktopFact('Starts again', '1 April'),
                ], leaders: true),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 7,
            windows: [
              RetroDesktopWindow(
                title: 'Every entry',
                icon: LucideIcons.table,
                info: '5 entries',
                infoEnd: '640 in all',
                child: RetroDesktopTable(
                  columns: [
                    RetroDesktopTableColumn('What', flex: 1.4),
                    RetroDesktopTableColumn('When', width: 72, figures: true),
                    RetroDesktopTableColumn('Kind', flex: .8),
                    RetroDesktopTableColumn(
                      'How much',
                      width: 84,
                      figures: true,
                      sorted: true,
                      end: true,
                    ),
                  ],
                  rows: [
                    ['The largest entry', '03 Mar', 'First', '190'],
                    ['The next one', '09 Mar', 'Second', '160'],
                    ['A middling entry', '11 Mar', 'First', '120'],
                    ['A smaller entry', '12 Mar', 'Third', '110'],
                    ['The latest entry', '14 Mar', 'Second', '60'],
                  ],
                  total: ['Total', '', '', '640'],
                ),
              ),
              RetroDesktopWindow(
                title: 'Week by week',
                icon: LucideIcons.chartColumn,
                child: RetroDesktopDayBars(
                  values: [120, 190, 210, 120],
                  labels: ['Wk\n1', 'Wk\n2', 'Wk\n3', 'Wk\n4'],
                  limit: 250,
                  max: 300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
