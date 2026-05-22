# Phase 3 — Chat (1:45 – 3:00)

**Goal:** DK sends a message; Aarav sees it within 2 seconds. Status ticks work. Typing indicator works.

## Tasks

| Task | Detail |
|------|--------|
| `3.1` | `shared/lib/services/chat_service.dart`: thin wrapper — uses `ApiClient` for sending, subscribes to `/events` SSE for incoming (fallback: poll `/messages?since=` every 1.5s) |
| `3.2` | `ChatBloc`: events `LoadHistory / SendMessage / MessageReceived / MarkRead / PeerStartedTyping`. States `ChatInitial / ChatLoading / ChatLoaded(messages, isPeerTyping) / ChatError`. Optimistic send: temp message with `status=sending`, replace on server ack |
| `3.3` | `ChatListBloc`: single Aarav↔DK conversation row with last message preview, unread count, "5m ago" timestamp |
| `3.4` | Conversation UI: `ChatBubble` left (received) / right (sent); role-colored; status ticks ✓ / ✓✓; `TypingIndicator` dot animation; pull-to-refresh; auto-scroll on new message; quick reply chips; sticky multiline input |
| `3.5` | Mark-read: when screen open, `POST /messages/read-batch` for all unread. Peer receives SSE `message.read` → double tick |
| `3.6` | Empty state: **"No messages yet. Start the conversation."** with "Say hi" CTA |
| `3.7` | Manual test: send from Guru → visible in Trainer within 2s |
| `3.8` | Unit test: `message_test.dart` — `Message.fromJson(m.toJson()) == m` round-trip |
| `3.9` | Commit: `feat: real-time chat with status ticks and typing indicator` + AI_LEDGER entry |

## ChatBloc Pattern
```dart
sealed class ChatEvent extends Equatable { ... }
final class LoadHistory extends ChatEvent { ... }
final class SendMessage extends ChatEvent { final String senderId, receiverId, text; ... }
final class MessageReceived extends ChatEvent { final Message message; ... }
final class MarkRead extends ChatEvent { ... }
final class PeerStartedTyping extends ChatEvent { ... }

sealed class ChatState extends Equatable { ... }
final class ChatInitial extends ChatState { ... }
final class ChatLoading extends ChatState { ... }
final class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool isPeerTyping;
  ChatLoaded copyWith({...}) => ...;
}
final class ChatError extends ChatState { final String message; ... }
```

## Required UI Copy
- Empty chat: **"No messages yet. Start the conversation."**

## Quick Reply Chips
- "Got it 👍"
- "Can we talk at 6?"
- "Share plan?"

## Performance Target
- Chat send → render on peer: ≤ 2s via SSE, ~3s worst-case via polling
- Use `ListView.builder` for 60fps scrolling
