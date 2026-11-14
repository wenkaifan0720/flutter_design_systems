/// Hearth: a small home app built from the look's parts, the gallery's showcase. Home (the room you are in, its dial
/// and its lights, the house), Devices (a list, and the device beside it on a desk), Shop (a lamp and bulbs, to the
/// door), Account and Settings. Its own navigation: a bar on a phone, a rail on a tablet, the pilaster on a desk.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

/// One of the app's screens: its route id (the `?design=` query, kept from the gallery's pages), the name the app
/// gives it and its glyph in the navigation.
typedef HearthScreen = ({String id, String title, IconData icon});

/// The app's screens, in its navigation's order.
const hearthScreens = <HearthScreen>[
  (id: 'home', title: 'Home', icon: NeumorphicGlyphs.house),
  (id: 'list', title: 'Devices', icon: NeumorphicGlyphs.lamp),
  (id: 'checkout', title: 'Shop', icon: NeumorphicGlyphs.lightbulb),
  (id: 'form', title: 'Account', icon: NeumorphicGlyphs.user),
  (id: 'settings', title: 'Settings', icon: NeumorphicGlyphs.settings),
];

/// Whether [id] is one of the app's screens.
bool isHearthScreen(String id) => hearthScreens.any((s) => s.id == id);

/// A light, a fan or a socket in the house.
class HearthDevice {
  HearthDevice({
    required this.id,
    required this.name,
    required this.room,
    required this.icon,
    this.on = false,
    this.level = 1,
    this.dims = true,
    required this.kind,
    required this.fitted,
    required this.schedule,
    required this.today,
  });

  final String id, name, room, kind, fitted, schedule, today;
  final IconData icon;
  final bool dims;
  bool on;
  double level;

  /// Its state in a few words: 'On · 70%', 'Off'.
  String get state =>
      on ? (dims ? 'On · ${(level * 100).round()}%' : 'On') : 'Off';
}

/// A room: its name, the warmth it is at and the warmth it is set to.
class HearthRoom {
  HearthRoom(this.name, this.floor, this.now, this.target);
  final String name, floor;
  final double now;
  double target;
}

/// The household: what every screen reads and changes, so a lamp turned off on Home is off on Devices.
class HearthHome extends ChangeNotifier {
  final rooms = <HearthRoom>[
    HearthRoom('Living room', 'Ground', 21.0, 21.5),
    HearthRoom('Kitchen', 'Ground', 20.0, 20.0),
    HearthRoom('Hall', 'Ground', 18.5, 18.0),
    HearthRoom('Bedroom', 'Upper', 18.5, 18.0),
    HearthRoom('Study', 'Upper', 19.5, 20.0),
  ];

  final devices = <HearthDevice>[
    HearthDevice(
      id: 'floor-lamp',
      name: 'Floor lamp',
      room: 'Living room',
      icon: NeumorphicGlyphs.lamp,
      on: true,
      level: .7,
      kind: 'Warm white bulb, 2700 K',
      fitted: '3 March 2026',
      schedule: 'On at sunset, off at 23:30',
      today: '0.3 kWh',
    ),
    HearthDevice(
      id: 'reading-lamp',
      name: 'Reading lamp',
      room: 'Living room',
      icon: NeumorphicGlyphs.lamp,
      level: .4,
      kind: 'Warm white bulb, 2700 K',
      fitted: '3 March 2026',
      schedule: 'No schedule',
      today: '0.1 kWh',
    ),
    HearthDevice(
      id: 'ceiling',
      name: 'Ceiling light',
      room: 'Living room',
      icon: NeumorphicGlyphs.lightbulb,
      kind: 'Daylight panel, 4000 K',
      fitted: '12 January 2025',
      schedule: 'No schedule',
      today: '0.0 kWh',
    ),
    HearthDevice(
      id: 'pendants',
      name: 'Pendants',
      room: 'Kitchen',
      icon: NeumorphicGlyphs.lightbulb,
      on: true,
      level: .55,
      kind: 'Three warm white bulbs, 2700 K',
      fitted: '20 June 2025',
      schedule: 'On at 7:00 on weekdays',
      today: '0.4 kWh',
    ),
    HearthDevice(
      id: 'hall-light',
      name: 'Hall light',
      room: 'Hall',
      icon: NeumorphicGlyphs.lightbulb,
      kind: 'Warm white bulb, 2700 K',
      fitted: '20 June 2025',
      schedule: 'On when the door opens after dark',
      today: '0.1 kWh',
    ),
    HearthDevice(
      id: 'bedside',
      name: 'Bedside lamp',
      room: 'Bedroom',
      icon: NeumorphicGlyphs.lamp,
      level: .3,
      kind: 'Warm white bulb, 2200 K',
      fitted: '3 March 2026',
      schedule: 'Off at 23:00',
      today: '0.0 kWh',
    ),
    HearthDevice(
      id: 'fan',
      name: 'Ceiling fan',
      room: 'Bedroom',
      icon: NeumorphicGlyphs.fan,
      dims: false,
      kind: 'Three speeds, quiet at night',
      fitted: '8 August 2025',
      schedule: 'No schedule',
      today: '0.0 kWh',
    ),
    HearthDevice(
      id: 'desk-lamp',
      name: 'Desk lamp',
      room: 'Study',
      icon: NeumorphicGlyphs.lamp,
      level: .8,
      kind: 'Warm white bulb, 3000 K',
      fitted: '3 March 2026',
      schedule: 'No schedule',
      today: '0.0 kWh',
    ),
  ];

