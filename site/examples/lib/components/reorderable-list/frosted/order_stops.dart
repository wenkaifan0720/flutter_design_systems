import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class OrderStops extends StatefulWidget {
  const OrderStops({super.key});
  @override
  State<OrderStops> createState() => _OrderStopsState();
}

class _OrderStopsState extends State<OrderStops> {
  final stops = ['Park', 'Market', 'Pier'];
  void move(int from, int to) {
    setState(() {
      final stop = stops.removeAt(from);
      stops.insert(to, stop);
    });
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SizedBox(
      height: 200,
      child: FrostedReorderableListView<String>(
        items: stops,
        labelOf: (stop) => stop,
        shrinkWrap: true,
        onReorder: move,
        itemBuilder: (context, stop) => FrostedListTile(
          title: stop,
          meta: 'Make first',
          onPressed: () => move(stops.indexOf(stop), 0),
        ),
      ),
    ),
  );
}
