import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
          const Fluent2Skeleton(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Fluent2SkeletonItem(width: 176),
                Fluent2SkeletonItem(width: 120),
              ],
            ),
          ),
        ] else ...[
          const Text('Planning notes'),
          const Text('Owner: Mara Chen'),
        ],
        Fluent2Button(
          loading ? 'Show details' : 'Reload',
          onPressed: () => setState(() => loading = !loading),
        ),
      ],
    ),
  );
}
