import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class BrowseStops extends StatelessWidget {
  const BrowseStops({super.key});
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: MinimalScrollArea(
      height: 150,
      semanticLabel: 'Route stops',
      alwaysShown: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var stop = 1; stop <= 12; stop++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Stop $stop'),
            ),
        ],
      ),
    ),
  );
}
