import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum PomodoroState { idle, working, onBreak }

class PomodoroService extends ChangeNotifier with WidgetsBindingObserver {
  static final PomodoroService _instance = PomodoroService._internal();
  factory PomodoroService() => _instance;
  PomodoroService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  PomodoroState _state = PomodoroState.idle;
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _secondsRemaining = 0;
  int _pomodorosCompleted = 0;
  Timer? _timer;
  // Wall-clock target for the current phase (work/break) instead of trusting
  // a per-tick decrement — Timer.periodic can be throttled or paused while
  // the app is backgrounded, so counting down by exactly 1 per tick drifted
  // from real elapsed time whenever the app was backgrounded mid-session.
  // Recomputing _secondsRemaining from this each tick (and immediately on
  // app resume, see didChangeAppLifecycleState) keeps the displayed time
  // accurate regardless of how many ticks were actually delivered.
  DateTime? _phaseEndTime;
  bool _observerRegistered = false;

  PomodoroState get state => _state;
  int get secondsRemaining => _secondsRemaining;
  int get pomodorosCompleted => _pomodorosCompleted;
  bool get isActive => _state != PomodoroState.idle;
  bool get isWorking => _state == PomodoroState.working;
  bool get isOnBreak => _state == PomodoroState.onBreak;

  String get timeDisplay {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Lexivo',
      appUserModelId: 'com.lexivo.app',
      guid: 'a8b9c0d1-e2f3-4a5b-6c7d-8e9f0a1b2c3d',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      windows: windowsSettings,
    );
    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );
    // Guarded — initialize() is called from MainShell.initState(), which can
    // run more than once per app process (e.g. logout then log back in
    // remounts MainShell). WidgetsBinding.addObserver has no dedup of its
    // own, so without this guard each remount would register this same
    // singleton instance again, firing didChangeAppLifecycleState multiple
    // times per actual lifecycle event.
    if (!_observerRegistered) {
      _observerRegistered = true;
      WidgetsBinding.instance.addObserver(this);
    }
  }

  // Immediately reconciles the displayed countdown against wall-clock time
  // on resume, instead of waiting up to 1 second for the next Timer tick to
  // self-correct (Timer.periodic can be throttled/paused while backgrounded,
  // so it may not fire again the instant the app resumes).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _phaseEndTime != null) {
      _reconcileFromWallClock();
    }
  }

  void _reconcileFromWallClock() {
    if (_phaseEndTime == null) return;
    final remaining = _phaseEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _onTimerEnd();
    } else if (remaining != _secondsRemaining) {
      _secondsRemaining = remaining;
      notifyListeners();
    }
  }

  void _beginPhase(PomodoroState newState, int seconds) {
    _state = newState;
    _secondsRemaining = seconds;
    _phaseEndTime = DateTime.now().add(Duration(seconds: seconds));
  }

  void start(int workMinutes, int breakMinutes) {
    _workMinutes = workMinutes;
    _breakMinutes = breakMinutes;
    _beginPhase(PomodoroState.working, workMinutes * 60);
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Recomputed from the wall-clock phase end, not decremented by
      // exactly 1 per tick — Timer.periodic can be throttled or paused
      // while the app is backgrounded, which previously let the displayed
      // countdown drift from real elapsed time.
      final remaining = _phaseEndTime != null
          ? _phaseEndTime!.difference(DateTime.now()).inSeconds
          : _secondsRemaining - 1;

      if (remaining <= 0) {
        _onTimerEnd();
        return;
      }

      if (remaining == 61 && _state == PomodoroState.working) {
        _sendNotification(
          '🍅 Almost done!',
          '1 minute left in your focus session. Get ready for a break!',
        );
      }
      if (remaining == 61 && _state == PomodoroState.onBreak) {
        _sendNotification(
          '✅ Break ending!',
          'Break ends in 1 minute. Get ready to focus!',
        );
      }

      _secondsRemaining = remaining;
      notifyListeners();
    });
  }

  void _onTimerEnd() {
    _timer?.cancel();
    if (_state == PomodoroState.working) {
      _pomodorosCompleted++;
      _beginPhase(PomodoroState.onBreak, _breakMinutes * 60);
      _sendNotification(
        '🍅 Focus session complete!',
        'Time for a $_breakMinutes-minute break. You earned it!',
      );
      _startTimer();
    } else if (_state == PomodoroState.onBreak) {
      _beginPhase(PomodoroState.working, _workMinutes * 60);
      _sendNotification(
        '✅ Break over!',
        "Ready to get back to learning? Let's go!",
      );
      _startTimer();
    }
    notifyListeners();
  }

  void skipBreak() {
    if (_state != PomodoroState.onBreak) return;
    _timer?.cancel();
    _beginPhase(PomodoroState.working, _workMinutes * 60);
    _startTimer();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    _secondsRemaining = 0;
    _phaseEndTime = null;
    notifyListeners();
  }

  Future<void> _sendNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Pomodoro timer notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      windows: WindowsNotificationDetails(),
    );
    await _notifications.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  // Not named dispose()/not an override on purpose — this is a singleton
  // shared for the whole app session, not a per-screen ChangeNotifier. A
  // screen that followed the normal pattern of disposing a listened-to
  // ChangeNotifier in its own dispose() would otherwise permanently disable
  // this instance: ChangeNotifier.dispose() sets an internal "disposed" flag
  // with no way to undo it, so every later notifyListeners() call (from any
  // other screen still using the timer) would throw in debug for the rest
  // of the app session. Only the timer — this instance's own resource —
  // ever needs cleanup here.
  void cancelTimer() {
    _timer?.cancel();
  }
}
