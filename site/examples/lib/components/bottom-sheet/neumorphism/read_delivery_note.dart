import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => NeumorphicButton(
    'Delivery note',
    onPressed: () => showNeumorphicBottomSheet<void>(
      context,
      builder: (sheetContext) => NeumorphicBottomSheet(
        title: 'Delivery note',
        onClose: () => Navigator.pop(sheetContext),
        child: const Text('Leave the parcel at the side door.'),
      ),
    ),
  );
}
