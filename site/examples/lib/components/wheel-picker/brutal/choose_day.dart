import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class ChooseDay extends StatefulWidget {
  const ChooseDay({super.key});
  @override
  State<ChooseDay> createState() => _ChooseDayState();
}

class _ChooseDayState extends State<ChooseDay> {
  int day = 12;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrutalWheelPicker<int>(
            semanticLabel: 'Day in November',
            items: const [10, 11, 12, 13, 14],
            value: day,
            onChanged: (next) => setState(() => day = next),
            labelOf: (day) => '$day',
          ),
          const SizedBox(height: 12),
          Text('November $day'),
        ],
      ),
    ),
  );
}
