import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => ComicPopover(
    semanticLabel: 'Sharing details',
    anchorBuilder: (_, anchor) =>
        ComicButton('Sharing details', onPressed: anchor.toggle),
    builder: (_, close) =>
        const Text('Only invited people can read this file.'),
  );
}
