# GymTrack Flutter Frontend — MVVM Architecture Guide

This document defines the **Model-View-ViewModel (MVVM)** architectural standard for the GymTrack Flutter application. All existing and upcoming features must follow these patterns.

---

## 1. Architectural Layers & Separation of Concerns

```
┌────────────────────────────────────────────────────────┐
│                      VIEW LAYER                        │
│   (lib/views/ - ConsumerWidget, ConsumerStateful)      │
│   • Renders UI reactively based on ViewModel State     │
│   • Dispatches UI events (e.g. onTap, onSubmit)        │
│   • Listens for side-effects (navigation, snackbars)   │
│   • ZERO business logic, ZERO direct API calls         │
└───────────────────────────▲────────────────────────────┘
                            │ ref.watch / ref.listen
                            │ ref.read(...notifier).action()
┌───────────────────────────▼────────────────────────────┐
│                   VIEWMODEL LAYER                      │
│   (lib/viewmodels/ - Notifier<ViewState>)              │
│   • Holds and emits immutable ViewState                │
│   • Formats data & handles validation                  │
│   • Executes business logic & operations               │
│   • Coordinates with Repositories & Services           │
└───────────────────────────▲────────────────────────────┘
                            │ Calls repository methods
                            │ Returns Domain Models
┌───────────────────────────▼────────────────────────────┐
│                  REPOSITORY LAYER                      │
│   (lib/repositories/ - Abstract interfaces + Impl)     │
│   • Data access abstraction layer                      │
│   • Coordinates ApiService (HTTP/SSE) & StorageService │
│   • Maps network payloads to typed Domain Models       │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    MODEL LAYER                         │
│   (lib/models/ - Immutable Data Classes)               │
│   • Data entities (UserModel, WorkoutModel, etc.)      │
│   • fromJson, toJson, copyWith, value equality         │
└────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```
lib/
├── config/                  # App constants, router, theme
│   ├── constants.dart
│   ├── router.dart
│   └── theme.dart
├── models/                  # [M] Domain Entities & Models
│   ├── user_model.dart
│   └── ...
├── repositories/            # Data Layer / Repositories
│   ├── auth_repository.dart
│   └── ...
├── services/                # Low-level network & persistent storage
│   ├── api_service.dart     # Dio HTTP client, SSE streaming, JWT refresh
│   └── storage_service.dart # FlutterSecureStorage tokens & preferences
├── viewmodels/              # [VM] ViewModels (State + Logic via Riverpod Notifiers)
│   ├── auth/
│   │   ├── auth_session_viewmodel.dart
│   │   ├── login_viewmodel.dart
│   │   └── register_viewmodel.dart
│   ├── home/
│   │   └── home_viewmodel.dart
│   └── ...
├── views/                   # [V] Presentation Views & Screens
│   ├── auth/
│   │   ├── login_view.dart
│   │   └── register_view.dart
│   ├── coach/
│   │   └── coach_view.dart
│   ├── exercise/
│   │   └── exercise_view.dart
│   ├── home/
│   │   └── home_view.dart
│   ├── social/
│   │   └── social_view.dart
│   ├── workout/
│   │   └── workout_view.dart
│   └── main_shell_view.dart
└── widgets/                 # Reusable shared UI widgets
    └── custom_button.dart
```

---

## 3. Implementation Patterns & Rules

### A. Model Layer (`lib/models/`)
- All models must be immutable (`@immutable` or `const` constructors).
- Provide `fromJson(Map<String, dynamic> json)` and `toJson()`.
- Implement `copyWith(...)` and value equality (`operator ==` & `hashCode`).
- Models must not depend on any View or ViewModel.

### B. Repository Layer (`lib/repositories/`)
- Always declare an abstract interface (`IAuthRepository`, `IWorkoutRepository`) and an implementation class (`AuthRepository`).
- Inject low-level services (`ApiService`, `StorageService`).
- Expose the repository as a Riverpod `Provider<T>`:
  ```dart
  final authRepositoryProvider = Provider<IAuthRepository>((ref) {
    return AuthRepository(
      apiService: ref.watch(apiServiceProvider),
      storageService: ref.watch(storageServiceProvider),
    );
  });
  ```
- Catches network exceptions and translates them into domain or `ApiException` objects.

### C. ViewModel Layer (`lib/viewmodels/`)
- Each View or Feature has a dedicated ViewModel implementing `Notifier<ViewState>` or `AsyncNotifier<T>`.
- **ViewState**: Immutable class containing UI properties (`isLoading`, `errorMessage`, `isSuccess`, data fields).
  ```dart
  class LoginState {
    final String email;
    final String password;
    final bool isLoading;
    final String? errorMessage;
    final bool isSuccess;
    ...
  }
  ```
- **ViewModel**: Extends `Notifier<ViewState>`:
  ```dart
  class LoginViewModel extends Notifier<LoginState> {
    late final IAuthRepository _authRepository;

    @override
    LoginState build() {
      _authRepository = ref.watch(authRepositoryProvider);
      return const LoginState();
    }

    Future<bool> login() async { ... }
  }

  final loginViewModelProvider =
      NotifierProvider.autoDispose<LoginViewModel, LoginState>(() => LoginViewModel());
  ```
- **Rules**:
  - Do NOT import `flutter/material.dart` unless strictly required for value types (pure Dart is preferred for unit tests).
  - Do NOT reference `BuildContext` inside a ViewModel.

### D. View Layer (`lib/views/`)
- Extend `ConsumerWidget` or `ConsumerStatefulWidget`.
- **Reactive UI**: Watch state with `ref.watch(viewModelProvider)`.
- **User Actions**: Trigger methods with `ref.read(viewModelProvider.notifier).action()`.
- **Side Effects**: Handle single-shot side-effects (navigation, dialogs, SnackBars) using `ref.listen`:
  ```dart
  ref.listen<LoginState>(loginViewModelProvider, (previous, next) {
    if (next.isSuccess) {
      context.go('/home');
    }
    if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.errorMessage!)),
      );
    }
  });
  ```

---

## 4. Testing Strategy in MVVM

Because MVVM decouples business logic from the UI framework, ViewModels can be tested via standard Dart unit tests without booting the Flutter widget engine:

1. **Mock Repositories**: Create a mock or fake class implementing the repository interface (`FakeAuthRepository implements IAuthRepository`).
2. **ProviderContainer**: Inject the mock using `overrides`:
   ```dart
   final container = ProviderContainer(
     overrides: [
       authRepositoryProvider.overrideWithValue(fakeAuthRepository),
     ],
   );
   ```
3. **Execute & Assert**: Call methods on `container.read(viewModelProvider.notifier)` and assert against `container.read(viewModelProvider)`.
