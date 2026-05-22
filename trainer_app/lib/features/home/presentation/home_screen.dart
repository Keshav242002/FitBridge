import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

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
            _HomeTile(icon: Icons.people_outline, label: 'Members', dest: _Dest.members),
            _HomeTile(icon: Icons.chat_bubble_outline, label: 'Chats', dest: _Dest.chats),
            _HomeTile(icon: Icons.calendar_month_outlined, label: 'Requests', dest: _Dest.requests),
            _HomeTile(icon: Icons.bar_chart_outlined, label: 'Sessions', dest: _Dest.sessions),
          ],
        ),
      ),
      floatingActionButton: kDebugMode ? _HealthFab(user: user) : null,
    );
  }
}

enum _Dest { members, chats, requests, sessions }

class _HealthFab extends StatefulWidget {
  const _HealthFab({required this.user});
  final User user;

  @override
  State<_HealthFab> createState() => _HealthFabState();
}

class _HealthFabState extends State<_HealthFab> {
  bool _loading = false;

  Future<void> _ping(BuildContext context) async {
    if (_loading) return;
    final api = context.read<ApiClient>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    final res = await api.get('/health');
    if (!mounted) return;
    setState(() => _loading = false);
    switch (res) {
      case ApiSuccess(:final body):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Server OK — hmsMode: ${(body as Map)['hmsMode']}'),
            backgroundColor: Colors.green[700],
          ),
        );
      case ApiFailure(:final message):
        messenger.showSnackBar(
          SnackBar(content: Text('Server error: $message'), backgroundColor: Colors.red[700]),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _ping(context),
      icon: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.wifi_tethering),
      label: const Text('Ping Server'),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.icon, required this.label, required this.dest});

  final IconData icon;
  final String label;
  final _Dest dest;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigate(context),
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

  void _navigate(BuildContext context) {
    switch (dest) {
      case _Dest.chats:
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const ChatListPage()));
      case _Dest.requests:
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const RequestsScreen()));
      case _Dest.members:
      case _Dest.sessions:
        break;
    }
  }
}
