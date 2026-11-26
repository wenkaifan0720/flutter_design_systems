import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => NeumorphicPopover(
    label: 'Sharing details',
    trigger: (_, toggle) =>
        NeumorphicButton('Sharing details', onPressed: toggle),
    content: const Text('Only invited people can read this file.'),
  );
}
