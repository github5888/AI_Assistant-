import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'location_setup_screen.dart';

/// Gives customers explicit controls for OS notification and location access.
/// Permissions are always granted by the customer through the system UI.
class DeviceAccessScreen extends StatefulWidget {
  const DeviceAccessScreen({super.key});

  @override
  State<DeviceAccessScreen> createState() => _DeviceAccessScreenState();
}

class _DeviceAccessScreenState extends State<DeviceAccessScreen>
    with WidgetsBindingObserver {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  AuthorizationStatus? _notificationStatus;
  LocationPermission? _locationPermission;
  bool? _locationServiceEnabled;
  bool _checking = true;
  bool _working = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      final results = await Future.wait<Object>([
        _messaging.getNotificationSettings(),
        Geolocator.isLocationServiceEnabled(),
        Geolocator.checkPermission(),
      ]);
      if (!mounted) return;
      setState(() {
        _notificationStatus = (results[0] as NotificationSettings).authorizationStatus;
        _locationServiceEnabled = results[1] as bool;
        _locationPermission = results[2] as LocationPermission;
        _checking = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _enableNotifications() async {
    if (_working) return;
    setState(() { _working = true; _message = null; });
    try {
      var status = (await _messaging.getNotificationSettings()).authorizationStatus;
      if (status == AuthorizationStatus.notDetermined) {
        status = (await _messaging.requestPermission(
          alert: true, badge: true, sound: true, provisional: false,
        )).authorizationStatus;
      }
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        final refreshRegistration = AppScope.of(context).refreshPushRegistration;
        try {
          await refreshRegistration?.call();
          if (mounted) setState(() => _message =
              'Notifications are allowed on this device.');
        } catch (_) {
          if (mounted) setState(() => _message =
              'Device notifications are allowed, but account registration could not be refreshed.');
        }
      } else {
        await Geolocator.openAppSettings();
        if (mounted) setState(() => _message =
            'Allow notifications in your device app settings, then return here.');
      }
    } catch (_) {
      if (mounted) setState(() => _message =
          'Could not update notification access. Check your device settings.');
    } finally {
      if (mounted) {
        setState(() => _working = false);
        await _refreshStatus();
      }
    }
  }

  Future<void> _enableLocation() async {
    if (_working) return;
    setState(() { _working = true; _message = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        if (mounted) setState(() => _message =
            'Turn on Location in device settings, then tap Set delivery location.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (mounted) setState(() => _message =
            'Allow location in app settings, then return and try again.');
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _message =
            'Location permission was not granted. You can still enter your address manually.');
        return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) setState(() => _message =
            'Location access is unavailable. You can enter your address manually.');
        return;
      }
      if (mounted) {
        await pushScreen<void>(context, const DeliveryLocationSetupScreen());
        if (mounted) setState(() => _message =
            'You can review or change your saved delivery pin in Profile.');
      }
    } catch (_) {
      if (mounted) setState(() => _message =
          'Could not update location access. You can enter your address manually.');
    } finally {
      if (mounted) {
        setState(() => _working = false);
        await _refreshStatus();
      }
    }
  }

  String get _notificationLabel => switch (_notificationStatus) {
    AuthorizationStatus.authorized => 'Allowed on this device',
    AuthorizationStatus.provisional => 'Quiet notifications are allowed',
    AuthorizationStatus.denied => 'Off — enable in device app settings',
    AuthorizationStatus.notDetermined => 'Not enabled yet',
    null => 'Status unavailable',
  };

  String get _locationLabel {
    if (_locationServiceEnabled == false) return 'Device Location is turned off';
    return switch (_locationPermission) {
      LocationPermission.whileInUse || LocationPermission.always =>
        'Location permission is allowed',
      LocationPermission.denied => 'Permission needed to set a delivery pin',
      LocationPermission.deniedForever => 'Off — enable in device app settings',
      LocationPermission.unableToDetermine || null => 'Status unavailable',
    };
  }

  bool get _notificationsAllowed =>
      _notificationStatus == AuthorizationStatus.authorized ||
      _notificationStatus == AuthorizationStatus.provisional;

  bool get _locationAllowed => _locationServiceEnabled == true &&
      (_locationPermission == LocationPermission.whileInUse ||
       _locationPermission == LocationPermission.always);

  @override
  Widget build(BuildContext context) => ListScaffold(
    title: 'Notifications & location',
    subtitle: 'Manage device access for your account',
    children: [
      SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Notifications', style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 5),
        Text(_checking ? 'Checking device permission…' : _notificationLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 6),
        const Text('Allow order and delivery alerts. This is the device permission only; actual delivery also depends on account and server support.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: _checking || _working ? null : _enableNotifications,
          icon: Icon(_notificationsAllowed ? Icons.refresh_rounded : Icons.notifications_active_outlined),
          label: Text(_notificationsAllowed ? 'REFRESH NOTIFICATION SETUP' : 'TURN ON NOTIFICATIONS'),
        )),
      ])),
      SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Delivery location', style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink)),
        const SizedBox(height: 5),
        Text(_checking ? 'Checking device permission…' : _locationLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 6),
        const Text('Use your current position to set or update a delivery pin. You can also enter your address manually.',
          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.muted)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: _checking || _working ? null : _enableLocation,
          icon: Icon(_locationAllowed ? Icons.location_searching_rounded : Icons.location_on_outlined),
          label: Text(_locationAllowed ? 'SET DELIVERY LOCATION' : 'TURN ON LOCATION'),
        )),
      ])),
      if (_working) const Padding(padding: EdgeInsets.symmetric(horizontal: 20),
        child: LinearProgressIndicator(minHeight: 2)),
      if (_message != null) Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
        child: Text(_message!, style: const TextStyle(
          fontSize: 13, height: 1.4, color: AppColors.muted))),
    ],
  );
}
