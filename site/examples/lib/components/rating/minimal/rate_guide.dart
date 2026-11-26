import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

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
      MinimalRating(
        label: 'Rate the guide',
        value: score.toDouble(),
        onChanged: (next) => setState(() => score = next),
      ),
      const SizedBox(height: 12),
      Text('Rated $score out of 5'),
    ],
  );
}
