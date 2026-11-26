import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart' show RawWidgetsLocalizations;
import 'package:web/web.dart' as web;

import 'preview_look.dart';

void runPreview(Map<String, Future<PreviewLook> Function()> lookLoaders) {
  // The fragment addresses the specimen. Opening a modal uses an in-app
  // Navigator and must leave that public address intact.
  setUrlStrategy(null);
  runApp(Preview(lookLoaders: lookLoaders));
}

class Preview extends StatefulWidget {
  const Preview({required this.lookLoaders, super.key});

  final Map<String, Future<PreviewLook> Function()> lookLoaders;

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final _semantics = SemanticsBinding.instance.ensureSemantics();
  final _libraries = <String, Future<PreviewLook>>{};
  late final StreamSubscription<web.Event> _locationChanges;
  Uri _route = Uri();
  var _navigator = GlobalKey<NavigatorState>();
  String? _lookId;
  Future<PreviewLook>? _library;

  @override
  void initState() {
    super.initState();
    _readLocation();
    _locationChanges = web.EventStreamProviders.hashChangeEvent
        .forTarget(web.window)
        .listen((_) {
          setState(_readLocation);
        });
  }

  void _readLocation() {
    final next = Uri.tryParse(Uri.base.fragment) ?? Uri();
    final paletteChanged =
        next.queryParameters['theme'] != _route.queryParameters['theme'];
    // Modal helpers capture a look's palette when pushing the route.
    if (next.path != _route.path ||
        (paletteChanged && (_navigator.currentState?.canPop() ?? false))) {
      _navigator = GlobalKey<NavigatorState>();
    }
    _route = next;
    final look = _route.pathSegments.firstOrNull;
    if (look != _lookId) {
      _lookId = look;
      final load = widget.lookLoaders[look];
      _library = look != null && load != null
          ? _libraries.putIfAbsent(look, load)
          : null;
    }
  }

  @override
  void dispose() {
    _locationChanges.cancel();
    _semantics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = _route.queryParameters;
    final night = params['theme'] == 'night';
    final brightness = night ? Brightness.dark : Brightness.light;
    final scale = params['scale'] == '2' ? 2.0 : 1.0;
    final direction = params['dir'] == 'rtl'
        ? TextDirection.rtl
        : TextDirection.ltr;
    final path = _route.pathSegments.skip(1).join('/');

    return FutureBuilder<PreviewLook>(
      future: _library,
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final look = loading ? null : snapshot.data;
        final example = look?.examples[path];
        return MaterialApp(
          key: ValueKey('$_lookId/$path'),
          navigatorKey: _navigator,
          debugShowCheckedModeBanner: false,
          title: look == null
              ? 'Component preview'
              : '${look.name} · ${_route.pathSegments.elementAtOrNull(1) ?? 'Component'} preview',
          initialRoute: '/',
          localizationsDelegates: const [RawWidgetsLocalizations.delegate],
          theme: ThemeData(brightness: brightness),
          builder: (context, navigator) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scale),
                platformBrightness: brightness,
              ),
              child: Directionality(
                textDirection: direction,
                child: look?.wrapTheme(brightness, navigator!) ?? navigator!,
              ),
            );
          },
          home: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(
              alignment: params['align'] == 'top'
                  ? Alignment.topCenter
                  : Alignment.center,
              child: snapshot.hasError && !loading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'The preview could not be loaded.',
                          style: TextStyle(
                            color: Color(0xff53565b),
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _libraries.remove(_lookId);
                            _lookId = null;
                            _readLocation();
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : example != null
                  ? Builder(builder: example)
                  : Text(
                      loading ? 'Loading preview…' : 'Example not found.',
                      style: const TextStyle(
                        color: Color(0xff53565b),
                        fontSize: 16,
                        fontFamily: 'Roboto',
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
