import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => ClayPopover(
    semanticLabel: 'Sharing details',
    builder: (_, toggle, open) =>
        ClayButton('Sharing details', onPressed: toggle),
    content: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
