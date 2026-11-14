/// What a render asks of Minimal's gallery, on the web: the lab's preview
/// asks nothing through the environment, so every page demo reads left to
/// right.
library;

import 'package:flutter/widgets.dart';

/// Which way a page demo reads: always left to right on the web.
TextDirection get templateDirection => TextDirection.ltr;
