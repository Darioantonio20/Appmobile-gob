import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/app_logger.dart';

/// One GPS fix: `null` fields mean no location was captured.
typedef GeoFix = ({double latitude, double longitude});

/// Best-effort GPS capture for the survey audit trail (Módulo C).
///
/// Every failure mode — services disabled, permission denied, no fix
/// within the time budget, an unexpected platform error — resolves to
/// `null` rather than throwing. A missing GPS fix must never block a
/// surveyor from completing their work; that's the explicit "fallback si
/// el usuario no tiene GPS de alta precisión" requirement.
class LocationService {
  final _log = AppLogger.of('LocationService');

  Future<GeoFix?> getCurrentFix() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _log.info('Servicios de ubicación desactivados; se continúa sin GPS.');
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _log.info('Permiso de ubicación no concedido; se continúa sin GPS.');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      // Covers TimeoutException (no fix within timeLimit) and any
      // platform-specific location error.
      _log.warning('No se pudo obtener la ubicación', e);
      return null;
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());
