import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/call_request.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/schedule_service.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  List<CallRequest>? _requests;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiClient>();
    final service = ScheduleService(api: api);
    final res = await service.getRequests(AuthService.currentUser()!.id);
    if (!mounted) return;
    switch (res) {
      case ApiSuccess(:final body):
        try {
          final list = (body as List)
              .map((j) => CallRequest.fromJson(j as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
          setState(() {
            _requests = list;
            _loading = false;
          });
        } catch (e) {
          setState(() {
            _error = 'Could not parse requests';
            _loading = false;
          });
        }
      case ApiFailure(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final requests = _requests ?? [];
    if (requests.isEmpty) {
      return const Center(
        child: Text('No requests yet.', style: TextStyle(color: Colors.black54)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _RequestCard(request: requests[i]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final CallRequest request;

  @override
  Widget build(BuildContext context) {
    final canJoin = request.status == CallRequestStatus.approved &&
        request.scheduledFor.isAfter(DateTime.now()) &&
        request.scheduledFor.difference(DateTime.now()).inMinutes <= 10;

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
              Text(request.note, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
            if (request.declineReason != null) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${request.declineReason}',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            ],
            if (canJoin) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {},
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
    final date = '${_weekday(dt.weekday)}, ${dt.day} ${_month(dt.month)} ${dt.year}';
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
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
