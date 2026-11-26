import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => StudioButton(
    'Delivery note',
    onPressed: () => showStudioBottomSheet<void>(
      context: context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
  );
}
