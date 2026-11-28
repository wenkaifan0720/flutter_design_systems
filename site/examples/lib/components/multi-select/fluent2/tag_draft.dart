import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
        Fluent2MultiSelect<String>(
          semanticLabel: 'Labels',
          options: const [
            Fluent2Option('Work', 'Work'),
            Fluent2Option('Home', 'Home'),
            Fluent2Option('Travel', 'Travel'),
          ],
          selected: labels,
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
