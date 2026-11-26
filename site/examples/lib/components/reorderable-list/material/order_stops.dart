import 'package:material_ui/material_ui.dart';

class OrderStops extends StatefulWidget {
  const OrderStops({super.key});
  @override
  State<OrderStops> createState() => _OrderStopsState();
}

class _OrderStopsState extends State<OrderStops> {
  final stops = ['Park', 'Market', 'Pier'];

  void move(int from, int to) {
    setState(() => stops.insert(to, stops.removeAt(from)));
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SizedBox(
      height: 200,
      child: ReorderableListView(
        onReorderItem: move,
        children: [
          for (final (index, stop) in stops.indexed)
            ListTile(
              key: ValueKey(stop),
              title: Text(stop),
              subtitle: const Text('Make first'),
              onTap: () => move(index, 0),
            ),
        ],
      ),
    ),
  );
}
