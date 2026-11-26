import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => TermPopover(
    title: 'Sharing details',
    anchorBuilder: (_, anchor) =>
        TermButton(label: 'Sharing details', onPressed: anchor.toggle),
    builder: (_) => const Text('Only invited people can read this file.'),
  );
}
