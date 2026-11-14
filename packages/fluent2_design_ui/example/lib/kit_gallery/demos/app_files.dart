/// The Screens group's Northwind Files, the list: a search, the sets as tabs and the files in dated groups, each with its size.
/// The whole app stands around it: the tab bar on a phone, the nav pane
/// from 1024 wide, the other roots a tap away.
library;

import 'package:flutter/material.dart';

import '../kit.dart';

Widget kitAppFilesDemo(Brightness brightness) =>
    KitNorthwind(brightness: brightness, root: KitNorthwindRoot.files);
