import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../auth_models.dart';
import '../auth_platform.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_dispatch_screen.dart';

enum _AuthMode { email, password, register, linkGoogle }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.adminSessionVault});

  final SessionVault? adminSessionVault;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _identity = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  _AuthMode _mode = _AuthMode.email;
  String? _challengeEmail;
  String? _googleToken;
  String? _error;
  String? _notice;
  bool _busy = false;
  Timer? _timer;
  DateTime? _resendAt;

  bool get _waitingForCode => _challengeEmail != null;
  int get _resendSeconds {
    final ms = _resendAt?.difference(DateTime.now()).inMilliseconds ?? 0;
    return ms < 1 ? 0 : (ms / 1000).ceil();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_identity, _password, _confirmation, _name, _phone, _otp]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _changeMode(_AuthMode mode) {
    _timer?.cancel();
    _form.currentState?.reset();
    _password.clear();
    _confirmation.clear();
    _otp.clear();
    setState(() {
      _mode = mode;
      _challengeEmail = null;
      _googleToken = null;
      _error = null;
      _notice = null;
      _resendAt = null;
    });
  }

  void _cooldown(int seconds) {
    _timer?.cancel();
    final wait = seconds.clamp(0, 3600).toInt();
    _resendAt = DateTime.now().add(Duration(seconds: wait));
    if (wait == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) timer.cancel();
      if (mounted) setState(() {});
    });
  }

  Future<void> _run(Future<void> Function(AppState state) action) async {
    if (_busy) return;
    final state = AppScope.of(context);
    if (state.api == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      await action(state);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        final delay = error.retryAfter;
        if (delay != null && delay > 0) _cooldown(delay);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not complete sign-in. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  SessionVault? _adminVault() {
    final api = AppScope.of(context).api;
    if (api == null) return null;
    return widget.adminSessionVault ?? AndroidAdminSessionVault(api.base);
  }

  Future<void> _finishAdmin(AdminSession session) async {
    final vault = _adminVault();
    if (vault == null) return;
    await vault.write(session.token);
    if (!mounted) return;
    _password.clear();
    await pushScreen(context, AdminDispatchScreen(vault: vault));
  }

  Future<void> _finish(AppState state, CustomerSession session) async {
    if (!mounted) return;
    await state.acceptSession(session);
    if (!mounted) return;
    _googleToken = null;
    Navigator.of(context).pop();
  }

  void _continueWithGoogle() {
    _run((state) async {
      final credential = await state.googleIdentity?.idToken();
      if (credential == null || !mounted) return;
      final result = await state.api!.googleLogin(credential);
      if (!mounted) return;
      final session = result.session;
      if (session != null) {
        await _finish(state, session);
      } else {
        _changeMode(_AuthMode.linkGoogle);
        _identity.text = result.linkEmail!;
        setState(() => _googleToken = credential);
      }
    });
  }

  void _requestCode({bool resend = false}) {
    if (_resendSeconds > 0 || (!resend && !(_form.currentState?.validate() ?? false))) return;
    final email = _challengeEmail ?? _identity.text.trim().toLowerCase();
    _run((state) async {
      final api = state.api!;
      final challenge = switch ((_mode, resend)) {
        (_AuthMode.register, true) => await api.resendRegistrationOtp(email),
        (_AuthMode.register, false) => await api.startRegistration(
          name: _name.text, mobile: _phone.text, email: email, password: _password.text,
          confirmPassword: _confirmation.text,
        ),
        _ => await api.requestLoginOtp(email),
      };
      if (!mounted) return;
      _otp.clear();
      _password.clear();
      _confirmation.clear();
      setState(() {
        _challengeEmail = email;
        _notice = 'If this email is eligible, a six-digit code has been sent. '
          'Check your email and spam folder.';
        _cooldown(challenge.resendAfter);
      });
    });
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_waitingForCode && _mode != _AuthMode.password) {
      _requestCode();
      return;
    }
    _run((state) async {
      final api = state.api!;
      if (_mode == _AuthMode.password) {
        final result = await api.passwordLogin(_identity.text, _password.text);
        final adminSession = result.adminSession;
        if (adminSession != null) {
          // Re-authenticate through the backend's admin-only endpoint so the
          // stored token uses the shorter admin lifetime and role checks.
          final verifiedAdmin = await api.adminPasswordLogin(_identity.text, _password.text);
          await _finishAdmin(verifiedAdmin);
        } else {
          await _finish(state, result.customerSession!);
        }
        return;
      }
      final session = switch (_mode) {
        _AuthMode.email => await api.verifyLoginOtp(_challengeEmail!, _otp.text),
        _AuthMode.register => await api.verifyRegistrationOtp(_challengeEmail!, _otp.text),
        _AuthMode.linkGoogle => await api.linkGoogleOtp(_googleToken!, _otp.text),
        _AuthMode.password => throw StateError('Password login is handled above.'),
      };
      await _finish(state, session);
    });
  }

  String? _validIdentity(String? value) {
    final input = value?.trim() ?? '';
    if (_mode == _AuthMode.password) {
      return input.isEmpty ? 'Enter your email or mobile number.' : null;
    }
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(input) ? null : 'Enter a valid email address.';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final registering = _mode == _AuthMode.register;
    final passwordMode = _mode == _AuthMode.password;
    final linking = _mode == _AuthMode.linkGoogle;
    final action = _waitingForCode ? (linking ? 'Verify & link Google' : 'Verify email code')
        : registering ? 'Send verification email' : passwordMode ? 'Sign in' : 'Send email OTP';
    return AppPage(child: Column(children: [
      AppTopBar(title: registering ? 'Create an account' : 'Sign in', back: true),
      Expanded(child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppGradients.navy, borderRadius: BorderRadius.circular(24)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 160,
                height: 70,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Image.asset('assets/images/itsclear-logo.png', fit: BoxFit.contain,
                  semanticLabel: 'itsclear logo'),
              ),
              const SizedBox(height: 12),
              Text(linking ? 'Link your Google account' : registering ? 'Join itsclear' : 'Welcome to itsclear',
                style: const TextStyle(color: Colors.white, fontSize: 26, height: 1.13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(linking ? 'Confirm the email on your existing account before linking Google.'
                  : '100% pure cold-stoneground chakki atta',
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 16),
          if (_mode == _AuthMode.email && !_waitingForCode) ...[
            OutlinedButton.icon(
              onPressed: _busy || state.googleIdentity == null ? null : _continueWithGoogle,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Sign in with Google'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 12),
            const Row(children: [Expanded(child: Divider()), Padding(
              padding: EdgeInsets.symmetric(horizontal: 12), child: Text('OR'),
            ), Expanded(child: Divider())]),
            const SizedBox(height: 12),
          ],
          if (_notice != null) Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_notice!, style: const TextStyle(color: AppColors.green, fontSize: 13)),
          ),
          if (_error != null) Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFEDE5), borderRadius: BorderRadius.circular(12)),
            child: Semantics(liveRegion: true, child: Text(_error!, style: const TextStyle(fontSize: 13))),
          ),
          AutofillGroup(child: Form(key: _form, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_waitingForCode) ...[
                if (registering) ...[
                  _field(_name, 'Full name', autofill: AutofillHints.name,
                    validator: (text) => (text ?? '').trim().isEmpty ? 'Enter your name.' : null),
                  _field(_phone, 'Mobile number', type: TextInputType.phone, autofill: AutofillHints.telephoneNumber,
                    validator: (text) => RegExp(r'^\d{10,15}$').hasMatch((text ?? '').replaceAll(RegExp(r'\D'), ''))
                      ? null : 'Enter a valid mobile number.'),
                ],
                _field(_identity, passwordMode ? 'Email or mobile number' : 'Email address',
                  type: passwordMode ? TextInputType.text : TextInputType.emailAddress,
                  autofill: AutofillHints.email, validator: _validIdentity, readOnly: linking),
                if (passwordMode || registering)
                  _field(_password, 'Password', obscure: true,
                    autofill: registering ? AutofillHints.newPassword : AutofillHints.password,
                    validator: (text) => (text ?? '').length < (registering ? 6 : 1)
                      ? (registering ? 'Use at least six characters.' : 'Enter your password.') : null),
                if (registering)
                  _field(_confirmation, 'Confirm password', obscure: true,
                    validator: (text) => text != _password.text ? 'Passwords do not match.' : null),
              ] else ...[
                Text(_challengeEmail!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _field(_otp, 'Six-digit email code', type: TextInputType.number,
                  autofill: AutofillHints.oneTimeCode,
                  formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  validator: (text) => RegExp(r'^\d{6}$').hasMatch(text ?? '') ? null : 'Enter the six-digit code.'),
              ],
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: _busy || state.restoringSession || (!_waitingForCode && !passwordMode && _resendSeconds > 0)
                    ? null : _submit,
                child: _busy ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(action),
              ),
              if (_waitingForCode)
                TextButton(
                  onPressed: _busy || _resendSeconds > 0 ? null : () => _requestCode(resend: true),
                  child: Text(_resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend code'),
                ),
            ],
          ))),
          const SizedBox(height: 8),
          if (_mode == _AuthMode.email && !_waitingForCode) ...[
            TextButton(onPressed: _busy ? null : () => _changeMode(_AuthMode.password), child: const Text('Sign in with password instead')),
            const Divider(),
            TextButton(onPressed: _busy ? null : () => _changeMode(_AuthMode.register), child: const Text('Create an account')),
          ] else
            TextButton(onPressed: _busy ? null : () => _changeMode(_AuthMode.email),
              child: Text(_mode == _AuthMode.email ? 'Change email address' : 'Back to email sign-in')),
        ],
      )),
    ]));
  }

  Widget _field(TextEditingController controller, String label, {
    TextInputType? type, String? autofill, String? Function(String?)? validator,
    bool readOnly = false, bool obscure = false, List<TextInputFormatter>? formatters,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: type,
      autofillHints: autofill == null ? null : [autofill],
      validator: validator,
      obscureText: obscure,
      readOnly: readOnly || _busy,
      autocorrect: false,
      inputFormatters: formatters,
      style: const TextStyle(fontSize: 15),
    ),
  );
}
