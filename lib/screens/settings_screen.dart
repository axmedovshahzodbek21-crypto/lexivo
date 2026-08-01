import '../main.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../data/storage_service.dart';
import '../app_theme.dart';
import '../l10n.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _notifTime = '20:00';
  int _dailyWordGoal = 5;
  String _englishLevel = 'B1';
  String _userName = '';
  String? _profileImagePath;
  String? _profileImageUrl;
  String _themeMode = 'system';
  bool _loading = true;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    appLangNotifier.addListener(_onLangChange);
  }

  @override
  void dispose() {
    appLangNotifier.removeListener(_onLangChange);
    _nameController.dispose();
    super.dispose();
  }

  void _onLangChange() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _notifTime = prefs.getString('notif_time') ?? '20:00';
      _dailyWordGoal = prefs.getInt('daily_word_goal') ?? 5;
      _englishLevel = prefs.getString('english_level') ?? 'B1';
      _userName = prefs.getString('user_name') ?? '';
      _profileImagePath = prefs.getString('profile_image_path');
      _profileImageUrl = prefs.getString('profile_image_url');
      _themeMode = prefs.getString('theme_mode') ?? 'system';
      _nameController.text = _userName;
      _loading = false;
    });
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ui_language', lang);
    appLangNotifier.value = lang;
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('name_updated_at', DateTime.now().toUtc().toIso8601String());
    setState(() => _userName = name);
    SyncService.pushSettings();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', picked.path);
    setState(() => _profileImagePath = picked.path);

    final user = currentUser;
    if (user != null) {
      try {
        final bytes = await File(picked.path).readAsBytes();
        await supabase.storage.from('avatars').uploadBinary(
          '${user.id}/avatar.jpg',
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
        final url = supabase.storage.from('avatars').getPublicUrl('${user.id}/avatar.jpg');
        final urlWithBust = '$url?t=${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString('profile_image_url', urlWithBust);
        await supabase.from('profiles').upsert({'id': user.id, 'avatar_url': urlWithBust});
        SyncService.pushSettings();
        if (mounted) setState(() => _profileImageUrl = urlWithBust);
      } catch (_) {}
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr('choose_photo'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: context.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  tr('camera'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF2ECC71),
                    size: 22,
                  ),
                ),
                title: Text(
                  tr('gallery'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              if (_profileImagePath != null || _profileImageUrl != null)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    tr('remove_photo'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade400,
                    ),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: ctx.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(tr('remove_photo'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        content: Text(tr('remove_photo_confirm')),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: Text(tr('remove'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('profile_image_path');
                    await prefs.remove('profile_image_url');
                    final user = currentUser;
                    if (user != null) {
                      try {
                        await supabase.storage.from('avatars').remove(['${user.id}/avatar.jpg']);
                        await supabase.from('profiles').upsert({'id': user.id, 'avatar_url': null});
                      } catch (_) {}
                    }
                    setState(() { _profileImagePath = null; _profileImageUrl = null; });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameDialog() {
    _nameController.text = _userName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('edit_name'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: tr('your_name'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _saveName(_nameController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
    final streak = await StorageService.getStreak();
    final userName = prefs.getString('user_name') ?? '';
    await NotificationService.scheduleReminder(
      customTime: _notifTime,
      streak: streak,
      userName: userName,
      enabled: value,
    );
    SyncService.pushSettings();
  }

  Future<void> _pickNotifTime() async {
    final parts = _notifTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 20,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_time', formatted);
    await NotificationService.saveTime(formatted);
    setState(() => _notifTime = formatted);
    if (_notificationsEnabled) {
      final streak = await StorageService.getStreak();
      final userName = prefs.getString('user_name') ?? '';
      await NotificationService.scheduleReminder(
        customTime: formatted,
        streak: streak,
        userName: userName,
        enabled: true,
      );
    }
    SyncService.pushSettings();
  }

  Future<void> _setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    setState(() => _themeMode = mode);
    themeModeNotifier.value = mode == 'dark'
        ? ThemeMode.dark
        : mode == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
  }

  Future<void> _setEnglishLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('english_level', level);
    await prefs.setString('language_level', level);
    await prefs.setString('language_level_updated_at', DateTime.now().toIso8601String());
    setState(() => _englishLevel = level);
  }

  Future<void> _setDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_word_goal', goal);
    setState(() => _dailyWordGoal = goal);
    SyncService.pushSettings();
  }

  Future<void> _handleSave() async {
    if (mounted) Navigator.pop(context);
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
        title: Text(
          tr('settings_title'),
          style: TextStyle(
            color: context.appText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
                      onPressed: _handleSave,
                      style: TextButton.styleFrom(
                        backgroundColor: context.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(tr('save'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Section
                _buildSectionHeader(context, tr('profile'), icon: '👤', iconBg: const Color(0xFF6366F1).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Stack(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: context.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(36),
                                border: Border.all(
                                  color: context.primary.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: _profileImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(36),
                                      child: Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => _profileImagePath != null
                                            ? Image.file(File(_profileImagePath!), fit: BoxFit.cover)
                                            : const Center(child: Text('👤', style: TextStyle(fontSize: 32))),
                                      ),
                                    )
                                  : _profileImagePath != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(36),
                                          child: Image.file(File(_profileImagePath!), fit: BoxFit.cover),
                                        )
                                      : const Center(
                                          child: Text(
                                            '👤',
                                            style: TextStyle(fontSize: 32),
                                          ),
                                        ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: context.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName.isNotEmpty ? _userName : 'Learner',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.appText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('english_level_label').replaceFirst('{level}', _englishLevel),
                              style: TextStyle(
                                fontSize: 13,
                                color: context.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: context.primary,
                          size: 20,
                        ),
                        onPressed: _showEditNameDialog,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('appearance'), icon: '🎨', iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('theme'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _themeOption(context, tr('system'), 'system', Icons.brightness_auto),
                          const SizedBox(width: 8),
                          _themeOption(context, tr('light'), 'light', Icons.light_mode),
                          const SizedBox(width: 8),
                          _themeOption(context, tr('dark'), 'dark', Icons.dark_mode),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Language Section
                _buildSectionHeader(context, tr('language'), icon: '🌐', iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('language_label'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _langOption(context, tr('lang_en'), 'en'),
                          const SizedBox(width: 8),
                          _langOption(context, tr('lang_uz'), 'uz'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('notifications'), icon: '🔔', iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1)),
                _buildCard(
                  context,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tr('daily_notifications'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: context.appText,
                      ),
                    ),
                    subtitle: Text(
                      tr('notif_subtitle'),
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _notificationsEnabled,
                    activeThumbColor: context.primary,
                    onChanged: _toggleNotifications,
                  ),
                ),
                if (_notificationsEnabled) ...[
                  const SizedBox(height: 8),
                  _buildCard(
                    context,
                    child: Column(
                      children: [
                        // Fixed: Morning
                        Row(
                          children: [
                            const Text('📚', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Good morning!', style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 13)),
                                  Text('Start your day with a few words', style: TextStyle(color: context.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text('8:00 AM', style: TextStyle(color: context.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Fixed: Streak at Risk
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Streak at Risk', style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 13)),
                                  Text('Don\'t forget to study today', style: TextStyle(color: context.textMuted, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text('9:00 PM', style: TextStyle(color: context.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 4),
                        // Custom: user-chosen
                        InkWell(
                          onTap: _pickNotifTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              const Text('📖', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tr('reminder_time'), style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 13)),
                                    Text('Tap to change', style: TextStyle(color: context.textMuted, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(_notifTime, style: TextStyle(color: context.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: context.textMuted, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('english_level'), icon: '📊', iconBg: const Color(0xFF10B981).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('my_level'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.appText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.8,
                        children:
                            [
                              {
                                'level': 'A1',
                                'emoji': '🌱',
                                'color': const Color(0xFF2ECC71),
                              },
                              {
                                'level': 'A2',
                                'emoji': '🌿',
                                'color': const Color(0xFF27AE60),
                              },
                              {
                                'level': 'B1',
                                'emoji': '📗',
                                'color': const Color(0xFF3498DB),
                              },
                              {
                                'level': 'B2',
                                'emoji': '📘',
                                'color': const Color(0xFF2980B9),
                              },
                              {
                                'level': 'C1',
                                'emoji': '📙',
                                'color': const Color(0xFF9B59B6),
                              },
                              {
                                'level': 'C2',
                                'emoji': '📕',
                                'color': const Color(0xFF8E44AD),
                              },
                            ].map((l) {
                              final level = l['level'] as String;
                              final emoji = l['emoji'] as String;
                              final color = l['color'] as Color;
                              final isSelected = _englishLevel == level;
                              return GestureDetector(
                                onTap: () => _setEnglishLevel(level),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.12)
                                        : context.surface2,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : context.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        level,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? color
                                              : context.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('display'), icon: '🔤', iconBg: const Color(0xFF6366F1).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('font_size'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appText,
                            ),
                          ),
                          Text(
                            textScaleNotifier.value == 0.8
                                ? tr('small')
                                : textScaleNotifier.value == 1.0
                                ? tr('medium')
                                : textScaleNotifier.value == 1.2
                                ? tr('large')
                                : tr('extra_large'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: textScaleNotifier.value,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        activeColor: context.primary,
                        onChanged: (value) async {
                          textScaleNotifier.value = value;
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setDouble('text_scale', value);
                          setState(() {});
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr('small'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                          Text(tr('medium'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                          Text(tr('large'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                          Text(tr('xl'), style: TextStyle(fontSize: 11, color: context.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildSectionHeader(context, tr('daily_goal_section'), icon: '🎯', iconBg: const Color(0xFFF97316).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('words_per_day'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.appText,
                            ),
                          ),
                          Text(
                            tr('words_count').replaceFirst('{n}', '$_dailyWordGoal'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: _dailyWordGoal.toDouble(),
                        min: 3,
                        max: 100,
                        divisions: 97,
                        activeColor: context.primary,
                        onChanged: (value) => _setDailyGoal(value.toInt()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '3',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                            ),
                          ),
                          Text(
                            '100',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('about'), icon: 'ℹ️', iconBg: const Color(0xFF6366F1).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      _buildAboutRow(context, '📱', tr('app_label'), 'Lexivo'),
                      Divider(height: 16, color: context.border),
                      _buildAboutRow(context, '🏷️', tr('version'), '1.0.0'),
                      Divider(height: 16, color: context.border),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://lexivo-web-six.vercel.app'), mode: LaunchMode.externalApplication),
                        child: Row(
                          children: [
                            const Text('🌐', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Website', style: TextStyle(fontWeight: FontWeight.w500, color: context.appText))),
                            Text('lexivo-web.vercel.app', style: TextStyle(color: context.primary, fontSize: 13)),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 14, color: context.primary),
                          ],
                        ),
                      ),
                      Divider(height: 16, color: context.border),
                      GestureDetector(
                        onTap: () => launchUrl(Uri.parse('https://t.me/lexivo_support_bot'), mode: LaunchMode.externalApplication),
                        child: Row(
                          children: [
                            const Text('✈️', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Contact Support', style: TextStyle(fontWeight: FontWeight.w500, color: context.appText))),
                            Text('@lexivo_support_bot', style: TextStyle(color: context.primary, fontSize: 13)),
                            const SizedBox(width: 4),
                            Icon(Icons.open_in_new, size: 14, color: context.primary),
                          ],
                        ),
                      ),
                      Divider(height: 16, color: context.border),
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://github.com/axmedovshahzodbek21-crypto/lexivo-web/releases/latest/download/app-release.apk'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Row(
                          children: [
                            const Text('🤖', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 12),
                            Expanded(child: Text('Download Android App', style: TextStyle(fontWeight: FontWeight.w500, color: context.appText))),
                            Text('Latest APK', style: TextStyle(color: const Color(0xFF3DDC84), fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.download, size: 14, color: Color(0xFF3DDC84)),
                          ],
                        ),
                      ),
                      Divider(height: 16, color: context.border),
                      _buildAboutRow(context, '📚', tr('collections'), '3 collections'),
                      Divider(height: 16, color: context.border),
                      _buildAboutRow(context, '🔤', tr('total_words'), '700+ words'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('account'), icon: '🔑', iconBg: const Color(0xFF6366F1).withValues(alpha: 0.12)),
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      if (Supabase.instance.client.auth.currentUser != null) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person_outline, color: context.primary, size: 20),
                          ),
                          title: Text(
                            Supabase.instance.client.auth.currentUser!.email ?? tr('sign_in'),
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.appText, fontSize: 14),
                          ),
                          subtitle: Text(tr('signed_in_sub'), style: TextStyle(fontSize: 12, color: context.textMuted)),
                        ),
                        Divider(height: 16, color: context.border),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout, color: Colors.red, size: 20),
                          ),
                          title: Text(tr('sign_out'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                          onTap: _confirmSignOut,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                          ),
                          title: Text(tr('delete_account'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          subtitle: Text(tr('delete_account_sub'), style: TextStyle(fontSize: 12, color: context.textMuted)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                          onTap: _showDeleteAccountDialog,
                        ),
                      ] else
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: context.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.login, color: context.primary, size: 20),
                          ),
                          title: Text(tr('sign_in'), style: TextStyle(fontWeight: FontWeight.bold, color: context.primary)),
                          subtitle: Text(tr('sign_in_sub'), style: TextStyle(fontSize: 12, color: context.textMuted)),
                          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: context.primary),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _buildSectionHeader(context, tr('data'), icon: '⚠️', iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1)),
                _buildCard(
                  context,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                    title: Text(tr('reset_progress'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    subtitle: Text(tr('reset_progress_sub'), style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
                    onTap: _showResetDialog,
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: Colors.red),
            const SizedBox(width: 8),
            Text(tr('sign_out'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(tr('sign_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('sign_out'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) _signOut();
  }

  Future<void> _signOut() async {
    await StorageService.clearAllProgress();
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(tr('delete_account_title'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('delete_perm_intro'), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...[
              tr('delete_item1'),
              tr('delete_item2'),
              tr('delete_item3'),
              tr('delete_item4'),
              tr('delete_item5'),
            ].map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(t, style: TextStyle(fontSize: 13, color: context.textMuted)),
            )),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Text(tr('cannot_undo'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel'), style: TextStyle(color: context.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(tr('delete_forever')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final navigator = Navigator.of(context);
    try {
      await Supabase.instance.client.rpc('delete_own_account');
      await StorageService.clearAllProgress();
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tr('error_deleting')}$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr('reset_progress_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          tr('reset_progress_body'),
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                final db = Supabase.instance.client;
                final ts = DateTime.now().toUtc().toIso8601String();
                await db.from('user_data').upsert({
                  'id': user.id,
                  'total_xp': 0, 'streak': 0, 'streak_freezes': 0,
                  'last_study_date': null, 'last_freeze_week': null,
                  'today_xp': 0, 'today_xp_date': null,
                  'daily_words_learned': 0, 'daily_words_date': null,
                  'stats_updated_at': ts,
                  'learned_words': [], 'srs_words': [], 'starred_words': [],
                  'hard_words': [], 'study_days': [], 'review_days': [],
                  'word_goal_days': [], 'unit_done_days': [], 'xp_history': [],
                  'unit_progress': {}, 'review_log': {}, 'imported_words': [],
                  'achievements': [], 'lists_updated_at': ts,
                  'reset_at': ts,
                });
                await db.from('srs_words').delete().eq('user_id', user.id);
                await db.from('learned_words').delete().eq('user_id', user.id);
                await db.from('starred_words').delete().eq('user_id', user.id);
                await db.from('xp_history').delete().eq('user_id', user.id);
                await db.from('user_stats').delete().eq('id', user.id);
                await db.from('unit_progress').delete().eq('user_id', user.id);
              }
              await StorageService.clearAllProgress();
              final prefs = await SharedPreferences.getInstance();
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => MainShell(
                    wordSource: prefs.getString('word_source') ?? 'prebuilt',
                    exampleStyle: prefs.getString('example_style') ?? 'reallife',
                    userProfile: prefs.getString('user_profile') ?? 'worker',
                    languageLevel: prefs.getString('language_level') ?? 'intermediate',
                    dailyWordGoal: prefs.getInt('daily_word_goal') ?? 15,
                  ),
                ),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(tr('reset')),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String icon = '', Color? iconBg}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (icon.isNotEmpty) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg ?? context.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 15))),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.appText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeOption(BuildContext context, String label, String value, IconData icon) {
    final selected = _themeMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setThemeMode(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.primary : context.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.primary : context.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : context.textMuted,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : context.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, String label, String value) {
    final selected = appLangNotifier.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setLanguage(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? context.primary : context.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? context.primary : context.border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : context.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: context.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildAboutRow(BuildContext context, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: context.appText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: context.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}
