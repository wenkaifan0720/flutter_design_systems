/// A carousel, headless: slides on a [PageView] with the controls a look
/// lays out (previous, next, a dot per slide, play and pause, and where the
/// slides are as they move). One that loops goes round: next on the last
/// slide turns on to the first, as a swipe past it does. The arrows
/// turn it while the keyboard is on it; autoplay pauses under a pointer or
/// the keyboard and stays off under Reduce Motion; a screen reader hears
/// "Slide 2 of 5", and is told it when a turn it did not start by autoplay
/// lands.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'localizations.dart';

/// What a carousel's controls act on.
@immutable
class DesignCarouselControls {
  /// The controls; the carousel makes them.
  const DesignCarouselControls({
    required this.page,
    required this.count,
    required this.position,
    required this.previous,
    required this.next,
    required this.goToPage,
    required this.playing,
    required this.togglePlay,
    required this.focused,
  });

  /// The slide shown.
  final int page;

  /// How many slides there are.
  final int count;

  /// Where the slides are, in slides, as they move: 1.5 is half way from
  /// slide 1 to slide 2, so a look's dots can follow a swipe. A carousel
  /// that loops runs from 0 up to [count] and wraps: 2.5 of 3 is half way
  /// from the last slide to the first.
  final ValueListenable<double> position;

  /// Turns back; null at the first slide of a carousel that does not loop.
  final VoidCallback? previous;

  /// Turns on; null at the last slide of a carousel that does not loop.
  final VoidCallback? next;

  /// Shows a slide (a dot's press).
  final ValueChanged<int> goToPage;

  /// Whether it is playing.
  final bool playing;

  /// Plays or pauses; null when it has no autoplay.
  final VoidCallback? togglePlay;

  /// Whether the keyboard is on the slides (their focus ring).
  final bool focused;
}

/// Slides [itemBuilder] builds, [itemCount] of them.
///
/// The frame's shape is the look's to hold. The slides are cut at the
/// viewport's edge as [clipBehavior] says, square by default, so a slide
/// whose corners are rounded shows square ones mid-swipe where it crosses
/// that edge. A look with a rounded frame clips the `viewport` it gets in
/// [layoutBuilder] to that shape (a `ClipRRect` around it).
///
/// ```dart
/// DesignCarousel(itemCount: 3, itemBuilder: (context, index) => Text('Slide $index'))
/// ```
class DesignCarousel extends StatefulWidget {
  /// A carousel of [itemCount] slides.
  const DesignCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.layoutBuilder,
    this.initialPage = 0,
    this.viewportFraction = 1,
    this.loop = false,
    this.autoplayInterval,
    this.onPageChanged,
    this.focusable = true,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.slideLabel,
    this.duration = const Duration(milliseconds: 350),
    this.clipBehavior = Clip.hardEdge,
  });

  /// How many slides there are.
  final int itemCount;

  /// Builds slide `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// Lays out the slides (`viewport`) with the controls; null: the slides
  /// alone (a swipe, the keys and a screen reader still turn them).
  final Widget Function(
    BuildContext context,
    Widget viewport,
    DesignCarouselControls controls,
  )?
  layoutBuilder;

  /// The slide it starts on.
  final int initialPage;

  /// Each slide's share of the view (under 1 shows the neighbours).
  final double viewportFraction;

  /// Whether it goes round: next at the last slide turns on to the first
  /// (and a swipe past it does), previous at the first back to the last.
  final bool loop;

  /// How long each slide shows while it plays; null: it does not play.
  final Duration? autoplayInterval;

  /// Called when the slide shown changes.
  final ValueChanged<int>? onPageChanged;

  /// Whether the slides are a tab stop the arrows turn.
  final bool focusable;

  /// The slides' focus. The caller's, who disposes it; null: the carousel
  /// makes its own and disposes it.
  final FocusNode? focusNode;

  /// Whether the slides take focus when they first appear (with
  /// [focusable]).
  final bool autofocus;

  /// What a screen reader calls the carousel; null:
  /// [DesignLocalizations.carouselLabel].
  final String? semanticLabel;

  /// What a screen reader calls slide `index` of `count`; null:
  /// [DesignLocalizations.carouselSlideLabel].
  final String Function(int index, int count)? slideLabel;

  /// How long a turn takes.
  final Duration duration;

  /// How the slides are cut at the viewport's edge, as
  /// [PageView.clipBehavior]: [Clip.hardEdge], a square cut, by default.
  /// [Clip.none] lets a moving slide paint past the edge, for slides that
  /// run to the screen's edge, or inside a frame the look clips itself.
  final Clip clipBehavior;

  @override
  State<DesignCarousel> createState() => _DesignCarouselState();
}

class _DesignCarouselState extends State<DesignCarousel> {
  String _slideLabel(int index, int count) =>
      (widget.slideLabel ?? DesignLocalizations.of(context).carouselSlideLabel)(
        index,
        count,
      );

  // A carousel that loops runs on pages without end: page p shows slide
  // p mod count, starting this many rounds in so it can go back as far.
  static const _rounds = 10000;

  bool get _looping => widget.loop && widget.itemCount > 1;

  int _pageFor(int slide) =>
      _looping ? _rounds * widget.itemCount + slide : slide;

  int _slideOf(int page) => _looping ? page % widget.itemCount : page;

