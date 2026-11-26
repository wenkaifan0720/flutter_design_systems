import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
        FrostedMeter(
          people / 8,
          hue: context.frostedTheme.hue(0),
          label: 'Room capacity',
        ),
        const SizedBox(height: 12),
        Text('$people of 8 places'),
        const SizedBox(height: 12),
        FrostedButton(
          people == 8 ? 'Reset room' : 'Add two people',
          onPressed: () =>
              setState(() => people = people == 8 ? 2 : people + 2),
        ),
      ],
    ),
  );
}
