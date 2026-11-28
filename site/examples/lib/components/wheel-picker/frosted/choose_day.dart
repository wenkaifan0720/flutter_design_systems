import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
          FrostedWheelPicker<int>(
            semanticLabel: 'Day in November',
            options: const [
              FrostedSelectOption(10, '10'),
              FrostedSelectOption(11, '11'),
              FrostedSelectOption(12, '12'),
              FrostedSelectOption(13, '13'),
              FrostedSelectOption(14, '14'),
            ],
            value: day,
            onChanged: (next) => setState(() => day = next),
          ),
          const SizedBox(height: 12),
          Text('November $day'),
        ],
      ),
    ),
  );
}
