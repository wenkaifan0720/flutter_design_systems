import 'package:material_ui/material_ui.dart';

class ChooseDelivery extends StatefulWidget {
  const ChooseDelivery({super.key});
  @override
  State<ChooseDelivery> createState() => _ChooseDeliveryState();
}

class _ChooseDeliveryState extends State<ChooseDelivery> {
  static const methods = ['Pickup', 'Courier'];
  String delivery = 'Pickup';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioGroup<String>(
          groupValue: delivery,
          onChanged: (value) {
            if (value != null) setState(() => delivery = value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final method in methods)
                RadioListTile<String>(value: method, title: Text(method)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text('Delivery: $delivery'),
      ],
    ),
  );
}
