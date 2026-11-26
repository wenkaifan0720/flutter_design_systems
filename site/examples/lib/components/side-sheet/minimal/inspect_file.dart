import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => MinimalButton(
    'File details',
    onPressed: () => showMinimalSheet<void>(
      context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
  );
}
