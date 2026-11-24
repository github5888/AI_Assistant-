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
      throw const AuthException('Use a customer account to sign in to this app.');
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

class GoogleExchange {
  const GoogleExchange.signedIn(this.session) : linkEmail = null;
  const GoogleExchange.needsLink(this.linkEmail) : session = null;
  final CustomerSession? session;
  final String? linkEmail;
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
