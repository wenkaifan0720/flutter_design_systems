import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => ClayButton(
    'File details',
    onPressed: () => showClaySideSheet<void>(
      context: context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
  );
}
