# Sailesh Task App

A complete multi-screen Flutter task manager built with Firebase Auth, Firestore CRUD, Provider state management, and Light/Dark theming.

## Features

- 🔐 Firebase Email/Password Authentication (Sign Up, Sign In, Sign Out, Forgot Password)
- ✅ Full CRUD — Create, Read, Update, Delete tasks linked to logged-in user
- 📡 Real-time Firestore stream — tasks update instantly
- 🎨 Light & Dark mode toggle with system default support
- 📊 Animated progress bar showing tasks completed
- 🔴🟡🟢 Priority levels — High, Medium, Low
- 🗑️ Swipe-to-delete + delete button on completed tasks
- 🔄 3D flip animation on task completion
- 📱 Smooth page transitions and staggered list animations
- 🔒 Screen protection — unauthenticated users redirected to login

## Project Structure

```
lib/
├── models/         # TaskModel with toJson / fromJson
├── services/       # AuthService & FirestoreService
├── providers/      # AuthProvider, TaskProvider, ThemeProvider
├── theme/          # AppTheme (Light & Dark ThemeData)
├── screens/        # Auth, Home, TaskForm, Settings screens
├── widgets/        # AuthGate, TaskTile, GradientButton, CustomTextField
└── main.dart       # Firebase init & root providers
```

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** authentication
3. Create a **Firestore Database** in test mode
4. Add an **Android app** with your package name
5. Download `google-services.json` → place in `android/app/`
6. Replace values in `lib/firebase_options.dart` with your project credentials

## Running the App

```bash
flutter pub get
flutter run
```

## State Management

Uses **Provider** pattern:
- `AuthProvider` — wraps Firebase Auth, exposes user state and auth actions
- `TaskProvider` — owns real-time Firestore stream, exposes CRUD actions
- `ThemeProvider` — manages Light/Dark/System theme switching

## Firestore Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```
