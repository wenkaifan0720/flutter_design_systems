import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class AdjustZoom extends StatefulWidget {
  const AdjustZoom({super.key});

  @override
  State<AdjustZoom> createState() => _AdjustZoomState();
}

class _AdjustZoomState extends State<AdjustZoom> {
  int zoom = 100;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Fluent2ToolbarGroup(
        label: 'Zoom',
        items: [
          Fluent2ToolbarItem.button(
            icon: Fluent2Icons.subtract,
            label: 'Zoom out',
            onPressed: zoom > 10 ? () => setState(() => zoom -= 10) : null,
          ),
          Fluent2ToolbarItem.button(
            icon: Fluent2Icons.add,
            label: 'Zoom in',
            onPressed: () => setState(() => zoom += 10),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Zoom: $zoom%'),
    ],
  );
}
