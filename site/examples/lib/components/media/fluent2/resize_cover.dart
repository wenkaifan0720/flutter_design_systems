import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
              child: Fluent2Image(
                width: 156,
                height: 156 / aspect,
                semanticLabel: 'Route guide cover',
              ),
            ),
            const SizedBox(height: 12),
            Fluent2Button(
              square ? 'Wide cover' : 'Square cover',
              onPressed: () => setState(() => square = !square),
            ),
          ],
        ),
      ),
    );
  }
}
