import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        KeycapTag(
          published ? 'Published' : 'Draft',
          tone: published ? KeycapTone.success : null,
        ),
        const SizedBox(height: 12),
        KeycapButton(
          onPressed: () => setState(() => published = !published),
          child: Text(published ? 'Return to draft' : 'Publish'),
        ),
      ],
    ),
  );
}
