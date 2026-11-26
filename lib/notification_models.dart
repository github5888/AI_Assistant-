class PushNotificationItem {
  const PushNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.priority,
    required this.referenceId,
    required this.deepLinkDestination,
    required this.read,
    required this.createdAt,
    this.imageUrl = '',
  });

  final String id;
  final String title;
  final String message;
  final String imageUrl;
  final String type;
  final String category;
  final String priority;
  final String referenceId;
  final String deepLinkDestination;
  final bool read;
  final DateTime? createdAt;

  Map<String, dynamic> toTapData() => {
    'screen': deepLinkDestination,
    'referenceId': referenceId,
    'notificationId': id,
  };

  factory PushNotificationItem.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid notification row');
    final rawDate = value['createdAt'];
    return PushNotificationItem(
      id: _string(value['id']),
      title: _string(value['title'], fallback: 'itsclear update'),
      message: _string(value['message']),
      imageUrl: _string(value['imageUrl']),
      type: _string(value['type']),
      category: _string(value['category']),
      priority: _string(value['priority']),
      referenceId: _string(value['referenceId']),
      deepLinkDestination: _string(value['deepLinkDestination']),
      read: value['readStatus'] == true,
      createdAt: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }
}

class NotificationHistoryPage {
  const NotificationHistoryPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.unreadCount,
  });

  final List<PushNotificationItem> items;
  final int page;
  final int totalPages;
  final int unreadCount;

  factory NotificationHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    final pagination = json['pagination'];
    if (json['success'] != true || rawItems is! List || pagination is! Map) {
      throw const FormatException('Invalid notification history response');
    }
    return NotificationHistoryPage(
      items: List.unmodifiable(rawItems.map(PushNotificationItem.fromJson)),
      page: _integer(pagination['page'], fallback: 1),
      totalPages: _integer(pagination['totalPages'], fallback: 1),
      unreadCount: _integer(json['unreadCount']),
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.orderUpdates = true,
    this.paymentUpdates = true,
    this.deliveryUpdates = true,
    this.promotionalOffers = false,
    this.productAvailabilityAlerts = true,
    this.cartReminders = true,
    this.generalAnnouncements = true,
  });

  final bool orderUpdates;
  final bool paymentUpdates;
  final bool deliveryUpdates;
  final bool promotionalOffers;
  final bool productAvailabilityAlerts;
  final bool cartReminders;
  final bool generalAnnouncements;

  Map<String, Object?> toJson() => {
    'orderUpdates': orderUpdates,
    'paymentUpdates': paymentUpdates,
    'deliveryUpdates': deliveryUpdates,
    'promotionalOffers': promotionalOffers,
    'productAvailabilityAlerts': productAvailabilityAlerts,
    'cartReminders': cartReminders,
    'generalAnnouncements': generalAnnouncements,
  };

  factory NotificationPreferences.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Invalid notification preferences');
    const defaults = NotificationPreferences();
    return NotificationPreferences(
      orderUpdates: value['orderUpdates'] is bool ? value['orderUpdates'] as bool : defaults.orderUpdates,
      paymentUpdates: value['paymentUpdates'] is bool ? value['paymentUpdates'] as bool : defaults.paymentUpdates,
      deliveryUpdates: value['deliveryUpdates'] is bool ? value['deliveryUpdates'] as bool : defaults.deliveryUpdates,
      promotionalOffers: value['promotionalOffers'] is bool ? value['promotionalOffers'] as bool : defaults.promotionalOffers,
      productAvailabilityAlerts: value['productAvailabilityAlerts'] is bool
          ? value['productAvailabilityAlerts'] as bool : defaults.productAvailabilityAlerts,
      cartReminders: value['cartReminders'] is bool ? value['cartReminders'] as bool : defaults.cartReminders,
      generalAnnouncements: value['generalAnnouncements'] is bool
          ? value['generalAnnouncements'] as bool : defaults.generalAnnouncements,
    );
  }

  NotificationPreferences copyWith({
    bool? orderUpdates,
    bool? paymentUpdates,
    bool? deliveryUpdates,
    bool? promotionalOffers,
    bool? productAvailabilityAlerts,
    bool? cartReminders,
    bool? generalAnnouncements,
  }) => NotificationPreferences(
    orderUpdates: orderUpdates ?? this.orderUpdates,
    paymentUpdates: paymentUpdates ?? this.paymentUpdates,
    deliveryUpdates: deliveryUpdates ?? this.deliveryUpdates,
    promotionalOffers: promotionalOffers ?? this.promotionalOffers,
    productAvailabilityAlerts: productAvailabilityAlerts ?? this.productAvailabilityAlerts,
    cartReminders: cartReminders ?? this.cartReminders,
    generalAnnouncements: generalAnnouncements ?? this.generalAnnouncements,
  );
}

String _string(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

int _integer(Object? value, {int fallback = 0}) =>
    value is num && value.isFinite ? value.toInt() : fallback;
