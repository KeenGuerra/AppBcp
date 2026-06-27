// connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return !_isOffline(result);
    });
  }

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !_isOffline(result);
  }

  bool _isOffline(dynamic result) {
    if (result is List) {
      if (result.isEmpty) return true;
      return result.every((element) => element == ConnectivityResult.none);
    }
    return result == ConnectivityResult.none;
  }
}
