# bloc_patterns.md — BLoC State Management Rules

> Use `flutter_bloc` ^8.1.0. Use `equatable` for state/event equality. No setState for business logic. No Provider/Riverpod/GetX.

---

## 1. Folder layout per feature

```
features/
  chat/
    bloc/
      chat_bloc.dart
      chat_event.dart
      chat_state.dart
    data/
      chat_repository.dart    # thin wrapper around ApiClient if needed, optional
    presentation/
      chat_list_page.dart
      conversation_page.dart
      widgets/
        message_bubble.dart
        typing_indicator.dart
```

Each Bloc gets its own folder. Events and states live in separate files for readability.

---

## 2. Event naming

Verbs in past tense or imperative. They describe what **happened** or what to **do**:
- `LoadHistory`, `SendMessage`, `MessageReceived`, `PeerStartedTyping`, `MarkRead`
- Not: `ChatScreenInitialized` (too view-y), `OnTapSendButton` (lifecycle-y)

```dart
sealed class ChatEvent extends Equatable {
  const ChatEvent();
  @override List<Object?> get props => [];
}

final class LoadHistory extends ChatEvent {
  const LoadHistory();
}

final class SendMessage extends ChatEvent {
  final String senderId;
  final String receiverId;
  final String text;
  const SendMessage({required this.senderId, required this.receiverId, required this.text});
  @override List<Object?> get props => [senderId, receiverId, text];
}

final class MessageReceived extends ChatEvent {
  final Message message;
  const MessageReceived(this.message);
  @override List<Object?> get props => [message];
}
```

---

## 3. State naming

Use a **sealed class hierarchy** so the UI must handle every state (Dart 3 exhaustive switch).

```dart
sealed class ChatState extends Equatable {
  const ChatState();
  @override List<Object?> get props => [];
}

final class ChatInitial extends ChatState {
  const ChatInitial();
}

final class ChatLoading extends ChatState {
  const ChatLoading();
}

final class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool isPeerTyping;
  const ChatLoaded({required this.messages, required this.isPeerTyping});

  ChatLoaded copyWith({List<Message>? messages, bool? isPeerTyping}) =>
      ChatLoaded(
        messages: messages ?? this.messages,
        isPeerTyping: isPeerTyping ?? this.isPeerTyping,
      );

  @override List<Object?> get props => [messages, isPeerTyping];
}

final class ChatError extends ChatState {
  final String message;
  const ChatError({required this.message});
  @override List<Object?> get props => [message];
}
```

Three baseline states per feature: `Loading`, `Loaded`, `Error`. Add specialized states (e.g., `Joining`, `InCall`, `Ended` for CallBloc) where they help the UI.

---

## 4. Bloc structure

```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required this.api, required this.chatId}) : super(const ChatInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<SendMessage>(_onSendMessage, transformer: sequential());
    on<MessageReceived>(_onMessageReceived);
    on<MarkRead>(_onMarkRead);
    on<PeerStartedTyping>(_onPeerStartedTyping);

    _subscription = _chatStream.listen((msg) => add(MessageReceived(msg)));
  }

  final ApiClient api;
  final String chatId;
  late final StreamSubscription _subscription;

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }

  // ... handlers below ...
}
```

Rules:
- Inject dependencies via constructor (`api`, `chatId`, repositories). Never look them up inside.
- Cancel subscriptions in `close()`.
- Use `transformer: sequential()` from `bloc_concurrency` for handlers that must not interleave (e.g., send-message). Default `concurrent` is fine for read handlers.
- Keep handlers private (`_onLoadHistory`).

---

## 5. Handlers consume `ApiResponse`

Mandatory pattern — see `.claude/api_contract.md`:

```dart
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
      } catch (err) {
        emit(ChatError(message: 'Parse error: $err'));
      }
    case ApiFailure(:final message):
      emit(ChatError(message: message));
  }
}
```

Every handler that calls the network looks like this. No exceptions.

---

## 6. UI consumes the Bloc

