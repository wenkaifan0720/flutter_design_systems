import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class RateGuide extends StatefulWidget {
  const RateGuide({super.key});
  @override
  State<RateGuide> createState() => _RateGuideState();
}

class _RateGuideState extends State<RateGuide> {
  double score = 3;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FrostedRating(
        label: 'Rate the guide',
        value: score,
        onChanged: (next) => setState(() => score = next),
      ),
      const SizedBox(height: 12),
      Text('${score.round()} of 5'),
    ],
  );
}
