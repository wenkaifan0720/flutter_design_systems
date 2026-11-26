import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      Fluent2TabList(
        tabs: const ['Overview', 'Activity'],
        selectedIndex: selected,
        onChanged: (index) => setState(() => selected = index),
      ),
      const SizedBox(height: 16),
      Text(selected == 0 ? 'Private draft' : 'Created today'),
    ],
  );
}
