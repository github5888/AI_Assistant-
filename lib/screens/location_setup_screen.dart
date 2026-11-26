import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_state.dart';
import '../device_location.dart';
import '../theme.dart';
import '../widgets.dart';
import 'checkout_flow.dart';
import 'location_picker_screen.dart';

/// A single customer action starts GPS, asks Android permission only when needed,
/// then opens the map pin so the customer can confirm the actual entrance.
class DeliveryLocationSetupScreen extends StatefulWidget {
  const DeliveryLocationSetupScreen({super.key});

  @override
  State<DeliveryLocationSetupScreen> createState() => _DeliveryLocationSetupScreenState();
}

class _DeliveryLocationSetupScreenState extends State<DeliveryLocationSetupScreen> {
  DeliveryLocation? _location;
  String? _error;
  bool _busy = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_locateAndOpenMap()));
    }
  }

  Future<void> _locateAndOpenMap() async {
    if (_busy || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      final location = await DeliveryLocation.current();
      if (!mounted) return;
      setState(() => _location = location);
      await _openMap(location);
    } on DeliveryLocationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not get your current location. You can enter your address manually.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMap(DeliveryLocation location) async {
    final selected = await pushScreen<DeliveryPin>(context, LocationPickerScreen(
      latitude: location.latitude,
      longitude: location.longitude,
      accuracyMeters: location.accuracyMeters,
    ));
    if (selected == null || !mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      final pin = await DeliveryLocation.fromCoordinates(selected.latitude, selected.longitude);
      final state = AppScope.of(context);
      final previous = state.savedShippingAddress ?? const <String, Object?>{};
      String previousText(String key, [String? fallback]) {
        final value = previous[key] ?? (fallback == null ? null : previous[fallback]);
        return value is String ? value : '';
      }
      final name = previousText('fullName', 'name').isNotEmpty
          ? previousText('fullName', 'name') : state.customer?.name ?? '';
      await state.saveShippingAddress({
        'name': name,
        'fullName': name,
        'phone': previousText('phone', 'mobile'),
        'mobile': previousText('phone', 'mobile'),
        'address': pin.street.isNotEmpty ? pin.street : previousText('addressLine1', 'address'),
        'addressLine1': pin.street.isNotEmpty ? pin.street : previousText('addressLine1', 'address'),
        'street': pin.street.isNotEmpty ? pin.street : previousText('street', 'address'),
        if (previousText('landmark', 'addressLine2').isNotEmpty)
          'landmark': previousText('landmark', 'addressLine2'),
        'city': pin.city.isNotEmpty ? pin.city : previousText('city'),
        'state': pin.state.isNotEmpty ? pin.state : previousText('state'),
        'pincode': pin.pincode.isNotEmpty ? pin.pincode : previousText('pincode', 'postalCode'),
        'postalCode': pin.pincode.isNotEmpty ? pin.pincode : previousText('pincode', 'postalCode'),
        'country': 'India',
        'type': previousText('type').isNotEmpty ? previousText('type') : 'home',
        'location': pin.toJson(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = 'The pin could not be saved. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(child: Column(children: [
    const AppTopBar(title: 'Delivery location', subtitle: 'One quick step to find your address', back: true),
    Expanded(child: Center(child: Padding(
      padding: const EdgeInsets.all(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 62, height: 62,
            decoration: const BoxDecoration(color: Color(0xFFEAF6EE), shape: BoxShape.circle),
            child: Icon(_busy ? Icons.my_location_rounded : Icons.location_on_outlined,
              color: AppColors.green, size: 31)),
          const SizedBox(height: 14),
          Text(_busy ? 'Finding your location…' : 'Pin your delivery entrance',
            textAlign: TextAlign.center, style: displayStyle(size: 21)),
          const SizedBox(height: 7),
          Text(_error ?? (_location == null
              ? 'Allow location once and we’ll open the map at your current position.'
              : 'Your position is ready. Confirm the exact building entrance on the map.'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted)),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (!_busy && _location != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => _openMap(_location!),
              icon: const Icon(Icons.map_outlined),
              label: const Text('CONFIRM PIN ON MAP'),
            )),
          ],
          if (!_busy && _error != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: _locateAndOpenMap,
              icon: const Icon(Icons.refresh_rounded), label: const Text('TRY LOCATION AGAIN'),
            )),
            SizedBox(width: double.infinity, child: TextButton.icon(
              onPressed: () async {
                if (_error?.contains('app settings') == true) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
              },
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('OPEN LOCATION SETTINGS'),
            )),
            SizedBox(width: double.infinity, child: TextButton(
              onPressed: () => pushScreen(context, const InAppCheckoutScreen()),
              child: const Text('Enter address manually instead'),
            )),
          ],
        ]),
      ),
    ))),
  ]));
}
