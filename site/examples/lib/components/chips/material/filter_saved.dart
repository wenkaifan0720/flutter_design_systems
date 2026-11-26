import 'package:material_ui/material_ui.dart';

class FilterSaved extends StatefulWidget {
  const FilterSaved({super.key});
  @override
  State<FilterSaved> createState() => _FilterSavedState();
}

class _FilterSavedState extends State<FilterSaved> {
  bool savedOnly = false;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FilterChip(
        label: const Text('Saved'),
        selected: savedOnly,
        onSelected: (next) => setState(() => savedOnly = next),
      ),
      const SizedBox(height: 12),
      Text(savedOnly ? 'Field notes' : 'Field notes · Reading list'),
    ],
  );
}
