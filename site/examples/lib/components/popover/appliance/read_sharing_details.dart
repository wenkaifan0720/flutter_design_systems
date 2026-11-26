import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => AppliancePopover(
    semanticLabel: 'Sharing details',
    builder: (_, anchor) =>
        ApplianceButton('Sharing details', onPressed: anchor.toggle),
    content: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
