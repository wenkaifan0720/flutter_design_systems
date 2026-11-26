import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

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
      FrostedChip(
        'Saved',
        selected: savedOnly,
        onPressed: () => setState(() => savedOnly = !savedOnly),
      ),
      const SizedBox(height: 12),
      Text(savedOnly ? 'Field notes' : 'Field notes · Reading list'),
    ],
  );
}
