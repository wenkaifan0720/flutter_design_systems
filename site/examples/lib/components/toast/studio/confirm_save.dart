import 'package:flutter/widgets.dart';
import 'package:studio_ui/studio_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => StudioToaster(
    child: Center(
      child: Builder(
        builder: (context) => StudioButton(
          'Save draft',
          onPressed: () =>
              showStudioToast(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
