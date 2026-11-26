import 'package:material_ui/material_ui.dart';

class BrowseStops extends StatefulWidget {
  const BrowseStops({super.key});
  @override
  State<BrowseStops> createState() => _BrowseStopsState();
}

class _BrowseStopsState extends State<BrowseStops> {
  final controller = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SizedBox(
      height: 150,
      child: Scrollbar(
        controller: controller,
        thumbVisibility: true,
        child: ListView(
          controller: controller,
          children: [
            for (var stop = 1; stop <= 12; stop++)
              ListTile(dense: true, title: Text('Stop $stop')),
          ],
        ),
      ),
    ),
  );
}
