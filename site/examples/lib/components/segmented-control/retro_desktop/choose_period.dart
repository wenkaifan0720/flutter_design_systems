import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

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
        RetroDesktopSegmentedButton<String>(
          segments: const [
            RetroDesktopButtonSegment('Week', 'Week'),
            RetroDesktopButtonSegment('Month', 'Month'),
          ],
          label: 'Reporting period',
          value: period,
          onChanged: (next) => setState(() => period = next),
        ),
        const SizedBox(height: 12),
        Text('Report period: $period'),
      ],
    ),
  );
}
