import 'package:cupertino_ui/cupertino_ui.dart';

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
      CupertinoSlidingSegmentedControl<String>(
        groupValue: period,
        onValueChanged: (next) {
          if (next != null) setState(() => period = next);
        },
        children: const {
          'Week': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Week'),
          ),
          'Month': Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Month'),
          ),
        },
      ),
      const SizedBox(height: 12),
      Text('Report period: $period'),
    ],
  );
}
