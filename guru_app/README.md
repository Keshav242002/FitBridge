# Guru App (Member — DK)

Flutter app for gym members. Paired with **Trainer App** (Aarav). Communicates via the local `token_server` at `localhost:8787`.

## First-run flow

1. Two onboarding slides.
2. Profile setup — name pre-filled "DK", trainer pre-assigned to Aarav.
3. Home screen with 3 cards: **Chat with Trainer**, **Schedule Call**, **My Sessions**.

On reinstall, onboarding shows again. On subsequent launches, app lands directly on home.

## Running

From the repo root, start the token server first, then:

```bash
cd guru_app
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
