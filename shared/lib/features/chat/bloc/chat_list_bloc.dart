import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/message.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  ChatListBloc({required this.api, required this.currentUserId, required this.peerName})
      : super(const ChatListInitial()) {
    on<LoadChatList>(_onLoadChatList);
  }

  final ApiClient api;
  final String currentUserId;
  final String peerName;

  Future<void> _onLoadChatList(LoadChatList e, Emitter<ChatListState> emit) async {
    emit(const ChatListLoading());
    final res = await api.get('/messages', query: {'chatId': 'c_aarav_dk'});
    switch (res) {
      case ApiSuccess(:final body):
        try {
          final messages = (body as List)
              .map((j) => Message.fromJson(j as Map<String, dynamic>))
              .toList();
          final lastMsg = messages.isNotEmpty ? messages.last : null;
          final unread = messages
              .where((m) => m.receiverId == currentUserId && m.status != MessageStatus.read)
              .length;
          emit(ChatListLoaded(
            chatId: 'c_aarav_dk',
            peerName: peerName,
            lastMessage: lastMsg,
            unreadCount: unread,
          ));
        } catch (e) {
          emit(ChatListError(message: 'Could not load chats: $e'));
        }
      case ApiFailure(:final message):
        emit(ChatListError(message: message));
    }
  }

  static String peerNameFor(String currentUserId) =>
      currentUserId == AuthService.seededMember.id
          ? AuthService.seededTrainer.name
          : AuthService.seededMember.name;
}
