import 'package:material_ui/material_ui.dart';

class ChoosePeriod extends StatefulWidget {
  const ChoosePeriod({super.key});
  @override
  State<ChoosePeriod> createState() => _ChoosePeriodState();
}

class _ChoosePeriodState extends State<ChoosePeriod> {
  String period = 'Week';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Week', label: Text('Week')),
          ButtonSegment(value: 'Month', label: Text('Month')),
        ],
        selected: {period},
        onSelectionChanged: (next) => setState(() => period = next.single),
      ),
      const SizedBox(height: 12),
      Text('Report period: $period'),
    ],
  );
}
