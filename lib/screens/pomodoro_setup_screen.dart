import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'pomodoro_service.dart';
import '../app_theme.dart';

const _kBreakColor = Color(0xFF10B981);

// Pomodoro session length bounds/defaults for this setup screen, named so
// they aren't scattered as bare numeric literals across initial state and
// the custom-duration sliders below.
const _kDefaultWorkMinutes = 25;
const _kDefaultBreakMinutes = 5;
const double _kMinWorkMinutes = 5;
const double _kMaxWorkMinutes = 60;
const double _kMinBreakMinutes = 1;
const double _kMaxBreakMinutes = 20;
const _kAutoSkipSeconds = 5;

class PomodoroSetupScreen extends StatefulWidget {
  final VoidCallback onSkip;
  final VoidCallback onStart;

  const PomodoroSetupScreen({
    super.key,
    required this.onSkip,
    required this.onStart,
  });

  @override
  State<PomodoroSetupScreen> createState() => _PomodoroSetupScreenState();
}

class _PomodoroSetupScreenState extends State<PomodoroSetupScreen> {
  int _workMinutes = _kDefaultWorkMinutes;
  int _breakMinutes = _kDefaultBreakMinutes;
  int _autoSkipSeconds = _kAutoSkipSeconds;
  Timer? _autoSkipTimer;
  int? _selectedPreset = 0;

  static const _presets = [
    {'label': 'Classic',   'emoji': '🍅', 'work': 25, 'break': 5},
    {'label': 'Deep Work', 'emoji': '🧠', 'work': 50, 'break': 10},
    {'label': 'Quick',     'emoji': '⚡', 'work': 15, 'break': 3},
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSkip();
  }

  @override
  void dispose() {
    _autoSkipTimer?.cancel();
    super.dispose();
  }

  void _startAutoSkip() {
    _autoSkipTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_autoSkipSeconds <= 1) {
        timer.cancel();
        widget.onSkip();
        return;
      }
      setState(() => _autoSkipSeconds--);
    });
  }

  void _cancelAutoSkip() {
    _autoSkipTimer?.cancel();
    setState(() => _autoSkipSeconds = 0);
  }

  void _selectPreset(int index) {
    _cancelAutoSkip();
    final p = _presets[index];
    setState(() {
      _selectedPreset = index;
      _workMinutes = p['work'] as int;
      _breakMinutes = p['break'] as int;
    });
  }

  void _selectCustom() {
    _cancelAutoSkip();
    setState(() => _selectedPreset = null);
  }

  void _startPomodoro() {
    _autoSkipTimer?.cancel();
    PomodoroService().start(_workMinutes, _breakMinutes);
    widget.onStart();
  }

  double get _workFraction => _workMinutes / (_workMinutes + _breakMinutes);

  @override
  Widget build(BuildContext context) {
    final primary = context.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Mode',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.appText,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'Timed sessions with breaks',
                      style: TextStyle(fontSize: 13, color: context.textMuted),
                    ),
                  ],
                ),
              ),
              if (_autoSkipSeconds > 0)
                GestureDetector(
                  onTap: _cancelAutoSkip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Skip in ${_autoSkipSeconds}s',
                      style: TextStyle(fontSize: 12, color: context.textMuted),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Arc visualizer
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: _workFraction),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            builder: (context, fraction, _) {
              return SizedBox(
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(130, 130),
                      painter: _CyclePainter(
                        workFraction: fraction,
                        workColor: primary,
                        breakColor: _kBreakColor,
                        trackColor: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.07),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$_workMinutes',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: '+$_breakMinutes',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _kBreakColor,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'min cycle',
                          style: TextStyle(fontSize: 11, color: context.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: primary, label: 'Focus'),
              const SizedBox(width: 20),
              _LegendDot(color: _kBreakColor, label: 'Break'),
            ],
          ),
          const SizedBox(height: 18),

          // Preset cards + custom button
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...List.generate(_presets.length, (i) {
                  final p = _presets[i];
                  final selected = _selectedPreset == i;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectPreset(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? primary.withValues(alpha: 0.1)
                                : context.surface2,
                            border: Border.all(
                              color: selected ? primary : Colors.transparent,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p['emoji'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                p['label'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? primary : context.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${p['work']}+${p['break']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? primary : context.appText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(
                  width: 66,
                  child: GestureDetector(
                    onTap: _selectCustom,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _selectedPreset == null
                            ? primary.withValues(alpha: 0.1)
                            : context.surface2,
                        border: Border.all(
                          color: _selectedPreset == null ? primary : Colors.transparent,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: _selectedPreset == null ? primary : context.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _selectedPreset == null ? primary : context.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom sliders — only shown when Custom is selected
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _selectedPreset == null
                ? Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Column(
                      children: [
                        _SliderRow(
                          label: 'Focus',
                          value: _workMinutes.toDouble(),
                          min: _kMinWorkMinutes,
                          max: _kMaxWorkMinutes,
                          divisions: 11,
                          color: primary,
                          onChanged: (v) => setState(() => _workMinutes = v.round()),
                        ),
                        const SizedBox(height: 8),
                        _SliderRow(
                          label: 'Break',
                          value: _breakMinutes.toDouble(),
                          min: _kMinBreakMinutes,
                          max: _kMaxBreakMinutes,
                          divisions: 19,
                          color: _kBreakColor,
                          onChanged: (v) => setState(() => _breakMinutes = v.round()),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 22),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startPomodoro,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Start Focusing',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              'Skip, just learn',
              style: TextStyle(color: context.textMuted, fontSize: 14),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
        ],
          ),
        ),
      ),
    );
  }
}

class _CyclePainter extends CustomPainter {
  final double workFraction;
  final Color workColor;
  final Color breakColor;
  final Color trackColor;

  const _CyclePainter({
    required this.workFraction,
    required this.workColor,
    required this.breakColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final workSweep = workFraction * 2 * pi;

    // Focus arc
    canvas.drawArc(
      rect,
      -pi / 2,
      workSweep,
      false,
      Paint()
        ..color = workColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt,
    );

    // Break arc
    if (workFraction < 1.0) {
      canvas.drawArc(
        rect,
        -pi / 2 + workSweep,
        (1 - workFraction) * 2 * pi,
        false,
        Paint()
          ..color = breakColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(_CyclePainter old) =>
      old.workFraction != workFraction ||
      old.workColor != workColor ||
      old.breakColor != breakColor ||
      old.trackColor != trackColor;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.15),
              inactiveTrackColor: color.withValues(alpha: 0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${value.round()} min',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
