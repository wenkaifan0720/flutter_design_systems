import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
      NeumorphicButton.filled(
        saved ? 'Draft saved' : 'Save draft',
        onPressed: saved ? null : () => setState(() => saved = true),
      ),
      NeumorphicButton(
        'Reset',
        onPressed: saved ? () => setState(() => saved = false) : null,
      ),
    ],
  );
}
