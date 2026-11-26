import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => Fluent2Button(
    'Delivery note',
    onPressed: () => showFluent2BottomSheet<void>(
      context,
      builder: (sheetContext) => Fluent2BottomSheet(
        title: 'Delivery note',
        onClose: () => Navigator.pop(sheetContext),
        child: const Text('Leave the parcel at the side door.'),
      ),
    ),
  );
}
