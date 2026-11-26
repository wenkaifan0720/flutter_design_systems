import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class ChooseLayout extends StatefulWidget {
  const ChooseLayout({super.key});

  @override
  State<ChooseLayout> createState() => _ChooseLayoutState();
}

class _ChooseLayoutState extends State<ChooseLayout> {
  Set<String> layout = {'List'};

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FrostedToggleGroup<String>(
        label: 'Layout',
        segments: const [
          FrostedButtonSegment('List', 'List'),
          FrostedButtonSegment('Grid', 'Grid'),
        ],
        selected: layout,
        onSelectionChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