  /// The room on Home's dial.
  var room = 0;

  /// The device open on Devices.
  String? open = 'floor-lamp';

  // Shop.
  var bulbs = 2;
  var express = false;
  var pay = 'card';

  // Settings.
  var emailUpdates = true;
  var pushUpdates = true;
  var usageData = false;
  var awayLights = true;
  var volume = 4;

  int get lampPrice => 32;
  int get bulbPrice => 4;
  int get delivery => express ? 6 : 0;
  int get total => lampPrice + bulbs * bulbPrice + delivery;

  List<HearthDevice> inRoom(String room) =>
      devices.where((d) => d.room == room).toList();

  void change(VoidCallback edit) {
    edit();
    notifyListeners();
  }
}

/// Pounds with pence: '£40.00'.
String hearthMoney(int pounds) => '£$pounds.00';

/// Degrees with one place: '21.5°'.
String hearthDegrees(double value) => '${value.toStringAsFixed(1)}°';

/// The app's three layouts, by the window: a phone under 600, a tablet to the desk's 1024, and the desk.
enum HearthSize { phone, tablet, desk }

/// The layout [context]'s window takes.
HearthSize hearthSizeOf(BuildContext context) {
  if (NeumorphicTheme.of(context).desk) return HearthSize.desk;
  return MediaQuery.sizeOf(context).width >= 600
      ? HearthSize.tablet
      : HearthSize.phone;
}

/// The app. [route] is the screen it shows; [onRoute] asks for another. [onGallery] leaves for the gallery;
/// [brightness], [onBrightness], [customizing] and [onCustomize] are the gallery's day and night and its Customize,
/// carried here so a preset can be tried on the app; [panel] is the Customize panel while it is open.
class HearthApp extends StatefulWidget {
  const HearthApp({
    super.key,
    required this.route,
    required this.onRoute,
    required this.onGallery,
    required this.brightness,
    required this.onBrightness,
    required this.customizing,
    required this.onCustomize,
    this.panel,
  });

  final String route;
  final ValueChanged<String> onRoute;
  final VoidCallback onGallery;
  final Brightness brightness;
  final ValueChanged<Brightness> onBrightness;
  final bool customizing;
  final VoidCallback onCustomize;
  final Widget? panel;

  @override
  State<HearthApp> createState() => _HearthAppState();
}

class _HearthAppState extends State<HearthApp> {
  final _home = HearthHome();

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  int get _index {
    final i = hearthScreens.indexWhere((s) => s.id == widget.route);
    return i < 0 ? 0 : i;
  }

  List<NeumorphicNavItem> get _nav => [
    for (final s in hearthScreens)
      NeumorphicNavItem(
        label: s.title,
        icon: s.icon,
        key: Key('hearth-nav-${s.id}'),
        onPressed: () => widget.onRoute(s.id),
      ),
  ];

  /// The way back to the gallery on a phone or a tablet: one quiet key at the top, opening a sheet with the
  /// gallery, day and night, and Customize.
  Widget _galleryKey(BuildContext context) => NeumorphicRoundButton(
    NeumorphicGlyphs.layoutGrid,
    key: const Key('hearth-gallery'),
    label: 'Gallery',
    onPressed: () => showNeumorphicBottomSheet<void>(
      context,
      builder: (sheet) => NeumorphicBottomSheet(
        title: 'Neumorphism gallery',
        child: _GalleryWays(
          brightness: widget.brightness,
          onBrightness: (b) {
            Navigator.pop(sheet);
            widget.onBrightness(b);
          },
          onCustomize: () {
            Navigator.pop(sheet);
            widget.onCustomize();
          },
          onGallery: () {
            Navigator.pop(sheet);
            widget.onGallery();
          },
          customizing: widget.customizing,
        ),
      ),
    ),
  );

