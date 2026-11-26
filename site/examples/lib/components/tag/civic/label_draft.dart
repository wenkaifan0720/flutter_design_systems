import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
        CivicTag(
          label: published ? 'Published' : 'Draft',
          tone: published ? CivicTone.success : CivicTone.neutral,
        ),
        const SizedBox(height: 12),
        CivicButton(
          onPressed: () => setState(() => published = !published),
          child: Text(published ? 'Return to draft' : 'Publish'),
        ),
      ],
    ),
  );
}
