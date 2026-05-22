import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../bloc/call_bloc.dart';
import 'post_call_page.dart';

class InCallPage extends StatefulWidget {
  const InCallPage({super.key});

  @override
  State<InCallPage> createState() => _InCallPageState();
}

class _InCallPageState extends State<InCallPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<CallBloc>();
    switch (state) {
      case AppLifecycleState.paused:
        bloc.add(const AppBackgrounded());
      case AppLifecycleState.resumed:
        bloc.add(const AppForegrounded());
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CallBloc, CallState>(
          listener: (ctx, state) {
            if (state is CallEnded) {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => BlocProvider.value(
                    value: ctx.read<CallBloc>(),
                    child: PostCallPage(endedState: state),
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
        ),
        BlocListener<CallBloc, CallState>(
          listenWhen: (prev, curr) {
            if (curr is CallInCall && curr.peerJustLeft) return true;
            return false;
          },
          listener: (ctx, state) {
            if (state is CallInCall && state.peerJustLeft) {
              final name = state.peerLeftName ?? 'Remote peer';
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('$name left the call'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        ),
        BlocListener<CallBloc, CallState>(
          listenWhen: (prev, curr) {
            if (prev is CallInCall && curr is CallInCall) {
              return prev.audioDeviceName != curr.audioDeviceName &&
                  curr.audioDeviceName != null;
            }
            return false;
          },
          listener: (ctx, state) {
            if (state is CallInCall && state.audioDeviceName != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text('Audio routed to ${state.audioDeviceName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<CallBloc, CallState>(
        builder: (ctx, state) {
          if (state is CallInCall) {
            return _InCallScaffold(state: state);
          }
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        },
      ),
    );
  }
}

class _InCallScaffold extends StatelessWidget {
  const _InCallScaffold({required this.state});
  final CallInCall state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video grid: remote top, local bottom
          Column(
            children: [
              Expanded(
                child: _VideoTile(
                  track: state.remoteVideoTrack,
                  peer: state.remotePeer,
                  label: 'Remote',
                ),
              ),
              Expanded(
                child: _VideoTile(
                  track: state.localVideoTrack,
                  peer: state.localPeer,
                  label: 'You',
                  isLocal: true,
                ),
              ),
            ],
          ),
          // Controls overlay at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _Controls(state: state),
          ),
          // Reconnecting overlay
          if (state.isReconnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Reconnecting…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.track,
    required this.peer,
    required this.label,
    this.isLocal = false,
  });

  final HMSVideoTrack? track;
  final HMSPeer? peer;
  final String label;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (track != null && !track!.isMute)
            HMSVideoView(
              track: track!,
              setMirror: isLocal,
            )
          else
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade800,
                child: Text(
                  _initial(peer?.name ?? label),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 12,
            child: Text(
              peer?.name ?? label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});
  final CallInCall state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: state.isMicOn ? Icons.mic : Icons.mic_off,
              label: state.isMicOn ? 'Mute' : 'Unmute',
              onTap: () => bloc.add(const ToggleMic()),
            ),
            _ControlButton(
              icon: state.isVideoOn ? Icons.videocam : Icons.videocam_off,
              label: state.isVideoOn ? 'Camera' : 'No cam',
              onTap: () => bloc.add(const ToggleVideo()),
            ),
            _ControlButton(
              icon: Icons.flip_camera_ios,
              label: 'Flip',
              onTap: () => bloc.add(const FlipCamera()),
            ),
            _ControlButton(
              icon: Icons.call_end,
              label: 'End',
              color: Colors.red,
              onTap: () => bloc.add(const EndCall()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: c, size: 24),
          style: IconButton.styleFrom(
            backgroundColor: c.withValues(alpha: 0.15),
            fixedSize: const Size(56, 56),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: c, fontSize: 11)),
      ],
    );
  }
}
