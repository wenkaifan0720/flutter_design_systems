import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
        GlossMeter(label: 'Room capacity', value: people.toDouble(), max: 8),
        const SizedBox(height: 12),
        Text('Using $people of 8 places'),
        const SizedBox(height: 12),
        GlossButton(
          people == 8 ? 'Reset room' : 'Add two people',
          onPressed: () =>
              setState(() => people = people == 8 ? 2 : people + 2),
        ),
      ],
    ),
  );
}
