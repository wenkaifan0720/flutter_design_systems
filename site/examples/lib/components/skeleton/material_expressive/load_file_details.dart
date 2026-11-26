import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class LoadFileDetails extends StatefulWidget {
  const LoadFileDetails({super.key});
  @override
  State<LoadFileDetails> createState() => _LoadFileDetailsState();
}

class _LoadFileDetailsState extends State<LoadFileDetails> {
  bool loading = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 280),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        if (loading) ...[
          const Text('Loading file details'),
          const ExpressiveSkeleton.text(lines: 2),
        ] else ...[
          const Text('Planning notes'),
          const Text('Owner: Mara Chen'),
        ],
        ExpressiveFilledButton(
          loading ? 'Show details' : 'Reload',
          onPressed: () => setState(() => loading = !loading),
        ),
      ],
    ),
  );
}
