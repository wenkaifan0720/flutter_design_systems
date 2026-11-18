/// Larder's Search: a sunken search field under the bar, the shelf's goods
/// that match below it, and, when nothing does, a dark display reading
/// nothing with words to try instead.
library;

import 'package:material_ui/material_ui.dart';
import 'package:appliance_ui/appliance_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'larder.dart';
import 'shop.dart';
import 'words.dart';

/// Words a shopper might try.
const _tries = ['kettle', 'tea', 'bowls', 'jars', 'lamp'];

/// The goods whose name, note, shelf or finishes hold every word of [query].
List<LarderProduct> larderSearch(String query) {
  final words = query.toLowerCase().split(RegExp(r'\s+'))
    ..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return const [];
  return [
    for (final p in larderProducts)
      if (words.every(
        [
          p.name,
          p.blurb,
          p.category.label,
          ...p.finishes,
        ].join(' ').toLowerCase().contains,
      ))
        p,
  ];
}

/// The search page, opening on [initialQuery].
class LarderSearchPage extends StatefulWidget {
  /// Search; [initialQuery] already typed.
  const LarderSearchPage({super.key, this.initialQuery = ''});

  /// What stands in the field at first.
  final String initialQuery;

  @override
  State<LarderSearchPage> createState() => _LarderSearchPageState();
}

class _LarderSearchPageState extends State<LarderSearchPage> {
  late final _query = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _try(String word) => setState(() {
    _query.value = TextEditingValue(
      text: word,
      selection: TextSelection.collapsed(offset: word.length),
    );
  });

  @override
  Widget build(BuildContext context) {
    final t = context.applianceTheme.textTheme;
    final frame = LarderFrame.of(context);
    final query = _query.text.trim();
    final hits = larderSearch(query);
    Widget tries(String header) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ApplianceSectionHeader(header),
        Wrap(
          spacing: ApplianceSpacing.small,
          runSpacing: ApplianceSpacing.small,
          children: [
            for (final word in _tries)
              ApplianceChip(word, onSelected: (_) => _try(word)),
          ],
        ),
      ],
    );
    return LarderPage(
      title: 'Search',
      maxWidth: larderDeskWidth,
      barBottom: ApplianceSearchField(
        controller: _query,
        hint: 'Pots, kettles, jars',
        autofocus: widget.initialQuery.isEmpty,
        onChanged: (_) => setState(() {}),
      ),
      children: [
        if (query.isEmpty) ...[
          tries('Try'),
          larderGroupGap,
          ApplianceListGroup(
            header: 'Shelves',
            children: [
              for (final c in LarderCategory.values)
                ApplianceListTile(
                  leading: Icon(c.icon),
                  title: c.label,
                  onTap: () => _try(c.label.split(' ').first.toLowerCase()),
                ),
            ],
          ),
        ] else if (hits.isEmpty) ...[
          ApplianceEmptyState(
            title: 'Nothing called “$query”',
            message:
                'Check the spelling, or try a shorter word: a kettle, a '
                'jar, a bowl.',
            reading: '0',
            action: ApplianceButton(
              'Browse the shop',
              icon: const Icon(LucideIcons.layoutGrid),
              onPressed: () {
                Navigator.of(context).maybePop();
                frame.go(LarderPlace.shop);
              },
            ),
          ),
          larderGroupGap,
          tries('Try instead'),
        ] else ...[
          Semantics(
            liveRegion: true,
            child: Text(
              LarderWords.of(context).searchFound(hits.length, query),
              style: t.secondary,
            ),
          ),
          const SizedBox(height: ApplianceSpacing.regular),
          LarderProductGrid(products: hits),
        ],
      ],
    );
  }
}
