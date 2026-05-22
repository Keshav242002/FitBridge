import 'package:equatable/equatable.dart';

sealed class ChatListEvent extends Equatable {
  const ChatListEvent();
  @override
  List<Object?> get props => [];
}

final class LoadChatList extends ChatListEvent {
  const LoadChatList();
}
