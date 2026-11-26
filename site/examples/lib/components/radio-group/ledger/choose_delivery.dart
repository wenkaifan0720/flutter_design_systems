import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

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
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Delivery method'),
            const SizedBox(height: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final name in const ['Pickup', 'Courier'])
                  LedgerRadio<String>(
                    value: name,
                    groupValue: delivery,
                    label: name,
                    onChanged: (value) => setState(() => delivery = value),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Delivery: $delivery'),
      ],
    ),
  );
}
