import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      Fluent2ToolbarToggleGroup<String>(
        label: 'Layout',
        toggles: const [
          Fluent2ToolbarToggle('List', icon: Fluent2Icons.list, label: 'List'),
          Fluent2ToolbarToggle('Grid', icon: Fluent2Icons.grid, label: 'Grid'),
        ],
        selected: layout,
        onSelectionChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
