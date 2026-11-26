import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class BrowseDays extends StatefulWidget {
  const BrowseDays({super.key});
  @override
  State<BrowseDays> createState() => _BrowseDaysState();
}

class _BrowseDaysState extends State<BrowseDays> {
  bool tomorrow = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeycapSectionHeader(tomorrow ? 'Tomorrow' : 'Today'),
          const SizedBox(height: 12),
          Text(tomorrow ? '10 am · Walk' : '2 pm · Workshop'),
          const SizedBox(height: 12),
          KeycapButton(
            onPressed: () => setState(() => tomorrow = !tomorrow),
            child: Text(tomorrow ? 'Show today' : 'Show tomorrow'),
          ),
        ],
      ),
    ),
  );
}
