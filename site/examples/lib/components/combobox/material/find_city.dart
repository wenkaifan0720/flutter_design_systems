import 'package:material_ui/material_ui.dart';

class FindCity extends StatefulWidget {
  const FindCity({super.key});
  @override
  State<FindCity> createState() => _FindCityState();
}

class _FindCityState extends State<FindCity> {
  static const cities = ['Lima', 'Lisbon', 'Oslo'];
  String? city;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Autocomplete<String>(
          optionsBuilder: (value) => value.text.isEmpty
              ? const Iterable<String>.empty()
              : cities.where(
                  (option) =>
                      option.toLowerCase().startsWith(value.text.toLowerCase()),
                ),
          onSelected: (option) => setState(() => city = option),
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
              TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onSubmitted(),
              ),
        ),
        const SizedBox(height: 12),
        Text(city == null ? 'No destination chosen' : 'Destination: $city'),
      ],
    ),
  );
}
