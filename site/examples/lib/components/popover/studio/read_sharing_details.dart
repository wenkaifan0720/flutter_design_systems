import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => StudioPopover(
    semanticLabel: 'Sharing details',
    builder: (_, toggle, open) =>
        StudioButton('Sharing details', onPressed: toggle),
    content: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
