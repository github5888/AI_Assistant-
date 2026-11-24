import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

/// In-app route overview for a server-confirmed order. It only labels GPS as
/// live when the order response actually includes a current location.
class TrackingMapCard extends StatelessWidget {
  const TrackingMapCard({super.key, required this.order});

  final Map<String, dynamic> order;

  static Map? _map(Object? value) => value is Map ? value : null;

  static double? _coordinate(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite ? number : null;
  }

  String _destination() {
    final address = _map(order['shippingAddress']);
    if (address == null) return '';
    final parts = [
      address['addressLine1'] ?? address['street'] ?? address['address'],
      address['city'],
      address['state'],
      address['pincode'] ?? address['postalCode'],
    ].whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty);
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _map(order['tracking']) ?? const {};
    final location = _map(tracking['currentLocation']) ??
        _map(tracking['location']) ?? _map(order['currentLocation']);
    final latitude = _coordinate(location?['latitude'] ?? location?['lat']);
    final longitude = _coordinate(location?['longitude'] ?? location?['lng'] ?? location?['lon']);
    final hasGps = latitude != null && longitude != null &&
        latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
    final rawStatus = (order['orderStatus'] is String ? order['orderStatus'] as String : 'confirmed')
        .toLowerCase();
    final statusLabel = hasGps ? 'GPS update received'
        : const {'confirmed', 'farm_queued', 'queued'}.contains(rawStatus)
            ? 'Dispatch queued' : 'Route preview';
    final destination = _destination();
    final shippingAddress = _map(order['shippingAddress']);
    final dropPin = _map(shippingAddress?['location']);
    final dropLatitude = _coordinate(dropPin?['latitude'] ?? dropPin?['lat']);
    final dropLongitude = _coordinate(dropPin?['longitude'] ?? dropPin?['lng'] ?? dropPin?['lon']);
    final hasDropPin = dropLatitude != null && dropLongitude != null &&
        dropLatitude >= -90 && dropLatitude <= 90 &&
        dropLongitude >= -180 && dropLongitude <= 180;
    final gpsUpdatedAt = location?['updatedAt'] ?? location?['timestamp'];
    final eta = order['estimatedDelivery'] is String &&
        (order['estimatedDelivery'] as String).trim().isNotEmpty
        ? (order['estimatedDelivery'] as String).trim() : 'Updates after dispatch';
    final distance = tracking['distanceKm'] ?? order['distanceKm'];
    final distanceLabel = distance is num && distance.isFinite && distance >= 0
        ? '${distance.toStringAsFixed(1)} km' : 'Store update pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.route_rounded, color: AppColors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Delivery route', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(hasGps ? 'Last location shared by partner' : 'Route overview · not live GPS',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: hasGps ? const Color(0xFFE8F7EF) : const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 7, color: hasGps ? AppColors.green : AppColors.gold),
              const SizedBox(width: 5),
              Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                color: hasGps ? AppColors.green : const Color(0xFF805417))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 214,
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(
                painter: const _DeliveryRoutePainter(),
              )),
              Positioned(left: 10, top: 10, child: _MapLabel(
                icon: Icons.storefront_rounded,
                title: 'itsclear dispatch', subtitle: 'Starting point',
              )),
              Positioned(right: 10, top: 10, child: _MapLabel(
                icon: Icons.location_on_rounded,
                title: hasDropPin ? 'Exact drop pin' : 'Delivery address',
                subtitle: destination.isEmpty ? 'Address on your order' : _shortAddress(destination),
                alignRight: true,
              )),
              Positioned(left: 10, bottom: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.96),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 3))]),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.gold, size: 16),
                  const SizedBox(width: 6),
                  Text(eta, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
              )),
              if (destination.isNotEmpty || hasDropPin)
                Positioned(right: 10, bottom: 10, child: FilledButton.tonalIcon(
                  onPressed: () => _openMaps(context, destination,
                    latitude: hasDropPin ? dropLatitude : null,
                    longitude: hasDropPin ? dropLongitude : null),
                  icon: const Icon(Icons.near_me_outlined, size: 15),
                  label: const Text('Open Maps'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                )),
            ]),
          ),
        ),
        const SizedBox(height: 9),
        Row(children: [
          const Icon(Icons.straighten_rounded, size: 15, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(distanceLabel, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
        if (hasDropPin) ...[
          const SizedBox(height: 4),
          Text('Delivery pin · ${dropLatitude!.toStringAsFixed(6)}, ${dropLongitude!.toStringAsFixed(6)}'
              '${dropPin?['accuracyMeters'] is num ? ' · ±${(dropPin?['accuracyMeters'] as num).round()} m' : ''}',
            style: const TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w700)),
        ],
        if (hasGps) ...[
          const SizedBox(height: 7),
          Text('Partner GPS · ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
              '${gpsUpdatedAt is String && gpsUpdatedAt.isNotEmpty ? ' · updated $gpsUpdatedAt' : ''}',
            style: const TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w700)),
          Align(alignment: Alignment.centerLeft, child: TextButton.icon(
            onPressed: () => _openCoordinate(context, latitude!, longitude!),
            icon: const Icon(Icons.my_location_rounded, size: 15),
            label: const Text('Open partner pin in Maps'),
          )),
        ],
        const SizedBox(height: 4),
        Text(hasGps ? 'Schematic route · GPS coordinates supplied by store'
            : 'Schematic preview · waiting for a GPS update',
          style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      ]),
    );
  }

  String _shortAddress(String value) {
    final words = value.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();
    if (words.length <= 2) return value;
    return '${words[words.length - 2]}, ${words.last}';
  }

  Future<void> _openCoordinate(BuildContext context, double latitude, double longitude) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}',
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open Google Maps on this device.'),
      ));
    }
  }

  Future<void> _openMaps(BuildContext context, String destination, {
    double? latitude, double? longitude,
  }) async {
    final exactDestination = latitude != null && longitude != null
        ? '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}'
        : destination;
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': exactDestination,
    });
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open Google Maps on this device.'),
        ));
      }
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open Google Maps on this device.'),
      ));
    }
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel({required this.icon, required this.title, required this.subtitle, this.alignRight = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 145),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.96), borderRadius: BorderRadius.circular(11),
      boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 10, offset: Offset(0, 2))]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: AppColors.green),
      const SizedBox(width: 6),
      Flexible(child: Column(crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w700)),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.ink, fontWeight: FontWeight.w900)),
        ])),
    ]),
  );
}

