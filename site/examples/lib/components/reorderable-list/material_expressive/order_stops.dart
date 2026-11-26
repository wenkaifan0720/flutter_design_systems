import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
    child: SingleChildScrollView(
      child: ExpressiveReorderableListView(
        itemCount: stops.length,
        onReorder: move,
        itemBuilder: (context, i) => ExpressiveListTile(
          key: ValueKey(stops[i]),
          title: Text(stops[i]),
          subtitle: const Text('Make first'),
          onTap: () => move(i, 0),
          trailing: ExpressiveReorderHandle(index: i),
        ),
      ),
    ),
  );
}
