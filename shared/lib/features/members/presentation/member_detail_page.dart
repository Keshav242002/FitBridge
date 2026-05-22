import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../models/session_log.dart';
import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../widgets/skeleton_loader.dart';

class MemberDetailPage extends StatefulWidget {
  const MemberDetailPage({super.key, required this.member});
  final User member;

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  List<SessionLog>? _sessions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final api = context.read<ApiClient>();
    final res = await api.get('/session-logs', query: {'userId': widget.member.id});
    if (!mounted) return;
    switch (res) {
      case ApiSuccess(:final body):
        final list = (body as List)
            .whereType<Map<String, dynamic>>()
            .map(SessionLog.fromJson)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        setState(() {
          _sessions = list.take(3).toList();
          _loading = false;
        });
      case ApiFailure(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return Scaffold(
      appBar: AppBar(title: Text(m.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    m.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: const Text('Member'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Recent sessions
          Text(
            'Recent Sessions',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_loading) const SkeletonLoader(),
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading sessions: $_error'),
              ),
            ),
          if (_sessions != null && _sessions!.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_outlined,
                        size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No sessions yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          if (_sessions != null)
            ...List.generate(_sessions!.length, (i) {
              final s = _sessions![i];
              return _SessionCard(session: s);
            }),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});
  final SessionLog session;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(session.startedAt);
    final minutes = session.durationSec ~/ 60;
    final seconds = session.durationSec % 60;
    final duration = '${minutes}m ${seconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(Icons.videocam_outlined,
              color: Theme.of(context).colorScheme.secondary),
        ),
        title: Text(date, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(duration),
        trailing: session.rating != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${session.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 2),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                ],
              )
            : null,
      ),
    );
  }
}
