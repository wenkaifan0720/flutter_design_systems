import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      Fluent2Button(
        saved ? 'Draft saved' : 'Save draft',
        appearance: Fluent2ButtonAppearance.primary,
        onPressed: saved ? null : () => setState(() => saved = true),
      ),
      Fluent2Button(
        'Reset',
        onPressed: saved ? () => setState(() => saved = false) : null,
      ),
    ],
  );
}
