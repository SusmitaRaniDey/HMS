import 'dart:io';
import 'dart:ui';

import 'package:window_manager/window_manager.dart';

Future<void> desktopWindowInit() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1400, 900),
      minimumSize: Size(1100, 700),
      center: true,
      title: 'HealthGrid Admin Panel',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
