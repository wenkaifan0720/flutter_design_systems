import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => BrutalButton(
    'Delivery note',
    onPressed: () => showBrutalBottomSheet<void>(
      context: context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
  );
}
