import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

class UpdateBoard extends StatefulWidget {
  const UpdateBoard({super.key});
  @override
  State<UpdateBoard> createState() => _UpdateBoardState();
}

class _UpdateBoardState extends State<UpdateBoard> {
  int issue = 1;
  bool loading = false;
  Future<void> refresh() async {
    if (loading) return;
    setState(() => loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      issue++;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: KeycapRefresh(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [KeycapListTile(title: 'Issue $issue')],
            ),
          ),
        ),
        const SizedBox(height: 12),
        KeycapButton(
          onPressed: loading ? null : refresh,
          child: Text(loading ? 'Updating' : 'Refresh'),
        ),
      ],
    ),
  );
}
