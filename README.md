# Readify — Flutter MVP Build Prompt

Copy everything below into your vibe-coding IDE (Cursor, Windsurf, Bolt, Replit AI, etc.) as a single prompt. It covers setup → code → APK build.

---

## PROMPT START

You are an expert Flutter developer. Build a complete, working Flutter Android app called **Readify** — a simple PDF reader. Follow every step below in order. Do not add features beyond what is listed. Keep the code clean, well-commented, and beginner-friendly to maintain.

### 1. Project Setup

1. Create a new Flutter project:
   ```
   flutter create readify
   cd readify
   ```
2. Set the minimum SDK in `android/app/build.gradle` to `minSdkVersion 21`.
3. Set the app name to "Readify" in:
   - `android/app/src/main/AndroidManifest.xml` (`android:label="Readify"`)
   - `pubspec.xml` (`name: readify`, `description: A simple PDF reader`)
4. Add these dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     file_picker: ^8.0.0
     syncfusion_flutter_pdfviewer: ^26.0.0
     shared_preferences: ^2.2.0
     provider: ^6.1.0
     path_provider: ^2.1.0
   ```
5. Run `flutter pub get`.
6. Add required Android permissions in `AndroidManifest.xml`:
   - `READ_EXTERNAL_STORAGE`
   - `READ_MEDIA_IMAGES` (for Android 13+ compatibility with file_picker)
7. Create this folder structure inside `lib/`:
   ```
   lib/
     main.dart
     theme/
       app_theme.dart
       theme_provider.dart
     models/
       recent_pdf.dart
     services/
       recent_files_service.dart
     screens/
       home_screen.dart
       pdf_viewer_screen.dart
       settings_screen.dart
     widgets/
       recent_pdf_tile.dart
   ```

### 2. Theming (Light/Dark Mode)

- Create `theme/app_theme.dart` with a `lightTheme` and `darkTheme` (`ThemeData`), using Material 3 (`useMaterial3: true`).
- Create `theme/theme_provider.dart` using `ChangeNotifier` + `provider` package:
  - Holds current `ThemeMode` (light/dark/system).
  - Persists the choice using `shared_preferences` (key: `"theme_mode"`).
  - Loads saved preference on app start.
- Wrap the app in `main.dart` with `ChangeNotifierProvider<ThemeProvider>` and use `Consumer` to apply `themeMode` to `MaterialApp`.

### 3. Recent PDFs Model & Service

- `models/recent_pdf.dart`: a simple class `RecentPdf` with fields: `String name`, `String path`, `DateTime lastOpened`. Include `toJson`/`fromJson`.
- `services/recent_files_service.dart`:
  - Uses `shared_preferences` to store a JSON-encoded list of `RecentPdf` (key: `"recent_pdfs"`).
  - Methods: `getRecentPdfs()`, `addRecentPdf(RecentPdf pdf)` (add to top, dedupe by path, cap list at 10 items), `clearRecentPdfs()`.

### 4. Home Screen (`screens/home_screen.dart`)

- AppBar: title "Readify", with a settings icon button (top right) navigating to `SettingsScreen`.
- Center: large "📂 Open PDF" `ElevatedButton`.
  - On tap: use `file_picker` (`FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'])`) to select a PDF from device storage.
  - If a file is picked: save it to recent files via `RecentFilesService`, then navigate to `PdfViewerScreen` passing the file path.
  - Handle the case where the user cancels the picker (do nothing).
  - Handle errors (e.g. permission denied) with a `SnackBar`.
- Below the button: "Recently Opened" section header.
  - `FutureBuilder`/`ListView.builder` showing recent PDFs using `RecentPdfTile` widget (file icon, filename, last opened date, tappable to reopen in viewer).
  - If the file no longer exists at that path, show a small "file not found" state and let the user remove it from the list on tap.
  - If list is empty, show a friendly empty state ("No PDFs opened yet").

### 5. PDF Viewer Screen (`screens/pdf_viewer_screen.dart`)

- Accepts a `filePath` (String) as a constructor argument.
- AppBar: filename as title, current page indicator (e.g. "3 / 20") on the right.
- Body: `SfPdfViewer.file(File(filePath))` from `syncfusion_flutter_pdfviewer`:
  - Enable page swipe navigation (`pageLayoutMode: PdfPageLayoutMode.single` with `scrollDirection: PdfScrollDirection.horizontal` for swipe-between-pages behavior — OR use continuous vertical scroll with pinch zoom; pick single-page horizontal swipe since it's specified as "swipe between pages").
  - Enable pinch-to-zoom (`enableDoubleTapZooming: true`, default zoom is built into `SfPdfViewer`).
  - Use `PdfViewerController` to track and display current page number in the AppBar via `onPageChanged` callback.
- Handle load errors (corrupted/missing file) with an error message and a back button.

### 6. Settings Screen (`screens/settings_screen.dart`)

- AppBar: title "Settings".
- List items:
  1. "Dark Mode" — a `SwitchListTile` bound to `ThemeProvider` (toggle light/dark).
  2. "About Readify" — tapping opens a simple `AboutDialog` or a new screen showing: app name, version (use `package_info_plus` if you want dynamic version, otherwise hardcode "1.0.0"), and a one-line description: "Readify — a simple, fast PDF reader."

### 7. Main Entry (`main.dart`)

- Set up `MultiProvider`/`ChangeNotifierProvider` for `ThemeProvider`.
- `MaterialApp` with `title: 'Readify'`, `theme`, `darkTheme`, `themeMode` from provider, `home: HomeScreen()`.
- Remove the default debug banner (`debugShowCheckedModeBanner: false`).

### 8. Error Handling & Polish

- Wrap file picking and PDF loading in try/catch with user-friendly SnackBars.
- Add loading indicators (`CircularProgressIndicator`) while the PDF viewer initializes.
- Ensure the app works fully offline (no network calls anywhere).
- Test on both light and dark themes for contrast/readability.

### 9. Testing Checklist (verify before building APK)

- [ ] App builds and runs with `flutter run` on a physical device or emulator.
- [ ] "Open PDF" correctly opens the system file picker and filters to PDFs only.
- [ ] Selected PDF opens in the viewer and displays pages correctly.
- [ ] Swiping between pages works; pinch zoom works; page number updates live.
- [ ] Recently opened list updates after opening a PDF and persists after app restart.
- [ ] Tapping a recent PDF reopens it correctly.
- [ ] Dark/light mode toggle works and persists after app restart.
- [ ] About screen shows correct info.
- [ ] No crashes when permission is denied or file picker is cancelled.

### 10. Build the Release APK

1. Clean the project:
   ```
   flutter clean
   flutter pub get
   ```
2. (Optional but recommended) Create a signing key for a real release build:
   ```
   keytool -genkey -v -keystore ~/readify-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias readify
   ```
   Configure `android/key.properties` and reference it in `android/app/build.gradle` under `signingConfigs`.
3. Build the release APK:
   ```
   flutter build apk --release
   ```
4. Output APK will be at:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
5. (Optional) Build a smaller per-architecture APK set:
   ```
   flutter build apk --split-per-abi
   ```
6. Install on a connected device to do a final manual test:
   ```
   flutter install
   ```

### Constraints (do not exceed scope)

- Do NOT add PDF annotation, bookmarks, search, sharing, cloud storage, login/auth, or ads.
- Do NOT add any backend/server — this is a fully offline, local-only app.
- Keep the UI minimal and clean — no unnecessary screens beyond Home, PDF Viewer, and Settings.

## PROMPT END