import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => ApplianceToaster(
    child: Center(
      child: Builder(
        builder: (context) => ApplianceButton(
          'Save draft',
          onPressed: () =>
              showApplianceToast(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
