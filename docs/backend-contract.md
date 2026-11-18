# Backend boundary and privacy contract

The running app uses **only local browser storage**. There is no login, Firebase initialization, remote adapter, verified identity, real ownership claim or server-confirmed return. Old Firebase dependencies and obsolete native Google Services configuration were removed because they were unused.

`ListingRepository.load()` returns complete validated listings; `save(next)` either persists the entire snapshot or throws. UI commits its state only after success and offers retry on failure. This snapshot contract is suitable for one local writer, not concurrent cloud clients. A future server adapter should introduce per-listing commands with revision checks instead of copying snapshot writes to Firestore.

## Proposed authenticated service

- `POST /listings`: create an open found/lost record. Server assigns ID, owner ID, revision and timestamps. Public fields: title (3–70), description (3–400), district/public place (3–60), category enum, kind enum, sanitized photo reference. No email, phone, precise coordinates, exact residential addresses or identity documents in public records.
- `PATCH /listings/:id`: authenticated owner, matching revision, open status. Kind and creation time immutable. Reject unknown fields and enforce bounds on the server.
- `POST /listings/:id/resolve`: authenticated owner, matching revision, explicit confirmation and note (3–160). Atomic open → resolved; repeated command ID must return the same result. Keep verification details private. A production claim process needs separate consent and identity controls; local simulation is not evidence.
- `GET /listings`: authorized, paginated read with normalized title/description/area search, category, kind and status filters. Never return private claim evidence.
- Photo service: decode and re-encode PNG/JPEG, strip EXIF/GPS, reject malformed images, limit decoded dimensions and file size, moderate sensitive content and enforce owner-scoped access/deletion. The local picker asks for no full metadata but is not a server sanitizer.

## Emulator preparation

`firebase.json` binds Firestore to loopback. `backend/firestore.rules` intentionally denies every read and write. It is a closed starting point, not an implemented or validated backend.

With Firebase CLI and a supported Java runtime installed, start only a synthetic demo project:

```sh
firebase emulators:start --only firestore --project demo-reencontra
```

The app does not connect to this emulator yet. No emulator binaries/CLI were present in this validation environment, so emulator execution and rules integration tests are **not claimed**. Do not deploy these files as a functional backend. Before connecting a remote adapter, test unauthenticated access, cross-owner writes, unknown public fields, invalid transitions, stale revisions, duplicate commands, and malformed/EXIF-bearing uploads. Never use a production Firebase project for classroom fixtures.
