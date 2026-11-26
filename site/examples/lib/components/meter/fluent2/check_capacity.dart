import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class CheckCapacity extends StatefulWidget {
  const CheckCapacity({super.key});
  @override
  State<CheckCapacity> createState() => _CheckCapacityState();
}

class _CheckCapacityState extends State<CheckCapacity> {
  int people = 2;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Fluent2Spinner(label: 'Room capacity', value: people / 8, below: false),
        const SizedBox(height: 12),
        Text('Using $people of 8 places'),
        const SizedBox(height: 12),
        Fluent2Button(
          people == 8 ? 'Reset room' : 'Add two people',
          onPressed: () =>
              setState(() => people = people == 8 ? 2 : people + 2),
        ),
      ],
    ),
  );
}
