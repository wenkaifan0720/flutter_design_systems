import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class DraftSections extends StatefulWidget {
  const DraftSections({super.key});
  @override
  State<DraftSections> createState() => _DraftSectionsState();
}

class _DraftSectionsState extends State<DraftSections> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => RetroDesktopTabBar(
    tabs: const ['Overview', 'Activity'],
    selectedIndex: selected,
    onChanged: (index) => setState(() => selected = index),
    child: Text(selected == 0 ? 'Private draft' : 'Created today'),
  );
}
