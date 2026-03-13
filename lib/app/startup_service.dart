import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum TrackingAuthorizationStatus {
  notDetermined,
  restricted,
  denied,
  authorized,
  notSupported,
}

class StartupService {
  StartupService._();

  static final StartupService instance = StartupService._();
  static const MethodChannel _channel = MethodChannel('app.tracking/att');
  Future<void>? _startupFuture;

  Future<void> prepare() {
    return _startupFuture ??= _prepareInternal();
  }

  Future<void> _prepareInternal() async {
    if (Platform.isIOS) {
      await _requestTrackingPermissionIfNeeded();
    }
    await MobileAds.instance.initialize();
  }

  Future<TrackingAuthorizationStatus> _trackingAuthorizationStatus() async {
    try {
      final value = await _channel.invokeMethod<int>(
        'trackingAuthorizationStatus',
      );
      return _mapStatus(value);
    } on PlatformException {
      return TrackingAuthorizationStatus.notSupported;
    }
  }

  Future<void> _requestTrackingPermissionIfNeeded() async {
    final status = await _trackingAuthorizationStatus();
    if (status != TrackingAuthorizationStatus.notDetermined) return;
    try {
      await _channel.invokeMethod<int>('requestTrackingAuthorization');
    } on PlatformException {
      // If the OS ignores the request, continue app startup without blocking ads init.
    }
  }

  TrackingAuthorizationStatus _mapStatus(int? rawValue) {
    switch (rawValue) {
      case 0:
        return TrackingAuthorizationStatus.notDetermined;
      case 1:
        return TrackingAuthorizationStatus.restricted;
      case 2:
        return TrackingAuthorizationStatus.denied;
      case 3:
        return TrackingAuthorizationStatus.authorized;
      default:
        return TrackingAuthorizationStatus.notSupported;
    }
  }
}
