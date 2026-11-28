import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

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
      MinimalToggleGroup<String>(
        semanticLabel: 'Layout',
        items: const [
          MinimalToggleItem('List', label: 'List'),
          MinimalToggleItem('Grid', label: 'Grid'),
        ],
        selected: layout,
        onSelectionChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
