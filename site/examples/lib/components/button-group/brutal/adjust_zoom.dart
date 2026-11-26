import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

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
      BrutalButtonGroup(
        semanticLabel: 'Zoom',
        items: [
          BrutalButtonGroupItem(
            label: 'Out',
            onPressed: zoom > 10 ? () => setState(() => zoom -= 10) : null,
          ),
          BrutalButtonGroupItem(
            label: 'In',
            onPressed: () => setState(() => zoom += 10),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Zoom: $zoom%'),
    ],
  );
}
