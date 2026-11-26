import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
        ComicCombobox<String>(
          labelText: 'Destination',
          options: const ['Lima', 'Lisbon', 'Oslo'],
          onSelected: (option) => setState(() => city = option),
        ),
        const SizedBox(height: 12),
        Text(city == null ? 'No destination chosen' : 'Destination: $city'),
      ],
    ),
  );
}
