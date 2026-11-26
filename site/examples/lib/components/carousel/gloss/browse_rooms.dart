import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class BrowseRooms extends StatelessWidget {
  const BrowseRooms({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: GlossCarousel(
      semanticLabel: 'Rooms',
      aspectRatio: 3.4,
      itemCount: 3,
      itemBuilder: (context, i) =>
          Center(child: Text(const ['Hall', 'Studio', 'Loft'][i])),
    ),
  );
}
