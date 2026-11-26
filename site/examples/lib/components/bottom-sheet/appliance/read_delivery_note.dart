import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => ApplianceButton(
    'Delivery note',
    onPressed: () => showApplianceBottomSheet<void>(
      context: context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
  );
}
