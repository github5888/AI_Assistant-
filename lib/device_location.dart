import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryLocation {
  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    this.street = '',
    this.city = '',
    this.state = '',
    this.pincode = '',
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String street;
  final String city;
  final String state;
  final String pincode;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracyMeters': accuracyMeters,
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

    var street = '';
    var city = '';
    var state = '';
    var pincode = '';
    try {
      final places = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (places.isNotEmpty) {
        final place = places.first;
        street = [place.subThoroughfare, place.thoroughfare, place.subLocality]
            .whereType<String>().map((part) => part.trim())
            .where((part) => part.isNotEmpty).toSet().join(', ');
        city = (place.locality?.trim().isNotEmpty == true ? place.locality : place.subAdministrativeArea)?.trim() ?? '';
        state = place.administrativeArea?.trim() ?? '';
        pincode = place.postalCode?.trim() ?? '';
      }
    } catch (_) {
      // GPS coordinates are still useful if reverse geocoding is unavailable.
    }

    return DeliveryLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      street: street,
      city: city,
      state: state,
      pincode: pincode,
    );
  }
}

class DeliveryLocationException implements Exception {
  const DeliveryLocationException(this.message);
  final String message;
}
