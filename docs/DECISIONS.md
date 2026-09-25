# DECISIONS LOG

Format: DECISION / OPTIONS / RATIONALE / CONSEQUENCES.

---

## D-001 Install Flutter stable in the container
- DECISION: Install Flutter stable (3.47.5) under /opt/sdk for this session.
- OPTIONS: (a) install SDK locally; (b) rely only on CI.
- RATIONALE: Mission requires `dart format`, `flutter analyze`, `flutter test` to actually run. CI alone gives no fast feedback.
- CONSEQUENCES: SDK is ephemeral; CI workflows pin a Flutter version so results are reproducible.
