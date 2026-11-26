import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class CompareQuarters extends StatefulWidget {
  const CompareQuarters({super.key});
  @override
  State<CompareQuarters> createState() => _CompareQuartersState();
}

class _CompareQuartersState extends State<CompareQuarters> {
  bool alternate = false;

  String get period => alternate ? 'Q2' : 'Q1';

  List<double> get orders =>
      alternate ? const [18, 10, 24] : const [12, 20, 16];

  List<String> get months =>
      alternate ? const ['Apr', 'May', 'Jun'] : const ['Jan', 'Feb', 'Mar'];

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$period · monthly orders'),
          const SizedBox(height: 12),
          BrutalBarChart(
            labels: months,
            series: [BrutalSeries('Orders', orders)],
            semanticLabel: '$period monthly orders',
          ),
          const SizedBox(height: 12),
          BrutalButton(
            alternate ? 'Show Q1' : 'Show Q2',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}
