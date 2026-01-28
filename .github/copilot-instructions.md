<!-- Copied guidance for AI coding agents working on the OLED Editor Flutter app -->
# Copilot instructions — oled_editor

Purpose
- Help an AI contributor be productive quickly: explain architecture, key files, workflows, integration points, and common pitfalls.

Big picture
- This is a single-screen Flutter app that acts as a small HTML editor + preview (an "OLED IDE").
- The core UI and behavior live in `lib/main.dart` (editor, file manager, preview toggle and WebView controller).

Key files and entry points
- `lib/main.dart`: primary UI, editor, auto-save, file I/O, and WebView preview. See the WebView init at [lib/main.dart](lib/main.dart#L67) and the controller declaration at [lib/main.dart](lib/main.dart#L51).
- `pubspec.yaml`: dependency list — `webview_flutter`, `file_picker`, `path_provider`, `share_plus`, `intl`. Refer to it when adding packages.
- Platform folders (`android/`, `ios/`, `windows/`) contain platform-specific build settings; modify only if adding native integration.

Important patterns and examples
- Editor + preview: the WebViewController is initialized in `_initWebView()` and fed HTML via `loadHtmlString`. Example: [lib/main.dart](lib/main.dart#L71) and the play-button reload at [lib/main.dart](lib/main.dart#L203).
- Autosave: typing triggers `_saveInternal()` via the TextField `onChanged` handler ([lib/main.dart](lib/main.dart#L289) → save implementation [lib/main.dart](lib.main.dart#L89)).
- File storage: files are saved/loaded from application documents directory using `getApplicationDocumentsDirectory()` (see [lib/main.dart](lib/main.dart#L77)).
- Import/export: `file_picker` is used to import external files and a saved copy is written to internal storage; exports use `share_plus` and `XFile`.

Developer workflows
- Restore deps: `flutter pub get` (run from project root).
- Run locally (recommended for iterative UI work):
  - Windows: `flutter run -d windows`
  - Android emulator / device: `flutter run -d <device-id>`
- Build release artifacts: `flutter build <platform>` (e.g., `flutter build windows` / `apk` / `ios`).

Project-specific conventions
- Minimal, single-file app logic: prefer editing `lib/main.dart` for feature changes rather than scattering logic across many files.
- UI color and theme centrally set in `MaterialApp` ThemeData; change global colors there.
- Keep file extensions limited to `.html`, `.js`, `.css`, `.txt` (the drawer file filter follows this list).

Integration notes & gotchas for agents
- `webview_flutter` controller (`WebViewController`) is created in `initState`. Ensure the controller exists before invoking `loadHtmlString()`; race conditions can occur if preview toggle code runs before initialization (see [lib/main.dart](lib/main.dart#L51) and [lib/main.dart](lib/main.dart#L67)).
- When adding native plugins or upgrading plugin versions, check platform folders for additional setup (e.g., Android `minSdkVersion` or iOS platform settings).
- File I/O uses synchronous listing (`listSync()`) for the drawer; prefer async listings if you refactor to avoid UI jank.

How to change common behaviors
- To change autosave cadence: modify the `onChanged` handler at [lib/main.dart](lib/main.dart#L289) — replace direct `_saveInternal()` calls with debounced logic.
- To alter preview reload behavior: modify the play button handler around [lib/main.dart](lib/main.dart#L203).

What NOT to change without checking
- Replacing the single-file UI architecture with multi-file routing or state management requires agreement — many behaviors (autosave, file list, preview) are tightly coupled in `lib/main.dart`.

If you need clarification
- Ask which platform(s) you're targeting (desktop vs mobile) and whether you should split logic into separate modules.

Next steps for contributors
- Run the app locally, exercise open/import/export flows, and open `lib/main.dart` to trace the save/load/preview code paths mentioned above.
