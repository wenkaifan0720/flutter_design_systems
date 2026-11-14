/// The feedback group's demo: banners in their three tones (dismissable),
/// skeletons standing in for a feed post until it loads, the page's empty,
/// error and success states, and the status view that moves between
/// them.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The feedback group's demo, in [brightness].
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Feedback',
  sections: const <Widget>[
    _Banners(),
    SizedBox(height: kitGap * 3),
    _Skeletons(),
    SizedBox(height: kitGap * 3),
    _Empty(),
    SizedBox(height: kitGap * 3),
    _Error(),
    SizedBox(height: kitGap * 3),
    _Success(),
    SizedBox(height: kitGap * 3),
    _Status(),
    SizedBox(height: kitGap * 3),
    _Balanced(),
  ],
);

class _Banners extends StatefulWidget {
  const _Banners();

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final Set<int> _dismissed = <int>{};

  void _dismiss(int i) => setState(() => _dismissed.add(i));

  @override
  Widget build(BuildContext context) {
    final banners = <Widget>[
      if (!_dismissed.contains(0))
        ExpressiveBanner(
          icon: ExpressiveSymbols.wifiOff,
          title: 'You are offline',
          message: 'Edits are saved on this phone and sync when you reconnect.',
          actions: <ExpressiveBannerAction>[
            ExpressiveBannerAction('Dismiss', onPressed: () => _dismiss(0)),
            ExpressiveBannerAction('Retry', onPressed: () {}),
          ],
        ),
      if (!_dismissed.contains(1))
        ExpressiveBanner(
          icon: ExpressiveSymbols.email,
          message: 'Confirm your email to share lists with friends.',
          tone: ExpressiveTone.primary,
          actions: <ExpressiveBannerAction>[
            ExpressiveBannerAction('Later', onPressed: () => _dismiss(1)),
            ExpressiveBannerAction('Send link', onPressed: () => _dismiss(1)),
          ],
        ),
      if (!_dismissed.contains(2))
        ExpressiveBanner(
          icon: ExpressiveSymbols.error,
          title: 'Payment declined',
          message: 'Your plan renews on 1 October. Update the card to keep it.',
          tone: ExpressiveTone.error,
          actions: <ExpressiveBannerAction>[
            ExpressiveBannerAction('Update card', onPressed: () => _dismiss(2)),
          ],
        ),
    ];
    return kitSection(
      'Banner',
      children: <Widget>[
        for (final banner in banners) banner,
        if (banners.length < 3)
          Wrap(
            children: <Widget>[
              ExpressiveTextButton(
                'Show all banners',
                onPressed: () => setState(_dismissed.clear),
              ),
            ],
          ),
      ],
    );
  }
}

/// A feed post that loads: skeletons first, then the post.
class _Skeletons extends StatefulWidget {
  const _Skeletons();

  @override
  State<_Skeletons> createState() => _SkeletonsState();
}

