import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class ReadSharingDetails extends StatelessWidget {
  const ReadSharingDetails({super.key});

  @override
  Widget build(BuildContext context) => FrostedPopover(
    label: 'Sharing details',
    builder: (_, controller, child) => FrostedButton.glass(
      'Sharing details',
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
    ),
    content: const Text('Only invited people can read this file.'),
  );
}
