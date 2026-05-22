import 'package:equatable/equatable.dart';
import '../../../models/message.dart';

sealed class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

final class ChatInitial extends ChatState {
  const ChatInitial();
}

final class ChatLoading extends ChatState {
  const ChatLoading();
}

final class ChatLoaded extends ChatState {
  const ChatLoaded({required this.messages, required this.isPeerTyping});
  final List<Message> messages;
  final bool isPeerTyping;

  ChatLoaded copyWith({List<Message>? messages, bool? isPeerTyping}) => ChatLoaded(
        messages: messages ?? this.messages,
        isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      );

  @override
  List<Object?> get props => [messages, isPeerTyping];
}

final class ChatError extends ChatState {
  const ChatError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}
