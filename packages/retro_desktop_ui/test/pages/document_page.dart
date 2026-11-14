// One thing to read and work from: where it lives, a big title, its words, a checklist, and what's attached tiled beside it,
// with an alert laid over the column's top when something is due. Its star is RetroDesktopDocument in the active window. Copy it
// for a note, a brief, a recipe, an article, a plan. An alert that would hide a word steps down into its own column.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    const title = 'A plan worth keeping';
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: title),
      body: RetroDesktopDesktop(
        active: title,
        phoneOrder: const [title],
        tiles: [
          RetroDesktopWindowColumn(
            span: 7,
            windows: [
              RetroDesktopWindow(
                title: title,
                icon: LucideIcons.fileText,
                status: const ['First folder', '86 words · 2 of 4 checked'],
                toolbar: RetroDesktopToolbar(
                  gap: 6,
                  children: [
                    RetroDesktopPopupButton(
                      'First folder',
                      icon: LucideIcons.folder,
                      onPressed: onOpen,
                    ),
                    const RetroDesktopToolRule(),
                    RetroDesktopIconButton(
                      LucideIcons.tag,
                      label: 'Tag',
                      onPressed: onOpen,
                    ),
                    RetroDesktopIconButton(
                      LucideIcons.paperclip,
                      label: 'Attach',
                      onPressed: onOpen,
                    ),
                    const Spacer(),
                    const RetroDesktopToolNote(
                      'Saved',
                      icon: LucideIcons.cloudCheck,
                    ),
                    RetroDesktopIconButton(
                      LucideIcons.history,
                      label: 'Versions',
                      onPressed: onOpen,
                    ),
                  ],
                ),
                child: const RetroDesktopDocument(
                  title: title,
                  path: ['Everything', 'First folder'],
                  meta: [
                    ('Made', 'Sun 1 March'),
                    ('Edited', 'today 09:14'),
                    ('', '86 words'),
                  ],
                  tags: ['first', 'second'],
                  addTag: 'Tag',
                  paragraphs: [
                    'This is the paragraph that says what the thing is and who it is for. It runs to a line length that reads easily, and it stays there however wide the window gets.',
                    'The second paragraph says how much, how long and by when: 3 parts, 40 minutes each, done by Thursday. Numbers read in the same face as the words around them.',
                  ],
                  children: [
                    RetroDesktopChecklist(
                      title: 'Checklist',
                      items: [
                        RetroDesktopCheckItem(
                          'The first step, done some time ago',
                          value: true,
                        ),
                        RetroDesktopCheckItem(
                          'The second step, also done',
                          value: true,
                        ),
                        RetroDesktopCheckItem(
                          'The step to take next',
                          isCurrent: true,
                          chips: ['today 14:00'],
                          selectedChip: 'today 14:00',
                        ),
                        RetroDesktopCheckItem(
                          'The last step',
                          chips: ['Fri 13 Mar'],
                        ),
                      ],
                    ),
                    RetroDesktopDisclosure(
                      note: '12 versions · since Sunday',
                      title: 'Versions',
                      child: Text('Version history'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 5,
            windows: [
              RetroDesktopAlert(
                icon: LucideIcons.alarmClock,
                title: 'Due today at 14:00',
                body: 'The step to take next is due this afternoon.',
                meta: 'in 4 h 40 min',
                actions: [
                  RetroDesktopButton('Snooze', onPressed: onOpen),
                  RetroDesktopButton(
                    'Open it',
                    isDefaultAction: true,
                    onPressed: onOpen,
                  ),
                ],
              ),
              const RetroDesktopWindow(
                title: 'Attachments',
                icon: LucideIcons.paperclip,
                info: '3 items',
                infoEnd: '1.8 MB',
                child: RetroDesktopFileGrid(
                  items: [
                    RetroDesktopFile(
                      'first-sheet.pdf',
                      kind: 'PDF',
                      note: '2 pages',
                      art: RetroDesktopFilePageArt(
                        kind: RetroDesktopFileArt.text,
                        selected: false,
                      ),
                    ),
                    RetroDesktopFile(
                      'the-numbers.csv',
                      kind: 'CSV',
                      note: '18 rows',
                      art: RetroDesktopFilePageArt(
                        kind: RetroDesktopFileArt.table,
                        selected: true,
                      ),
                      selected: true,
                    ),
                    RetroDesktopFile(
                      'a-drawing.svg',
                      kind: 'SVG',
                      note: '1 sheet',
                      art: RetroDesktopFilePageArt(
                        kind: RetroDesktopFileArt.plan,
                        selected: false,
                      ),
                    ),
                  ],
                ),
              ),
              RetroDesktopWindow(
                title: 'Linked',
                icon: LucideIcons.link,
                info: '2 links',
                child: RetroDesktopWell(
                  child: RetroDesktopList(
                    children: [
                      RetroDesktopListTile(
                        title: 'The thing it came from',
                        subtitle: 'First folder',
                        leading: const Icon(LucideIcons.arrowUpRight, size: 15),
                        onPressed: onOpen,
                      ),
                      RetroDesktopListTile(
                        title: 'The thing it leads to',
                        subtitle: 'Second folder',
                        leading: const Icon(LucideIcons.arrowUpRight, size: 15),
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ),
              ),
              const RetroDesktopWindow(
                title: 'About this',
                child: RetroDesktopDescriptionList([
                  RetroDesktopFact('Folder', 'First folder'),
                  RetroDesktopFact(
                    'Made',
                    'Sun 1 Mar 2026 10:02',
                    figures: true,
                  ),
                  RetroDesktopFact('Edited', 'Today 09:14', figures: true),
                  RetroDesktopFact('Size', '86 words · 3 files'),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
