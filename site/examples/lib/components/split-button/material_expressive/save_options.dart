import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
      ExpressiveSplitButton(
        'Save',
        onPressed: () => setState(() => result = 'Draft saved'),
        menuLabel: 'Save options',
        menu: (context, close) => ExpressiveMenuSurface(
          groups: [
            ExpressiveMenuGroup([
              ExpressiveMenuItem(
                'Save a copy',
                onPressed: () {
                  close();
                  setState(() => result = 'Copy saved');
                },
              ),
            ]),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(result),
    ],
  );
}
