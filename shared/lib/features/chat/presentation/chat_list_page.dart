import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../models/message.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../bloc/chat_list_bloc.dart';
import '../bloc/chat_list_event.dart';
import '../bloc/chat_list_state.dart';
import 'conversation_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser()!;
    final peerName = ChatListBloc.peerNameFor(user.id);
    return BlocProvider(
      create: (ctx) => ChatListBloc(
        api: ctx.read<ApiClient>(),
        currentUserId: user.id,
        peerName: peerName,
      )..add(const LoadChatList()),
      child: const _ChatListView(),
    );
  }
}

class _ChatListView extends StatelessWidget {
  const _ChatListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chat_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ConversationPage()),
        ),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ChatListBloc, ChatListState>(
        builder: (ctx, state) {
          return switch (state) {
            ChatListInitial() || ChatListLoading() => const Center(child: CircularProgressIndicator()),
            ChatListLoaded(:final chatId, :final peerName, :final lastMessage, :final unreadCount) =>
              RefreshIndicator(
                onRefresh: () async => ctx.read<ChatListBloc>().add(const LoadChatList()),
                child: ListView(
                  children: [
                    _ConversationTile(
                      chatId: chatId,
                      peerName: peerName,
                      lastMessage: lastMessage,
                      unreadCount: unreadCount,
                    ),
                  ],
                ),
              ),
            ChatListError(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ctx.read<ChatListBloc>().add(const LoadChatList()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.chatId,
    required this.peerName,
    required this.lastMessage,
    required this.unreadCount,
  });

  final String chatId;
  final String peerName;
  final Message? lastMessage;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final preview = lastMessage?.isSystem == true
        ? '📋 ${lastMessage!.text}'
        : lastMessage?.text ?? 'No messages yet';
    final timeLabel = lastMessage != null ? _relativeTime(lastMessage!.createdAt) : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          peerName[0].toUpperCase(),
          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(peerName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: unreadCount > 0 ? Colors.black87 : Colors.black54),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeLabel, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ConversationPage()),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
