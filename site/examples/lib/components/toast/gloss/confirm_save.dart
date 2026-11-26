import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => GlossToaster(
    child: Center(
      child: Builder(
        builder: (context) => GlossButton(
          'Save draft',
          onPressed: () =>
              showGlossToast(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
