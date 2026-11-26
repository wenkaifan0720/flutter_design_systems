import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;

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
      KeycapToolbar(
        semanticLabel: 'Zoom',
        children: [
          KeycapIconButton(
            icon: const Icon(CupertinoIcons.minus),
            semanticLabel: 'Zoom out',
            onPressed: zoom > 10 ? () => setState(() => zoom -= 10) : null,
          ),
          KeycapIconButton(
            icon: const Icon(CupertinoIcons.plus),
            semanticLabel: 'Zoom in',
            onPressed: () => setState(() => zoom += 10),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text('Zoom: $zoom%'),
    ],
  );
}
