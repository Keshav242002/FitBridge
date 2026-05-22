# Phase 1 — Auth + Onboarding (0:30 – 1:00)

**Goal:** Both apps reach their Home screen with correct seeded identities.

## Tasks

| Task | Detail |
|------|--------|
| `1.1` | `AuthService` in `shared/`: `login()`, `currentUser()`, `logout()` — mock stores current user in Hive `meta` box |
| `1.2` | Seed `tr_aarav` + `mb_dk` into Hive on first launch (idempotent via `hasSeeded` flag) |
| `1.3` | **Trainer App:** `LoginBloc` + login screen (email prefilled `aarav@wtf.local`, any password works) → Home |
| `1.4` | **Guru App:** `OnboardingBloc` + 2 slides → Profile Setup (name prefilled "DK", trainer picker shows Aarav) → Home |
| `1.5` | `hasOnboarded` flag in Hive `meta` box for first-run detection |
| `1.6` | Home screens: Trainer 4 tiles (Members / Chats / Requests / Sessions); Guru 3 cards (Chat / Schedule / Sessions) |
| `1.7` | Apply themes: Trainer `#E50914` red, Guru `#1769E0` blue. `AppBarWithRole` widget with "Trainer • Aarav" / "Member • DK" badges |
| `1.8` | Commit: `feat: auth + onboarding flows for both apps` |

## Seeded Users
- Trainer: `id: "tr_aarav"`, name `"Aarav"`, email `"aarav@wtf.local"`, role `trainer`
- Member: `id: "mb_dk"`, name `"DK"`, email `"dk@wtf.local"`, role `member`, `assignedTrainerId: "tr_aarav"`

## Colors
- Trainer App primary: `#E50914` (red)
- Guru App primary: `#1769E0` (blue)
- Success `#12B76A`, Warning `#F79009`, Error `#D92D20`

## Hard check
Trainer logs in → Home. Guru completes onboarding → Home. Both show role badge in AppBar.
