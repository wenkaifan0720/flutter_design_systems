import 'package:material_ui/material_ui.dart';

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
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Parcel weight',
            suffixText: 'kg',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => weight = value.trim()),
        ),
        const SizedBox(height: 12),
        Text(weight.isEmpty ? 'Parcel not weighed' : 'Entered: $weight kg'),
      ],
    ),
  );
}
