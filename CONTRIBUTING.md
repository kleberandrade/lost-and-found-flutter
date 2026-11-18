# Contributing

Use Flutter 3.41.9 / Dart 3.11.5 and the committed lockfile. Start with `flutter pub get --enforce-lockfile`, then run `flutter analyze`, `flutter test` and `flutter build web --no-web-resources-cdn` sequentially. Keep changes focused and include behavior tests for domain changes.

Use synthetic data only. Preserve the distinction between local simulations and remote services. Never add credentials, personal contact details, precise coordinates or identity documents. New integrations must implement the domain boundary, surface errors, and document their platform limits. Follow [the backend contract](docs/backend-contract.md) before proposing a cloud implementation.

Preserve PT-BR and EN labels, keyboard focus, readable contrast, and 48-pixel touch targets. Test 390-pixel and desktop layouts, long labels, empty results, storage failures and image errors. Locale changes must preserve user content. Keep screenshots current and label conceptual art.

Document dependency/toolchain changes, including unresolved compatibility limits. Do not loosen SDK constraints or add overrides solely to hide a resolver conflict. Preserve Kleber Andrade's authorship and all third-party licenses.
