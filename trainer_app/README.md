# Trainer App (Aarav)

Flutter app for fitness trainers. Paired with **Guru App** (DK). Communicates via the local `token_server` at `localhost:8787`.

## First-run flow

1. Login screen — email: `aarav@wtf.local`, any password.
2. Home screen with 4 tiles: **Members**, **Chats**, **Requests**, **Sessions**.

## Running

From the repo root, start the token server first, then:

```bash
cd trainer_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

> On iOS Simulator use `http://localhost:8787`.  
> On a real device on the same Wi-Fi, replace with the host machine's LAN IP.

## State management

BLoC only (`flutter_bloc ^8.1.0`). No `setState` for business logic.

## Shared package

Business logic (models, services, feature Blocs, shared widgets) lives in `../shared` via a path dependency.

## Tests

```bash
cd ../shared && flutter test
```
