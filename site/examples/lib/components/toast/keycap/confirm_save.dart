import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => KeycapToaster(
    child: Center(
      child: Builder(
        builder: (context) => KeycapButton(
          onPressed: () =>
              showKeycapToast(context, 'Revision ${++revision} saved'),
          child: const Text('Save draft'),
        ),
      ),
    ),
  );
}
