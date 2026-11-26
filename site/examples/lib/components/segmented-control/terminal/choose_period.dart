import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ChoosePeriod extends StatefulWidget {
  const ChoosePeriod({super.key});
  @override
  State<ChoosePeriod> createState() => _ChoosePeriodState();
}

class _ChoosePeriodState extends State<ChoosePeriod> {
  Set<String> period = {'Week'};

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TermToggleGroup<String>(
          options: const ['Week', 'Month'],
          selected: period,
          semanticLabel: 'Reporting period',
          labelOf: (value) => value,
          selectFollowsFocus: true,
          onSelectionChanged: (next) => setState(() => period = next),
        ),
        const SizedBox(height: 12),
        Text('Report period: ${period.single}'),
      ],
    ),
  );
}
