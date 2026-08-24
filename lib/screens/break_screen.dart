import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'pomodoro_service.dart';
import '../app_theme.dart';
import '../l10n.dart';

class BreakOverlay extends StatefulWidget {
  const BreakOverlay({super.key});

  @override
  State<BreakOverlay> createState() => _BreakOverlayState();
}

class _BreakOverlayState extends State<BreakOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnim;
  int _tipIndex = 0;
  Timer? _tipTimer;
  // Tracks whether the breathing animation/tip timer are currently running,
  // so _syncWithBreakState only starts/stops them on an actual on-break
  // transition instead of on every one of PomodoroService's per-second
  // notifyListeners() calls.
  bool _running = false;

  final List<String> _tips = [
    '👁 Look 20 feet away for 20 seconds.\nYour eyes need rest too.',
    '🧘 Take 3 slow deep breaths.\nIn through nose, out through mouth.',
    '💧 Drink some water.\nHydration boosts memory.',
    '🙆 Stand up and stretch your neck.\nRoll shoulders back twice.',
    '😊 You\'re doing great!\nConsistent study beats marathon sessions.',
    '🧠 Your brain is consolidating\nwhat you just learned right now.',
    '🌿 Look at something green or far away.\nReduces eye strain.',
    '👐 Shake out your hands.\nRelease tension from typing.',
  ];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breatheAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    // This overlay is mounted at the app root for the whole session (see
    // main.dart), so unconditionally starting the animation/timer here (as
    // this used to) ran a 4s repeating animation and a 6s periodic rebuild
    // for the app's entire lifetime, not just while a break is actually
    // showing. Start/stop them only on real on-break transitions instead.
    PomodoroService().addListener(_syncWithBreakState);
    _syncWithBreakState();
  }

  void _syncWithBreakState() {
    final onBreak = PomodoroService().isOnBreak;
    if (onBreak == _running) return;
    _running = onBreak;
    if (onBreak) {
      _breatheController.repeat(reverse: true);
      _tipTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (mounted) setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      });
    } else {
      _breatheController.stop();
      _tipTimer?.cancel();
      _tipTimer = null;
    }
  }

  @override
  void dispose() {
    PomodoroService().removeListener(_syncWithBreakState);
    _breatheController.dispose();
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = PomodoroService();

    // The outer ListenableBuilder only decides show/hide — its `child` is
    // built once and reused across every per-second tick notification
    // instead of reconstructing the blur, breathing animation, tip card and
    // skip button on every tick just to update a timer string. Only the
    // countdown/pomodoro-count text below has its own small ListenableBuilder
    // to pick up the per-second changes.
    return ListenableBuilder(
      listenable: service,
      child: _BreakContent(breatheAnim: _breatheAnim, tips: _tips, tipIndex: _tipIndex),
      builder: (context, child) {
        if (!service.isOnBreak) return const SizedBox.shrink();
        return child!;
      },
    );
  }
}

class _BreakContent extends StatelessWidget {
  final Animation<double> breatheAnim;
  final List<String> tips;
  final int tipIndex;

  const _BreakContent({required this.breatheAnim, required this.tips, required this.tipIndex});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blur background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(color: Colors.black.withValues(alpha: 0.7)),
        ),

        // Content
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breathing animation
              ScaleTransition(
                scale: breatheAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.green.shade300,
                      width: 3,
                    ),
                  ),
                  child: const Center(
                    child: Text('☕', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Break Time',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Only these two lines need to update every second — scoped
              // to their own ListenableBuilder instead of the whole overlay.
              ListenableBuilder(
                listenable: PomodoroService(),
                builder: (context, _) {
                  final service = PomodoroService();
                  return Column(children: [
                    Text(
                      service.timeDisplay,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade300,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🍅 ${service.pomodorosCompleted} Pomodoro${service.pomodorosCompleted != 1 ? 's' : ''} completed',
                      style: const TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                  ]);
                },
              ),
              const SizedBox(height: 40),

              // Tip card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  key: ValueKey(tipIndex),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tips[tipIndex],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Skip break button
              TextButton(
                onPressed: () => PomodoroService().skipBreak(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Skip Break →',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Timer pill widget — shown in AppBar during active session
class PomodoroTimerPill extends StatelessWidget {
  const PomodoroTimerPill({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PomodoroService();

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isActive) return const SizedBox.shrink();

        final isWorking = service.isWorking;
        final color = isWorking ? context.primary : Colors.green;

        return GestureDetector(
          onTap: () => _showPomodoroOptions(context, service),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isWorking ? '🍅' : '☕',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  service.timeDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPomodoroOptions(BuildContext context, PomodoroService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🍅 ', style: TextStyle(fontSize: 24)),
            Text(
              service.isWorking ? 'Focus Session' : 'Break Time',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              service.timeDisplay,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: context.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${service.pomodorosCompleted} Pomodoros completed today',
              style: TextStyle(color: context.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              service.stop();
            },
            child: const Text(
              'Stop Session',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(tr('keep_going_btn')),
          ),
        ],
      ),
    );
  }
}