  late final PageController _pages = PageController(
    initialPage: _pageFor(widget.initialPage),
    viewportFraction: widget.viewportFraction,
  )..addListener(_moved);
  late int _page = widget.initialPage;
  late final ValueNotifier<double> _position = ValueNotifier(
    widget.initialPage.toDouble(),
  );
  FocusNode? _ownSlides;
  FocusNode get _slides =>
      widget.focusNode ??
      (_ownSlides ??= FocusNode(debugLabel: 'DesignCarousel slides'));
  bool _slidesFocused = false;
  bool _playing = true;
  bool _playChosen = false;
  bool _hovered = false;
  bool _dragging = false;
  bool _focusWithin = false;
  bool _focused = false;
  Timer? _timer;

  bool get _still => MediaQuery.disableAnimationsOf(context);

  bool get _running =>
      widget.autoplayInterval != null &&
      _playing &&
      !_hovered &&
      !_dragging &&
      !_focusWithin &&
      widget.itemCount > 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce Motion: no autoplay unless the reader presses play.
    if (!_playChosen) _playing = !_still;
    _schedule();
  }

  @override
  void didUpdateWidget(DesignCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loop != widget.loop ||
        oldWidget.itemCount != widget.itemCount) {
      // Pages and slides now pair differently: stay on the slide shown.
      _page = widget.itemCount == 0 ? 0 : _page.clamp(0, widget.itemCount - 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pages.hasClients) _pages.jumpToPage(_pageFor(_page));
      });
    }
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    _position.dispose();
    _ownSlides?.dispose();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final every = widget.autoplayInterval;
    if (every == null || !_running) return;
    _timer = Timer.periodic(every, (_) => _turn(1, wrap: true));
  }

  void _update(VoidCallback change) {
    setState(change);
    _schedule();
  }

  void _moved() {
    if (!_pages.hasClients || !_pages.position.haveDimensions) return;
    final p = _pages.page;
    if (p == null) return;
    _position.value = _looping ? p % widget.itemCount : p;
  }

  // The page shown, or the one it is nearest while it moves.
  int get _at => _pages.hasClients && _pages.position.haveDimensions
      ? _pages.page!.round()
      : _pageFor(_page);

  void _show(int page) {
    if (!_pages.hasClients) return;
    if (_still) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: widget.duration,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goTo(int slide) {
    final n = widget.itemCount;
    if (n == 0) return;
    final to = slide.clamp(0, n - 1);
    if (!_looping) return _show(to);
    // Round the nearer way.
    final at = _at;
    var by = to - at % n;
    if (by > n / 2) by -= n;
    if (by < -n / 2) by += n;
    _show(at + by);
  }

  void _turn(int by, {bool wrap = false}) {
    if (_looping) return _show(_at + by);
    final n = widget.itemCount;
    var to = _page + by;
    if (to < 0 || to >= n) {
      if (!(widget.loop || wrap)) return;
      to = to % n;
    }
    _show(to);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      _turn(rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _turn(rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      _goTo(0);
    } else if (key == LogicalKeyboardKey.end) {
      _goTo(widget.itemCount - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.itemCount;
    final viewport = Focus(
      focusNode: _slides,
      autofocus: widget.autofocus && widget.focusable,
      canRequestFocus: widget.focusable,
      skipTraversal: !widget.focusable,
      includeSemantics: false,
      onKeyEvent: _key,
      onFocusChange: (on) => setState(() {
        _slidesFocused = on;
        _focused =
            on &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional;
      }),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollStartNotification && n.dragDetails != null) {
            _update(() => _dragging = true);
          } else if (n is ScrollEndNotification && _dragging) {
            _update(() => _dragging = false);
          }
          return false;
        },
        child: PageView.builder(
          controller: _pages,
          itemCount: _looping ? null : n,
          clipBehavior: widget.clipBehavior,
          onPageChanged: (page) {
            final p = _slideOf(page);
            // A turn the reader made (a key, a control, a swipe) is told;
            // autoplay's are not, as a live region turns off while a
            // carousel rotates.
            if (!_running) designAnnounce(context, _slideLabel(p, n));
            setState(() => _page = p);
            widget.onPageChanged?.call(p);
          },
          itemBuilder: (context, page) {
            final i = _slideOf(page);
            return Semantics(
              container: true,
              label: _slideLabel(i, n),
              child: widget.itemBuilder(context, i),
            );
          },
        ),
      ),
    );
    final controls = DesignCarouselControls(
      page: _page,
      count: n,
      position: _position,
      previous: widget.loop || _page > 0 ? () => _turn(-1) : null,
      next: widget.loop || _page < n - 1 ? () => _turn(1) : null,
      goToPage: _goTo,
      playing: _playing && widget.autoplayInterval != null,
      togglePlay: widget.autoplayInterval == null
          ? null
          : () => _update(() {
              _playChosen = true;
              _playing = !_playing;
            }),
      focused: _focused,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          widget.semanticLabel ?? DesignLocalizations.of(context).carouselLabel,
      // The named carousel is the tab stop a screen reader hears, and says
      // when the keyboard is on its slides.
      focusable: widget.focusable,
      focused: widget.focusable ? _slidesFocused : null,
      onFocus: widget.focusable ? _slides.requestFocus : null,
      child: MouseRegion(
        onEnter: (_) => _update(() => _hovered = true),
        onExit: (_) => _update(() => _hovered = false),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (on) => _update(() => _focusWithin = on),
          child:
              widget.layoutBuilder?.call(context, viewport, controls) ??
              viewport,
        ),
      ),
    );
  }
}
