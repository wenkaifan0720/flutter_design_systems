import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class RateGuide extends StatefulWidget {
  const RateGuide({super.key});
  @override
  State<RateGuide> createState() => _RateGuideState();
}

class _RateGuideState extends State<RateGuide> {
  int score = 3;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TermRating(
        semanticLabel: 'Rate the guide',
        value: score,
        onChanged: (next) => setState(() => score = next),
      ),
      const SizedBox(height: 12),
      Text('$score of 5'),
    ],
  );
}
