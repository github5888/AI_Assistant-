import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../auth_models.dart';
import '../auth_platform.dart';
import '../store_api.dart';
import '../theme.dart';
import '../widgets.dart';

/// Admin-only mobile view of the dispatch/status APIs used by the website.
/// It deliberately does not imply a separate courier login or live GPS service.
class AdminDispatchScreen extends StatefulWidget {
  const AdminDispatchScreen({super.key, required this.vault});

  final SessionVault vault;

  @override
  State<AdminDispatchScreen> createState() => _AdminDispatchScreenState();
}

class _AdminDispatchScreenState extends State<AdminDispatchScreen> {
  SessionVault get _vault => widget.vault;
  final _email = TextEditingController();
  final _otp = TextEditingController();
  AdminSession? _session;
  OtpChallenge? _challenge;
  List<Map<String, dynamic>> _orders = const [];
  bool _restoring = true;
  bool _working = false;
  bool _loadingOrders = false;
  String? _error;

  StoreApi get _api {
    final api = AppScope.of(context).api;
    if (api == null) throw const StoreApiException('The store service is not configured.');
    return api;
  }

  @override
  void initState() {
    super.initState();
    _restoreAdmin();
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _restoreAdmin() async {
    try {
      final token = await _vault.read();
      if (token != null && token.isNotEmpty) {
        final session = await _api.currentAdmin(token);
        if (mounted) {
          setState(() => _session = session);
          await _loadOrders();
        }
      }
    } on AuthException catch (error) {
      if (error.status == 401 || error.status == 403 || error.status == 404) {
        await _vault.clear();
      } else if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not verify the saved admin session. Try again.');
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  Future<void> _requestCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _working = true; _error = null; });
    try {
      final challenge = await _api.requestAdminLoginOtp(_email.text);
      if (mounted) setState(() => _challenge = challenge);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not request an admin sign-in code. Try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _verifyCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() { _working = true; _error = null; });
    try {
      final session = await _api.verifyAdminLoginOtp(_email.text, _otp.text);
      await _vault.write(session.token);
      if (!mounted) return;
      setState(() { _session = session; _challenge = null; _otp.clear(); });
      await _loadOrders();
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Admin sign-in could not be completed. Try again.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _signOut() async {
    await _vault.clear();
    if (mounted) setState(() { _session = null; _orders = const []; _challenge = null; _error = null; });
  }

  Future<void> _loadOrders() async {
    final session = _session;
    if (session == null) return;
    setState(() { _loadingOrders = true; _error = null; });
    try {
      final orders = await _api.adminOrders(session.token);
      if (mounted && _session?.id == session.id) setState(() => _orders = orders);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Orders could not be loaded. Pull to retry.');
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> order, String status) async {
    final session = _session;
    final id = order['id'];
    if (session == null || id is! String || id.isEmpty) return;
    if (status == 'out_for_delivery') {
      await _dispatch(order, session, id);
      return;
    }
    setState(() { _working = true; _error = null; });
    try {
      final updated = await _api.updateAdminOrderStatus(id, session.token, status);
      _replaceOrder(updated);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Order status could not be updated.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _dispatch(Map<String, dynamic> order, AdminSession session, String id) async {
    final fields = await _askDispatchDetails(order);
    if (fields == null || !mounted) return;
    setState(() { _working = true; _error = null; });
    try {
      final updated = await _api.dispatchOrder(id, session.token,
        driverName: fields['name']!, driverPhone: fields['phone']!,
        vehicleNumber: fields['vehicle']!, estimatedDelivery: fields['eta']!);
      _replaceOrder(updated);
    } on StoreApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Dispatch could not be saved.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<Map<String, String>?> _askDispatchDetails(Map<String, dynamic> order) async {
    final hasFallbackPartner = _hasFallbackPartner(order);
    final name = TextEditingController(text: hasFallbackPartner ? '' : _text(order['driverName']));
    final phone = TextEditingController(text: hasFallbackPartner ? '' : _text(order['driverPhone']));
    final vehicle = TextEditingController(text: hasFallbackPartner ? '' : _text(order['vehicleNumber']));
    final eta = TextEditingController(text: _text(order['estimatedDelivery']));
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispatch order'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _DispatchField(controller: name, label: 'Delivery partner name'),
          _DispatchField(controller: phone, label: 'Partner phone', keyboardType: TextInputType.phone),
          _DispatchField(controller: vehicle, label: 'Vehicle number'),
          _DispatchField(controller: eta, label: 'Estimated delivery'),
          const Align(alignment: Alignment.centerLeft, child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Use the real assigned partner details. No live GPS is sent by this action.',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          )),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final values = {'name': name.text.trim(), 'phone': phone.text.trim(),
              'vehicle': vehicle.text.trim(), 'eta': eta.text.trim()};
            if (values.values.any((value) => value.isEmpty)) return;
            Navigator.pop(context, values);
          }, child: const Text('Confirm dispatch')),
        ],
      ),
    );
    name.dispose(); phone.dispose(); vehicle.dispose(); eta.dispose();
    return result;
  }

  void _replaceOrder(Map<String, dynamic> updated) {
    if (!mounted) return;
    setState(() => _orders = List.unmodifiable(_orders.map((order) =>
      order['id'] == updated['id'] ? updated : order)));
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(child: Column(children: [
      AppTopBar(title: 'Dispatch console', subtitle: 'Admin-only order operations', back: true),
      Expanded(child: _restoring
          ? const Center(child: CircularProgressIndicator())
          : _session == null ? _loginView() : _ordersView()),
    ]));
  }

  Widget _loginView() => ListView(padding: const EdgeInsets.all(16), children: [
    SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.admin_panel_settings_outlined, size: 30, color: AppColors.green),
      const SizedBox(height: 10),
      Text('itsclear operations', style: displayStyle(size: 21)),
      const SizedBox(height: 5),
      const Text('Sign in with an authorized admin email. The server verifies admin role before issuing access.',
        style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted)),
      const SizedBox(height: 15),
      TextField(controller: _email, enabled: !_working && _challenge == null,
        keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.send,
        decoration: const InputDecoration(labelText: 'Admin email', prefixIcon: Icon(Icons.email_outlined)),
        onSubmitted: (_) => _challenge == null ? _requestCode() : null),
      if (_challenge != null) ...[
        const SizedBox(height: 10),
        TextField(controller: _otp, enabled: !_working, keyboardType: TextInputType.number,
          maxLength: 6, textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Six-digit email code', prefixIcon: Icon(Icons.password)),
          onSubmitted: (_) => _verifyCode()),
        Align(alignment: Alignment.centerLeft, child: TextButton(
          onPressed: _working ? null : () => setState(() { _challenge = null; _otp.clear(); }),
          child: const Text('Change email')),
        ),
      ],
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 8),
        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: _working ? null : _challenge == null ? _requestCode : _verifyCode,
        icon: _working ? const SizedBox(width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2)) : Icon(_challenge == null ? Icons.mark_email_read_outlined : Icons.login),
        label: Text(_working ? 'Please wait…' : _challenge == null ? 'Send secure code' : 'Verify & sign in'),
      )),
    ])),
  ]);

  Widget _ordersView() {
    final session = _session!;
    return RefreshIndicator(onRefresh: _loadOrders, child: ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        SectionCard(child: Row(children: [
          CircleAvatar(backgroundColor: AppColors.navyDeep,
            child: Text(session.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(session.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            Text(session.email, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ])),
          IconButton(tooltip: 'Sign out', onPressed: _working ? null : _signOut,
            icon: const Icon(Icons.logout_rounded)),
        ])),
        if (_error != null) StoreNotice(message: _error!, onRetry: _loadOrders),
        if (_loadingOrders && _orders.isEmpty)
          const Padding(padding: EdgeInsets.all(28), child: Center(child: CircularProgressIndicator())),
        if (!_loadingOrders && _orders.isEmpty && _error == null)
          const StoreNotice(message: 'No orders are available to this admin account.'),
        for (final order in _orders) _orderCard(order),
      ],
    ));
  }

  Widget _orderCard(Map<String, dynamic> order) {
    final address = _asMap(order['shippingAddress']);
    final status = _text(order['orderStatus'], fallback: 'confirmed');
    final orderNumber = _text(order['orderNumber'], fallback: _text(order['id'], fallback: 'Order'));
    final customer = _text(address?['fullName'] ?? address?['name'], fallback: 'Customer');
    final phone = _text(address?['phone'] ?? address?['mobile']);
    final addressText = [address?['addressLine1'] ?? address?['address'], address?['city'],
      address?['state'], address?['pincode'] ?? address?['postalCode']]
      .whereType<String>().map((part) => part.trim()).where((part) => part.isNotEmpty).join(', ');
    final total = order['total'];
    final itemCount = order['items'] is List ? (order['items'] as List).length : 0;
    final fallbackPartner = _hasFallbackPartner(order);
    return Padding(padding: const EdgeInsets.only(bottom: 5), child: SectionCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.green, size: 19),
          const SizedBox(width: 7),
          Expanded(child: Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))),
          _StatusPill(status: status.replaceAll('_', ' ')),
        ]),
        const Divider(height: 18),
        Text(customer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        if (phone.isNotEmpty) Row(children: [
          Expanded(child: Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.muted))),
          IconButton(tooltip: 'Call customer', visualDensity: VisualDensity.compact,
            onPressed: () => _call(phone), icon: const Icon(Icons.call_outlined, size: 17)),
        ]),
        if (addressText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
          child: Text(addressText, style: const TextStyle(fontSize: 11, height: 1.35, color: AppColors.muted))),
        const SizedBox(height: 7),
        Text('$itemCount item${itemCount == 1 ? '' : 's'} · ${total is num ? '₹${total.toStringAsFixed(0)}' : 'Total unavailable'}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        _itemsSummary(order['items']),
        if (fallbackPartner) ...[
          const SizedBox(height: 9),
          const Text('Existing partner fields match the website fallback sample. Confirm the real partner before dispatch.',
            style: TextStyle(fontSize: 10, color: Color(0xFF805417))),
        ] else if (_text(order['driverName']).isNotEmpty || _text(order['driverPhone']).isNotEmpty) ...[
          const SizedBox(height: 9),
          Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0F4FA), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Assigned delivery partner', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              const SizedBox(height: 3),
              Text(_text(order['driverName'], fallback: 'Partner details'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              Text([_text(order['driverPhone']), _text(order['vehicleNumber'])]
                .where((value) => value.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            ])),
        ],
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          value: _validStatuses.contains(status) ? status : 'confirmed',
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Update fulfillment status', isDense: true),
          items: _validStatuses.map((value) => DropdownMenuItem(value: value,
            child: Text(_statusLabel(value), overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _working ? null : (value) {
            if (value != null && value != status) _changeStatus(order, value);
          },
        ),
      ],
    )));
  }

  Widget _itemsSummary(Object? rawItems) {
    if (rawItems is! List || rawItems.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(top: 7), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in rawItems.whereType<Map>()) _itemLine(item),
      ],
    ));
  }

  Widget _itemLine(Map item) {
    final product = _asMap(item['product']);
    final variant = _asMap(item['selectedVariant']);
    final name = _text(product?['name'], fallback: 'Store item');
    final size = _text(variant?['size']);
    final quantity = item['quantity'];
    final suffix = (size.isNotEmpty ? ' · $size' : '') +
        (quantity is num ? ' × ${quantity.toInt()}' : '');
    return Padding(padding: const EdgeInsets.only(top: 3), child: Text('$name$suffix',
      maxLines: 2, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 10, color: AppColors.muted)));
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^+0-9]'), ''));
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the phone app.')));
    }
  }

  static const _validStatuses = ['confirmed', 'milling', 'quality_check',
    'out_for_delivery', 'delivered', 'cancelled', 'return_requested', 'returned'];

  static String _statusLabel(String value) => switch (value) {
    'confirmed' => '1 · Confirmed', 'milling' => '2 · Milling',
    'quality_check' => '3 · Quality check', 'out_for_delivery' => '4 · Out for delivery',
    'delivered' => '5 · Delivered', 'cancelled' => 'Cancelled',
    'return_requested' => 'Return requested', 'returned' => 'Returned', _ => value,
  };

  static bool _hasFallbackPartner(Map<String, dynamic> order) =>
      order['driverName'] == 'Ramesh Kumar (EV Pilot)' &&
      order['driverPhone'] == '+91 88581 80597' &&
      order['vehicleNumber'] == 'UP-32-EV-4419';

  static Map? _asMap(Object? value) => value is Map ? value : null;
  static String _text(Object? value, {String fallback = ''}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;
}

class _DispatchField extends StatelessWidget {
  const _DispatchField({required this.controller, required this.label, this.keyboardType});
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: TextField(controller: controller, keyboardType: keyboardType,
      textCapitalization: keyboardType == null ? TextCapitalization.words : TextCapitalization.none,
      decoration: InputDecoration(labelText: label, isDense: true)),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFFE8F7EF), borderRadius: BorderRadius.circular(20)),
    child: Text(status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
      color: AppColors.green)),
  );
}
