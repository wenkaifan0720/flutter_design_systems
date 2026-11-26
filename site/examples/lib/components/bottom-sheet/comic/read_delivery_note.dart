import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => ComicButton(
    'Delivery note',
    onPressed: () => showComicBottomSheet<void>(
      context,
      builder: (_) => const ComicBottomSheet(
        title: 'Delivery note',
        child: Text('Leave the parcel at the side door.'),
      ),
    ),
  );
}
