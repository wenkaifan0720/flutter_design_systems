import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => MinimalButton(
    'Delivery note',
    onPressed: () => showMinimalBottomSheet<void>(
      context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
  );
}
