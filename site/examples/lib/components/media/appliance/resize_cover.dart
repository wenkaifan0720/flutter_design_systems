import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class ResizeCover extends StatefulWidget {
  const ResizeCover({super.key});
  @override
  State<ResizeCover> createState() => _ResizeCoverState();
}

class _ResizeCoverState extends State<ResizeCover> {
  bool square = false;
  @override
  Widget build(BuildContext context) {
    final aspect = square ? 1.0 : 16 / 9;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 156,
              child: ApplianceMedia(
                slotId: 'route-guide',
                semanticLabel: 'Route guide cover',
                aspectRatio: aspect,
              ),
            ),
            const SizedBox(height: 12),
            ApplianceButton(
              square ? 'Wide cover' : 'Square cover',
              onPressed: () => setState(() => square = !square),
            ),
          ],
        ),
      ),
    );
  }
}
