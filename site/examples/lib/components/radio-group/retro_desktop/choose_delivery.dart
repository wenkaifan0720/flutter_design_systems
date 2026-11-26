import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

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
        RetroDesktopRadioGroup<String>(
          labelText: 'Delivery method',
          value: delivery,
          options: const [
            RetroDesktopRadio('Pickup', 'Pickup'),
            RetroDesktopRadio('Courier', 'Courier'),
          ],
          onChanged: (value) => setState(() => delivery = value),
        ),
        const SizedBox(height: 12),
        Text('Delivery: $delivery'),
      ],
    ),
  );
}
