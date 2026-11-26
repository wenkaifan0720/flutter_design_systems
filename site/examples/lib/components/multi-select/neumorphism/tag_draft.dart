import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
        NeumorphicMultiSelect<String>(
          labelText: 'Labels',
          options: const ['Work', 'Home', 'Travel'],
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
