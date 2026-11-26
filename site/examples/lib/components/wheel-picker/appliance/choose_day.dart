import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
          ApplianceKnob<int>(
            semanticLabel: 'Day in November',
            options: const [
              ApplianceKnobOption(value: 10, label: '10'),
              ApplianceKnobOption(value: 11, label: '11'),
              ApplianceKnobOption(value: 12, label: '12'),
              ApplianceKnobOption(value: 13, label: '13'),
              ApplianceKnobOption(value: 14, label: '14'),
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
