
import 'dart:typed_data';

class InstalledAppWrapper {
  final String packageName;
  final String? appName;
  final bool? isSystemApp;
  final Uint8List? iconBytes;

  InstalledAppWrapper({
    required this.packageName,
    this.appName,
    this.isSystemApp,
    this.iconBytes,
  });
}
