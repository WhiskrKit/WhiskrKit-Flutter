# flutter_whiskrkit example

A manual test harness for the [`flutter_whiskrkit`](../) plugin: it initializes
WhiskrKit with mocked surveys (no backend needed), lets you edit the survey ID
with per-style presets (toast, sheet, fullscreen), and triggers both
`present` and `checkAndPresent`.

```sh
flutter run
```

Surveys render as fully native UI over the Flutter app — see the plugin's
[README](../README.md) for how attachment works and the platform differences.
