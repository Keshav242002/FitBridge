import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/call_request.dart';
import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/schedule_service.dart';
import '../../../widgets/dev_panel.dart';
import '../../../widgets/error_retry.dart';
import '../../call/presentation/pre_join_page.dart';
import 'schedule_screen.dart';
import '../bloc/my_requests_bloc.dart';
import '../bloc/my_requests_event.dart';
import '../bloc/my_requests_state.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyRequestsBloc(
        service: ScheduleService(api: context.read<ApiClient>()),
        userId: AuthService.currentUser()!.id,
      ),
      child: const _MyRequestsView(),
    );
  }
}

class _MyRequestsView extends StatelessWidget {
  const _MyRequestsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_request_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ScheduleScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<MyRequestsBloc, MyRequestsState>(
        builder: (context, state) => switch (state) {
          MyRequestsLoading() => const Center(child: CircularProgressIndicator()),
          MyRequestsError(:final message) => ErrorRetry(
              message: message,
              onRetry: () =>
                  context.read<MyRequestsBloc>().add(const LoadMyRequests()),
            ),
          MyRequestsLoaded(:final requests) => _buildList(context, requests),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<CallRequest> requests) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async =>
            context.read<MyRequestsBloc>().add(const LoadMyRequests()),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                'No requests yet.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<MyRequestsBloc>().add(const LoadMyRequests()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _RequestCard(request: requests[i]),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final CallRequest request;

  @override
  Widget build(BuildContext context) {
    final canJoin = request.status == CallRequestStatus.approved &&
        (allowJoiningCallsAnytime ||
            (request.scheduledFor.isAfter(DateTime.now()) &&
                request.scheduledFor.difference(DateTime.now()).inMinutes <=
                    10));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDateTime(request.scheduledFor),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                _StatusChip(status: request.status),
              ],
            ),
            if (request.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(request.note,
                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            if (request.status == CallRequestStatus.approved) ...[
              const SizedBox(height: 6),
              Text(
                'Call approved for ${_formatDateTime(request.scheduledFor)}.',
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
            if (request.status == CallRequestStatus.declined) ...[
              const SizedBox(height: 6),
              Text(
                'Call request declined. Reason: ${request.declineReason ?? '—'}.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            ],
            if (canJoin) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final user = AuthService.currentUser()!;
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PreJoinPage(
                      callRequestId: request.id,
                      userId: user.id,
                      userName: user.name,
                      role: UserRole.member.name,
                      memberId: user.id,
                      trainerId: request.trainerId,
                    ),
                  ));
                },
                icon: const Icon(Icons.videocam, size: 18),
                label: const Text('Join Call'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date =
        '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)} ${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];
  String _month(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final CallRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CallRequestStatus.pending => ('Pending', Colors.orange),
      CallRequestStatus.approved => ('Approved', Colors.green),
      CallRequestStatus.declined => ('Declined', Colors.red),
      CallRequestStatus.cancelled => ('Cancelled', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
