import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => FrostedButton(
    'Delivery note',
    onPressed: () => showFrostedBottomSheet<void>(
      context,
      builder: (sheetContext) => FrostedBottomSheet(
        title: 'Delivery note',
        onClose: () => Navigator.pop(sheetContext),
        child: const Text('Leave the parcel at the side door.'),
      ),
    ),
  );
}
