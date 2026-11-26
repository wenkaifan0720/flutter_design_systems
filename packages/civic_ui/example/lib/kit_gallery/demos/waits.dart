// What a page shows while the reader waits: a wait in words by its arc,
// how far an upload has come, an allowance against its limit, rows still
// on their way, and a list a pull fetches again (with its button).
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitWaitsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Spinners, progress, meters & skeletons',
  intro:
      'A wait is said in words. The arc, the bar and the grey blocks only '
      'show that the words are still true.',
  sections: const [
    KitSection(
      title: 'Spinner',
      children: [CivicSpinner(label: 'Checking your vehicle')],
    ),
    _Upload(),
    KitSection(
      title: 'Progress without a measure',
      children: [
        CivicProgressBar(
          label: 'Checking your documents',
          valueLabel: 'This can take up to a minute',
        ),
      ],
    ),
    KitSection(
      title: 'Meter',
      children: [
        CivicMeter(
          label: 'Visitor days used this year',
          value: 38,
          max: 60,
          high: 50,
          valueLabel: '38 of 60 days used',
        ),
        CivicMeter(
          label: 'Visitor days used this year',
          value: 54,
          max: 60,
          high: 50,
          valueLabel: '54 of 60 days used',
          highLabel: 'You have 6 days left',
        ),
      ],
    ),
    KitSection(
      title: 'Skeleton',
      caption: 'Your applications, on their way.',
      children: [
        CivicSkeleton(
          semanticLabel: 'Loading your applications',
          child: Column(
            spacing: CivicSpacing.s24,
            children: [_Row(), _Row(), _Row()],
          ),
        ),
      ],
    ),
    _Refresh(),
  ],
);

class _Row extends StatelessWidget {
  const _Row();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CivicSpacing.s16,
    children: [
      CivicSkeletonBlock(width: 40, height: 40, circle: true),
      Expanded(child: CivicSkeletonText(lines: 2)),
    ],
  );
}

class _Upload extends StatefulWidget {
  const _Upload();

  @override
  State<_Upload> createState() => _UploadState();
}

class _UploadState extends State<_Upload> {
  var _pages = 2;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Progress bar',
    children: [
      CivicProgressBar(
        label: 'Uploading proof of address',
        value: _pages / 5,
        valueLabel: '$_pages of 5 pages uploaded',
      ),
      CivicButton.secondary(
        onPressed: () => setState(() => _pages = _pages % 5 + 1),
        child: const Text('Upload a page'),
      ),
    ],
  );
}

class _Refresh extends StatefulWidget {
  const _Refresh();

  @override
  State<_Refresh> createState() => _RefreshState();
}

class _RefreshState extends State<_Refresh> {
  final _list = GlobalKey<CivicPullToRefreshState>();
  var _checks = 0;

  Future<void> _fetch() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _checks++);
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Pull to refresh',
    caption:
        'Pull the list down to fetch it again. The button does the same, '
        'for anyone who cannot pull.',
    children: [
      Row(
        spacing: CivicSpacing.s16,
        children: [
          Expanded(
            child: Text(
              _checks == 0 ? 'Updated at 10:42' : 'Updated just now ($_checks)',
            ),
          ),
          CivicButton.secondary(
            expand: false,
            onPressed: () => _list.currentState?.refresh(),
            child: const Text('Refresh'),
          ),
        ],
      ),
      SizedBox(
        height: 240,
        child: CivicPullToRefresh(
          key: _list,
          onRefresh: _fetch,
          child: ListView(
            children: const [
              CivicListRow(
                title: Text('Resident permit, Zone B'),
                subtitle: Text('Approved'),
              ),
              CivicListRow(
                title: Text('Visitor permit'),
                subtitle: Text('Being checked'),
              ),
              CivicListRow(
                title: Text('Second permit'),
                subtitle: Text('Waiting for proof of address'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
