import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class FindCity extends StatefulWidget {
  const FindCity({super.key});

  @override
  State<FindCity> createState() => _FindCityState();
}

class _FindCityState extends State<FindCity> {
  String? city;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StudioCombobox<String>(
          labelText: 'Destination',
          options: const ['Lima', 'Lisbon', 'Oslo'],
          value: city,
          labelOf: (name) => name,
          onSelected: (option) => setState(() => city = option),
        ),
        const SizedBox(height: 12),
        Text(city == null ? 'No destination chosen' : 'Destination: $city'),
      ],
    ),
  );
}
