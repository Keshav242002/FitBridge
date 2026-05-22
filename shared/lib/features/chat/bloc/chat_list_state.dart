import 'package:equatable/equatable.dart';
import '../../../models/message.dart';

sealed class ChatListState extends Equatable {
  const ChatListState();
  @override
  List<Object?> get props => [];
}

final class ChatListInitial extends ChatListState {
  const ChatListInitial();
}

final class ChatListLoading extends ChatListState {
  const ChatListLoading();
}

final class ChatListLoaded extends ChatListState {
  const ChatListLoaded({
    required this.chatId,
    required this.peerName,
    required this.unreadCount,
    this.lastMessage,
  });
  final String chatId;
  final String peerName;
  final int unreadCount;
  final Message? lastMessage;

  @override
  List<Object?> get props => [chatId, peerName, unreadCount, lastMessage];
}

final class ChatListError extends ChatListState {
  const ChatListError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}
