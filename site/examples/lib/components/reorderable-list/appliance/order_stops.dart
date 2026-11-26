import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: ApplianceReorderableList<String>(
            items: stops,
            labelOf: (stop) => stop,
            title: (stop) => stop,
            onReorder: move,
          ),
        ),
        const SizedBox(height: 12),
        ApplianceButton('Move first down', onPressed: () => move(0, 1)),
      ],
    ),
  );
}