```dart
class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key, required this.chatId});
  final String chatId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => ChatBloc(api: ctx.read<ApiClient>(), chatId: chatId)
        ..add(const LoadHistory()),
      child: const _ConversationView(),
    );
  }
}

class _ConversationView extends StatelessWidget {
  const _ConversationView();
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (ctx, state) {
        if (state is ChatError) {
          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (ctx, state) {
        return switch (state) {
          ChatInitial() || ChatLoading() => const _LoadingSkeleton(),
          ChatLoaded(:final messages, :final isPeerTyping) =>
              _MessageList(messages: messages, isPeerTyping: isPeerTyping),
          ChatError(:final message) => _ErrorRetry(message: message),
        };
      },
    );
  }
}
```

- Use `BlocBuilder` for state → UI mapping.
- Use `BlocListener` (or `BlocConsumer` for both) for side effects: snackbars, navigation, dialogs.
- **Exhaustive switch** on sealed states — Dart 3 will warn if you miss a case.

---

## 7. Cross-Bloc coordination

When the call ends, `CallBloc` finishes a session — and `SessionsBloc` on the list screen should refresh. Two options:

**Option A (preferred):** Have `SessionsBloc` re-fetch when its page mounts. Simple, no coupling.

**Option B:** A `BlocListener` at app root listens to `CallBloc.Ended` and dispatches `LoadSessions` to `SessionsBloc`. Use only if you need true cross-screen reactivity.

Don't chain Blocs by passing one into another's constructor — that creates ordering nightmares.

---

## 8. Globally provided dependencies

In `main.dart`:

```dart
runApp(
  MultiRepositoryProvider(
    providers: [
      RepositoryProvider<ApiClient>(create: (_) => ApiClient(baseUrl: kApiBaseUrl)),
      RepositoryProvider<AuthService>(create: (ctx) => AuthService(ctx.read<ApiClient>())),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (ctx) => AppBloc(auth: ctx.read<AuthService>())..add(BootstrapApp())),
      ],
      child: const WtfApp(),
    ),
  ),
);
```

Feature-scoped Blocs (`ChatBloc`, `CallBloc`) are created **at the page** that needs them via `BlocProvider`. Don't put them at app root.

---

## 9. Testing Blocs

Use `bloc_test`:

```dart
blocTest<ChatBloc, ChatState>(
  'emits [Loading, Loaded] when LoadHistory succeeds',
  build: () => ChatBloc(api: mockApi, chatId: 'c1'),
  setUp: () {
    when(() => mockApi.get('/messages', query: any(named: 'query')))
      .thenAnswer((_) async => const ApiSuccess(statusCode: 200, body: [], headers: {}));
  },
  act: (bloc) => bloc.add(const LoadHistory()),
  expect: () => [
    const ChatLoading(),
    const ChatLoaded(messages: [], isPeerTyping: false),
  ],
);
```

You don't need to test every Bloc exhaustively in the timebox — one happy path and one error path per critical Bloc is enough. Spend the rest of the test budget on model serialization and validators.

---

## 10. Anti-patterns to avoid

| Anti-pattern | Fix |
|-------------|-----|
| `setState` inside a `BlocBuilder`'s builder for local UI state | Use a `StatefulWidget` wrapper for ephemeral UI (e.g., text controller); keep business state in Bloc |
| Multiple Blocs holding the same data | Single source of truth — one Bloc owns it, others read via `BlocSelector` or events |
| Emitting from outside the Bloc | All emits happen inside event handlers |
| Long handlers (>40 lines) | Extract to private methods on the Bloc |
| Models in `bloc_state.dart` | Models live in `shared/models/`. Bloc files only hold state classes |
| `if (state is ChatLoaded)` casting | Use Dart 3 pattern matching: `switch (state) { case ChatLoaded(:final messages): ... }` |
| Calling `add()` from `build()` without an event guard | Use `BlocProvider(create: (ctx) => Bloc()..add(InitialEvent()))` in the provider, not in `build()` |
