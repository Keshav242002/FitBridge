import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

class AppBarWithRole extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWithRole({
    super.key,
    required this.user,
    this.actions,
    this.bottom,
  });

  final User user;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final roleLabel = user.role == UserRole.trainer ? 'Trainer' : 'Member';
    return AppBar(
      title: Row(
        children: [
          Text(user.name),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
