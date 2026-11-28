import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ReadDailyTrend extends StatefulWidget {
  const ReadDailyTrend({super.key});
  @override
  State<ReadDailyTrend> createState() => _ReadDailyTrendState();
}

class _ReadDailyTrendState extends State<ReadDailyTrend> {
  bool alternate = false;

  String get period => alternate ? 'Week 2' : 'Week 1';

  List<double> get requests =>
      alternate ? const [9, 8, 6, 7, 4] : const [3, 5, 4, 6, 8];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$period · ${requests.first.toInt()} requests on Monday, ${requests.last.toInt()} on Friday',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 106,
            child: NeumorphicSparkline(
              values: requests,
              semanticLabel: '$period daily requests',
            ),
          ),
          const SizedBox(height: 12),
          NeumorphicButton(
            alternate ? 'Show Week 1' : 'Show Week 2',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}
