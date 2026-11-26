class CustomerAccount {
  const CustomerAccount({required this.id, required this.email, required this.name,
    this.clearCoins = 0});

  final String id;
  final String email;
  final String name;
  final int clearCoins;

  factory CustomerAccount.fromJson(Object? json) {
    if (json is! Map || json['id'] is! String || json['email'] is! String ||
        (json['id'] as String).isEmpty || (json['email'] as String).isEmpty) {
      throw const AuthException('The store returned an invalid account.');
    }
    if (json['role'] != 'customer') {
      throw const AuthException('This account cannot be used for customer sign-in. Check the account details and try again.');
    }
    final name = json['name'];
    final rawCoins = json['clearCoins'];
    final coins = rawCoins is num && rawCoins.isFinite && rawCoins >= 0
        ? rawCoins.floor() : 0;
    return CustomerAccount(id: json['id'] as String, email: json['email'] as String,
      name: name is String && name.trim().isNotEmpty ? name.trim() : 'itsclear customer',
      clearCoins: coins);
  }
}

class CustomerSession {
  const CustomerSession(this.account, this.token);
  final CustomerAccount account;
  final String token;

  factory CustomerSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty || RegExp(r'\s').hasMatch(token)) {
      throw const AuthException('The store did not confirm the sign-in.');
    }
    return CustomerSession(CustomerAccount.fromJson(json['user']), token);
  }
}

class AdminSession {
  const AdminSession({required this.id, required this.name, required this.email, required this.token});

  final String id;
  final String name;
  final String email;
  final String token;

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (token is! String || token.isEmpty || RegExp(r'\s').hasMatch(token) ||
        user is! Map || user['role'] != 'admin' || user['id'] is! String ||
        (user['id'] as String).isEmpty || user['email'] is! String) {
      throw const AuthException('This account is not authorized for the admin dispatch console.');
    }
    final name = user['name'];
    return AdminSession(id: user['id'] as String,
      name: name is String && name.trim().isNotEmpty ? name.trim() : 'itsclear admin',
      email: user['email'] as String, token: token);
  }
}

class GoogleExchange {
  const GoogleExchange.signedIn(this.session) : linkEmail = null;
  const GoogleExchange.needsLink(this.linkEmail) : session = null;
  final CustomerSession? session;
  final String? linkEmail;
}

class PasswordLoginResult {
  const PasswordLoginResult.customer(CustomerSession session)
      : customerSession = session, adminSession = null;
  const PasswordLoginResult.admin(AdminSession session)
      : customerSession = null, adminSession = session;

  final CustomerSession? customerSession;
  final AdminSession? adminSession;

  factory PasswordLoginResult.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is Map && user['role'] == 'admin') {
      return PasswordLoginResult.admin(AdminSession.fromJson(json));
    }
    return PasswordLoginResult.customer(CustomerSession.fromJson(json));
  }
}

class OtpChallenge {
  const OtpChallenge(this.resendAfter, this.expiresIn);
  final int resendAfter;
  final int expiresIn;
}

class AuthException implements Exception {
  const AuthException(this.message, {this.status, this.retryAfter});
  final String message;
  final int? status;
  final int? retryAfter;
}
