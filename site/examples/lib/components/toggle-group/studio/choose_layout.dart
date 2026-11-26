import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
      StudioToggleBank<String>(
        semanticLabel: 'Layout',
        options: const ['List', 'Grid'],
        labelOf: (layout) => layout,
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
