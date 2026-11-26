import 'package:material_ui/material_ui.dart';

class FindTitle extends StatefulWidget {
  const FindTitle({super.key});
  @override
  State<FindTitle> createState() => _FindTitleState();
}

class _FindTitleState extends State<FindTitle> {
  static const titles = ['Field notes', 'Field guide', 'Travel diary'];
  final controller = TextEditingController();
  String query = '';

  Iterable<String> get matches =>
      titles.where((title) => title.toLowerCase().contains(query));

  void filter(String value) =>
      setState(() => query = value.trim().toLowerCase());

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchBar(
          controller: controller,
          hintText: 'Search titles',
          leading: const Icon(Icons.search),
          trailing: [
            if (query.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  filter('');
                },
              ),
          ],
          onChanged: filter,
        ),
        const SizedBox(height: 12),
        Text(
          matches.isEmpty ? 'No matching titles' : matches.join('\n'),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
