import 'dart:async';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/message.dart';
import '../../../services/api_client.dart';
import '../../../services/chat_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({
    required this.api,
    required this.chatService,
    required this.chatId,
    required this.currentUserId,
    required this.peerId,
  }) : super(const ChatInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<SendMessage>(_onSendMessage, transformer: sequential());
    on<MessageReceived>(_onMessageReceived);
    on<MarkRead>(_onMarkRead);
    on<PeerStartedTyping>(_onPeerStartedTyping);
    on<PeerStoppedTyping>(_onPeerStoppedTyping);
    on<LocalTyping>(_onLocalTyping);

    _sub = chatService.startPolling(chatId, peerId: peerId).listen(
          (msg) => add(MessageReceived(msg)),
        );
    _typingSub = chatService.typingStream.listen((isTyping) {
      if (isTyping) {
        add(const PeerStartedTyping());
      } else {
        add(const PeerStoppedTyping());
      }
    });
  }

  final ApiClient api;
  final ChatService chatService;
  final String chatId;
  final String currentUserId;
  final String peerId;
  late final StreamSubscription<Message> _sub;
  late final StreamSubscription<bool> _typingSub;

  @override
  Future<void> close() {
    _sub.cancel();
    _typingSub.cancel();
    chatService.stopPolling();
    return super.close();
  }

  Future<void> _onLoadHistory(LoadHistory e, Emitter<ChatState> emit) async {
    emit(const ChatLoading());
    final res = await api.get('/messages', query: {'chatId': chatId});
    switch (res) {
      case ApiSuccess(:final body):
        try {
          final list = (body as List)
              .map((j) => Message.fromJson(j as Map<String, dynamic>))
              .toList();
          emit(ChatLoaded(messages: list, isPeerTyping: false));
        } catch (e) {
          emit(ChatError(message: 'Could not parse messages: $e'));
        }
      case ApiFailure(:final message):
        emit(ChatError(message: message));
    }
  }

  Future<void> _onSendMessage(SendMessage e, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final temp = Message(
      id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: e.senderId,
      receiverId: e.receiverId,
      text: e.text,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    emit(current.copyWith(messages: [...current.messages, temp]));

    final res = await api.post('/messages', body: {
      'chatId': chatId,
      'senderId': e.senderId,
      'receiverId': e.receiverId,
      'text': e.text,
    });

    switch (res) {
      case ApiSuccess(:final body):
        try {
          final real = Message.fromJson(body as Map<String, dynamic>);
          final loaded = state;
          if (loaded is ChatLoaded) {
            final updated = loaded.messages.map((m) => m.id == temp.id ? real : m).toList();
            emit(loaded.copyWith(messages: updated));
          }
        } catch (_) {}
      case ApiFailure(:final message):
        final loaded = state;
        if (loaded is ChatLoaded) {
          final trimmed = loaded.messages.where((m) => m.id != temp.id).toList();
          emit(loaded.copyWith(messages: trimmed));
        }
        emit(ChatError(message: message));
    }
  }

  void _onMessageReceived(MessageReceived e, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoaded) return;

    final idx = current.messages.indexWhere((m) => m.id == e.message.id);
    if (idx != -1) {
      final updated = List<Message>.from(current.messages)..[idx] = e.message;
      emit(current.copyWith(messages: updated));
      return;
    }
    emit(current.copyWith(messages: [...current.messages, e.message]));

    if (e.message.receiverId == currentUserId && e.message.status != MessageStatus.read) {
      add(const MarkRead());
    }
  }

  Future<void> _onMarkRead(MarkRead e, Emitter<ChatState> emit) async {
    final current = state;
    if (current is! ChatLoaded) return;
    final unreadIds = current.messages
        .where((m) =>
            m.receiverId == currentUserId &&
            m.status != MessageStatus.read &&
            !m.id.startsWith('tmp_'))
        .map((m) => m.id)
        .toList();
    if (unreadIds.isEmpty) return;
    await api.post('/messages/read-batch', body: {'ids': unreadIds, 'readerId': currentUserId});
  }

  void _onPeerStartedTyping(PeerStartedTyping e, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoaded) return;
    emit(current.copyWith(isPeerTyping: true));
  }

  void _onPeerStoppedTyping(PeerStoppedTyping e, Emitter<ChatState> emit) {
    final current = state;
    if (current is! ChatLoaded) return;
    emit(current.copyWith(isPeerTyping: false));
  }

  Future<void> _onLocalTyping(LocalTyping e, Emitter<ChatState> emit) async {
    await chatService.sendTyping(chatId, currentUserId);
  }
}
