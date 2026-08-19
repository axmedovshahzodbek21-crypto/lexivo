import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum PomodoroState { idle, working, onBreak }

class PomodoroService extends ChangeNotifier {
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
  }

  void start(int workMinutes, int breakMinutes) {
    _workMinutes = workMinutes;
    _breakMinutes = breakMinutes;
    _state = PomodoroState.working;
    _secondsRemaining = workMinutes * 60;
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        _onTimerEnd();
        return;
      }

      if (_secondsRemaining == 61 && _state == PomodoroState.working) {
        _sendNotification(
          '🍅 Almost done!',
          '1 minute left in your focus session. Get ready for a break!',
        );
      }
      if (_secondsRemaining == 61 && _state == PomodoroState.onBreak) {
        _sendNotification(
          '✅ Break ending!',
          'Break ends in 1 minute. Get ready to focus!',
        );
      }

      _secondsRemaining--;
      notifyListeners();
    });
  }

  void _onTimerEnd() {
    _timer?.cancel();
    if (_state == PomodoroState.working) {
      _pomodorosCompleted++;
      _state = PomodoroState.onBreak;
      _secondsRemaining = _breakMinutes * 60;
      _sendNotification(
        '🍅 Focus session complete!',
        'Time for a $_breakMinutes-minute break. You earned it!',
      );
      _startTimer();
    } else if (_state == PomodoroState.onBreak) {
      _state = PomodoroState.working;
      _secondsRemaining = _workMinutes * 60;
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
    _state = PomodoroState.working;
    _secondsRemaining = _workMinutes * 60;
    _startTimer();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    _secondsRemaining = 0;
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
