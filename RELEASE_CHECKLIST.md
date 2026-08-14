# Release Checklist — docwellness-dietician (Dietician App)

Based on `docwellness-ai-plan/RELEASE_CHECKLIST.md` (AI_EXECUTION_PLAN.md
Phase 8, P8-05), filled in against the actual state of this repo as of the
`chore/senior-improvements-phase-0` branch (Phases 0-8). Re-verify anything
marked ⚠️ before deploying — this reflects what was true when last checked,
not a live status.

Legend: ✅ verified this session · ⚠️ needs action before release · ❔ not
verified (out of this session's scope)

---

## Security

- ✅ No hardcoded tokens - `EnvService`/`SessionService` (added an earlier phase, verified this session)
- ✅ Fixed a hardcoded production IP (`http://65.20.81.44:5001`) in `custom_food_bubble.dart` - now resolves via `EnvService.apiHost` like everything else (Phase 7)
- ✅ Fixed `dio_function.dart` unconditionally printing a JWT-prefix slice plus full request/response bodies (can carry patient health data) to console **in release builds too** - now gated to `kDebugMode`, and the token itself is never printed even partially (Phase 7)
- ✅ Secure storage used - `SessionService` backed by `flutter_secure_storage`
- ✅ Real login screen added (`app/modules/auth`) ahead of the public Play Store release - the previous auto-login baked a real password into the compiled binary via `--dart-define`/`lib/dev_credentials.dart`, which is a genuine credential leak once the APK is publicly downloadable, unlike the Supabase anon key (designed to be public). `SplashView` now checks for a persisted session and routes to `Routes.AUTH` when there isn't one; a logout entry point was added to `DoctorProfileView`'s AppBar (there was previously no way to log out at all).

## Dietician App

- ✅ Login works (real email/password screen, not auto-login), session persists securely, logout (see `DoctorProfileController.logout()`) clears both the Supabase session and local session state
- ✅ Patient list works - loading/empty states pre-existing; **error state with retry added** (Phase 7, was previously indistinguishable from "no patients")
- ✅ Patient detail works
- ✅ Diet plan builder works - generate → draft review → explicit finalize → activate pipeline confirmed intact and unmodified in its core flow
- ✅ Recipe management - pre-existing, not touched
- ✅ Chat works - `clientMessageId` dedup added (Phase 7), unit-tested (Phase 8)
- ✅ Notifications work - pre-existing
- ✅ Socket reconnect works - `SocketService` reconnect-callback registry added (Phase 7): rejoins the active conversation room, re-syncs it, and re-requests presence; `HomeController` re-fetches dashboard stats/unread counts on reconnect too
- ✅ AI generation states clear - new `AiGenerationStatus` enum (idle/queued/generating/reviewDraft/failed/published) wired through generate/finalize, surfaced as a status label in the generate sheet (Phase 7)
- ✅ AI publish requires approval - confirmed already true (generate → draft review → explicit finalize, never auto-live); **added a confirmation dialog before finalize** since it was previously one tap with no confirmation for a hard-to-walk-back action (Phase 7)
- ✅ Error states / loading states / empty states - patient list has all three now (Phase 7); other screens not audited this session

## Monitoring

- ✅ Crash reporting enabled - `SentryFlutter.init`, DSN-gated, wraps `runApp` in `appRunner`
- ✅ Analytics events enabled - this app had **zero** PostHog `.capture()` calls despite being initialized before this session; Phase 8 added `login_success`, `dashboard_loaded`, `chat_message_sent`, `diet_plan_published`
- ✅ No PHI in analytics - `diet_plan_published` only sends `scope`/`week` (never meal/recipe/nutrition content), `chat_message_sent` only sends `message_type`, `login_success`/`dashboard_loaded` send nothing at all

---

## Testing (this session, Phase 8)

`flutter test` - new test added:
- `test/message_dedup_test.dart` - `ChatModel.isDuplicate` (extracted from `ChatController` as a pure function specifically to make this testable)
- Pre-existing tests untouched and still passing: `nutrition_circles_layout_test.dart` (9 cases), `recipe_free_from_layout_test.dart`
- Pre-existing `test/widget_test.dart` ("Counter increments smoke test") still fails - unmodified `flutter create` boilerplate, predates this session entirely

⚠️ No widget test exists for the patient-list error/sort states or the finalize confirmation dialog added in Phase 7 - only the underlying dedup logic got a proper unit test this session, matching the codebase's existing testing style (pure-logic tests, e.g. `recipe_dietary_constraints_test.dart`) rather than full-widget-tree tests requiring heavy GetX/network mocking.
