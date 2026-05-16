import 'package:universal_html/html.dart' as html;

void openPostyInBrowserTab(Uri url, {String windowName = 'posty'}) {
  html.window.open(
    url.toString(),
    windowName,
    'noopener,noreferrer,width=1280,height=860',
  );
}