class _DeliveryRoutePainter extends CustomPainter {
  const _DeliveryRoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFF1F3EE));
    final parkPaint = Paint()..color = const Color(0xFFDDEBD8).withOpacity(.75);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .02, size.height * .48, size.width * .23, size.height * .34),
      const Radius.circular(20)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .65, size.height * .42, size.width * .33, size.height * .48),
      const Radius.circular(26)), parkPaint);

    final roads = <Path>[
      Path()..moveTo(-10, size.height * .34)..cubicTo(size.width * .24, size.height * .20,
        size.width * .42, size.height * .38, size.width + 10, size.height * .17),
      Path()..moveTo(-10, size.height * .85)..cubicTo(size.width * .25, size.height * .65,
        size.width * .62, size.height * .94, size.width + 10, size.height * .72),
      Path()..moveTo(size.width * .45, -10)..cubicTo(size.width * .35, size.height * .35,
        size.width * .62, size.height * .60, size.width * .48, size.height + 10),
    ];
    for (final road in roads) {
      canvas.drawPath(road, Paint()..color = Colors.white..strokeWidth = 10
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      canvas.drawPath(road, Paint()..color = const Color(0xFFE2E7E0)..strokeWidth = 1.2
        ..style = PaintingStyle.stroke);
    }

    final route = Path()
      ..moveTo(size.width * .17, size.height * .75)
      ..cubicTo(size.width * .34, size.height * .72, size.width * .36, size.height * .45,
        size.width * .53, size.height * .48)
      ..cubicTo(size.width * .69, size.height * .52, size.width * .68, size.height * .25,
        size.width * .84, size.height * .29);
    canvas.drawPath(route, Paint()..color = Colors.white..strokeWidth = 11
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    final metrics = route.computeMetrics().toList();
    for (final metric in metrics) {
      for (var offset = 0.0; offset < metric.length; offset += 13) {
        final end = math.min(offset + 7, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(offset, end), Paint()
          ..color = const Color(0xFF31A77C)..strokeWidth = 4
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      }
    }

    _drawPin(canvas, Offset(size.width * .17, size.height * .75), const Color(0xFF219A72), Icons.storefront_rounded);
    _drawPin(canvas, Offset(size.width * .84, size.height * .29), const Color(0xFFFFA51E), Icons.location_on_rounded);
  }

  void _drawPin(Canvas canvas, Offset center, Color color, IconData icon) {
    canvas.drawCircle(center, 15, Paint()..color = color.withOpacity(.16));
    canvas.drawCircle(center, 9, Paint()..color = Colors.white);
    canvas.drawCircle(center, 6, Paint()..color = color);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr,
      text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(
        fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 10, color: Colors.white)));
    textPainter.layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DeliveryRoutePainter oldDelegate) => false;
}
