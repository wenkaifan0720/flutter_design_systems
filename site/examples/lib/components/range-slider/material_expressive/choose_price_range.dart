import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ChoosePriceRange extends StatefulWidget {
  const ChoosePriceRange({super.key});
  @override
  State<ChoosePriceRange> createState() => _ChoosePriceRangeState();
}

class _ChoosePriceRangeState extends State<ChoosePriceRange> {
  double low = 20;
  double high = 60;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressiveRangeSlider(
          start: low,
          end: high,
          max: 100,
          steps: 19,
          startSemanticLabel: 'Minimum price',
          endSemanticLabel: 'Maximum price',
          onChanged: (start, end) => setState(() {
            low = start;
            high = end;
          }),
          valueLabel: (price) => '\$${price.round()}',
        ),
        const SizedBox(height: 12),
        Text('From \$${low.round()} to \$${high.round()}'),
      ],
    ),
  );
}
