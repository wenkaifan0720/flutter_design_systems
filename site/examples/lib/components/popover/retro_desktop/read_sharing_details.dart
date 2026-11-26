import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => RetroDesktopPopover(
    label: 'Sharing details',
    semanticLabel: 'Sharing details',
    content: (_) => const Text('Only invited people can read this file.'),
  );
}
