import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/api_client.dart';
import '../../../services/session_service.dart';
import '../../../models/session_log.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/error_retry.dart';
import '../../../widgets/empty_state.dart';
import '../bloc/sessions_bloc.dart';
import '../bloc/sessions_event.dart';
import '../bloc/sessions_state.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionsBloc(
        service: SessionService(api: context.read<ApiClient>()),
        userId: userId,
      ),
      child: const _SessionsView(),
    );
  }
}

class _SessionsView extends StatelessWidget {
  const _SessionsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
      body: BlocBuilder<SessionsBloc, SessionsState>(
        builder: (context, state) => switch (state) {
          SessionsLoading() => _buildSkeleton(),
          SessionsError(:final message) => ErrorRetry(
              message: message,
              onRetry: () => context.read<SessionsBloc>().add(const LoadSessions()),
            ),
          SessionsLoaded() => _buildLoaded(context, state),
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, _) => const SkeletonListTile(),
    );
  }

  Widget _buildLoaded(BuildContext context, SessionsLoaded state) {
    return Column(
      children: [
        _FilterBar(current: state.filter),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async =>
                context.read<SessionsBloc>().add(const LoadSessions()),
            child: state.filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: EmptyState(
                          icon: Icons.videocam_off_outlined,
                          title: 'No sessions yet',
                          subtitle: 'Schedule your first call',
                          ctaLabel: 'Go to Schedule',
                          onCta: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: state.filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) =>
                        _SessionRow(session: state.filtered[i]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current});

  final SessionFilter current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            selected: current == SessionFilter.all,
            onTap: () => context
                .read<SessionsBloc>()
                .add(const ChangeFilter(SessionFilter.all)),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Last 7 days',
            selected: current == SessionFilter.last7Days,
            onTap: () => context
                .read<SessionsBloc>()
                .add(const ChangeFilter(SessionFilter.last7Days)),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'This Month',
            selected: current == SessionFilter.thisMonth,
            onTap: () => context
                .read<SessionsBloc>()
                .add(const ChangeFilter(SessionFilter.thisMonth)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final SessionLog session;

  String get _dateLabel {
    final d = session.startedAt;
    return '${d.day}/${d.month}/${d.year}';
  }

  String get _durationLabel {
    final m = session.durationSec ~/ 60;
    final s = session.durationSec % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.videocam_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(_dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(_durationLabel, style: const TextStyle(color: Colors.black54)),
          if (session.rating != null) ...[
            const SizedBox(width: 12),
            ...List.generate(
              5,
              (i) => Icon(
                i < session.rating! ? Icons.star : Icons.star_border,
                size: 14,
                color: Colors.amber,
              ),
            ),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: () => _showDetail(context),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SessionDetail(session: session),
    );
  }
}

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.session});

  final SessionLog session;

  String get _dateTimeLabel {
    final d = session.startedAt;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} at $h:$m';
  }

  String get _durationLabel {
    final m = session.durationSec ~/ 60;
    final s = session.durationSec % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Session Details',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _DetailRow(icon: Icons.calendar_today_outlined, label: _dateTimeLabel),
            _DetailRow(icon: Icons.timer_outlined, label: _durationLabel),
            if (session.rating != null)
              _DetailRow(
                icon: Icons.star_outlined,
                label: '${'★' * session.rating!}${'☆' * (5 - session.rating!)} (${session.rating}/5)',
              ),
            if (session.trainerNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                'Trainer Notes',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(session.trainerNotes!),
            ],
            if (session.memberNotes?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text(
                'Member Notes',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(session.memberNotes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
