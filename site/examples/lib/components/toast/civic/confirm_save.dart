import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => CivicToaster(
    child: Center(
      child: Builder(
        builder: (context) => CivicButton(
          child: Text('Save draft'),
          onPressed: () =>
              CivicToast.show(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
