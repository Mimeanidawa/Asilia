import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// True on Linux, Windows, macOS — no bundled Google Fonts assets.
bool get isDesktop =>
    !kIsWeb &&
    (Platform.isLinux || Platform.isWindows || Platform.isMacOS);

/// Use system/bundled fonts instead of GoogleFonts network fetch.
bool get useSystemFonts => kIsWeb || isDesktop;
