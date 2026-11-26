import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const GlossSkeleton(width: 176, height: 16),
              const GlossSkeleton(width: 120, height: 12),
            ],
          ),
        ] else ...[
          const Text('Planning notes'),
          const Text('Owner: Mara Chen'),
        ],
        GlossButton(
          loading ? 'Show details' : 'Reload',
          onPressed: () => setState(() => loading = !loading),
        ),
      ],
    ),
  );
}
