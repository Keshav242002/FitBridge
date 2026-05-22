import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../services/api_client.dart';
import '../../../services/call_service.dart';
import '../bloc/call_bloc.dart';
import 'in_call_page.dart';

class PreJoinPage extends StatelessWidget {
  const PreJoinPage({
    super.key,
    required this.callRequestId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.memberId,
    required this.trainerId,
  });

  final String callRequestId;
  final String userId;
  final String userName;
  final String role;
  final String memberId;
  final String trainerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CallBloc(
        api: context.read<ApiClient>(),
        callService: CallService(),
      )..add(PrepareJoin(
          callRequestId: callRequestId,
          userId: userId,
          userName: userName,
          role: role,
          memberId: memberId,
          trainerId: trainerId,
        )),
      child: const _PreJoinView(),
    );
  }
}

class _PreJoinView extends StatelessWidget {
  const _PreJoinView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (ctx, state) {
        if (state is CallJoining) {
          Navigator.of(ctx).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: ctx.read<CallBloc>(),
                child: const InCallPage(),
              ),
            ),
          );
        }
        if (state is CallError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Join Call')),
        body: BlocBuilder<CallBloc, CallState>(
          builder: (ctx, state) {
            return switch (state) {
              CallPreparing() => const Center(child: CircularProgressIndicator()),
              CallError(:final message) => _ErrorBody(message: message),
              CallPreJoin() => _PreJoinBody(state: state),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }
}

class _PreJoinBody extends StatelessWidget {
  const _PreJoinBody({required this.state});
  final CallPreJoin state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.videocam_rounded, size: 64, color: Colors.black38),
          const SizedBox(height: 20),
          Text(
            'Ready to join?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check your mic and camera before joining.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ToggleButton(
                icon: state.isMicOn ? Icons.mic : Icons.mic_off,
                label: state.isMicOn ? 'Mic on' : 'Mic off',
                active: state.isMicOn,
                onTap: () => context.read<CallBloc>().add(const ToggleMic()),
              ),
              const SizedBox(width: 24),
              _ToggleButton(
                icon: state.isVideoOn ? Icons.videocam : Icons.videocam_off,
                label: state.isVideoOn ? 'Camera on' : 'Camera off',
                active: state.isVideoOn,
                onTap: () => context.read<CallBloc>().add(const ToggleVideo()),
              ),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => context.read<CallBloc>().add(const JoinNow()),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text('Join Call', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}
