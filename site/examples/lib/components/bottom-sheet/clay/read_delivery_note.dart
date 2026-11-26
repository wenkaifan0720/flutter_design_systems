import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => ClayButton(
    'Delivery note',
    onPressed: () => showClayBottomSheet<void>(
      context: context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
  );
}
