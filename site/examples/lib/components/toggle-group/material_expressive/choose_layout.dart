import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ChooseLayout extends StatefulWidget {
  const ChooseLayout({super.key});

  @override
  State<ChooseLayout> createState() => _ChooseLayoutState();
}

class _ChooseLayoutState extends State<ChooseLayout> {
  String layout = 'List';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExpressiveToggleGroup<String>(
        label: 'Layout',
        segments: const [
          ExpressiveButtonSegment('List', 'List'),
          ExpressiveButtonSegment('Grid', 'Grid'),
        ],
        value: layout,
        onChanged: (next) => setState(() => layout = next),
      ),
      const SizedBox(height: 12),
      Text('Layout: $layout'),
    ],
  );
}
