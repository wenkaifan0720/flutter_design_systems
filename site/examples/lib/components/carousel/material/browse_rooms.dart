import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

class BrowseRooms extends StatelessWidget {
  const BrowseRooms({super.key});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SizedBox(
      height: 112,
      // Slides also follow a mouse drag, as they follow a finger.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context)
            .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
        child: CarouselView(
          itemExtent: 220,
          shrinkExtent: 120,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          children: const [
            Center(child: Text('Hall')),
            Center(child: Text('Studio')),
            Center(child: Text('Loft')),
          ],
        ),
      ),
    ),
  );
}
