import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../services/chat_service.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser()!;
    final peerId =
        user.role == UserRole.member ? AuthService.seededTrainer.id : AuthService.seededMember.id;
    final peerName =
        user.role == UserRole.member ? AuthService.seededTrainer.name : AuthService.seededMember.name;
    final api = context.read<ApiClient>();
    return BlocProvider(
      create: (_) => ChatBloc(
        api: api,
        chatService: ChatService(api: api),
        chatId: kChatId,
        currentUserId: user.id,
        peerId: peerId,
      )..add(const LoadHistory()),
      child: _ConversationView(
        currentUserId: user.id,
        peerId: peerId,
        peerName: peerName,
      ),
    );
  }
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
  });
  final String currentUserId;
  final String peerId;
  final String peerName;

  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView> {
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  final _seenIds = <String>{};
  Timer? _typingDebounce;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _textCtrl.removeListener(_onTextChanged);
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_textCtrl.text.isEmpty) return;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<ChatBloc>().add(const LocalTyping());
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(BuildContext ctx) {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    ctx.read<ChatBloc>().add(
          SendMessage(senderId: widget.currentUserId, receiverId: widget.peerId, text: text),
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text(widget.peerName)),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (ctx, state) {
          if (state is ChatLoaded) {
            _scrollToBottom();
            ctx.read<ChatBloc>().add(const MarkRead());
            if (_isInitialLoad) {
              // Mark all history as seen so they don't animate in
              setState(() {
                _seenIds.addAll(state.messages.map((m) => m.id));
                _isInitialLoad = false;
              });
            }
          }
          if (state is ChatError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(state.message),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () => ctx.read<ChatBloc>().add(const LoadHistory()),
                ),
              ),
            );
          }
        },
        builder: (ctx, state) {
          return Column(
            children: [
              Expanded(child: _buildBody(ctx, state, primaryColor)),
              if (state is ChatLoaded) ...[
                _QuickReplies(
                  onTap: (text) => ctx.read<ChatBloc>().add(
                        SendMessage(
                          senderId: widget.currentUserId,
                          receiverId: widget.peerId,
                          text: text,
                        ),
                      ),
                ),
                _InputBar(controller: _textCtrl, onSend: () => _send(ctx)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext ctx, ChatState state, Color primaryColor) {
    return switch (state) {
      ChatInitial() || ChatLoading() => const Center(child: CircularProgressIndicator()),
      ChatLoaded(:final messages, :final isPeerTyping) => messages.isEmpty
          ? _EmptyState(
              onSayHi: () => ctx.read<ChatBloc>().add(
                    SendMessage(
                      senderId: widget.currentUserId,
                      receiverId: widget.peerId,
                      text: 'Hi 👋',
                    ),
                  ),
            )
          : RefreshIndicator(
              onRefresh: () async => ctx.read<ChatBloc>().add(const LoadHistory()),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: messages.length + (isPeerTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (isPeerTyping && i == messages.length) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: TypingIndicator(),
                    );
                  }
                  final msg = messages[i];
                  final bubble = MessageBubble(
                    message: msg,
                    isMe: msg.senderId == widget.currentUserId,
                    primaryColor: primaryColor,
                  );
                  if (_seenIds.contains(msg.id)) return bubble;
                  // Slide-in animation for new messages
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(msg.id),
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    onEnd: () {
                      if (mounted) setState(() => _seenIds.add(msg.id));
                    },
                    builder: (_, t, child) => Transform.translate(
                      offset: Offset(0, t * 20),
                      child: Opacity(opacity: 1 - t, child: child),
                    ),
                    child: bubble,
                  );
                },
              ),
            ),
      ChatError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ctx.read<ChatBloc>().add(const LoadHistory()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSayHi});
  final VoidCallback onSayHi;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No messages yet. Start the conversation.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onSayHi, child: const Text('Say hi')),
          ],
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.onTap});
  final void Function(String) onTap;

  static const _chips = ['Got it 👍', 'Can we talk at 6?', 'Share plan?'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(_chips[i]),
          onPressed: () => onTap(_chips[i]),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
