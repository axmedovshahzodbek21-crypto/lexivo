import 'package:flutter/material.dart';

/// Circular avatar for a class member: shows their profile photo when
/// [avatarUrl] is set, otherwise a coloured circle with their first initial.
/// A photo that fails to load also falls back to the initial (the initial is
/// the always-present `child`; the photo is a `foregroundImage` painted on
/// top, and [onForegroundImageError] just swallows the failure).
///
/// Student profile fields (name + avatar_url) reach the client through the
/// SECURITY DEFINER RPCs (get_class_dashboard / get_class_leaderboard) — a
/// direct `profiles` read is blocked by RLS for anyone but the row's owner.
class MemberAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Color color;
  final double size;

  const MemberAvatar({
    super.key,
    required this.name,
    required this.color,
    this.avatarUrl,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      foregroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
      onForegroundImageError: hasImage ? (_, _) {} : null,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
