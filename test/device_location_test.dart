import 'package:flutter_test/flutter_test.dart';
import 'package:itsclear_app/device_location.dart';

void main() {
  test('retains a user-adjusted map pin without inventing GPS accuracy', () async {
    final location = await DeliveryLocation.fromCoordinates(26.8467, 80.9462);
    expect(location.latitude, 26.8467);
    expect(location.longitude, 80.9462);
    expect(location.accuracyMeters, isNull);
    expect(location.toJson(), {'latitude': 26.8467, 'longitude': 80.9462});
  });

  test('rejects map coordinates outside valid latitude and longitude ranges', () async {
    await expectLater(DeliveryLocation.fromCoordinates(95, 181),
        throwsA(isA<DeliveryLocationException>()));
  });
}
