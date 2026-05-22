import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/call_request.dart';
import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/schedule_service.dart';
import '../../../widgets/dev_panel.dart';
import '../../call/presentation/pre_join_page.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return BlocProvider(
      create: (_) => RequestsBloc(
        service: ScheduleService(api: api),
        trainerId: AuthService.currentUser()!.id,
      ),
      child: const _RequestsView(),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      body: BlocConsumer<RequestsBloc, RequestsState>(
        listener: (ctx, state) {
          if (state is RequestsError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => ctx.read<RequestsBloc>().add(const LoadRequests()),
                ),
              ),
            );
          }
        },
        builder: (ctx, state) {
          return switch (state) {
            RequestsLoading() => const Center(child: CircularProgressIndicator()),
            RequestsError() => _buildError(ctx),
            RequestsLoaded(:final requests) => _buildList(ctx, requests),
          };
        },
      ),
    );
  }

  Widget _buildError(BuildContext ctx) => Center(
        child: ElevatedButton(
          onPressed: () => ctx.read<RequestsBloc>().add(const LoadRequests()),
          child: const Text('Retry'),
        ),
      );

  Widget _buildList(BuildContext ctx, List<CallRequest> requests) {
    final pending =
        requests.where((r) => r.status == CallRequestStatus.pending).toList();
    final upcoming = requests
        .where((r) =>
            r.status == CallRequestStatus.approved &&
            r.scheduledFor.isAfter(DateTime.now()))
        .toList();

    if (pending.isEmpty && upcoming.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => ctx.read<RequestsBloc>().add(const LoadRequests()),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text('No pending requests.', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ctx.read<RequestsBloc>().add(const LoadRequests()),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            _SectionHeader(title: 'Pending (${pending.length})'),
            const SizedBox(height: 8),
            ...pending.map((r) => _PendingCard(request: r)),
            const SizedBox(height: 20),
          ],
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(title: 'Upcoming Calls (${upcoming.length})'),
            const SizedBox(height: 8),
            ...upcoming.map((r) => _UpcomingCard(request: r)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black54));
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.request});
  final CallRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime(request.scheduledFor),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(request.note, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: () =>
                      context.read<RequestsBloc>().add(ApproveRequest(request.id)),
                  child: const Text('Approve'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showDeclineSheet(context),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeclineSheet(BuildContext context) {
    final bloc = context.read<RequestsBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeclineSheet(
        onDecline: (reason) => bloc.add(DeclineRequest(id: request.id, reason: reason)),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  String _month(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          [m - 1];
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.request});
  final CallRequest request;

  @override
  Widget build(BuildContext context) {
    final canJoin = allowJoiningCallsAnytime ||
        request.scheduledFor.difference(DateTime.now()).inMinutes <= 10;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateTime(request.scheduledFor),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (request.note.isNotEmpty)
                    Text(request.note,
                        style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
            if (canJoin)
              FilledButton.icon(
                onPressed: () {
                  final user = AuthService.currentUser()!;
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PreJoinPage(
                      callRequestId: request.id,
                      userId: user.id,
                      userName: user.name,
                      role: UserRole.trainer.name,
                      memberId: request.memberId,
                      trainerId: user.id,
                    ),
                  ));
                },
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join'),
              )
            else
              Text(
                _timeUntil(request.scheduledFor),
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }

  String _timeUntil(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inHours > 0) return 'in ${diff.inHours}h';
    return 'in ${diff.inMinutes}m';
  }

  String _formatDateTime(DateTime dt) {
    final date = '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  String _month(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          [m - 1];
}

class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet({required this.onDecline});
  final void Function(String reason) onDecline;

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Decline Request',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLength: 140,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Reason (optional)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onDecline(_ctrl.text.trim());
                },
                child: const Text('Confirm Decline'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
