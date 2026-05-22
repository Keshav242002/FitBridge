import 'package:equatable/equatable.dart';
import '../../../models/message.dart';

sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

final class LoadHistory extends ChatEvent {
  const LoadHistory();
}

final class SendMessage extends ChatEvent {
  const SendMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
  });
  final String senderId;
  final String receiverId;
  final String text;
  @override
  List<Object?> get props => [senderId, receiverId, text];
}

final class MessageReceived extends ChatEvent {
  const MessageReceived(this.message);
  final Message message;
  @override
  List<Object?> get props => [message];
}

final class MarkRead extends ChatEvent {
  const MarkRead();
}

final class PeerStartedTyping extends ChatEvent {
  const PeerStartedTyping();
}

final class PeerStoppedTyping extends ChatEvent {
  const PeerStoppedTyping();
}

final class LocalTyping extends ChatEvent {
  const LocalTyping();
}
