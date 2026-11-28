import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => Fluent2Popover(
    semanticLabel: 'Sharing details',
    trigger: (_, toggle) => Fluent2Button('Sharing details', onPressed: toggle),
    content: const Text('Only invited people can read this file.'),
  );
}
