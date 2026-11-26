import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class BrowseRooms extends StatelessWidget {
  const BrowseRooms({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: LedgerCarousel(
      semanticLabel: 'Rooms',
      height: 112,
      itemCount: 3,
      itemBuilder: (context, i) =>
          Center(child: Text(const ['Hall', 'Studio', 'Loft'][i])),
    ),
  );
}
