import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_shell.dart';
import '../app_theme.dart';
import '../l10n.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _currentPage = 0;
  String _userName = '';
  String _englishLevel = '';
  int _dailyWordGoal = 15;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    appLangNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _nameController.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  void _nextPage() => setState(() => _currentPage++);
  void _prevPage() { if (_currentPage > 0) setState(() => _currentPage--); }

  // A system/gesture back press used to pop this whole route immediately
  // regardless of which step the user was on, silently discarding
  // _userName/_englishLevel/_dailyWordGoal entered so far. Now it steps
  // back one page at a time instead, and only actually exits the flow
  // (back to whatever pushed it) once already on the first page.
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _prevPage();
      },
      child: switch (_currentPage) {
        0 => _buildNamePage(context),
        1 => _buildLanguageLevelPage(context),
        2 => _buildDailyGoalPage(context),
        3 => _buildHowItWorksPage(context),
        _ => _buildNamePage(context),
      },
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: _prevPage,
        icon: Icon(Icons.arrow_back_rounded, color: context.appText),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // ─── Page 1: Name ─────────────────────────────────────────────────────────

  Widget _buildNamePage(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                tr('welcome_title'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('what_to_call'),
                style: TextStyle(fontSize: 16, color: context.textMuted),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.appText,
                ),
                decoration: InputDecoration(
                  hintText: tr('your_name'),
                  hintStyle: TextStyle(color: context.textMuted),
                  filled: true,
                  fillColor: context.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onChanged: (val) => setState(() => _userName = val.trim()),
              ),
              const Spacer(),
              _buildContinueButton(context, _userName.isNotEmpty ? _nextPage : null),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 2: English Level ────────────────────────────────────────────────

  Widget _buildLanguageLevelPage(BuildContext context) {
    final levels = [
      {'level': 'A1', 'emoji': '🌱', 'labelKey': 'level_beginner', 'color': const Color(0xFF2ECC71)},
      {'level': 'A2', 'emoji': '🌿', 'labelKey': 'level_elementary', 'color': const Color(0xFF27AE60)},
      {'level': 'B1', 'emoji': '📗', 'labelKey': 'level_intermediate', 'color': const Color(0xFF3498DB)},
      {'level': 'B2', 'emoji': '📘', 'labelKey': 'level_upper_inter', 'color': const Color(0xFF2980B9)},
      {'level': 'C1', 'emoji': '📙', 'labelKey': 'level_advanced', 'color': const Color(0xFF9B59B6)},
      {'level': 'C2', 'emoji': '📕', 'labelKey': 'level_mastery', 'color': const Color(0xFF8E44AD)},
    ];

    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(context),
              const SizedBox(height: 16),
              Text(
                tr('hi_name').replaceFirst('{name}', _userName),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('your_english_level'),
                style: TextStyle(fontSize: 16, color: context.textMuted),
              ),
              const SizedBox(height: 32),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: levels.map((l) {
                  final level = l['level'] as String;
                  final emoji = l['emoji'] as String;
                  final label = tr(l['labelKey'] as String);
                  final color = l['color'] as Color;
                  final isSelected = _englishLevel == level;
                  return GestureDetector(
                    onTap: () => setState(() => _englishLevel = level),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : context.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : context.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 26)),
                          const SizedBox(height: 4),
                          Text(
                            level,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? color
                                  : context.appText,
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected ? color : context.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: color, size: 14),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              _buildContinueButton(context, _englishLevel.isNotEmpty ? _nextPage : null),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 3: Daily Goal ───────────────────────────────────────────────────

  Widget _buildDailyGoalPage(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(context),
              const SizedBox(height: 16),
              Text(
                tr('daily_word_goal_title'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('how_many_words'),
                style: TextStyle(fontSize: 16, color: context.textMuted),
              ),
              const SizedBox(height: 60),
              Center(
                child: Text(
                  '$_dailyWordGoal',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: context.primary,
                  ),
                ),
              ),
              Center(
                child: Text(
                  tr('words_per_day_label'),
                  style: TextStyle(fontSize: 16, color: context.textMuted),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _dailyWordGoal <= 10
                      ? tr('pace_light')
                      : _dailyWordGoal <= 20
                      ? tr('pace_good')
                      : _dailyWordGoal <= 40
                      ? tr('pace_ambitious')
                      : tr('pace_intense'),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Slider(
                value: _dailyWordGoal.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                activeColor: context.primary,
                onChanged: (value) =>
                    setState(() => _dailyWordGoal = value.toInt()),
              ),
              const Spacer(),
              _buildContinueButton(context, _nextPage),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Page 4: How it works ─────────────────────────────────────────────────

  Widget _buildHowItWorksPage(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackButton(context),
              const SizedBox(height: 8),
              Text(
                tr('how_lexivo_works'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr('four_steps'),
                style: TextStyle(fontSize: 16, color: context.textMuted),
              ),
              const SizedBox(height: 32),
              _buildStepCard(
                tr('step_1'),
                '📖',
                tr('step_1_title'),
                tr('step_1_desc'),
                const Color(0xFF6C63FF),
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                tr('step_2'),
                '🃏',
                tr('step_2_title'),
                tr('step_2_desc'),
                const Color(0xFFFF6584),
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                tr('step_3'),
                '🧠',
                tr('step_3_title'),
                tr('step_3_desc'),
                const Color(0xFF2ECC71),
              ),
              const SizedBox(height: 12),
              _buildStepCard(
                tr('step_4'),
                '🔄',
                tr('step_4_title'),
                tr('step_4_desc'),
                const Color(0xFFFF6B35),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_completed', true);
                    await prefs.setString('user_name', _userName);
                    await prefs.setString('english_level', _englishLevel);
                    await prefs.setString('language_level', _englishLevel);
                    await prefs.setString('word_source', 'prebuilt');
                    await prefs.setString('example_style', 'reallife');
                    await prefs.setString('user_profile', 'general');
                    await prefs.setInt('daily_word_goal', _dailyWordGoal);
                    if (!mounted) return;
                    navigator.pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => MainShell(
                          wordSource: 'prebuilt',
                          exampleStyle: 'reallife',
                          userProfile: _userName,
                          languageLevel: _englishLevel,
                          dailyWordGoal: _dailyWordGoal,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    tr('lets_start'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    String number,
    String emoji,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        number,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          tr('continue_label'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
