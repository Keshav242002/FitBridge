import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/schedule_service.dart';
import '../bloc/schedule_bloc.dart';
import '../bloc/schedule_event.dart';
import '../bloc/schedule_state.dart';
import 'my_requests_page.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser()!;
    final api = context.read<ApiClient>();
    return BlocProvider(
      create: (_) => ScheduleBloc(
        service: ScheduleService(api: api),
        memberId: user.id,
        trainerId: AuthService.seededTrainer.id,
      ),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatefulWidget {
  const _ScheduleView();

  @override
  State<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<_ScheduleView> {
  final _noteCtrl = TextEditingController();

  // 08:00–21:30 in 30-min increments
  static final _slots = [
    for (int h = 8; h <= 21; h++) ...[
      TimeOfDay(hour: h, minute: 0),
      TimeOfDay(hour: h, minute: 30),
    ],
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listener: (ctx, state) {
        if (state is ScheduleSubmitted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('Call requested. Waiting for trainer approval.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(ctx).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const MyRequestsPage()),
          );
        }
      },
      builder: (ctx, state) {
        if (state is! ScheduleForm) return const SizedBox.shrink();
        return Scaffold(
          appBar: AppBar(title: const Text('Request a Call')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(title: 'Select Date', child: _DateChips(selected: state.selectedDate)),
              const SizedBox(height: 20),
              _Section(title: 'Select Time', child: _SlotChips(slots: _slots, state: state)),
              const SizedBox(height: 20),
              _Section(
                title: 'Note (optional)',
                child: TextField(
                  controller: _noteCtrl,
                  maxLength: 140,
                  maxLines: 3,
                  onChanged: (v) => ctx.read<ScheduleBloc>().add(UpdateNote(v)),
                  decoration: const InputDecoration(
                    hintText: 'Any details for your trainer…',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.isSubmitting
                    ? null
                    : () => ctx.read<ScheduleBloc>().add(const SubmitRequest()),
                child: state.isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Request Call'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DateChips extends StatelessWidget {
  const _DateChips({required this.selected});
  final DateTime selected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = [
      for (int i = 0; i < 3; i++)
        DateTime(today.year, today.month, today.day + i),
    ];
    return Row(
      children: dates.map((d) {
        final isSelected = d.year == selected.year &&
            d.month == selected.month &&
            d.day == selected.day;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(_formatDate(d)),
            selected: isSelected,
            onSelected: (_) =>
                context.read<ScheduleBloc>().add(SelectDate(d)),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (d == today) return 'Today';
    if (d == tomorrow) return 'Tomorrow';
    return '${_weekday(d.weekday)}, ${d.day} ${_month(d.month)}';
  }

  String _weekday(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  String _month(int m) =>
      const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
          [m - 1];
}

class _SlotChips extends StatelessWidget {
  const _SlotChips({required this.slots, required this.state});
  final List<TimeOfDay> slots;
  final ScheduleForm state;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = state.selectedSlot == slot;
        return ChoiceChip(
          label: Text(_fmt(slot)),
          selected: isSelected,
          onSelected: (_) => context.read<ScheduleBloc>().add(SelectSlot(slot)),
        );
      }).toList(),
    );
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
