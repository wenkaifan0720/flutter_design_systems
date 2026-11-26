import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class ChooseDay extends StatefulWidget {
  const ChooseDay({super.key});
  @override
  State<ChooseDay> createState() => _ChooseDayState();
}

class _ChooseDayState extends State<ChooseDay> {
  static const days = [10, 11, 12, 13, 14];
  int day = 12;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KeycapWheelPicker(
            semanticLabel: 'Day in November',
            columns: (_) => [
              RawPickerColumn(
                itemCount: days.length,
                itemLabel: (i) => '${days[i]}',
                semanticLabel: 'Day',
              ),
            ],
            selection: [days.indexOf(day)],
            onChanged: (next) => setState(() => day = days[next.first]),
          ),
          const SizedBox(height: 12),
          Text('November $day'),
        ],
      ),
    ),
  );
}
