import 'package:cupertino_ui/cupertino_ui.dart';

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
        CupertinoTextField(
          placeholder: 'Parcel weight',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          suffix: const Padding(
            padding: EdgeInsetsDirectional.only(end: 8),
            child: Text('kg'),
          ),
          onChanged: (value) => setState(() => weight = value.trim()),
        ),
        const SizedBox(height: 12),
        Text(weight.isEmpty ? 'Parcel not weighed' : 'Entered: $weight kg'),
      ],
    ),
  );
}
