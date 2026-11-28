import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class BrowseRooms extends StatelessWidget {
  const BrowseRooms({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: const NeumorphicCarouselView(
      semanticLabel: 'Rooms',
      height: 112,
      children: [
        Center(child: Text('Hall')),
        Center(child: Text('Studio')),
        Center(child: Text('Loft')),
      ],
    ),
  );
}
