# ADR-002: Hybrid Data Strategy: Cloud Firestore and Local Storage with Hive

## Status
Accepted

## Date
2026-10-23

## Context
Michi Link Mobile manages two fundamentally different data categories:
1. **Real-Time Telemetry and Collar State**: Collar GPS coordinates, battery voltage/percentage, LoRa radio link metrics (RSSI, SNR, packet loss), location breadcrumbs, and security alerts.
2. **Device Preferences and Local Cache**: Paired collar device IDs on the local device, currently selected active collar, and UI preferences (theme mode, base color, font family, language).

## Decision
Adopt a hybrid storage model abstracted behind repository contracts (`DatabaseRepository` and `LocalStorageRepository`):

1. **Cloud Firestore (`FirestoreDatabaseRepository`)**:
   - Acts as the remote database for real-time reactive streams (`collars/{collarId}`), alert subcollections (`alerts`), and telemetry breadcrumbs (`history`).
   - Enables instant updates via Firestore `snapshots()` without HTTP polling overhead.
2. **Hive (`HiveLocalStorageRepository`)**:
   - Embedded, lightweight key-value database for offline local storage.
   - Persists user preferences and paired collar IDs with zero network latency.
3. **Mock Repositories**:
   - `MockDatabaseRepository` and `MockLocalStorageRepository` provide fully deterministic offline simulation for unit testing and demo runs.

## Alternatives Considered

### SharedPreferences for Local Storage
- **Pros**: Standard and officially supported.
- **Cons**: Asynchronous disk-access API based on string keys, lacking native reactive stream support for complex models.
- **Rejected**: Hive offers superior synchronous in-memory read performance and reactive box listeners.

### Supabase / PostgreSQL with WebSockets
- **Pros**: Relational capabilities and open-source foundation.
- **Cons**: Higher initial operational overhead and custom connection management compared to Firebase, which is already integrated with the LoRa gateway infrastructure.
- **Rejected**: The LoRa gateway and backend functions write directly to Firestore collections.

## Consequences
- **Positive**:
  - Instant reactive UI updates driven directly by Firestore document streams.
  - Sub-millisecond application startup due to local Hive cache reading.
  - Total decoupling through abstract repository interfaces, allowing future backend migrations without UI impact.
- **Negative / Trade-offs**:
  - Requires Hive initialization (`Hive.initFlutter()`) before rendering widgets.
  - Firestore deserialization must handle null-safe fallbacks for hardware-emitted fields.
