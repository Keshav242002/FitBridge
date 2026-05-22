import 'package:flutter/material.dart';
import 'package:wtf_shared/wtf_shared.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return DevPanelOverlay(
      child: Scaffold(
        appBar: AppBarWithRole(user: user),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: const [
              SizedBox(height: 8),
              _HomeCard(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                subtitle: 'Message your trainer',
                destination: _Dest.chat,
              ),
              SizedBox(height: 16),
              _HomeCard(
                icon: Icons.calendar_month_outlined,
                label: 'Schedule',
                subtitle: 'Request a video call',
                destination: _Dest.schedule,
              ),
              SizedBox(height: 16),
              _HomeCard(
                icon: Icons.bar_chart_outlined,
                label: 'Sessions',
                subtitle: 'View past sessions',
                destination: _Dest.sessions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Dest { chat, schedule, sessions }

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.destination,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final _Dest destination;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigate(context),
      ),
    );
  }

  void _navigate(BuildContext context) {
    final user = AuthService.currentUser()!;
    switch (destination) {
      case _Dest.chat:
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const ChatListPage()));
      case _Dest.schedule:
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const MyRequestsPage()));
      case _Dest.sessions:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SessionsPage(userId: user.id),
          ),
        );
    }
  }
}
