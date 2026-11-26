import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => ExpressivePopover(
    label: 'Sharing details',
    builder: (_, popover) =>
        ExpressiveFilledButton('Sharing details', onPressed: popover.toggle),
    content: (_) => const Text('Only invited people can read this file.'),
  );
}
