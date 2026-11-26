import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class SaveDraft extends StatefulWidget {
  const SaveDraft({super.key});
  @override
  State<SaveDraft> createState() => _SaveDraftState();
}

class _SaveDraftState extends State<SaveDraft> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      ExpressiveFilledButton(
        saved ? 'Draft saved' : 'Save draft',
        onPressed: saved ? null : () => setState(() => saved = true),
      ),
      ExpressiveOutlinedButton(
        'Reset',
        onPressed: saved ? () => setState(() => saved = false) : null,
      ),
    ],
  );
}
