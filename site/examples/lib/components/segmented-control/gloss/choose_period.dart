import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
        GlossSegmentedButton<String>(
          segments: const [
            GlossSegment(value: 'Week', label: 'Week'),
            GlossSegment(value: 'Month', label: 'Month'),
          ],
          semanticLabel: 'Reporting period',
          selected: period,
          onChanged: (next) => setState(() => period = next),
        ),
        const SizedBox(height: 12),
        Text('Report period: $period'),
      ],
    ),
  );
}
