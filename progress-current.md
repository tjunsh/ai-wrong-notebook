---
name: progress-2026-04-19
description: End of session progress for smart-wrong-notebook
type: project
---

Done:
- Route wiring: GoRouter redirect for onboarding (/onboarding → first-launch check)
  using SettingsRepository, 7 routes wired across all screens
- OnboardingScreen: 3-page PageView (拍照录题/AI智能分析/随时复习), saves
  onboarding_done=true to settings on finish
- Restructured app.dart + main.dart: GoRouter created outside ProviderScope
  to enable test provider overrides with redirect
- Smoke tests updated: _OnboardingDoneSettings stub, 33 tests pass
- Cleanup: 5 unused imports, 2 dead fields (_withConfig/_dio), deleted 3 unused DAO placeholders
- Android applicationId/namespace → com.smartwrongnotebook.app, moved MainActivity.kt
- iOS display name → 智能错题本

Blockers:
- None

Next First Step:
- Build and test on device/emulator

Tomorrow first action:
- `flutter run` to verify onboarding flow and full capture→analysis→save cycle

MVP Feature Status:
- ✅ GoRouter routing + StatefulShellRoute tab nav
- ✅ Onboarding screen (first-launch)
- ✅ Home screen (stats, recent, camera entry)
- ✅ Capture: camera/gallery → image storage
- ✅ OCR: ML Kit Chinese text recognition
- ✅ Question Correction: image display, OCR trigger
- ✅ OCR Confirmation: text edit + subject select
- ✅ AI Analysis: DeepSeek/OpenAI API, fake fallback
- ✅ Analysis Result: rich card layout with steps/knowledge/exercises
- ✅ Exercise Practice: mark correct/incorrect, persist results
- ✅ Notebook: list/filter/search, detail view, mastery management
- ✅ Review: due questions, mastery lifecycle, review logs
- ✅ Settings: theme mode, notification trigger, AI provider config, subjects, data import/export
- ✅ Drift SQLite persistence
- ✅ All 33 tests passing
