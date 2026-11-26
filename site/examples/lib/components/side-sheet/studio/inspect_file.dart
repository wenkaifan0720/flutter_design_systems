import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class InspectFile extends StatelessWidget {
  const InspectFile({super.key});

  @override
  Widget build(BuildContext context) => StudioButton(
    'File details',
    onPressed: () => showStudioSideSheet<void>(
      context: context,
      title: 'File details',
      builder: (_) => const Text('Owner: Mara Chen\nLast edited: 14 June'),
    ),
  );
}
