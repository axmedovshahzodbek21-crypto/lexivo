import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../services/sync_service.dart';
import 'main_shell.dart';
import 'onboarding.dart';

// Lightweight shape check only — not a full RFC 5322 validator. Catches
// "forgot the @" / "no domain" typos before wasting a Supabase round-trip;
// Supabase itself is still the real validator for anything more subtle.
final _emailShapeRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool _looksLikeEmail(String email) => _emailShapeRegex.hasMatch(email);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _password2Ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
    _passwordCtrl.addListener(_onPasswordChange);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _passwordCtrl.removeListener(_onPasswordChange);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  void _onPasswordChange() { if (mounted) setState(() {}); }

  // Simple heuristic (length + character variety), not a full policy —
  // signup only enforces an 8-character minimum below; this is feedback to
  // nudge toward a stronger password, not a hard gate.
  (double, String) _passwordStrength(String pass) {
    if (pass.isEmpty) return (0, '');
    var score = 0;
    if (pass.length >= 8) score++;
    if (pass.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass) && RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) score++;
    switch (score) {
      case 0: case 1: return (0.25, tr('password_strength_weak'));
      case 2: return (0.5, tr('password_strength_fair'));
      case 3: case 4: return (0.75, tr('password_strength_good'));
      default: return (1.0, tr('password_strength_strong'));
    }
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;
    final pass2 = _password2Ctrl.text;

    if (email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() => _error = tr('fill_all_fields')); return;
    }
    if (!_looksLikeEmail(email)) {
      setState(() => _error = tr('invalid_email')); return;
    }
    if (pass.length < 8) {
      setState(() => _error = tr('password_min_chars')); return;
    }
    if (pass != pass2) {
      setState(() => _error = tr('passwords_no_match')); return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final response = await Supabase.instance.client.auth.signUp(email: email, password: pass);
      if (!mounted) return;
      // Supabase's anti-email-enumeration behavior: signing up with an email
      // that already has an account returns a fake user with an empty
      // identities list and no error, indistinguishable from a genuine new
      // signup unless checked for explicitly. Without this check the user
      // was silently dropped into the app as if a new account had been
      // created, with no indication they already have one and should log in
      // instead.
      if (response.user != null && (response.user!.identities?.isEmpty ?? false)) {
        setState(() => _error = tr('email_already_registered'));
        return;
      }
      // If the project requires email confirmation, signUp() succeeds but
      // issues no session yet. Continuing into the app here would push an
      // effectively-unauthenticated user into UI that assumes currentUser is
      // set (SyncService, class_shell.dart, etc.) instead of showing a
      // "check your email" message.
      if (response.session == null) {
        setState(() => _error = tr('check_email_confirm'));
        return;
      }
      _goToApp();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      // A network failure (SocketException, timeout, etc.) isn't an
      // AuthException, so it fell through uncaught before this — the finally
      // block still stopped the spinner, but with no error message shown,
      // the button looked like it had silently done nothing.
      if (mounted) setState(() => _error = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', false);
    SyncService.pushAll();
    if (!mounted) return;
    final done = prefs.getBool('onboarding_completed') ?? false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => done
            ? MainShell(
                wordSource: prefs.getString('word_source') ?? 'prebuilt',
                exampleStyle: prefs.getString('example_style') ?? 'reallife',
                userProfile: prefs.getString('user_profile') ?? 'worker',
                languageLevel: prefs.getString('language_level') ?? 'intermediate',
                dailyWordGoal: prefs.getInt('daily_word_goal') ?? 15,
              )
            : const OnboardingFlow(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(tr('create_account'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: context.appText)),
                const SizedBox(height: 4),
                Text(tr('free_forever'), style: TextStyle(fontSize: 13, color: context.textMuted)),
                const SizedBox(height: 32),

                _AuthField(controller: _emailCtrl, label: tr('email'), hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _AuthField(controller: _passwordCtrl, label: tr('password'), hint: tr('password_hint'), obscure: true),
                if (_passwordCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Builder(builder: (_) {
                    final (strength, label) = _passwordStrength(_passwordCtrl.text);
                    final color = strength <= 0.25
                        ? context.dangerColor
                        : strength <= 0.5
                            ? const Color(0xFFF59E0B)
                            : strength <= 0.75
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF22C55E);
                    return Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: strength,
                            minHeight: 5,
                            backgroundColor: context.border,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                    ]);
                  }),
                ],
                const SizedBox(height: 12),
                _AuthField(controller: _password2Ctrl, label: tr('confirm_password'), hint: '••••••••', obscure: true, onSubmit: _signUp),
                const SizedBox(height: 16),

                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: context.dangerColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(_error!, style: TextStyle(color: context.dangerColor, fontSize: 13)),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _signUp,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(tr('create_account'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmit;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
          style: TextStyle(fontSize: 16, color: context.appText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: context.textMuted),
            filled: true,
            fillColor: context.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
