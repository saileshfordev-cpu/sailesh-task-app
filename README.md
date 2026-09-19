# TaskFlow

A multi-screen Flutter task manager with Firebase Authentication, real-time
Firestore CRUD, Provider state management, and dynamic Light/Dark theming.

<!--
  Add your screenshots or a screen recording/GIF here before submitting, e.g.:
  ![Login screen](docs/screenshots/login.png)
  ![Home screen - light](docs/screenshots/home_light.png)
  ![Home screen - dark](docs/screenshots/home_dark.png)
-->

## Features

- **Authentication** — Email/Password sign up, sign in, sign out, and
  password-reset email, all via Firebase Auth.
- **Screen protection** — `AuthGate` listens to `authStateChanges()` and
  routes signed-out users to `LoginScreen`, signed-in users to `HomeScreen`.
  No screen is reachable without a valid session.
- **Real-time CRUD** — Tasks live at `users/{uid}/tasks/{taskId}` in Cloud
  Firestore and stream live into the UI with `snapshots()`.
  - **Create** — the `+ New Task` button.
  - **Read** — the live list on Home, with All / Active / Done filters.
  - **Update** — tap a task to edit title, description, or priority.
  - **Delete** — swipe a task left, confirm in the dialog.
- **State management** — `provider` with three `ChangeNotifier`s
  (`AuthProvider`, `TaskProvider`, `ThemeProvider`); widgets never call
  Firebase directly.
- **Light/Dark mode** — custom `ThemeData` for both modes (indigo/teal
  palette, rounded cards, custom inputs). Toggle from the AppBar icon or the
  Settings screen; the switch is instant and doesn't reset app state.

## Project structure

```
lib/
├── models/          # TaskModel (toJson / fromJson)
├── services/        # AuthService, FirestoreService — the only files that touch Firebase
├── providers/        # AuthProvider, TaskProvider, ThemeProvider
├── theme/           # AppTheme (light + dark ThemeData)
├── screens/
│   ├── auth/        # LoginScreen, SignUpScreen
│   ├── home/        # HomeScreen, TaskFormScreen
│   └── settings/    # SettingsScreen
├── widgets/         # AuthGate, TaskTile, CustomTextField, GradientButton
└── main.dart         # Firebase init + root MultiProvider + MaterialApp
```

## Firebase setup

1. **Create a Firebase project** at [console.firebase.google.com](https://console.firebase.google.com).
2. **Enable Authentication** → Sign-in method → enable **Email/Password**.
3. **Enable Firestore** → Create database → start in production mode.
4. **Deploy the security rules** in `firestore.rules` (already scoped so a
   user can only read/write their own `users/{uid}/tasks` subcollection):
   ```
   firebase deploy --only firestore:rules
   ```
5. **Install the FlutterFire CLI** and generate `lib/firebase_options.dart`
   for your own project (the one in this repo is a placeholder):
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This walks you through selecting your Firebase project and the
   platforms to target (Android/iOS/Web/macOS), then writes the real
   `firebase_options.dart`.
6. **Install dependencies and run:**
   ```
   flutter pub get
   flutter run
   ```

### Android-specific step
`flutterfire configure` also creates `android/app/google-services.json`
automatically. If you set up the Android app manually in the console
instead, download that file yourself and place it in `android/app/`.

### iOS-specific step
Similarly, `flutterfire configure` adds `ios/Runner/GoogleService-Info.plist`.
If configuring manually, download it from the console and add it to the
`Runner` target in Xcode.

## Firestore data model

```
users (collection)
  └── {uid} (document)
        └── tasks (collection)
              └── {taskId} (document)
                    ├── title: string
                    ├── description: string
                    ├── isDone: bool
                    ├── priority: "low" | "medium" | "high"
                    ├── createdAt: timestamp
                    └── userId: string
```

## Notes on architecture choices

- **Provider** was chosen for its low boilerplate and tight fit with
  `ChangeNotifier` + `Stream` — ideal for wrapping Firebase's own reactive
  APIs (`authStateChanges()`, `snapshots()`) without extra plumbing.
- Every Firebase call is isolated inside `services/`; `providers/` hold
  state and expose intention-revealing methods (`signIn`, `addTask`,
  `toggleDone`); `screens/` and `widgets/` are purely presentational and
  read state via `context.watch` / `context.read`.
- Errors from Firebase (auth failures, stream errors) are translated into
  human-readable messages in the provider layer, not shown as raw
  exceptions in the UI.
