import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => NeumorphicButton(
    'File details',
    onPressed: () => showNeumorphicSheet<void>(
      context,
      builder: (_, close) => NeumorphicSheet(
        title: 'File details',
        onClose: close,
        child: const Text('Owner: Mara Chen\nLast edited: 14 June'),
      ),
    ),
  );
}
