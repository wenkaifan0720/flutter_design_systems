/// What a render asks of Minimal's gallery off the web, through the
/// environment. The web version is host_bridge_web.dart.
library;

import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

/// Which way a page demo reads (`TEMPLATE_DIRECTION=rtl` on a render;
/// left to right by default), so a render can show a page right to left.
TextDirection get templateDirection =>
    Platform.environment['TEMPLATE_DIRECTION'] == 'rtl'
    ? TextDirection.rtl
    : TextDirection.ltr;
