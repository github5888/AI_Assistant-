import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itsclear_app/notification_models.dart';
import 'package:itsclear_app/store_api.dart';

http.Response _json(Object value) => http.Response(jsonEncode(value), 200,
  headers: {'content-type': 'application/json'});

void main() {
  test('device and notification calls follow the customer API contract', () async {
    final seen = <String>[];
    final api = StoreApi('https://example.test', client: MockClient((request) async {
      seen.add('${request.method} ${request.url.path}');
      expect(request.headers['authorization'], 'Bearer customer-jwt');
      switch ('${request.method} ${request.url.path}') {
        case 'POST /api/devices/register':
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['deviceId'], 'device-uuid');
          expect(body['fcmToken'], 'fcm-token');
          expect(body.containsKey('userId'), isFalse);
          return _json({'success': true, 'device': {'isActive': true}});
        case 'DELETE /api/devices/device-uuid':
          return _json({'success': true});
        case 'GET /api/notifications':
          expect(request.url.queryParameters, {'page': '2', 'limit': '15', 'status': 'unread', 'category': 'delivery'});
          return _json({
            'success': true,
            'data': [{
              'id': 'notif-1', 'title': 'Out for delivery', 'message': 'Order is on its way.',
              'type': 'delivery', 'category': 'delivery', 'priority': 'high',
              'referenceId': 'order-1', 'deepLinkDestination': 'ORDER_TRACKING',
              'readStatus': false, 'createdAt': '2026-11-26T08:00:00.000Z',
            }],
            'pagination': {'page': 2, 'limit': 15, 'total': 16, 'totalPages': 2},
            'unreadCount': 3,
          });
        case 'GET /api/notifications/unread-count':
          return _json({'success': true, 'unreadCount': 3});
        case 'PATCH /api/notifications/notif-1/read':
        case 'PATCH /api/notifications/read-all':
        case 'DELETE /api/notifications/notif-1':
          return _json({'success': true, 'unreadCount': 2});
        case 'GET /api/notifications/preferences':
          return _json({'success': true, 'preferences': const NotificationPreferences().toJson()});
        case 'PATCH /api/notifications/preferences':
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['promotionalOffers'], false);
          expect(body['orderUpdates'], true);
          return _json({'success': true, 'preferences': body});
        default:
          throw StateError('Unexpected request ${request.method} ${request.url}');
      }
    }));
    addTearDown(api.close);

    await api.registerDevice('customer-jwt', {
      'deviceId': 'device-uuid', 'fcmToken': 'fcm-token', 'platform': 'android',
    });
    await api.unregisterDevice('customer-jwt', 'device-uuid');
    final history = await api.notificationHistory('customer-jwt', page: 2, limit: 15,
      status: 'unread', category: 'delivery');
    expect(history.items.single.deepLinkDestination, 'ORDER_TRACKING');
    expect(history.items.single.read, isFalse);
    expect(history.unreadCount, 3);
    expect(await api.notificationUnreadCount('customer-jwt'), 3);
    expect(await api.markNotificationRead('customer-jwt', 'notif-1'), 2);
    expect(await api.markAllNotificationsRead('customer-jwt'), 2);
    expect(await api.deleteNotification('customer-jwt', 'notif-1'), 2);
    final preferences = await api.notificationPreferences('customer-jwt');
    expect(preferences.promotionalOffers, isFalse);
    final changed = await api.updateNotificationPreferences('customer-jwt',
      preferences.copyWith(deliveryUpdates: false));
    expect(changed.deliveryUpdates, isFalse);
    expect(seen, contains('POST /api/devices/register'));
    expect(seen, contains('PATCH /api/notifications/preferences'));
  });
}
