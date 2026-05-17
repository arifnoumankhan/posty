# Posty

Lightweight in-app REST API client for Flutter. Test endpoints without leaving your app or opening Insomnia/Postman.

## Features

- **Request bar** — base URL, HTTP method, endpoint path, **Send** / **Cancel**, live URL sync
- **Params** — query key/value rows, import from URL, URL preview
- **Body** — none, JSON (with format), multipart form (text fields + file upload)
- **Auth** — Bearer, Basic, API Key
- **Headers** — editable rows with presets
- **Response** — status, timing, size; preview & headers tabs; pretty JSON and copy
- **Convert to JSON** — embedded [quicktype](https://app.quicktype.io/) WebView tab
- **Layout** — draggable horizontal/vertical split; dark/light theme
- **Host integration** — open in-app, new desktop window, or new browser tab (`PostyLauncher`, `PostyBootstrap`)
- **Collections + History sidebar** — import Insomnia YAML; environment (`base_url`, `access_token`); right-click **duplicate / rename / add / delete**; expand/collapse all folders
- **Local history** — last 50 calls with request + response snapshots (reload from History tab)

## Install

### Git (recommended)

```yaml
dependencies:
  posty:
    git:
      url: https://github.com/arifnoumankhan/posty.git
      ref: main
```

### Path (local development)

```yaml
dependencies:
  posty:
    path: ../posty
```

## Quick start

### Full screen

```dart
import 'package:posty/posty.dart';

PostyScreen(
  initialBaseUrl: 'https://api.example.com',
  initialHeaders: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
  initialQuicktypeConverterUrl: PostyDefaults.quicktypeConverterUrl,
  persistenceId: 'my_app',
  enableLocalWorkspace: true,
)
```

### Embedded panel

```dart
PostyPanel(
  height: 600,
  initialBaseUrl: 'https://api.example.com',
  initialHeaders: {'Accept': 'application/json'},
)
```

### Open from a menu (new window / tab / in-app)

```dart
await PostyLauncher.open(
  context,
  PostyLaunchRequest(
    openInNewWindow: true, // desktop & web default when supported
    onOpenInApp: (ctx) => ctx.pushNamed('posty_api_screen'),
    webHashRoute: 'posty_api_screen', // Flutter web: opens origin/#/posty_api_screen
  ),
);
```

### Secondary desktop window in `main()`

```dart
void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await PostyBootstrap.runSecondaryWindowIfNeeded(
    args,
    home: (_) => const MyPostyScreen(),
    appTitle: 'My App · Posty',
  )) {
    return;
  }

  runApp(const MyApp());
}
```

Use `PostyWindowIds.defaultDisplayId` and `PostyWindowIds.screenType` when creating windows with `WindowManagerPlus`, or call `PostyDesktopWindow.open()`.

## Example app

```bash
cd example
flutter pub get
flutter run
```

The example runs full **PostyScreen** with collections, history, and environment saved locally (`persistenceId: posty_example`).

## Programmatic API

```dart
final controller = PostyController(
  initialBaseUrl: 'https://httpbin.org',
  initialHeaders: {'Accept': 'application/json'},
);
await controller.send();
final response = controller.lastResponse;
```

## UI mockup

Open [`docs/ui_mockup.html`](docs/ui_mockup.html) for a static layout preview (dark Insomnia-style split view).

## Web note

Browser builds are subject to **CORS**. Mobile and desktop targets work best for arbitrary APIs. For a new tab on web, pass `webUrl` or `webHashRoute` on `PostyLaunchRequest`.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT
