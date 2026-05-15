# Posty

Lightweight in-app REST API client for Flutter. Test endpoints without leaving your app or opening Insomnia/Postman.

## Features

- Base URL + path, HTTP method selector, **Send** / **Cancel**
- **Params** tab with URL preview, query key/value rows, import from URL
- **Body** tab: None, JSON (with format), form-urlencoded
- **Auth** tab: Bearer, Basic, API Key
- **Headers** tab with presets
- **Response** panel: status, timing, size, pretty JSON preview, copy body, response headers
- Dark/light theme
- Responsive split layout (side-by-side on wide screens)

## Install via Git

```yaml
dependencies:
  posty:
    git:
      url: https://github.com/arifnoumankhan/posty.git
      ref: main
```

## Run the demo app

```bash
cd example
flutter pub get
flutter run
```

The example persists **base URL** and the last **20 requests** using `shared_preferences`.

## Usage in your app

### Full screen

```dart
import 'package:posty/posty.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PostyScreen(
      initialBaseUrl: 'https://api.example.com',
      initialHeaders: {'Accept': 'application/json'},
    ),
  ),
);
```

### Embedded panel

```dart
PostyPanel(
  height: 600,
  initialBaseUrl: 'https://api.example.com',
)
```

### Programmatic request / response

```dart
final controller = PostyController(initialBaseUrl: 'https://httpbin.org');
await controller.send();
final response = controller.lastResponse;
```

## UI mockup

Open [`docs/ui_mockup.html`](docs/ui_mockup.html) in a browser for a static layout preview (dark Insomnia-style split view).

## Barioo integration (phase 2)

Add a dev-menu entry that opens `PostyScreen` with your staging base URL and optional auth header from the logged-in session.

## Web note

Browser builds are subject to **CORS**. The example app works best on mobile/desktop for arbitrary APIs.

## License

MIT
