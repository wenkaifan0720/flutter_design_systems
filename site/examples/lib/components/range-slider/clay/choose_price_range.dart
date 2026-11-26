import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class ChoosePriceRange extends StatefulWidget {
  const ChoosePriceRange({super.key});
  @override
  State<ChoosePriceRange> createState() => _ChoosePriceRangeState();
}

class _ChoosePriceRangeState extends State<ChoosePriceRange> {
  var prices = const ClayRangeValues(20, 60);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClayRangeSlider(
          values: prices,
          max: 100,
          divisions: 20,
          startLabel: 'Minimum price',
          endLabel: 'Maximum price',
          onChanged: (next) => setState(() => prices = next),
          semanticFormatterCallback: (price) => '\$${price.round()}',
        ),
        const SizedBox(height: 12),
        Text('From \$${prices.start.round()} to \$${prices.end.round()}'),
      ],
    ),
  );
}
