import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
        ApplianceTag(
          published ? 'Published' : 'Draft',
          tone: published ? ApplianceTagTone.ready : ApplianceTagTone.neutral,
        ),
        const SizedBox(height: 12),
        ApplianceButton(
          published ? 'Return to draft' : 'Publish',
          onPressed: () => setState(() => published = !published),
        ),
      ],
    ),
  );
}
