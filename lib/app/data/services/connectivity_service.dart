import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/widgets/custom_snackbar.dart';

/// Service monitoring network state across Mobile and Web.
class ConnectivityService extends GetxService {
  final Connectivity _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  final Rx<List<ConnectivityResult>> connectionTypes = Rx<List<ConnectivityResult>>([ConnectivityResult.wifi]);
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _initialCheckDone = false;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      if (kDebugMode) {
        print('Connectivity check failed: $e');
      }
      isConnected.value = true; // Fallback to online
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    connectionTypes.value = results;
    final bool hasConnection = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );

    final bool wasConnected = isConnected.value;
    isConnected.value = hasConnection;

    // Show alerts only after initial check when status actually changes
    if (_initialCheckDone && wasConnected != hasConnection) {
      if (!hasConnection) {
        CustomSnackbar.showWarning(
          title: 'Network Disconnected',
          message: 'You are currently offline. Cached data may be displayed.',
        );
      } else {
        CustomSnackbar.showSuccess(
          title: 'Back Online',
          message: 'Network connection restored successfully.',
        );
      }
    }
    _initialCheckDone = true;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
