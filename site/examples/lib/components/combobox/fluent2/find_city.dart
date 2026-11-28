import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
        Fluent2Combobox<String>(
          semanticLabel: 'Destination',
          options: const [
            Fluent2Option('Lima', 'Lima'),
            Fluent2Option('Lisbon', 'Lisbon'),
            Fluent2Option('Oslo', 'Oslo'),
          ],
          value: city,
          onChanged: (option) => setState(() => city = option),
        ),
        const SizedBox(height: 12),
        Text(city == null ? 'No destination chosen' : 'Destination: $city'),
      ],
    ),
  );
}
