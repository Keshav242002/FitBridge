# wtf_shared

Dart/Flutter package shared by `guru_app` and `trainer_app`. Contains all business logic, data models, BLoC feature modules, reusable widgets, and utilities.

## Contents

| Directory | What's inside |
|-----------|--------------|
| `lib/models/` | `User`, `Message`, `CallRequest`, `SessionLog`, `RoomMeta` — with `fromJson` / `toJson` / `copyWith` / `Equatable` |
| `lib/services/` | `ApiClient` (sealed HTTP), `AuthService` (Hive-backed), `ChatService`, `ScheduleService`, `CallService` (100ms), `SessionService` |
| `lib/features/` | BLoC modules: `chat/`, `schedule/`, `call/`, `sessions/`, `members/`, `requests/` |
| `lib/widgets/` | `AppBarWithRole`, `SkeletonLoader`, `ErrorRetry`, `EmptyState`, `PrimaryButton`, `DevPanel` |
| `lib/utils/` | `Logger` (tagged ring buffer, 200 lines), theme constants, validators |

## Adding as a dependency

Both apps reference this package via a path dependency in their `pubspec.yaml`:

```yaml
dependencies:
  wtf_shared:
    path: ../shared
```

## Running tests

```bash
cd shared
flutter test
```

Unit tests cover:
- `message_test.dart` — serialization / deserialization roundtrip
- `schedule_validator_test.dart` — past-time rejection, future-time acceptance
- `session_duration_test.dart` — duration calculation from start/end timestamps
