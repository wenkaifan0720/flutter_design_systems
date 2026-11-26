import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => BrutalButton(
    'File details',
    onPressed: () => showBrutalSideSheet<void>(
      context: context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
  );
}
