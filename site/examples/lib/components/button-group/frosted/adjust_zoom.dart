import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
      FrostedButtonGroup(
        label: 'Zoom',
        items: [
          FrostedButtonGroupItem(
            label: 'Out',
            onPressed: zoom > 10 ? () => setState(() => zoom -= 10) : null,
          ),
          FrostedButtonGroupItem(
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
