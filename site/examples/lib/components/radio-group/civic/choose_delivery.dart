import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class ChooseDelivery extends StatefulWidget {
  const ChooseDelivery({super.key});

  @override
  State<ChooseDelivery> createState() => _ChooseDeliveryState();
}

class _ChooseDeliveryState extends State<ChooseDelivery> {
  String? delivery = 'Pickup';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CivicRadioGroup<String>(
          labelText: 'Delivery method',
          groupValue: delivery,
          children: const [
            CivicRadio(value: 'Pickup', labelText: 'Pickup'),
            CivicRadio(value: 'Courier', labelText: 'Courier'),
          ],
          onChanged: (value) => setState(() => delivery = value),
        ),
        const SizedBox(height: 12),
        Text('Delivery: $delivery'),
      ],
    ),
  );
}
