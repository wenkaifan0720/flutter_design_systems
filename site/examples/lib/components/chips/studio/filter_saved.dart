import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
      StudioChip(
        label: 'Saved',
        selected: savedOnly,
        onSelected: (next) => setState(() => savedOnly = next),
      ),
      const SizedBox(height: 12),
      Text(savedOnly ? 'Field notes' : 'Field notes · Reading list'),
    ],
  );
}
