import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class ResizeCover extends StatefulWidget {
  const ResizeCover({super.key});
  @override
  State<ResizeCover> createState() => _ResizeCoverState();
}

class _ResizeCoverState extends State<ResizeCover> {
  bool square = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 156,
            child: RetroDesktopMedia(
              slotId: 'route-guide',
              label: 'Route guide cover',
              aspect: square ? 1.0 : 16 / 9,
            ),
          ),
          const SizedBox(height: 12),
          RetroDesktopButton(
            square ? 'Wide cover' : 'Square cover',
            onPressed: () => setState(() => square = !square),
          ),
        ],
      ),
    ),
  );
}
