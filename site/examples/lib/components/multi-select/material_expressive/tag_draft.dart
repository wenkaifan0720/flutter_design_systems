import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class TagDraft extends StatefulWidget {
  const TagDraft({super.key});

  @override
  State<TagDraft> createState() => _TagDraftState();
}

class _TagDraftState extends State<TagDraft> {
  List<String> labels = ['Work'];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpressiveMultiSelect<String>(
          labelText: 'Labels',
          options: const [
            ExpressiveSelectOption('Work', 'Work'),
            ExpressiveSelectOption('Home', 'Home'),
            ExpressiveSelectOption('Travel', 'Travel'),
          ],
          values: labels,
          onChanged: (next) => setState(() => labels = next),
        ),
        const SizedBox(height: 12),
        Text(
          labels.isEmpty ? 'No labels' : 'Draft labels: ${labels.join(', ')}',
        ),
      ],
    ),
  );
}
