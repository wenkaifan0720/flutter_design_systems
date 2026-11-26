import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
        ExpressiveCombobox<String>(
          labelText: 'Destination',
          options: const [
            ExpressiveSelectOption('Lima', 'Lima'),
            ExpressiveSelectOption('Lisbon', 'Lisbon'),
            ExpressiveSelectOption('Oslo', 'Oslo'),
          ],
          onSelected: (option) => setState(() => city = option.value),
        ),
        const SizedBox(height: 12),
        Text(city == null ? 'No destination chosen' : 'Destination: $city'),
      ],
    ),
  );
}
