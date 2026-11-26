import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

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
              const StudioSkeleton(width: 176, height: 16),
              const StudioSkeleton(width: 120, height: 12),
            ],
          ),
        ] else ...[
          const Text('Planning notes'),
          const Text('Owner: Mara Chen'),
        ],
        StudioButton(
          loading ? 'Show details' : 'Reload',
          onPressed: () => setState(() => loading = !loading),
        ),
      ],
    ),
  );
}
