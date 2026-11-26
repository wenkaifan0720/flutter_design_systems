import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => KeycapPopover(
    semanticLabel: 'Sharing details',
    builder: (_, anchor) => KeycapButton(
      onPressed: anchor.toggle,
      child: const Text('Sharing details'),
    ),
    content: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
