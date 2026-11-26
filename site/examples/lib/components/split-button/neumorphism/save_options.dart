import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class SaveOptions extends StatefulWidget {
  const SaveOptions({super.key});

  @override
  State<SaveOptions> createState() => _SaveOptionsState();
}

class _SaveOptionsState extends State<SaveOptions> {
  String result = 'Unsaved draft';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NeumorphicSplitButton(
        'Save',
        onPressed: () => setState(() => result = 'Draft saved'),
        menuLabel: 'Save options',
        actions: [
          NeumorphicSplitAction(
            'Save a copy',
            onPressed: () => setState(() => result = 'Copy saved'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(result),
    ],
  );
}
