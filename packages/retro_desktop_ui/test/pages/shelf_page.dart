// A shelf of things to look at: filters in the toolbar, then pictures with a figure on each, two across on a phone and three on
// a desktop, with the folders beside them. Its star is RetroDesktopPictureCard, which takes the media slot; a picture still missing
// at night stays dark with the look's mark. Copy it for a catalogue, a menu, listings, search results.
import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../example/lib/demo_art.dart';

class ShelfPage extends StatelessWidget {
  const ShelfPage({super.key, this.onOpen});
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopScaffold(
      topBar: const RetroDesktopAppBar(title: 'All things'),
      body: RetroDesktopDesktop(
        active: 'All things',
        tiles: [
          RetroDesktopWindowColumn(
            span: 3,
            windows: [
              RetroDesktopWindow(
                title: 'Kinds',
                icon: LucideIcons.folder,
                info: '6 kinds',
                child: RetroDesktopFolderGrid(
                  items: [
                    RetroDesktopFolder(
                      'First kind',
                      icon: LucideIcons.star,
                      note: '6 things',
                      selected: true,
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: true,
                        icon: LucideIcons.star,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Second kind',
                      icon: LucideIcons.bookOpen,
                      note: '4 things',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.bookOpen,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Third kind',
                      icon: LucideIcons.house,
                      note: '2 things',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.house,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Fourth kind',
                      icon: LucideIcons.mail,
                      note: '5 things',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.mail,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Fifth kind',
                      icon: LucideIcons.pencil,
                      note: '3 things',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.pencil,
                      ),
                    ),
                    RetroDesktopFolder(
                      'Sixth kind',
                      icon: LucideIcons.hammer,
                      note: '1 thing',
                      onPressed: onOpen,
                      art: RetroDesktopFolderArt(
                        selected: false,
                        icon: LucideIcons.hammer,
                      ),
                    ),
                  ],
                ),
              ),
              const RetroDesktopWindow(
                title: 'This shelf',
                child: RetroDesktopDescriptionList([
                  RetroDesktopFact('Things', '21'),
                  RetroDesktopFact('Kept', '4'),
                  RetroDesktopFact('Added', 'Monday'),
                ], leaders: true),
              ),
              RetroDesktopWindow(
                title: 'Looked at',
                icon: LucideIcons.history,
                child: RetroDesktopWell(
                  child: RetroDesktopList(
                    share: true,
                    children: [
                      RetroDesktopListTile(
                        title: 'The fourth thing',
                        subtitle: 'Today',
                        onPressed: onOpen,
                      ),
                      RetroDesktopListTile(
                        title: 'The second thing',
                        subtitle: 'Yesterday',
                        onPressed: onOpen,
                      ),
                      RetroDesktopListTile(
                        title: 'The first thing',
                        subtitle: 'Monday',
                        onPressed: onOpen,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 9,
            windows: [
              RetroDesktopWindow(
                title: 'All things',
                icon: LucideIcons.layoutGrid,
                info: '6 of 12',
                status: const ['Sorted by name'],
                toolbar: RetroDesktopToolbar(
                  children: [
                    RetroDesktopChip('All', onPressed: onOpen, selected: true),
                    RetroDesktopChip('New', onPressed: onOpen),
                    RetroDesktopChip('Kept', onPressed: onOpen),
                  ],
                ),
                child: RetroDesktopGridOf(
                  columns: t.desk ? 3 : 2,
                  gap: 12,
                  runGap: 12,
                  children: [
                    RetroDesktopPictureCard(
                      art: RetroDesktopObjectArt(RetroDesktopObject.folder),
                      title: 'The first thing',
                      subtitle: 'First kind',
                      figure: '12',
                      onPressed: onOpen,
                    ),
                    RetroDesktopPictureCard(
                      art: RetroDesktopObjectArt(RetroDesktopObject.text),
                      title: 'The second thing',
                      subtitle: 'First kind',
                      figure: '40',
                      onPressed: onOpen,
                    ),
                    RetroDesktopPictureCard(
                      art: RetroDesktopObjectArt(RetroDesktopObject.disk),
                      title: 'The third thing',
                      subtitle: 'Second kind',
                      figure: '8',
                      onPressed: onOpen,
                    ),
                    RetroDesktopPictureCard(
                      art: RetroDesktopObjectArt(RetroDesktopObject.table),
                      title: 'The fourth thing',
                      subtitle: 'Second kind',
                      figure: '26',
                      onPressed: onOpen,
                    ),
                    RetroDesktopPictureCard(
                      art: RetroDesktopObjectArt(RetroDesktopObject.floppy),
                      title: 'The fifth thing',
                      subtitle: 'Third kind',
                      figure: '3',
                      onPressed: onOpen,
                    ),
                    RetroDesktopPictureCard(
                      slotId: 'shelf-f',
                      title: 'The sixth thing',
                      subtitle: 'Third kind',
                      figure: '17',
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
