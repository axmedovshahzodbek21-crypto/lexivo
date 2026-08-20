import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../main.dart' show navigatorKey;
import '../screens/class_shell.dart';

/// Listens for lexivo://class/{id}?name={name} deep links (fired by
/// the home-screen widget) and navigates to the correct ClassShell.
class DeepLinkService {
  static final _appLinks = AppLinks();
  static StreamSubscription<Uri>? _sub;

  static Future<void> init() async {
    // Cold start: app was closed when widget was tapped. This runs before
    // runApp() (see main.dart), so navigatorKey.currentState is still null
    // here — fetching the link is fine this early, but handling it (which
    // pushes a route) has to wait until the first frame, once MaterialApp's
    // Navigator actually exists.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleUri(initial));
    }

    // Warm start: app already running, widget tapped
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  static void dispose() => _sub?.cancel();

  static void _handleUri(Uri uri) {
    if (uri.scheme != 'lexivo' || uri.host != 'class') return;

    final classId   = uri.pathSegments.firstOrNull;
    final className = uri.queryParameters['name'] ?? 'Class';
    if (classId == null || classId.isEmpty) return;

    final isTeacher = uri.queryParameters['isTeacher'] == 'true';
    navigateToClass(classId: classId, className: className, isTeacher: isTeacher);
  }

  // Shared by the widget-tap deep link above and OneSignalService's
  // notification-click handler (main.dart) — both ultimately just need to
  // land on the right ClassShell.
  static void navigateToClass({
    required String classId,
    required String className,
    bool isTeacher = false,
  }) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      // Cold start (app was closed when the notification/widget was
      // tapped): the Navigator may not exist yet at this exact moment.
      // Retry after the first frame instead of silently dropping it.
      WidgetsBinding.instance.addPostFrameCallback((_) =>
          navigateToClass(classId: classId, className: className, isTeacher: isTeacher));
      return;
    }

    // Pop back to root first so we don't stack duplicate class screens
    nav.popUntil((route) => route.isFirst);
    nav.push(MaterialPageRoute(
      builder: (_) => ClassShell(
        classId: classId,
        className: className,
        isTeacher: isTeacher,
      ),
    ));
  }
}
