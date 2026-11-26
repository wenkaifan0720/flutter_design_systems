import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
      CivicButtonGroup(
        children: [
          CivicButton(
            onPressed: zoom > 10 ? () => setState(() => zoom -= 10) : null,
            child: Text('Out'),
          ),
          CivicButton(
            onPressed: () => setState(() => zoom += 10),
            child: Text('In'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Zoom: $zoom%'),
    ],
  );
}
