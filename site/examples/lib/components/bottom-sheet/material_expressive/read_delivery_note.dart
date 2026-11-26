import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => ExpressiveFilledButton(
    'Delivery note',
    onPressed: () => showExpressiveBottomSheet<void>(
      context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Delivery note'),
            const SizedBox(height: 12),
            const Text('Leave the parcel at the side door.'),
            const SizedBox(height: 12),
            ExpressiveFilledButton(
              'Done',
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    ),
  );
}
