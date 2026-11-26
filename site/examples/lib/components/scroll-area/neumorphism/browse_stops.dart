import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class BrowseStops extends StatefulWidget {
  const BrowseStops({super.key});
  @override
  State<BrowseStops> createState() => _BrowseStopsState();
}

class _BrowseStopsState extends State<BrowseStops> {
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SizedBox(
      height: 150,
      child: NeumorphicScrollArea(
        controller: scroll,
        label: 'Route stops',
        child: ListView(
          controller: scroll,
          children: [
            for (var stop = 1; stop <= 12; stop++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Stop $stop'),
              ),
          ],
        ),
      ),
    ),
  );
}
