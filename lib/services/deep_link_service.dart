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
    // Cold start: app was closed when widget was tapped
    final initial = await _appLinks.getInitialLink();
    if (initial != null) _handleUri(initial);

    // Warm start: app already running, widget tapped
    _sub = _appLinks.uriLinkStream.listen(_handleUri);
  }

  static void dispose() => _sub?.cancel();

  static void _handleUri(Uri uri) {
    if (uri.scheme != 'lexivo' || uri.host != 'class') return;

    final classId   = uri.pathSegments.firstOrNull;
    final className = uri.queryParameters['name'] ?? 'Class';
    if (classId == null || classId.isEmpty) return;

    // Push to the class, replacing any existing class screen on the stack
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    // Pop back to root first so we don't stack duplicate class screens
    nav.popUntil((route) => route.isFirst);
    final isTeacher = uri.queryParameters['isTeacher'] == 'true';
    nav.push(MaterialPageRoute(
      builder: (_) => ClassShell(
        classId: classId,
        className: className,
        isTeacher: isTeacher,
      ),
    ));
  }
}
