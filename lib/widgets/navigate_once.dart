import 'package:flutter/material.dart';

/// Guards against double-navigation from a fast double-tap on a card: a
/// second tap that lands before the first push's route transition even
/// begins would otherwise stack a duplicate route. Mix this into a
/// [State] and call [pushOnce] instead of `Navigator.push` directly.
mixin NavigateOnceMixin<T extends StatefulWidget> on State<T> {
  bool _navigating = false;

  Future<void> pushOnce(Route route) async {
    if (_navigating) return;
    _navigating = true;
    try {
      await Navigator.push(context, route);
    } finally {
      _navigating = false;
    }
  }
}
