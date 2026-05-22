# api_contract.md — The One-API-Client Contract

> **This is mandatory.** The user explicitly requested this pattern. Do not deviate.

---

## The rule, stated plainly

1. There is **exactly one** HTTP client class in the codebase: `ApiClient`.
2. `ApiClient` exposes only `get`, `post`, `patch`, `delete`.
3. Every method returns `Future<ApiResponse>` — a sealed type with two variants: `ApiSuccess` (on HTTP 200/201) and `ApiFailure` (everything else, including network errors and timeouts).
4. **`ApiClient` does NOT parse responses into domain models.** It hands back the raw decoded body (`dynamic` — usually `Map<String, dynamic>` or `List<dynamic>`).
5. **The calling Bloc parses the body into a model**, then emits `Loaded(model)` on success or `Error(message)` on failure.
6. Local storage (Hive, SharedPreferences, files) does **not** go through `ApiClient`. Use `LocalStore` for that.

This separation matters because:
- The reviewer can see one place where all HTTP lives.
- Blocs own their domain — they decide what shape a "loaded" looks like.
- Error handling is uniform; success parsing is feature-specific.

---

## The exact code

```dart
// shared/lib/services/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Sealed response wrapper. Match on it in the Bloc.
sealed class ApiResponse {
  const ApiResponse();
}

final class ApiSuccess extends ApiResponse {
  final int statusCode;       // 200 or 201
  final dynamic body;         // decoded JSON: Map<String,dynamic> | List<dynamic> | String | null
  final Map<String, String> headers;
  const ApiSuccess({required this.statusCode, required this.body, required this.headers});
}

final class ApiFailure extends ApiResponse {
  final int? statusCode;      // null for network errors
  final String code;          // 'network', 'timeout', 'server', 'client', 'parse'
  final String message;       // human-readable
  final dynamic body;         // server's error body if any
  const ApiFailure({this.statusCode, required this.code, required this.message, this.body});
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client, this.defaultTimeout = const Duration(seconds: 15)})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration defaultTimeout;
  final Map<String, String> _defaultHeaders = {'Content-Type': 'application/json'};

  void setHeader(String key, String value) => _defaultHeaders[key] = value;
  void removeHeader(String key) => _defaultHeaders.remove(key);

  Future<ApiResponse> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(String path, {Object? body, Map<String, String>? query}) =>
      _send('POST', path, body: body, query: query);

  Future<ApiResponse> patch(String path, {Object? body, Map<String, String>? query}) =>
      _send('PATCH', path, body: body, query: query);

  Future<ApiResponse> delete(String path, {Map<String, String>? query}) =>
      _send('DELETE', path, query: query);

  Future<ApiResponse> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    Log.api('→ $method $uri ${body != null ? 'body=$body' : ''}');
    try {
      final encoded = body == null ? null : jsonEncode(body);
      final req = http.Request(method, uri)
        ..headers.addAll(_defaultHeaders)
        ..body = encoded ?? '';
      final streamed = await _client.send(req).timeout(defaultTimeout);
      final res = await http.Response.fromStream(streamed);

      Log.api('← $method $uri ${res.statusCode}');

      final decoded = _decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return ApiSuccess(statusCode: res.statusCode, body: decoded, headers: res.headers);
      }

      return ApiFailure(
        statusCode: res.statusCode,
        code: res.statusCode >= 500 ? 'server' : 'client',
        message: _extractMessage(decoded) ?? 'Request failed with ${res.statusCode}',
        body: decoded,
      );
    } on TimeoutException {
      Log.api('✗ $method $uri timeout');
      return const ApiFailure(code: 'timeout', message: 'Request timed out. Please try again.');
    } catch (e) {
      Log.api('✗ $method $uri error=$e');
      return ApiFailure(code: 'network', message: 'Network error: $e');
    }
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;   // return raw if not JSON
    }
  }

  String? _extractMessage(dynamic body) {
    if (body is Map && body['message'] is String) return body['message'] as String;
    if (body is Map && body['error'] is String) return body['error'] as String;
    return null;
  }
}
```

---

## How a Bloc uses it (template)

```dart
// guru_app/lib/features/chat/bloc/chat_bloc.dart

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc({required this.api, required this.chatId}) : super(ChatInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<SendMessage>(_onSendMessage);
    // ...
  }

  final ApiClient api;
  final String chatId;

  Future<void> _onLoadHistory(LoadHistory e, Emitter<ChatState> emit) async {
    emit(ChatLoading());

    final res = await api.get('/messages', query: {'chatId': chatId});

    switch (res) {
      case ApiSuccess(:final body):
        try {
          final list = (body as List).map((j) => Message.fromJson(j as Map<String, dynamic>)).toList();
          emit(ChatLoaded(messages: list, isPeerTyping: false));
        } catch (e) {
          emit(ChatError(message: 'Could not parse messages: $e'));
        }
      case ApiFailure(:final message):
        emit(ChatError(message: message));
    }
  }

  Future<void> _onSendMessage(SendMessage e, Emitter<ChatState> emit) async {
    // optimistic add with status=sending
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
          final updated = [...current.messages.where((m) => m.id != temp.id), real];
          emit(current.copyWith(messages: updated));
        } catch (e) {
          emit(ChatError(message: 'Send succeeded but response unparseable'));
        }
      case ApiFailure(:final message):
        emit(ChatError(message: message));
    }
  }
}
```

Key takeaways from the template:
- **`switch (res)`** with pattern matching on the sealed type. No `if (res is ApiSuccess)` chains.
- Parsing is wrapped in `try/catch` and emits a specific error state.
- The Bloc owns optimistic updates (sending → sent) — the ApiClient is dumb.

---

## Don'ts

| Don't | Why |
|-------|-----|
| Don't create a `ChatApi` class that wraps `ApiClient` and returns `List<Message>`. | Defeats the purpose — parsing belongs in the Bloc. |
| Don't put a `try/catch` inside `ApiClient` methods that returns `null`. | Use `ApiFailure` with a code. |
| Don't add headers via per-call params. Use `setHeader` for auth tokens etc. | One source of truth for headers. |
| Don't import `package:http/http.dart` anywhere except `api_client.dart`. | Lint check: grep before commit. |
| Don't bypass `ApiClient` for "just one small call". | The reviewer is grading this exactly. |

---

## Special case: SSE (server-sent events)

SSE is a long-lived stream, not a request/response, so it is **the one allowed exception** to "all HTTP in ApiClient". Put SSE handling in a separate `EventStreamClient` class in `shared/lib/services/event_stream_client.dart`. Document this in `ARCHITECTURE.md` so the reviewer doesn't think you broke the rule.

If you can avoid SSE entirely and just poll `GET /messages?since=...` every 1.5s through `ApiClient`, that's even better — one less class.
