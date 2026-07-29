import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_theme.dart';
import '../l10n.dart';
import '../services/sync_service.dart';
import 'main_shell.dart';
import 'onboarding.dart';

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
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _signUp() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;
    final pass2 = _password2Ctrl.text;

    if (email.isEmpty || pass.isEmpty || pass2.isEmpty) {
      setState(() => _error = tr('fill_all_fields')); return;
    }
    if (pass.length < 6) {
      setState(() => _error = tr('password_min_chars')); return;
    }
    if (pass != pass2) {
      setState(() => _error = tr('passwords_no_match')); return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signUp(email: email, password: pass);
      if (!mounted) return;
      if (!mounted) return;
      _goToApp();
    } on AuthException catch (e) {
      setState(() => _error = e.message);
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
