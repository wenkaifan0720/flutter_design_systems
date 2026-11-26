import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
          StudioBarChart(
            labels: months,
            series: [StudioSeries('Orders', orders)],
            semanticLabel: '$period monthly orders',
          ),
          const SizedBox(height: 12),
          StudioButton(
            alternate ? 'Show Q1' : 'Show Q2',
            onPressed: () => setState(() => alternate = !alternate),
          ),
        ],
      ),
    ),
  );
}
