import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ResizePanes extends StatelessWidget {
  const ResizePanes({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 640),
    child: const SizedBox(
      height: 140,
      child: NeumorphicResizable(
        minFirst: 88,
        minSecond: 88,
        first: Center(child: Text('Files')),
        second: Center(child: Text('Notes')),
      ),
    ),
  );
}
