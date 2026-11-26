import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        KeycapSegmentedButton<String>(
          segments: const [
            KeycapSegment(value: 'Week', label: 'Week'),
            KeycapSegment(value: 'Month', label: 'Month'),
          ],
          semanticLabel: 'Reporting period',
          selected: {period},
          onSelectionChanged: (next) => setState(() => period = next.first),
        ),
        const SizedBox(height: 12),
        Text('Report period: $period'),
      ],
    ),
  );
}
