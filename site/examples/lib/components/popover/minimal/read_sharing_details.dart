import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => MinimalPopover(
    label: 'Sharing details',
    anchor: (_, toggle, open) =>
        MinimalButton('Sharing details', onPressed: toggle),
    content: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
