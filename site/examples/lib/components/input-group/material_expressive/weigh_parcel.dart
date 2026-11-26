import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class WeighParcel extends StatefulWidget {
  const WeighParcel({super.key});

  @override
  State<WeighParcel> createState() => _WeighParcelState();
}

class _WeighParcelState extends State<WeighParcel> {
  String weight = '';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressiveInputGroup(
          semanticLabel: 'Parcel weight in kilograms',
          trailing: [ExpressiveInputGroup.text('kg')],
          hintText: 'Weight',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) => setState(() => weight = value.trim()),
        ),
        const SizedBox(height: 12),
        Text(weight.isEmpty ? 'Parcel not weighed' : 'Entered: $weight kg'),
      ],
    ),
  );
}
