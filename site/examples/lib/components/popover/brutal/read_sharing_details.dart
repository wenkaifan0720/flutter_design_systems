import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => BrutalPopover(
    semanticLabel: 'Sharing details',
    builder: (_, toggle, open) =>
        BrutalButton('Sharing details', onPressed: toggle),
    content: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
