/// The choice tiles' demo: a single-choice group that reports each tap (a
/// first-run step would advance on it), a multi-choice group of rooms, and
/// a lone tile at rest, selected and disabled — every one live, so the
/// press squeeze, the corner morph and the title's weight show on the real
/// thing. Also the catalog specimens of the tile and the group.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The choice tiles' demo, in [brightness].
Widget kitChoiceDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Choice tiles',
  sections: const <Widget>[_Single(), _Multi(), _Tiles()],
);

const List<ExpressiveChoiceOption<String>> _sources =
    <ExpressiveChoiceOption<String>>[
      ExpressiveChoiceOption<String>(
        value: 'cuff',
        title: 'Arm cuff',
        supportingText: 'Readings arrive on their own',
        icon: ExpressiveSymbols.sync,
      ),
      ExpressiveChoiceOption<String>(
        value: 'hand',
        title: 'Enter by hand',
        supportingText: 'Type each reading after you measure',
        icon: ExpressiveSymbols.edit,
      ),
    ];

const List<ExpressiveChoiceOption<String>> _rooms =
    <ExpressiveChoiceOption<String>>[
      ExpressiveChoiceOption<String>(
        value: 'kitchen',
        title: 'Kitchen',
        icon: ExpressiveSymbols.localDining,
      ),
      ExpressiveChoiceOption<String>(
        value: 'living',
        title: 'Living room',
        icon: ExpressiveSymbols.movie,
      ),
      ExpressiveChoiceOption<String>(
        value: 'bedroom',
        title: 'Bedroom',
        icon: ExpressiveSymbols.hotel,
      ),
      ExpressiveChoiceOption<String>(
        value: 'office',
        title: 'Office',
        icon: ExpressiveSymbols.laptop,
      ),
    ];

class _Single extends StatefulWidget {
  const _Single();

  @override
  State<_Single> createState() => _SingleState();
}

class _SingleState extends State<_Single> {
  String? _source;

  @override
  Widget build(BuildContext context) => kitSection(
    'Single choice: reports the tap',
    children: <Widget>[
      ExpressiveChoiceGroup<String>.single(
        options: _sources,
        value: _source,
        semanticLabel: 'How do your readings arrive?',
        onChanged: (value) => setState(() => _source = value),
      ),
      Text(_source == null ? 'Nothing chosen yet' : 'Chose $_source'),
    ],
  );
}

class _Multi extends StatefulWidget {
  const _Multi();

  @override
  State<_Multi> createState() => _MultiState();
}

class _MultiState extends State<_Multi> {
  Set<String> _chosen = <String>{'kitchen', 'bedroom'};

  @override
  Widget build(BuildContext context) => kitSection(
    'Multi choice',
    children: <Widget>[
      ExpressiveChoiceGroup<String>.multi(
        options: _rooms,
        values: _chosen,
        semanticLabel: 'Which rooms do you have?',
        onChanged: (value) => setState(() => _chosen = value),
      ),
    ],
  );
}

class _Tiles extends StatefulWidget {
  const _Tiles();

  @override
  State<_Tiles> createState() => _TilesState();
}

class _TilesState extends State<_Tiles> {
  var _selected = 'Evening';

  @override
  Widget build(BuildContext context) => kitSection(
    'A tile at rest, selected and disabled',
    children: <Widget>[
      ExpressiveChoiceTile(
        title: 'Morning',
        supportingText: '7:00 AM',
        icon: ExpressiveSymbols.wbSunny,
        selected: _selected == 'Morning',
        onPressed: () => setState(() => _selected = 'Morning'),
      ),
      ExpressiveChoiceTile(
        title: 'Evening',
        supportingText: '8:00 PM',
        icon: ExpressiveSymbols.nightlight,
        selected: _selected == 'Evening',
        onPressed: () => setState(() => _selected = 'Evening'),
      ),
      const ExpressiveChoiceTile(
        title: 'Midday',
        supportingText: 'Not offered here',
        icon: ExpressiveSymbols.schedule,
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Catalog specimens (metadata.yaml)

/// Enter by hand, chosen.
Widget kitSpecimenChoiceTileSelected() => ExpressiveChoiceTile(
  title: 'Enter by hand',
  supportingText: 'Type each reading after you measure',
  icon: ExpressiveSymbols.edit,
  selected: true,
  onPressed: () {},
);

/// Arm cuff, offered.
Widget kitSpecimenChoiceTileIdle() => ExpressiveChoiceTile(
  title: 'Arm cuff',
  supportingText: 'Readings arrive on their own',
  icon: ExpressiveSymbols.sync,
  onPressed: () {},
);

/// How readings arrive: two options, one chosen.
Widget kitSpecimenChoiceGroupSingle() => ExpressiveChoiceGroup<String>.single(
  options: _sources,
  value: 'hand',
  onChanged: (_) {},
);

/// Which rooms: four options, two chosen.
Widget kitSpecimenChoiceGroupMulti() => ExpressiveChoiceGroup<String>.multi(
  options: _rooms,
  values: const <String>{'kitchen', 'bedroom'},
  onChanged: (_) {},
);
