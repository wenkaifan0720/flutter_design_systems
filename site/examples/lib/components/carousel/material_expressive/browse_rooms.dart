import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class BrowseRooms extends StatefulWidget {
  const BrowseRooms({super.key});
  @override
  State<BrowseRooms> createState() => _BrowseRoomsState();
}

class _BrowseRoomsState extends State<BrowseRooms> {
  static const rooms = ['Hall', 'Studio', 'Loft'];
  final pages = ExpressiveCarouselController();

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, room) => ExpressiveCarouselView.uncontained(
            controller: pages,
            height: 90,
            itemWidth: room.maxWidth,
            itemCount: rooms.length,
            semanticLabel: 'Rooms',
            itemBuilder: (context, i) => Center(child: Text(rooms[i])),
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: pages,
          builder: (context, _) => Wrap(
            spacing: 8,
            children: [
              ExpressiveOutlinedButton(
                'Previous',
                onPressed: pages.currentItem > 0
                    ? () => pages.animateToItem(pages.currentItem - 1)
                    : null,
              ),
              ExpressiveFilledButton(
                'Next',
                onPressed: pages.currentItem < rooms.length - 1
                    ? () => pages.animateToItem(pages.currentItem + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
