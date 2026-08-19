import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../services/sync_service.dart';
import 'main_shell.dart';
import 'onboarding.dart';
import 'signup_screen.dart';

const _webClientId = '500337949373-naol002agngd9hva6dsccda5t82ofk29.apps.googleusercontent.com';

// Lightweight shape check only — not a full RFC 5322 validator. Catches
// "forgot the @" / "no domain" typos before wasting a Supabase round-trip;
// Supabase itself is still the real validator for anything more subtle.
final _emailShapeRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
bool _looksLikeEmail(String email) => _emailShapeRegex.hasMatch(email);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;
  bool _resetLoading = false;

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _signIn() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = tr('fill_all_fields'));
      return;
    }
    if (!_looksLikeEmail(email)) {
      setState(() => _error = tr('invalid_email'));
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email, password: password,
      );
      if (!mounted) return;
      if (!mounted) return;
      _goToApp();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final googleSignIn = GoogleSignIn(serverClientId: _webClientId);
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _googleLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        setState(() { _googleLoading = false; _error = tr('google_signin_failed'); });
        return;
      }
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      if (!mounted) return;
      if (!mounted) return;
      _goToApp();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Google error: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    String? dialogError;
    bool sent = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: context.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(tr('reset_password'), style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!sent) ...[
                Text(tr('reset_email_prompt'), style: TextStyle(color: context.textMuted, fontSize: 13)),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: TextStyle(color: context.appText),
                  decoration: InputDecoration(
                    hintText: 'you@example.com',
                    hintStyle: TextStyle(color: context.textMuted),
                    filled: true,
                    fillColor: context.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.primary, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!, style: TextStyle(color: context.dangerColor, fontSize: 12)),
                ],
              ] else
                Text(tr('check_email_reset'), style: TextStyle(color: context.primary, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          actions: sent
              ? [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('ok')))]
              : [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('cancel'), style: TextStyle(color: context.textMuted))),
                  FilledButton(
                    onPressed: _resetLoading ? null : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) { setS(() => dialogError = tr('enter_email')); return; }
                      if (!_looksLikeEmail(email)) { setS(() => dialogError = tr('invalid_email')); return; }
                      setS(() { _resetLoading = true; dialogError = null; });
                      try {
                        await Supabase.instance.client.auth.resetPasswordForEmail(
                          email,
                          redirectTo: 'https://lexivo-web-six.vercel.app/update-password',
                        );
                        setS(() { sent = true; _resetLoading = false; });
                      } on AuthException catch (e) {
                        setS(() { dialogError = e.message; _resetLoading = false; });
                      } catch (_) {
                        setS(() { dialogError = tr('something_wrong'); _resetLoading = false; });
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: context.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _resetLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(tr('send_link')),
                  ),
                ],
        ),
      ),
    );
    emailCtrl.dispose();
  }

  Future<void> _goToApp({bool asGuest = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (asGuest) {
      await prefs.setBool('guest_mode', true);
    } else {
      await prefs.setBool('guest_mode', false);
      SyncService.pullAll();
    }
    if (!mounted) return;
    // Authenticated users always go to the app — they already have an account
    // so onboarding_completed is irrelevant (mirrors the main.dart startup logic).
    // Only guests without an account fall through to onboarding.
    final done = asGuest ? (prefs.getBool('onboarding_completed') ?? false) : true;
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📖', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text('Lexivo', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: context.primary, letterSpacing: 1)),
                const SizedBox(height: 6),
                Text(tr('sign_in_to_continue'), style: TextStyle(fontSize: 14, color: context.textMuted)),
                const SizedBox(height: 40),

                // Google button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: (_loading || _googleLoading) ? null : _signInWithGoogle,
                    icon: _googleLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : _googleLogo(),
                    label: Text(
                      _googleLoading ? tr('signing_in') : tr('continue_with_google'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(color: context.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: context.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(tr('or'), style: TextStyle(color: context.textMuted, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: context.border)),
                ]),
                const SizedBox(height: 20),

                _AuthField(controller: _emailCtrl, label: tr('email'), hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _AuthField(controller: _passwordCtrl, label: tr('password'), hint: '••••••••', obscure: true, onSubmit: _signIn),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
                    child: Text(tr('forgot_password'), style: TextStyle(color: context.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 4),

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
                    onPressed: (_loading || _googleLoading) ? null : _signIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(tr('sign_in'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${tr('no_account')} ', style: TextStyle(color: context.textMuted, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: Text(tr('create_one_free'), style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _goToApp(asGuest: true),
                  child: Text(tr('continue_without_account'), style: TextStyle(color: context.textMuted, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _googleLogo() {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24 * s, 9.5 * s)
      ..cubicTo(27.54 * s, 9.5 * s, 30.71 * s, 10.72 * s, 33.21 * s, 13.1 * s)
      ..lineTo(40.06 * s, 6.25 * s)
      ..cubicTo(35.9 * s, 2.38 * s, 30.47 * s, 0, 24 * s, 0)
      ..cubicTo(14.62 * s, 0, 6.51 * s, 5.38 * s, 2.56 * s, 13.22 * s)
      ..lineTo(10.54 * s, 19.41 * s)
      ..cubicTo(12.43 * s, 13.72 * s, 17.74 * s, 9.5 * s, 24 * s, 9.5 * s);
    canvas.drawPath(redPath, paint);

    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98 * s, 24.55 * s)
      ..cubicTo(46.98 * s, 22.98 * s, 46.83 * s, 21.46 * s, 46.6 * s, 20 * s)
      ..lineTo(24 * s, 20 * s)
      ..lineTo(24 * s, 29.02 * s)
      ..lineTo(36.94 * s, 29.02 * s)
      ..cubicTo(36.36 * s, 31.98 * s, 34.68 * s, 34.5 * s, 32.16 * s, 36.2 * s)
      ..lineTo(39.89 * s, 42.2 * s)
      ..cubicTo(44.4 * s, 38.02 * s, 46.98 * s, 31.84 * s, 46.98 * s, 24.55 * s);
    canvas.drawPath(bluePath, paint);

    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53 * s, 28.59 * s)
      ..cubicTo(10.05 * s, 27.14 * s, 9.77 * s, 25.6 * s, 9.77 * s, 24 * s)
      ..cubicTo(9.77 * s, 22.4 * s, 10.04 * s, 20.86 * s, 10.53 * s, 19.41 * s)
      ..lineTo(2.55 * s, 13.22 * s)
      ..cubicTo(0.92 * s, 16.46 * s, 0, 20.12 * s, 0, 24 * s)
      ..cubicTo(0, 27.88 * s, 0.92 * s, 31.54 * s, 2.56 * s, 34.78 * s)
      ..lineTo(10.53 * s, 28.59 * s);
    canvas.drawPath(yellowPath, paint);

    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24 * s, 48 * s)
      ..cubicTo(30.48 * s, 48 * s, 35.93 * s, 45.87 * s, 39.89 * s, 42.19 * s)
      ..lineTo(32.16 * s, 36.19 * s)
      ..cubicTo(30.01 * s, 37.64 * s, 27.24 * s, 38.49 * s, 24 * s, 38.49 * s)
      ..cubicTo(17.74 * s, 38.49 * s, 12.43 * s, 34.27 * s, 10.53 * s, 28.58 * s)
      ..lineTo(2.55 * s, 34.77 * s)
      ..cubicTo(6.51 * s, 42.62 * s, 14.62 * s, 48 * s, 24 * s, 48 * s);
    canvas.drawPath(greenPath, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Shared input field ────────────────────────────────────────────────────────

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
