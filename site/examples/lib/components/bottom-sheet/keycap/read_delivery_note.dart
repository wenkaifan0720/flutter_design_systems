import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => KeycapButton(
    onPressed: () => showKeycapBottomSheet<void>(
      context: context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
    child: const Text('Delivery note'),
  );
}
