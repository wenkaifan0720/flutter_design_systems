import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => RetroDesktopButton(
    'Delivery note',
    onPressed: () => showRetroDesktopBottomSheet<void>(
      context,
      builder: (_) => const RetroDesktopBottomSheet(
        title: 'Delivery note',
        child: Text('Leave the parcel at the side door.'),
      ),
    ),
  );
}
