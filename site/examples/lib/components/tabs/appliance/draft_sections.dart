import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
      ApplianceTabBar<int>(
        tabs: const [
          ApplianceSegment(value: 0, label: 'Overview'),
          ApplianceSegment(value: 1, label: 'Activity'),
        ],
        value: selected,
        onChanged: (index) => setState(() => selected = index),
      ),
      const SizedBox(height: 16),
      Text(selected == 0 ? 'Private draft' : 'Created today'),
    ],
  );
}
