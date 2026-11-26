import 'package:cupertino_ui/cupertino_ui.dart';

class ReadDeliveryNote extends StatelessWidget {
  const ReadDeliveryNote({super.key});

  @override
  Widget build(BuildContext context) => CupertinoButton(
    onPressed: () => showCupertinoSheet<void>(
      context: context,
      scrollableBuilder: (context, controller) => CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          automaticallyImplyLeading: false,
          middle: const Text('Delivery note'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: const [Text('Leave the parcel at the side door.')],
        ),
      ),
    ),
    child: const Text('Delivery note'),
  );
}
