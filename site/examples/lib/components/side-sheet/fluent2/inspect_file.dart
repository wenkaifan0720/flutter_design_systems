import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => Fluent2Button(
    'File details',
    onPressed: () => showFluent2Sheet<void>(
      context,
      builder: (_, close) => Fluent2Sheet(
        title: 'File details',
        onClose: close,
        child: const Text('Owner: Mara Chen\nLast edited: 14 June'),
      ),
    ),
  );
}
