// api_config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8003';
    }
    if (Platform.isAndroid) {
      // Android Emulator connects to localhost via 10.0.2.2
      return 'http://10.0.2.2:8003';
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8003';
    }
    return 'http://127.0.0.1:8003';
  }
}
