import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';
import '../widgets.dart';

class DeliveryPin {
  const DeliveryPin(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Lets customers place their own drop pin on a real, attributed OpenStreetMap.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _pin;

  @override
  void initState() {
    super.initState();
    _pin = LatLng(widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) => AppPage(child: Column(children: [
    const AppTopBar(title: 'Set delivery pin', subtitle: 'Move the map and tap your entrance', back: true),
    Expanded(child: FlutterMap(
      options: MapOptions(
        initialCenter: _pin,
        initialZoom: 17,
        minZoom: 4,
        maxZoom: 19,
        onTap: (_, point) => setState(() => _pin = point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.itsclear.app',
          maxZoom: 19,
        ),
        MarkerLayer(markers: [
          Marker(
            point: _pin,
            width: 52,
            height: 56,
            alignment: Alignment.bottomCenter,
            child: const Icon(Icons.location_pin, size: 48, color: AppColors.orange),
          ),
        ]),
        RichAttributionWidget(attributions: [
          TextSourceAttribution('© OpenStreetMap contributors', onTap: () {
            launchUrl(Uri.https('www.openstreetmap.org', '/copyright'),
              mode: LaunchMode.externalApplication);
          }),
        ]),
      ],
    )),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Delivery entrance pin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('${_pin.latitude.toStringAsFixed(6)}, ${_pin.longitude.toStringAsFixed(6)}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted, fontFeatures: [FontFeature.tabularFigures()])),
        if (widget.accuracyMeters != null) ...[
          const SizedBox(height: 3),
          Text('Initial GPS accuracy: ±${widget.accuracyMeters!.round()} m · tap the exact building entrance to adjust.',
            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ] else
          const Padding(padding: EdgeInsets.only(top: 3), child: Text(
            'Tap the map at the building entrance; verify the pin before saving.',
            style: TextStyle(fontSize: 10, color: AppColors.muted))),
        const SizedBox(height: 10),
        SizedBox(height: 48, child: FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(DeliveryPin(_pin.latitude, _pin.longitude)),
          icon: const Icon(Icons.check_rounded),
          label: const Text('SAVE THIS DELIVERY PIN'),
        )),
      ]),
    ),
  ]));
}
