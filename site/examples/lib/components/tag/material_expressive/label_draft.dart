import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class LabelDraft extends StatefulWidget {
  const LabelDraft({super.key});
  @override
  State<LabelDraft> createState() => _LabelDraftState();
}

class _LabelDraftState extends State<LabelDraft> {
  bool published = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpressiveTag(
          published ? 'Published' : 'Draft',
          tone: published ? ExpressiveTone.success : ExpressiveTone.neutral,
        ),
        const SizedBox(height: 12),
        ExpressiveOutlinedButton(
          published ? 'Return to draft' : 'Publish',
          onPressed: () => setState(() => published = !published),
        ),
      ],
    ),
  );
}
