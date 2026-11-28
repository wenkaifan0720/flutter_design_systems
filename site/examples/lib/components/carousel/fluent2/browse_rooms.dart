import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class BrowseRooms extends StatelessWidget {
  const BrowseRooms({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: const Fluent2CarouselView(
      semanticLabel: 'Rooms',
      aspect: 3.4,
      children: [
        Center(child: Text('Hall')),
        Center(child: Text('Studio')),
        Center(child: Text('Loft')),
      ],
    ),
  );
}
