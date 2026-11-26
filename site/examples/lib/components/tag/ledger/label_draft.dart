import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

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
        LedgerTag(published ? 'Published' : 'Draft'),
        const SizedBox(height: 12),
        LedgerButton(
          published ? 'Return to draft' : 'Publish',
          onPressed: () => setState(() => published = !published),
        ),
      ],
    ),
  );
}
