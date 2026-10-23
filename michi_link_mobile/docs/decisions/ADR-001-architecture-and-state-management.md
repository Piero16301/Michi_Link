# ADR-001: Feature-First Architecture with BLoC/Cubit and GetIt Service Locator

## Status
Accepted

## Date
2026-10-23

## Context
Michi Link Mobile manages continuous real-time data streams (LoRa radio link telemetry, critical geofence alerts, GPS coordinates) and requires a predictable, reactive, and easily testable user interface state.
Key requirements include:
- Clear separation between presentation, business logic, and data layers.
- High testability for isolated components (unit tests and widget tests with mocks).
- Support for toggling execution environments (mock/testing environment vs. live production).
- Modular and scalable codebase structure as additional pet monitoring capabilities are introduced.

## Decision
1. **Feature-First Structure**: Code organization is segmented by functional modules (`app`, `home`, `collars`, `history`, `notifications`, `settings`), where each module encapsulates its views (`view`), reusable components (`widgets`), and state managers (`cubit`).
2. **State Management with BLoC / Cubit**: We adopt `flutter_bloc` and `Cubit` due to their unidirectional data flow (`State -> Event/Method -> State`), immutability powered by `equatable`, and seamless debugging integration via `AppBlocObserver`.
3. **Dependency Injection with GetIt and ServiceFactory**:
   - `GetIt` serves as the lazy singleton service locator.
   - `ServiceFactory` decouples concrete implementations based on the active `Environment` (`mock` vs. `prod`).

## Alternatives Considered

### Provider / ChangeNotifier
- **Pros**: Low learning curve, native within the Flutter ecosystem.
- **Cons**: Prone to unnecessary coupling and mutable state that is harder to audit across high-frequency telemetry updates.
- **Rejected**: Lacks the formal predictability and traceability required for continuous real-time telemetry.

### Riverpod
- **Pros**: Compile-time safety, no BuildContext needed for reads.
- **Cons**: Requires wholesale adoption of its custom widget wrappers and generator patterns, adding overhead for a team standardized on BLoC.
- **Rejected**: Internal engineering guidelines and the Very Good Analysis ecosystem strongly favor BLoC/Cubit.

## Consequences
- **Positive**:
  - Highly testable code with `bloc_test` and `mocktail`.
  - Strict separation of concerns between UI, repositories, and services.
  - Immediate capability to run the app in `Environment.mock` without active Firebase credentials.
- **Negative / Trade-offs**:
  - Requires boilerplate for immutable state classes (`copyWith`, `props`).
  - Learning curve for developers unfamiliar with BLoC state streams.
