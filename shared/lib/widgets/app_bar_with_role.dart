import 'package:flutter/material.dart';
import '../models/models.dart';

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
      title: Text('$roleLabel • ${user.name}'),
      actions: actions,
      bottom: bottom,
    );
  }
}
