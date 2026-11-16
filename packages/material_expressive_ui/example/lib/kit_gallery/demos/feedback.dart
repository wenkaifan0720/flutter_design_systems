/// The feedback group's demo: banners in their three tones (dismissable),
/// skeletons standing in for a feed post until it loads, the page's empty,
/// error and success states, and the status view that moves between
/// them.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';
import '../trip_words.dart';

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
    final w = TripWords.of(context);
    final banners = <Widget>[
      if (!_dismissed.contains(0))
        ExpressiveBanner(
          icon: ExpressiveSymbols.wifiOff,
          title: w.offlineTitle,
          message: w.offlineText,
          actions: <ExpressiveBannerAction>[
            ExpressiveBannerAction(w.dismiss, onPressed: () => _dismiss(0)),
            ExpressiveBannerAction(w.retry, onPressed: () {}),
          ],
        ),
      if (!_dismissed.contains(1))
        ExpressiveBanner(
          icon: ExpressiveSymbols.email,
          message: w.confirmEmail,
          tone: ExpressiveTone.primary,
          actions: <ExpressiveBannerAction>[
            ExpressiveBannerAction(w.later, onPressed: () => _dismiss(1)),
            ExpressiveBannerAction(w.sendLink, onPressed: () => _dismiss(1)),
          ],
        ),
      if (!_dismissed.contains(2))
        ExpressiveBanner(
          icon: ExpressiveSymbols.error,
          title: w.paymentDeclined,
          message: w.paymentText,
          tone: ExpressiveTone.error,
          actions: <ExpressiveBannerAction>[
            ExpressiveBannerAction(w.updateCard, onPressed: () => _dismiss(2)),
          ],
        ),
    ];
    return kitSection(
      w.feedbackBanner,
      children: <Widget>[
        for (final banner in banners) banner,
        if (banners.length < 3)
          Wrap(
            children: <Widget>[
              ExpressiveTextButton(
                w.showAllBanners,
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
    final w = TripWords.of(context);
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
              w.posterInitials,
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
                      w.posterName,
                      style: t.type.titleSmall.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                    Text(
                      w.posterLine,
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
            w.postText,
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
      w.skeleton,
      children: <Widget>[
        header,
        body,
        picture,
        Wrap(
          children: <Widget>[
            ExpressiveFilledButton.tonal(
              _loaded ? w.loadAgain : w.finishLoading,
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
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    return kitSection(
      w.emptyState,
      children: <Widget>[
        ExpressiveEmptyState(
          icon: ExpressiveSymbols.inbox,
          title: w.noSavedWalks,
          body: w.noSavedWalksText,
          actionLabel: w.openMap,
          onAction: () {},
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error();

  @override
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    return kitSection(
      w.errorState,
      children: <Widget>[
        ExpressiveErrorState(
          title: w.walksFailed,
          message: w.checkConnection,
          onRetry: () {},
        ),
      ],
    );
  }
}

/// A state's wrapped lines set balanced, so no last word sits alone; and
/// the error state with its glyph left out, as under a mark the page keeps.
class _Balanced extends StatelessWidget {
  const _Balanced();

  @override
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        kitSection(
          w.longerEmptyCaption,
          children: <Widget>[
            ExpressiveEmptyState(
              icon: ExpressiveSymbols.hiking,
              title: w.noWalksThisWeek,
              body: w.noWalksThisWeekText,
            ),
          ],
        ),
        const SizedBox(height: kitGap * 3),
        kitSection(
          w.plainErrorCaption,
          children: <Widget>[
            ExpressiveErrorState(
              title: w.mapFailed,
              message: w.mapFailedText,
              icon: null,
              onRetry: _noop,
            ),
          ],
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    return kitSection(
      w.successState,
      children: <Widget>[
        ExpressiveSuccessState(
          title: w.tableBooked,
          message: w.tableBookedText,
          actionLabel: w.done,
          onAction: () {},
        ),
      ],
    );
  }
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
  Widget build(BuildContext context) {
    final w = TripWords.of(context);
    return kitSection(
      w.statusSection,
      children: <Widget>[
        // At least 320 so the three states swap in one place; taller as the
        // text grows.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 320),
          child: switch (_status) {
            ExpressiveStatus.loading => ExpressiveStatusView.loading(
              message: w.loadingWalks,
            ),
            ExpressiveStatus.error => ExpressiveStatusView.error(
              title: w.walksFailed,
              message: w.checkConnection,
              onRetry: () => _to(ExpressiveStatus.loading),
            ),
            ExpressiveStatus.success => ExpressiveStatusView.success(
              title: w.walksUpToDate,
              message: w.walksSaved,
              actionLabel: w.startOver,
              onAction: () => _to(ExpressiveStatus.error),
            ),
          },
        ),
        if (_status == ExpressiveStatus.loading)
          KitAction(
            w.finishLoading,
            onTap: () => _to(ExpressiveStatus.success),
          ),
      ],
    );
  }
}

/// A status view in its error state, its retry offered.
Widget kitSpecimenStatusViewError() => ExpressiveStatusView.error(
  title: 'Could not load your trips',
  message: 'Check your connection and try again.',
  onRetry: () {},
);