  Widget _screen(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final screen = hearthScreens[_index];
    final body = ListenableBuilder(
      listenable: _home,
      builder: (context, _) => switch (screen.id) {
        'list' => _DevicesScreen(home: _home),
        'checkout' => _ShopScreen(home: _home),
        'form' => _AccountScreen(home: _home),
        'settings' => _SettingsScreen(home: _home),
        _ => _HomeScreen(home: _home),
      },
    );
    return NeumorphicScaffold(
      key: ValueKey('hearth-${screen.id}'),
      actions: [if (!t.desk) _galleryKey(context)],
      // A phone's checkout keeps its total and Pay at the foot in the tab bar's own slab (below).
      railFoot: [
        _GalleryWays(
          brightness: widget.brightness,
          onBrightness: widget.onBrightness,
          onCustomize: widget.onCustomize,
          onGallery: widget.onGallery,
          customizing: widget.customizing,
        ),
      ],
      body: widget.panel == null
          ? body
          : NeumorphicColumn(gap: 28, children: [widget.panel!, body]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final nav = _nav;
    final scope = NeumorphicChromeScope(
      brand: const NeumorphicBrand(name: 'Hearth'),
      nav: nav,
      active: _index,
      child: Builder(builder: _screen),
    );
    if (t.desk) return scope;
    if (width >= 600) {
      return ColoredBox(
        color: t.colors.ground,
        child: Row(
          children: [
            NeumorphicNavigationRail(
              key: const Key('hearth-rail'),
              label: 'Hearth',
              items: nav,
              selectedIndex: _index,
              onDestinationSelected: (i) => widget.onRoute(hearthScreens[i].id),
            ),
            Expanded(child: scope),
          ],
        ),
      );
    }
    return ColoredBox(
      color: t.colors.ground,
      child: Column(
        children: [
          Expanded(child: scope),
          NeumorphicNavigationBar(
            key: const Key('hearth-bar'),
            items: nav,
            selectedIndex: _index,
            onDestinationSelected: (i) => widget.onRoute(hearthScreens[i].id),
            // The checkout's total and Pay over the tabs, one slab: a bar of its own stacked on the tab bar.
            header: hearthScreens[_index].id == 'checkout'
                ? ListenableBuilder(
                    listenable: _home,
                    builder: (context, _) => _PayBar(home: _home),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// The gallery's day and night, its Customize and the way back to it: at the pilaster's foot on a desk, in a sheet
/// behind the top's key elsewhere.
class _GalleryWays extends StatelessWidget {
  const _GalleryWays({
    required this.brightness,
    required this.onBrightness,
    required this.onCustomize,
    required this.onGallery,
    required this.customizing,
  });

  final Brightness brightness;
  final ValueChanged<Brightness> onBrightness;
  final VoidCallback onCustomize, onGallery;
  final bool customizing;

  @override
  Widget build(BuildContext context) => NeumorphicColumn(
    gap: 12,
    children: [
      NeumorphicSegmentedButton<Brightness>(
        key: const Key('hearth-appearance'),
        label: 'Appearance',
        value: brightness,
        segments: const [
          NeumorphicButtonSegment(Brightness.light, 'Day'),
          NeumorphicButtonSegment(Brightness.dark, 'Night'),
        ],
        onChanged: onBrightness,
      ),
      // Raised keys, as the gallery's own rail's Customize is: flat text keys at the foot read as out of use.
      NeumorphicButton(
        customizing ? 'Close Customize' : 'Customize',
        key: const Key('hearth-customize'),
        icon: NeumorphicGlyphs.slidersHorizontal,
        wide: true,
        onPressed: onCustomize,
      ),
      NeumorphicButton(
        'Back to the gallery',
        key: const Key('hearth-back-to-gallery'),
        icon: NeumorphicGlyphs.layoutGrid,
        wide: true,
        onPressed: onGallery,
      ),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------- Home

/// Home: the room you are in, warming to what it is set to; its lights; the house. The dial leads.
class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.home});
  final HearthHome home;

  @override
  Widget build(BuildContext context) {
    final room = home.rooms[home.room];
    final lights = home.inRoom(room.name);
    final on = lights.where((d) => d.on).length;
    final warming = room.target > room.now;
    final head = NeumorphicPageHead(
      overline: '14 Harbour Street',
      title: room.name,
      subtitle: on == 0
          ? 'The lights are off.'
          : on == 1
          ? 'One light is on.'
          : '$on lights are on.',
    );
    final dial = NeumorphicDial(
      key: const Key('hearth-dial'),
      value: room.target,
      min: 10,
      max: 30,
      now: room.now,
      label: warming ? 'Warming to' : 'Holding at',
      labelIcon: warming ? NeumorphicGlyphs.flame : null,
      figure: hearthDegrees(room.target),
      sub: 'Now ${hearthDegrees(room.now)}',
      onDecrease: room.target <= 10
          ? null
          : () => home.change(() => room.target -= .5),
      onIncrease: room.target >= 30
          ? null
          : () => home.change(() => room.target += .5),
    );
    final lightsSet = NeumorphicListSection(
      label: 'Lights',
      children: [
        for (final (i, d) in lights.indexed)
          NeumorphicLevelRow(
            key: Key('hearth-light-${d.id}'),
            icon: d.icon,
            title: d.name,
            state: d.state,
            value: d.on,
            level: d.dims ? d.level : null,
            isFirst: i == 0,
            onChanged: (v) => home.change(() => d.on = v),
            onLevel: d.dims ? (v) => home.change(() => d.level = v) : null,
          ),
      ],
    );
    final house = NeumorphicRelief(
      key: const Key('hearth-house'),
      title: '14',
      subtitle: 'Harbour Street',
      count:
          '*${home.devices.where((d) => d.on).length} of ${home.devices.length}* on',
      courses: [
        for (final floor in ['Upper', 'Ground'])
          NeumorphicCourse(floor, [
            for (final (i, r) in home.rooms.indexed)
              if (r.floor == floor)
                NeumorphicBay(
                  name: r.name,
                  figure: hearthDegrees(r.now),
                  note: i == home.room ? 'Here' : null,
                  lit: _lit(home.inRoom(r.name)),
                  onPressed: () => home.change(() => home.room = i),
                ),
          ]),
      ],
      ground: const [
        NeumorphicGroundNote('Door locked', icon: NeumorphicGlyphs.lock),
        NeumorphicGroundNote('Garden', icon: NeumorphicGlyphs.trees),
      ],
    );
    final rooms = NeumorphicWallSet(
      title: 'Rooms',
      subtitle: 'Press one to set it',
      child: house,
    );
    // A phone's house would be a thumbnail too small to press: its rooms are a list, the one you are in chosen.
    final roomList = NeumorphicListSection(
      key: const Key('hearth-rooms'),
      label: 'Rooms',
      children: [
        for (final (i, r) in home.rooms.indexed)
          NeumorphicListTile(
            key: Key('hearth-room-$i'),
            title: r.name,
            subtitle: r.floor == 'Upper' ? 'Upstairs' : 'Ground floor',
            trailing: Text(hearthDegrees(r.now)),
            selected: i == home.room,
            isFirst: i == 0,
            onPressed: () => home.change(() => home.room = i),
          ),
      ],
    );
    // The day so far, under the heat it paid for: what the house used and what that cost.
    final used = home.devices.fold<double>(
      0,
      (a, d) => a + (double.tryParse(d.today.split(' ').first) ?? 0),
    );
    final today = NeumorphicStats(key: const Key('hearth-today'), [
      const NeumorphicStat('Outside', '9°'),
      NeumorphicStat('Used today', used.toStringAsFixed(1), 'kWh'),
      NeumorphicStat('Cost today', '£${(used * .28).toStringAsFixed(2)}'),
    ]);
    return switch (hearthSizeOf(context)) {
      HearthSize.desk => NeumorphicSections(
        children: [
          head,
          NeumorphicRow(
            spans: const [7, 5],
            children: [
              NeumorphicColumn(gap: 28, children: [dial, today]),
              NeumorphicColumn(gap: 28, children: [lightsSet, rooms]),
            ],
          ),
        ],
      ),
      // The dial alone on its line; under it the lights beside the house.
      HearthSize.tablet => NeumorphicSections(
        children: [
          head,
          dial,
          today,
          NeumorphicRow(spans: const [1, 1], children: [lightsSet, rooms]),
        ],
      ),
      // What a person does first on a phone is the heat and the lights; the day's figures come last.
      HearthSize.phone => NeumorphicSections(
        children: [head, dial, lightsSet, roomList, today],
      ),
    };
  }

  static double _lit(List<HearthDevice> lights) {
    final on = lights.where((d) => d.on);
    if (on.isEmpty) return 0;
    return on
        .map((d) => d.dims ? d.level : 1.0)
        .reduce((a, b) => a > b ? a : b);
  }
}

// ---------------------------------------------------------------------------------------------------------- Devices

/// Devices: every device in the house, found by name or room; the open one beside the list on a desk, its own page
/// on a phone. What a person scans for, the name, leads each row.
class _DevicesScreen extends StatefulWidget {
  const _DevicesScreen({required this.home});
  final HearthHome home;

  @override
  State<_DevicesScreen> createState() => _DevicesScreenState();
}

/// The add dialog owns its field's controller, so the field keeps it while the dialog's route animates out.
class _AddDevice extends StatefulWidget {
  const _AddDevice({required this.rooms});

  final List<String> rooms;

  @override
  State<_AddDevice> createState() => _AddDeviceState();
}

class _AddDeviceState extends State<_AddDevice> {
  final _name = TextEditingController();
  late var _room = widget.rooms.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NeumorphicDialog(
    title: 'Add a device',
    message: 'Switch it on and hold its button for three seconds; it joins your home.',
    actions: [
      NeumorphicButton.text('Cancel', onPressed: () => Navigator.pop(context)),
      NeumorphicButton.filled(
        'Add device',
        key: const Key('hearth-add-confirm'),
        onPressed: () => Navigator.pop(context, (_name.text.trim(), _room)),
      ),
    ],
    content: [
      NeumorphicColumn(
        gap: 20,
        children: [
          NeumorphicTextField(
            key: const Key('hearth-add-name'),
            label: 'Name',
            hint: 'Hall lamp',
            controller: _name,
          ),
          NeumorphicSelect<String>(
            label: 'Room',
            value: _room,
            options: [for (final r in widget.rooms) NeumorphicMenuItem(r, r)],
            onChanged: (v) => setState(() => _room = v),
          ),
        ],
      ),
    ],
  );
}

class _DevicesScreenState extends State<_DevicesScreen> {
  var _query = '';

  HearthHome get home => widget.home;

  Future<void> _add() async {
    final added = await showNeumorphicDialog<(String, String)>(
      context,
      builder: (context) =>
          _AddDevice(rooms: [for (final r in home.rooms) r.name]),
    );
    if (added == null || !mounted) return;
    final (words, room) = added;
    final device = HearthDevice(
      id: 'new-${home.devices.length}',
      name: words.isEmpty ? 'New lamp' : words,
      room: room,
      icon: NeumorphicGlyphs.lamp,
      kind: 'Warm white bulb, 2700 K',
      fitted: 'Today',
      schedule: 'No schedule',
      today: '0.0 kWh',
    );
    home.change(() {
      home.devices.add(device);
      home.open = device.id;
    });
    if (mounted) {
      showNeumorphicToast(context, message: '${device.name} joined your home.');
    }
  }

  void _openOnPhone(HearthDevice device) {
    home.change(() => home.open = device.id);
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => ListenableBuilder(
          listenable: home,
          builder: (context, _) => NeumorphicScaffold(
            topBar: NeumorphicAppBar(
              title: device.name,
              subtitle: device.room,
              leading: const NeumorphicBackButton(),
            ),
            body: _DeviceDetail(home: home, device: device, page: true),
          ),
        ),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final size = hearthSizeOf(context);
    final words = _query.toLowerCase();
    final shown = [
      for (final d in home.devices)
        if (d.name.toLowerCase().contains(words) ||
            d.room.toLowerCase().contains(words))
          d,
    ];
    final on = home.devices.where((d) => d.on).length;
    // Adding is the screen's second job: a key at the head's end, not the act. Beside the search it stood a round key
    // by a field of another height on a desk, where a field keeps its 48 and a key's face is compact.
    final head = NeumorphicPageHead(
      title: 'Devices',
      subtitle: '${home.devices.length} in your home, $on on',
      trailing: NeumorphicRoundButton(
        NeumorphicGlyphs.plus,
        key: const Key('hearth-add'),
        label: 'Add a device',
        onPressed: _add,
      ),
    );
    final find = NeumorphicSearchField(
      key: const Key('hearth-search'),
      label: 'Search devices',
      hint: 'Search by name or room',
      onChanged: (v) => setState(() => _query = v),
    );
    final list = shown.isEmpty
        ? NeumorphicEmptyState(
            title: 'Nothing called "$_query"',
            body: 'Try a room: kitchen, hall or study.',
          )
        : NeumorphicListSection(
            children: [
              for (final (i, d) in shown.indexed)
                NeumorphicListTile(
                  key: Key('hearth-device-${d.id}'),
                  title: d.name,
                  subtitle: d.room,
                  isFirst: i == 0,
                  leading: Icon(d.icon, size: 22),
                  trailing: Text(
                    d.state,
                    style: t.textTheme.caption.copyWith(
                      color: d.on ? t.colors.ink : t.colors.inkTertiary,
                      fontWeight: d.on ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  // From a tablet up the open device stands beside the list: its row is the chosen one.
                  selected: size != HearthSize.phone && d.id == home.open,
                  onPressed: size == HearthSize.phone
                      ? () => _openOnPhone(d)
                      : () => home.change(() => home.open = d.id),
                ),
            ],
          );
    if (size == HearthSize.phone) {
      return NeumorphicSections(children: [head, find, list]);
    }
    // From a tablet up, the list beside the device it opened.
    final open = home.devices.where((d) => d.id == home.open).firstOrNull;
    return NeumorphicSections(
      children: [
        head,
        NeumorphicRow(
          spans: size == HearthSize.desk ? const [5, 7] : const [1, 1],
          children: [
            NeumorphicColumn(gap: 20, children: [find, list]),
            if (open == null)
              const NeumorphicEmptyState(
                title: 'No device open',
                body: 'Choose one from the list.',
              )
            else
              _DeviceDetail(home: home, device: open),
          ],
        ),
      ],
    );
  }
}

/// One device: its control first, then what it is, when it runs and what it used; removing it last and quiet.
class _DeviceDetail extends StatelessWidget {
  const _DeviceDetail({
    required this.home,
    required this.device,
    this.page = false,
  });
  final HearthHome home;
  final HearthDevice device;

  /// It is a phone's page, under its own top: no head of its own.
  final bool page;

  Future<void> _remove(BuildContext context) async {
    final gone = await showNeumorphicDialog<bool>(
      context,
      builder: (context) => NeumorphicDialog(
        title: 'Remove ${device.name}?',
        message: 'It leaves your home and its schedule stops. You can add it again later.',
        actions: [
          NeumorphicButton.text(
            'Keep it',
            onPressed: () => Navigator.pop(context, false),
          ),
          NeumorphicButton(
            'Remove',
            isDestructiveAction: true,
            key: const Key('hearth-remove-confirm'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (gone != true || !context.mounted) return;
    if (page) Navigator.pop(context);
    home.change(() {
      home.devices.remove(device);
      home.open = home.devices.firstOrNull?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = NeumorphicCard(
      key: Key('hearth-detail-${device.id}'),
      title: page ? null : device.name,
      subtitle: page ? null : device.room,
      // Ruled rows: the rules space them, so each row's words stand midway between its rules.
      gap: 0,
      children: [
        NeumorphicLevelRow(
          icon: device.icon,
          title: device.on ? 'On' : 'Off',
          state: device.dims
              ? 'Brightness ${(device.level * 100).round()}%'
              : device.kind,
          value: device.on,
          level: device.dims ? device.level : null,
          isFirst: true,
          onChanged: (v) => home.change(() => device.on = v),
          onLevel: device.dims
              ? (v) => home.change(() => device.level = v)
              : null,
        ),
        NeumorphicKvRow('Bulb', device.kind),
        NeumorphicKvRow('Schedule', device.schedule),
        NeumorphicKvRow('Used today', device.today),
        NeumorphicKvRow('Fitted', device.fitted),
      ],
    );
    return NeumorphicColumn(
      gap: 28,
      children: [
        card,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: NeumorphicButton(
            'Remove from home',
            isDestructiveAction: true,
            key: const Key('hearth-remove'),
            onPressed: () => _remove(context),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------------------------------------------- Shop

/// Shop's checkout: a desk lamp and its bulbs, to the door. The total leads; paying is the act.
class _ShopScreen extends StatelessWidget {
  const _ShopScreen({required this.home});
  final HearthHome home;

  @override
  Widget build(BuildContext context) {
    final order = _Order(home: home);
    final delivery = NeumorphicColumn(
      gap: 20,
      children: [
        const NeumorphicSectionHeader(title: 'Deliver to'),
        const NeumorphicTextField(
          key: Key('hearth-street'),
          label: 'Street',
          initialValue: '14 Harbour Street',
        ),
        const NeumorphicRow(
          spans: [7, 5],
          children: [
            NeumorphicTextField(label: 'Town', initialValue: 'Bristol'),
            NeumorphicTextField(label: 'Postcode', initialValue: 'BS1 4DJ'),
          ],
        ),
        NeumorphicRadioGroup<bool>(
          key: const Key('hearth-delivery'),
          label: 'Delivery',
          value: home.express,
          options: const [
            NeumorphicRadio(
              false,
              'Standard',
              note: 'Monday 16 November',
              trailingText: 'Free',
            ),
            NeumorphicRadio(
              true,
              'Next day',
              note: 'Tomorrow by 18:00',
              trailingText: '£6.00',
            ),
          ],
          onChanged: (v) => home.change(() => home.express = v),
        ),
        NeumorphicFormGroup(
          label: 'Pay with',
          child: NeumorphicSegmentedButton<String>(
            key: const Key('hearth-pay-with'),
            label: 'Pay with',
            value: home.pay,
            segments: const [
              NeumorphicButtonSegment(
                'card',
                'Card',
                icon: NeumorphicGlyphs.creditCard,
              ),
              NeumorphicButtonSegment('bank', 'Bank'),
              NeumorphicButtonSegment('later', 'Later'),
            ],
            onChanged: (v) => home.change(() => home.pay = v),
          ),
        ),
      ],
    );
    const head = NeumorphicPageHead(
      title: 'Checkout',
      subtitle: 'A desk lamp for the study, and bulbs.',
    );
    final size = hearthSizeOf(context);
    if (size == HearthSize.phone) {
      return NeumorphicSections(children: [head, order, delivery]);
    }
    // The order beside the form, the act under the order.
    return NeumorphicSections(
      children: [
        head,
        NeumorphicRow(
          spans: size == HearthSize.desk ? const [7, 5] : const [1, 1],
          children: [
            delivery,
            NeumorphicColumn(
              gap: 20,
              children: [
                order,
                _PayButton(home: home),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// The order: each line a list row with its price, the bulbs with their count under their words, delivery, the total.
class _Order extends StatelessWidget {
  const _Order({required this.home});
  final HearthHome home;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    Widget price(int pounds) => Text(
      hearthMoney(pounds),
      style: t.textTheme.body.copyWith(fontWeight: FontWeight.w700).tabular,
    );
    return NeumorphicCard(
      key: const Key('hearth-order'),
      title: 'Your order',
      gap: 0,
      children: [
        NeumorphicListTile(
          isFirst: true,
          leading: const NeumorphicIconWell(NeumorphicGlyphs.lamp),
          title: 'Arc desk lamp',
          subtitle: 'Porcelain, 42 cm',
          trailing: price(home.lampPrice),
        ),
        NeumorphicListTile(
          leading: const NeumorphicIconWell(NeumorphicGlyphs.lightbulb),
          title: 'Bulbs',
          subtitle: 'Warm white, ${hearthMoney(home.bulbPrice)} each',
          trailing: price(home.bulbs * home.bulbPrice),
          action: NeumorphicNumberField(
            key: const Key('hearth-bulbs'),
            value: '${home.bulbs}',
            onDecrease: home.bulbs == 1
                ? null
                : () => home.change(() => home.bulbs--),
            onIncrease: home.bulbs == 9
                ? null
                : () => home.change(() => home.bulbs++),
          ),
        ),
        NeumorphicKvRow(
          'Delivery',
          home.delivery == 0 ? 'Free' : hearthMoney(home.delivery),
        ),
        NeumorphicTotalRow(
          'Total',
          hearthMoney(home.total),
          key: const Key('hearth-total'),
        ),
      ],
    );
  }
}

Future<void> _pay(
  BuildContext context,
  HearthHome home,
) => showNeumorphicDialog<void>(
  context,
  builder: (context) => NeumorphicDialog(
    title: 'Order placed',
    message:
        'Your desk lamp and ${home.bulbs} bulbs arrive ${home.express ? 'tomorrow by 18:00' : 'on Monday 16 November'}. We sent the receipt to alex.morgan@hearth.example.',
    actions: [
      NeumorphicButton.filled(
        'Done',
        key: const Key('hearth-paid'),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ),
);

class _PayButton extends StatelessWidget {
  const _PayButton({required this.home, this.sum = true});
  final HearthHome home;

  /// Whether the key says the sum: not beside the total, where it said it twice and broke in two at large text.
  final bool sum;
  @override
  // As wide as the order above it: a narrower one flush to its end stood under the card aligned to nothing.
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: NeumorphicButton.filled(
      sum ? 'Pay ${hearthMoney(home.total)}' : 'Pay',
      key: const Key('hearth-pay'),
      wide: true,
      onPressed: () => _pay(context, home),
    ),
  );
}

/// A phone's foot on the checkout: the total beside the act.
class _PayBar extends StatelessWidget {
  const _PayBar({required this.home});
  final HearthHome home;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    return Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total', style: t.textTheme.caption),
            Text(hearthMoney(home.total), style: t.textTheme.value.tabular),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(child: _PayButton(home: home, sum: false)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------------------- Account

/// Account: who you are to the house. Your name leads; saving is the act.
class _AccountScreen extends StatefulWidget {
  const _AccountScreen({required this.home});
  final HearthHome home;

  @override
  State<_AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<_AccountScreen> {
  final _first = TextEditingController(text: 'Alex');
  final _last = TextEditingController(text: 'Morgan');
  final _email = TextEditingController(text: 'alex.morgan@hearth.example');
  final _phone = TextEditingController(text: '07700 900 412');
  var _country = 'United Kingdom';

  /// Set when Save finds the email unusable; cleared as the person types.
  String? _emailError;

  void _save() {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(
        () => _emailError = 'Enter an email address, like name@example.com.',
      );
      return;
    }
    showNeumorphicToast(context, message: 'Saved. Your receipts go to $email.');
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final initials =
        '${_first.text.characters.firstOrNull ?? ''}'
        '${_last.text.characters.firstOrNull ?? ''}';
    final name = '${_first.text} ${_last.text}'.trim();
    final form = NeumorphicColumn(
      gap: 20,
      children: [
        NeumorphicRow(
          spans: const [1, 1],
          children: [
            NeumorphicTextField(
              key: const Key('hearth-first'),
              label: 'First name',
              controller: _first,
              autofillHints: const [AutofillHints.givenName],
              onChanged: (_) => setState(() {}),
            ),
            NeumorphicTextField(
              key: const Key('hearth-last'),
              label: 'Last name',
              controller: _last,
              autofillHints: const [AutofillHints.familyName],
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        NeumorphicTextField(
          key: const Key('hearth-email'),
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          helper: 'Receipts and the weekly summary go here.',
          error: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        NeumorphicTextField(
          label: 'Phone',
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          helper: 'For the courier, on delivery days only.',
        ),
        NeumorphicSelect<String>(
          key: const Key('hearth-country'),
          label: 'Country',
          value: _country,
          options: const [
            NeumorphicMenuItem('United Kingdom', 'United Kingdom'),
            NeumorphicMenuItem('Ireland', 'Ireland'),
            NeumorphicMenuItem('United States', 'United States'),
          ],
          onChanged: (v) => setState(() => _country = v),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: NeumorphicButton.filled(
            'Save details',
            key: const Key('hearth-save'),
            // A phone's act spans the form; with room it stands at the end, on the fields' edge.
            wide: hearthSizeOf(context) == HearthSize.phone,
            onPressed: _save,
          ),
        ),
      ],
    );
    const head = NeumorphicPageHead(title: 'Account');
    // Who it is leads: the face and the name, then what they share.
    final identity = Row(
      children: [
        NeumorphicAvatar(initials, size: 56, name: name),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: t.textTheme.value),
              Text('Member since March 2024', style: t.textTheme.caption),
            ],
          ),
        ),
      ],
    );
    final size = hearthSizeOf(context);
    // A phone shows the same card over the form: without it the home, who it is shared with and the plan were gone.
    final who = NeumorphicCard(
      key: const Key('hearth-who'),
      children: [
        identity,
        // The rows in their own list, not on the card's gap: each row's words stand midway between its rules.
        const NeumorphicList(
          children: [
            NeumorphicKvRow('Home', '14 Harbour Street', isFirst: true),
            NeumorphicKvRow('Shared with', 'Sam and Jordan'),
            NeumorphicKvRow('Plan', 'Hearth Plus, renews 1\u00a0March'),
          ],
        ),
      ],
    );
    return NeumorphicSections(
      children: [
        head,
        if (size == HearthSize.desk)
          // The card is as tall as what it holds, not the form's height beside it.
          NeumorphicRow(
            spans: const [7, 5],
            children: [
              form,
              Align(alignment: AlignmentDirectional.topStart, child: who),
            ],
          )
        else ...[
          who,
          form,
        ],
      ],
    );
  }
}

// --------------------------------------------------------------------------------------------------------- Settings

/// Settings: each switch applies as it moves; there is nothing to save. Leaving the home is last and quiet.
class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({required this.home});
  final HearthHome home;

  Future<void> _leave(BuildContext context) => showNeumorphicDialog<void>(
    context,
    builder: (context) => NeumorphicDialog(
      title: 'Leave 14 Harbour Street?',
      message: 'Its devices and schedules stay with Sam and Jordan. You can be invited back.',
      actions: [
        NeumorphicButton.text('Stay', onPressed: () => Navigator.pop(context)),
        NeumorphicButton(
          'Leave home',
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final notices = NeumorphicListSection(
      label: 'Notifications',
      children: [
        NeumorphicSwitchRow(
          key: const Key('hearth-email-updates'),
          label: 'Weekly summary',
          note: 'What your home used, each Monday by email.',
          value: home.emailUpdates,
          onChanged: (v) => home.change(() => home.emailUpdates = v),
        ),
        NeumorphicSwitchRow(
          key: const Key('hearth-push'),
          label: 'Alerts on this phone',
          note: 'A door left open, a room too cold.',
          value: home.pushUpdates,
          onChanged: (v) => home.change(() => home.pushUpdates = v),
        ),
      ],
    );
    final sound = NeumorphicListSection(
      label: 'Sound',
      children: [
        NeumorphicDial(
          key: const Key('hearth-volume'),
          value: home.volume.toDouble(),
          min: 0,
          max: 10,
          step: 1,
          compact: true,
          label: 'Alert volume',
          figure: '${home.volume}',
          sub: home.volume == 0 ? 'Silent' : 'Out of 10',
          onDecrease: home.volume == 0
              ? null
              : () => home.change(() => home.volume--),
          onIncrease: home.volume == 10
              ? null
              : () => home.change(() => home.volume++),
        ),
      ],
    );
    final away = NeumorphicListSection(
      label: 'While you are away',
      children: [
        NeumorphicSwitchRow(
          key: const Key('hearth-away'),
          label: 'Lights on at sunset',
          note: 'So the house looks lived in.',
          value: home.awayLights,
          onChanged: (v) => home.change(() => home.awayLights = v),
        ),
      ],
    );
    final privacy = NeumorphicListSection(
      label: 'Privacy',
      children: [
        NeumorphicSwitchRow(
          key: const Key('hearth-usage'),
          label: 'Share usage, without names',
          note: 'Helps us make the schedules better.',
          value: home.usageData,
          onChanged: (v) => home.change(() => home.usageData = v),
        ),
      ],
    );
    final leave = Align(
      alignment: AlignmentDirectional.centerStart,
      child: NeumorphicButton(
        'Leave this home',
        isDestructiveAction: true,
        key: const Key('hearth-leave'),
        onPressed: () => _leave(context),
      ),
    );
    const head = NeumorphicPageHead(title: 'Settings');
    if (hearthSizeOf(context) == HearthSize.phone) {
      return NeumorphicSections(
        children: [head, notices, sound, away, privacy, leave],
      );
    }
    // Two columns of groups, every group the same raised list: the switches in one, the dial (as tall as three groups
    // of switches) in the other, so neither column leaves a hole above the way out.
    return NeumorphicSections(
      children: [
        head,
        NeumorphicRow(
          spans: const [1, 1],
          children: [
            NeumorphicColumn(gap: 28, children: [notices, away, privacy]),
            sound,
          ],
        ),
        leave,
      ],
    );
  }
}
