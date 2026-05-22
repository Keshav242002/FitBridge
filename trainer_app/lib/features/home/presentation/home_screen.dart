import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';
import '../../../shared/widgets/app_bar_with_role.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithRole(user: user),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: const [
            _HomeTile(icon: Icons.people_outline, label: 'Members', route: '/members'),
            _HomeTile(icon: Icons.chat_bubble_outline, label: 'Chats', route: '/chats'),
            _HomeTile(icon: Icons.calendar_month_outlined, label: 'Requests', route: '/requests'),
            _HomeTile(icon: Icons.bar_chart_outlined, label: 'Sessions', route: '/sessions'),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.icon, required this.label, required this.route});

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
