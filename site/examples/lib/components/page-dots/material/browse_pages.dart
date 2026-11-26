import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';

class BrowsePages extends StatelessWidget {
  const BrowsePages({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            // Pages also follow a mouse drag, as they follow a finger.
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: const TabBarView(
                children: [
                  Center(child: Text('Cover')),
                  Center(child: Text('Notes')),
                  Center(child: Text('Credits')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const TabPageSelector(),
        ],
      ),
    ),
  );
}
