import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => GlossButton(
    'Delivery note',
    onPressed: () => showGlossSheet<void>(
      context: context,
      title: 'Delivery note',
      builder: (_) => const Text('Leave the parcel at the side door.'),
    ),
  );
}
