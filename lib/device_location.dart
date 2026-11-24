import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryLocation {
  static const _geocoding = MethodChannel('com.itsclear.app/geocoding');

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.street = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String street;
  final String city;
  final String state;
  final String pincode;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
  };

  static Future<DeliveryLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DeliveryLocationException('Turn on your device location and try again.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeliveryLocationException('Location permission was denied. You can enter the address manually.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeliveryLocationException('Allow location access in app settings, or enter the address manually.');
    }
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      throw const DeliveryLocationException('Location permission is unavailable. You can enter the address manually.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 25),
      ),
    );

    return fromCoordinates(position.latitude, position.longitude,
      accuracyMeters: position.accuracy);
  }

  static Future<DeliveryLocation> fromCoordinates(double latitude, double longitude, {
    double? accuracyMeters,
  }) async {
    if (!latitude.isFinite || !longitude.isFinite || latitude < -90 || latitude > 90 ||
        longitude < -180 || longitude > 180) {
      throw const DeliveryLocationException('Choose a valid point on the map.');
    }
    var street = '';
    var city = '';
    var state = '';
    var pincode = '';
    try {
      final place = await _geocoding.invokeMapMethod<String, Object?>(
        'reverseGeocode', {'latitude': latitude, 'longitude': longitude},
      );
      String field(String key) {
        final value = place?[key];
        return value is String ? value : '';
      }
      street = field('street');
      city = field('city');
      state = field('state');
      pincode = field('pincode');
    } on PlatformException {
      // GPS coordinates remain valid if reverse geocoding is unavailable.
    } on MissingPluginException {
      // Tests and non-Android builds can still use the manually entered address.
    } catch (_) {
      // GPS coordinates remain valid if reverse geocoding is unavailable.
    }

    return DeliveryLocation(latitude: latitude, longitude: longitude,
      accuracyMeters: accuracyMeters, street: street, city: city, state: state, pincode: pincode);
  }
}

class DeliveryLocationException implements Exception {
  const DeliveryLocationException(this.message);
  final String message;
}
