# Changelog

All notable changes to this project are documented in this file.

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
