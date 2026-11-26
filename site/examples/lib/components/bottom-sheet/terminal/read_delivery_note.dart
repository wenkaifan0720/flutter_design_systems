import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => TermButton(
    label: 'Delivery note',
    onPressed: () => showTermSheet<void>(
      context: context,
      builder: (sheet) => TermSheet(
        title: 'Delivery note',
        actions: [
          TermButton(label: 'Done', onPressed: () => Navigator.pop(sheet)),
        ],
        child: const Text('Leave the parcel at the side door.'),
      ),
    ),
  );
}
