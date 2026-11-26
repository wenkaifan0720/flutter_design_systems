import 'package:material_ui/material_ui.dart';

class DraftSections extends StatelessWidget {
  const DraftSections({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Activity'),
            ],
          ),
          SizedBox(
            height: 64,
            child: TabBarView(
              children: [
                Center(child: Text('Private draft')),
                Center(child: Text('Created today')),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
