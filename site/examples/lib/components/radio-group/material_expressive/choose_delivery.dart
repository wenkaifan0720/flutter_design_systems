import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ChooseDelivery extends StatefulWidget {
  const ChooseDelivery({super.key});

  @override
  State<ChooseDelivery> createState() => _ChooseDeliveryState();
}

class _ChooseDeliveryState extends State<ChooseDelivery> {
  String delivery = 'Pickup';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressiveRadioGroup<String>(
          semanticLabel: 'Delivery method',
          value: delivery,
          options: const [
            ExpressiveRadioOption(value: 'Pickup', label: 'Pickup'),
            ExpressiveRadioOption(value: 'Courier', label: 'Courier'),
          ],
          onChanged: (value) => setState(() => delivery = value),
        ),
        const SizedBox(height: 12),
        Text('Delivery: $delivery'),
      ],
    ),
  );
}