class _SkeletonsState extends State<_Skeletons> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final header = Row(
      children: <Widget>[
        if (_loaded)
          Container(
            width: kitGap * 5,
            height: kitGap * 5,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: t.colors.tertiaryContainer,
              shape: t.shapes.full,
            ),
            child: Text(
              'JR',
              style: t.type.labelLarge.copyWith(
                color: t.colors.onTertiaryContainer,
              ),
            ),
          )
        else
          const ExpressiveSkeleton.circle(size: kitGap * 5),
        const SizedBox(width: kitGap * 1.5),
        Expanded(
          child: _loaded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'June Rivera',
                      style: t.type.titleSmall.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                    Text(
                      'Harbour walk · 2 h',
                      style: t.type.bodySmall.copyWith(
                        color: t.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : ExpressiveSkeleton.text(lines: 2, textStyle: t.type.bodySmall),
        ),
      ],
    );
    final body = _loaded
        ? Text(
            'Low tide this morning — the whole bay was ours. The café on the '
            'pier finally reopened too.',
            style: t.type.bodyMedium.copyWith(color: t.colors.onSurface),
          )
        : const ExpressiveSkeleton.text(lines: 3);
    final picture = _loaded
        ? Container(
            height: kitGap * 20,
            decoration: ShapeDecoration(
              color: t.colors.secondaryContainer,
              shape: t.shapes.medium,
            ),
            alignment: Alignment.center,
            child: ExpressiveIcon(
              ExpressiveSymbols.image,
              size: kitGap * 5,
              color: t.colors.onSecondaryContainer,
            ),
          )
        : const ExpressiveSkeleton(height: kitGap * 20);
    return kitSection(
      'Skeleton',
      children: <Widget>[
        header,
        body,
        picture,
        Wrap(
          children: <Widget>[
            ExpressiveFilledButton.tonal(
              _loaded ? 'Load again' : 'Finish loading',
              onPressed: () => setState(() => _loaded = !_loaded),
            ),
          ],
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => kitSection(
    'Empty state',
    children: <Widget>[
      ExpressiveEmptyState(
        icon: ExpressiveSymbols.inbox,
        title: 'No saved walks yet',
        body: 'Save a route from the map and it will wait for you here.',
        actionLabel: 'Open the map',
        onAction: () {},
      ),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error();

  @override
  Widget build(BuildContext context) => kitSection(
    'Error state',
    children: <Widget>[
      ExpressiveErrorState(
        title: 'Could not load your walks',
        message: 'Check your connection and try again.',
        onRetry: () {},
      ),
    ],
  );
}

/// A state's wrapped lines set balanced, so no last word sits alone; and
/// the error state under a mark the page keeps, its glyph left out.
class _Balanced extends StatelessWidget {
  const _Balanced();

  @override
  Widget build(BuildContext context) => kitSection(
    'States · balanced lines; an error under a mark, no glyph',
    children: const <Widget>[
      ExpressiveEmptyState(
        icon: ExpressiveSymbols.favorite,
        title: 'No readings yet this week',
        body:
            'Take your first reading and it will show here, with the '
            'category it falls in.',
      ),
      ExpressiveErrorState(
        title: 'The cuff did not answer',
        message: 'Check it is on and paired, then try again in a minute.',
        icon: null,
        onRetry: _noop,
      ),
    ],
  );
}

void _noop() {}

// Catalog specimens (docs/architecture/component-catalog.md).

/// An offline banner with its two actions.
Widget kitSpecimenBannerOffline() => ExpressiveBanner(
  icon: ExpressiveSymbols.wifi,
  title: 'You are offline',
  message: 'Edits are saved on this phone and sync when you reconnect.',
  actions: <ExpressiveBannerAction>[
    ExpressiveBannerAction('Dismiss', onPressed: () {}),
    ExpressiveBannerAction('Retry', onPressed: () {}),
  ],
);

/// A row still loading: an avatar circle beside two lines.
Widget kitSpecimenSkeletonRow() => const Row(
  children: <Widget>[
    ExpressiveSkeleton.circle(size: ExpressiveSpacing.s40),
    SizedBox(width: ExpressiveSpacing.s16),
    Expanded(child: ExpressiveSkeleton.text(lines: 2)),
  ],
);

/// The page's loading state with what is loading.
Widget kitSpecimenLoadingStateTrips() =>
    const ExpressiveLoadingState(message: 'Loading your trips');

/// The page's error state with its retry.
Widget kitSpecimenErrorStateRetry() => ExpressiveErrorState(
  title: 'Could not load your trips',
  message: 'Check your connection and try again.',
  onRetry: () {},
);

/// The page's empty state with its call to action.
Widget kitSpecimenEmptyStateTrips() => ExpressiveEmptyState(
  icon: ExpressiveSymbols.flight,
  title: 'No trips yet',
  body: 'Plan your first one and it shows up here.',
  actionLabel: 'Plan a trip',
  onAction: () {},
);

class _Success extends StatelessWidget {
  const _Success();

  @override
  Widget build(BuildContext context) => kitSection(
    'Success state',
    children: <Widget>[kitSpecimenSuccessState()],
  );
}

/// The success state a booking ends on, with its next step.
Widget kitSpecimenSuccessState() => ExpressiveSuccessState(
  title: 'Table booked',
  message: 'We sent the details to your inbox.',
  actionLabel: 'Done',
  onAction: () {},
);

/// One status view walked through its states: the error's retry loads, the
/// load finishes in success, and success starts over.
class _Status extends StatefulWidget {
  const _Status();

  @override
  State<_Status> createState() => _StatusState();
}

class _StatusState extends State<_Status> {
  ExpressiveStatus _status = ExpressiveStatus.error;

  void _to(ExpressiveStatus status) => setState(() => _status = status);

  @override
  Widget build(BuildContext context) => kitSection(
    'Status view · error, retry to loading, then success',
    children: <Widget>[
      // At least 320 so the three states swap in one place; taller as the
      // text grows.
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 320),
        child: switch (_status) {
          ExpressiveStatus.loading => const ExpressiveStatusView.loading(
            message: 'Loading your walks',
          ),
          ExpressiveStatus.error => ExpressiveStatusView.error(
            title: 'Could not load your walks',
            message: 'Check your connection and try again.',
            onRetry: () => _to(ExpressiveStatus.loading),
          ),
          ExpressiveStatus.success => ExpressiveStatusView.success(
            title: 'Walks are up to date',
            message: 'Twelve routes, saved on this phone.',
            actionLabel: 'Start over',
            onAction: () => _to(ExpressiveStatus.error),
          ),
        },
      ),
      if (_status == ExpressiveStatus.loading)
        KitAction('Finish loading', onTap: () => _to(ExpressiveStatus.success)),
    ],
  );
}

/// A status view in its error state, its retry offered.
Widget kitSpecimenStatusViewError() => ExpressiveStatusView.error(
  title: 'Could not load your trips',
  message: 'Check your connection and try again.',
  onRetry: () {},
);
