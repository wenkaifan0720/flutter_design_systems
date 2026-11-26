import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

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
      ClayToggleGroup<String>(
        semanticLabel: 'Layout',
        toggles: const [
          ClayToggle(value: 'List', label: 'List'),
          ClayToggle(value: 'Grid', label: 'Grid'),
        ],
        multiSelectionEnabled: false,
        emptySelectionAllowed: false,
        selected: layout,
        onSelectionChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: ${layout.single}'),
    ],
  );
}
