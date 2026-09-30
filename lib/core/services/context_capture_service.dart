import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ContextCaptureService {
  static final ContextCaptureService instance = ContextCaptureService._();
  ContextCaptureService._();

  final _networkInfo = NetworkInfo();

  /// Captures GPS + WiFi. Retries GPS up to [maxRetries] times with [retryDelay].
  Future<CapturedContext> capture({
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 30),
  }) async {
    final wifi = await _getWifiName();
    Position? position;

    for (int i = 0; i < maxRetries; i++) {
      position = await _getPosition();
      if (position != null) break;
      if (i < maxRetries - 1) await Future.delayed(retryDelay);
    }

    String? locationName;
    if (position != null) {
      locationName = await _reverseGeocode(position.latitude, position.longitude);
    }

    return CapturedContext(
      latitude: position?.latitude,
      longitude: position?.longitude,
      locationName: locationName,
      wifiName: wifi,
    );
  }

  Future<Position?> _getPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      final parts = [
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality,
      ];
      return parts.isNotEmpty ? parts.join(', ') : p.administrativeArea;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getWifiName() async {
    try {
      final ssid = await _networkInfo.getWifiName();
      // Android returns SSID wrapped in quotes — strip them
      return ssid?.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }
}

class CapturedContext {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? wifiName;

  const CapturedContext({
    this.latitude,
    this.longitude,
    this.locationName,
    this.wifiName,
  });
}
