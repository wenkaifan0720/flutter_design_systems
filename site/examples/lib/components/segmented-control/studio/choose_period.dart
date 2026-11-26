import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class ChoosePeriod extends StatefulWidget {
  const ChoosePeriod({super.key});
  @override
  State<ChoosePeriod> createState() => _ChoosePeriodState();
}

class _ChoosePeriodState extends State<ChoosePeriod> {
  String period = 'Week';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioSegmentedButton<String>(
          segments: const [
            StudioSegment(value: 'Week', label: 'Week'),
            StudioSegment(value: 'Month', label: 'Month'),
          ],
          semanticLabel: 'Reporting period',
          value: period,
          onChanged: (next) => setState(() => period = next),
        ),
        const SizedBox(height: 12),
        Text('Report period: $period'),
      ],
    ),
  );
}
