import 'package:cupertino_ui/cupertino_ui.dart';

class ChooseChannel extends StatefulWidget {
  const ChooseChannel({super.key});
  @override
  State<ChooseChannel> createState() => _ChooseChannelState();
}

class _ChooseChannelState extends State<ChooseChannel> {
  String channel = 'Email';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoListSection.insetGrouped(
            header: const Text('Delivery'),
            children: [
              for (final option in ['Email', 'Post'])
                CupertinoListTile(
                  title: Text(option),
                  trailing: channel == option
                      ? const Icon(CupertinoIcons.check_mark)
                      : null,
                  onTap: () => setState(() => channel = option),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Deliver by $channel'),
        ],
      ),
    ),
  );
}
