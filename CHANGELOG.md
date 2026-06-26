# Changelog

All notable changes to this project are documented in this file.

## [0.4.0] - 2026-06-26

### Added

- **Duplicate collection detection on import** — when importing an Insomnia YAML whose workspace name matches an existing collection, a dialog prompts to **Replace**, **Import as Duplicate**, or **Cancel**.
- **Version badge** next to the Posty title in the app bar (`v0.4.0`).
- **Description column** in Params, Headers, and Body (form) editors — imported from Insomnia's `description` field.
- **Insomnia query param import** — reads `parameters` YAML field directly instead of only parsing the URL string, preserving enabled/disabled state and descriptions.

### Changed

- **JSON response panel** — syntax-highlighted with colour-coded keys (blue), strings (green), numbers (orange), and booleans/null (purple). Tab renamed from "Convert to JSON" to "Convert to Model".
- **JSON request body editor** — live syntax highlighting as you type via a custom `TextEditingController`; no tap-to-toggle required.
- **Auto tab switching** — selecting a POST/PUT/PATCH request opens the Body tab; GET/DELETE/HEAD opens Params.
- **Edit retention on navigation** — params, body, and headers edited in the UI are flushed back to the collection node before switching to another request, so changes are never lost.

### Fixed

- Bearer token dropped on first render frame (`PostyApiScreen` now reads synchronously from the pre-initialised prefs singleton).
- Base URL reverting to localhost — persisted environment is now merged with host-supplied `initialBaseUrl` / `initialEnvironment`; host values always win.
- JSON syntax colours not rendering — removed parent `color` from `SelectableText.rich` so child `TextSpan` colours take effect.
- macOS entitlement `com.apple.security.files.user-selected.read-write` re-added after accidental revert, enabling file picker for Insomnia YAML import.

## [0.3.0] - 2026-05-16

### Added

- **Collections + History sidebar** on `PostyScreen` (enabled by default via `enableLocalWorkspace`).
- **Local history** — last 50 sends with full request + response snapshots (`shared_preferences`).
- **Insomnia import** — REST v5 `.yaml` / `.yml` exports; folder tree kept in **Insomnia `sortKey` order**.
- **Environment** — `base_url` and `access_token` fields; changes apply to the active request and **all** collection requests. Host `Authorization: Bearer` header seeds `access_token`.
- **Collection actions** — toolbar **new request**, **import**, **expand/collapse all** folders.
- **Right-click menu** on folders and requests: **Duplicate**, **Rename**, **Add request**, **Delete** (with confirm).
- `PostyWorkspace`, `PostyEnvironment`, `InsomniaYamlImporter`, `PostySidebar`, `PostyScope`, and related models.

### Changed

- Example app simplified to a single `PostyScreen` with built-in persistence (`persistenceId`).
- Bearer token edits on the Auth tab sync to the environment and all collection requests.

### Fixed

- **Collections / History** tab switcher now updates correctly when returning to Collections.

### Dependencies

- Added `shared_preferences`, `yaml`.

## [0.2.0] - 2026-05-16

### Added

- **Host launch API** — `PostyLauncher`, `PostyLaunchRequest`, `PostyBootstrap`, and desktop/web helpers to open Posty in-app, in a new desktop window (`WindowManagerPlus`), or in a new browser tab.
- **`webHashRoute`** on `PostyLaunchRequest` so Flutter web hosts can open a hash route without building `webUrl` manually.
- **`PostyDefaults`** — shared quicktype converter URL helper.
- **Multipart form body** — file picker support via `file_picker` and `FormData` uploads in `PostyHttpService`.
- **Draggable split layout** — `PostyHorizontalSplitView` / `PostyVerticalSplitView` for resizable request/response panes.
- **URL preview** widget on the Params tab with live updates while typing.
- **Quicktype tab** — embedded WebView on the response panel (“Convert to JSON”).
- **Request history drawer** — optional `showHistoryDrawer` on `PostyScreen`.
- **`PostyWindowIds`** — constants for secondary desktop window integration.

### Changed

- Request bar layout: base URL on its own row; live URL sync via controller listeners.
- Body tab: None, JSON (format), and multipart form editors; tab content rebuild fixes (`ListenableBuilder`, `IndexedStack`).
- `PostyController` notifies listeners on base URL/path changes for live URL preview.
- Expanded public exports in `lib/posty.dart`.

### Fixed

- Text fields losing input on every keystroke (regression from 0.1.x).
- Web launcher: nullable `location.origin` when building hash URLs.
- Body/Params tab showing wrong content after tab switches.

### Dependencies

- Added `file_picker`, `universal_html`, `url_launcher`, `webview_flutter`, `webview_flutter_wkwebview`, `window_manager_plus`.

## [0.1.0] - 2026-05-01

### Added

- Initial release: `PostyScreen`, `PostyPanel`, request/response UI, auth headers, dark/light theme, example app with persisted base URL and request history.
