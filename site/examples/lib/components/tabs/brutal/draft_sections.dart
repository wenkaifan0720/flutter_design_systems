import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class DraftSections extends StatefulWidget {
  const DraftSections({super.key});
  @override
  State<DraftSections> createState() => _DraftSectionsState();
}

class _DraftSectionsState extends State<DraftSections> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      BrutalTabBar(
        tabs: const ['Overview', 'Activity'],
        selectedIndex: selected,
        onTap: (index) => setState(() => selected = index),
      ),
      const SizedBox(height: 16),
      Text(selected == 0 ? 'Private draft' : 'Created today'),
    ],
  );
}
