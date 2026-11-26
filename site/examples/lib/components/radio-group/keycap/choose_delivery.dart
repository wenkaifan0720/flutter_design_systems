import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The group already announces its name.
        const ExcludeSemantics(child: KeycapFieldLabel('Delivery method')),
        KeycapRadioGroup<String>(
          semanticLabel: 'Delivery method',
          options: const ['Pickup', 'Courier'],
          groupValue: delivery,
          labelOf: (name) => name,
          onChanged: (value) => setState(() => delivery = value),
        ),
        const SizedBox(height: 12),
        Text('Delivery: $delivery'),
      ],
    ),
  );
}
