import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
          LayoutBuilder(
            builder: (context, room) {
              final line = context.termGrid.lineHeight;
              final width = room.maxWidth.clamp(0.0, 156.0);
              final rows = (width / (square ? 1.0 : 16 / 9) / line).round();
              return SizedBox(
                width: width,
                child: TermMedia(
                  slotId: 'route-guide',
                  alt: 'Route guide cover',
                  lines: rows.clamp(1, 20),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          TermButton(
            label: square ? 'Wide cover' : 'Square cover',
            onPressed: () => setState(() => square = !square),
          ),
        ],
      ),
    ),
  );
}
