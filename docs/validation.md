# Validation and limitations

Validation date: **2026-11-17**, America/Sao_Paulo. All records and images used for verification are synthetic.

## Verified locally

- Flutter 3.41.9 stable, framework `00b0c91f06`; Dart 3.11.5. An isolated copy of the installed SDK and an isolated package cache were used; the shared Flutter installation was not upgraded or modified.
- `flutter pub upgrade`: no dependency changes under this SDK. Direct stable packages resolve to shared_preferences 2.5.6, image_picker 1.2.4 and flutter_lints 6.0.0. Fifteen newer transitive/package releases were outside compatible constraints. No overrides added.
- `flutter analyze`: no issues.
- `flutter test`: **11 tests passed**. Five domain/storage tests and six widget tests exercise search/filter intersection, contact rejection, resolution rules, edit/resolve persistence, corrupt storage, 390 × 844 layout, language/data preservation, load retry, editing and read-only resolution, save retry, accessible photo cards and stale-retry protection.
- `flutter build web --no-web-resources-cdn`: release output generated successfully; Wasm compatibility dry run succeeded. This is a JavaScript Web build, not a separately tested Wasm deployment.
- Real Chrome browser inspection against an HTTP-served release build at desktop and 390-pixel viewport sizes. Verified opt-in fixtures, persistent reload, create with a synthetic PNG, photo persistence, case-insensitive search, accessible photographed card action, simulated resolution and resolved state after another reload. No page errors. Current PNG captures are in `docs/screenshots`.

The compiler printed a Cupertino font-family lookup notice although the application uses Material icons and has no Cupertino dependency. The actual inspected Material symbols render correctly. No runtime Cupertino feature is claimed.

## Explicitly unverified

Android/iOS native compilation, device gallery permission behavior, camera (not used), assistive technology on physical devices, other browsers, multi-tab writes and production-sized image collections. Native project scaffolds are freshly generated for the selected SDK, with gallery description on iOS, not certified mobile releases.

No Firebase CLI/emulator binary was installed for this project. Emulator preparation includes loopback configuration, closed rules and a concrete service/privacy contract; there is no implemented remote adapter or claimed emulator test. No backend or app was deployed, no legal license prompts were accepted, and no real user data was accessed.

No Medium article URL or editorial tool/session was available. A full Portuguese revision with current captures, checked examples, references and exactly five final exercises is provided in `docs/lesson-pt-BR.md`. Editorial publication remains blocked on identifying the original article and obtaining editorial access; code work is complete independently.

The installed development guidance referred to `crapper`, `dryer` and `mutator`; these tools were not available in the session. No complexity, duplication score or mutation coverage result is claimed. Behavioral tests and manual review were used instead.

## Manual acceptance checklist

1. Fresh origin starts empty; fictional data appears only after explicit loading.
2. Create found/lost records, edit details, add/replace/remove a small synthetic PNG/JPEG and reload on the same origin.
3. Combine accent-insensitive search, category, found/lost and resolved filters; inspect empty results.
4. Confirm resolution needs a note and consent to simulation. After completion, the original kind remains and editing disappears.
5. Toggle PT-BR/EN; user content persists. Inspect desktop and mobile controls and keyboard focus.
6. Simulate corrupt storage or failed writes using tests; verify records are not silently replaced and retries work.

GitHub metadata is updated with a descriptive summary and seven relevant topics. CI configuration runs analysis, tests and Web build; remote CI results are reported separately from local results.

## Repeat the browser check

With the release build served at `http://127.0.0.1:8387` and Playwright installed separately, run:

```sh
node tool/browser_smoke.cjs
```

`PLAYWRIGHT_MODULE` can point to an installed Playwright/Playwright Core module; `CHROME_PATH` selects a Chrome binary and `APP_URL` selects another local origin. macOS defaults to the installed Google Chrome app. On other systems, provide `CHROME_PATH` or install Playwright's browser. The script uses a fresh browser context and synthetic data, rewrites the application captures, and closes the browser when done. The selected SDK's Web accessibility focus updates need a short pause after focusing a field; the script types through keyboard events instead of injecting input values directly.
