import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/posty_defaults.dart';

/// Embedded quicktype (or custom URL) + optional response JSON helpers.
///
/// Uses [WebViewPlatform] implementations when not on web ([kIsWeb]).
class QuicktypeConverterTab extends StatefulWidget {
  const QuicktypeConverterTab({
    super.key,
    required this.theme,
    required this.converterUrl,
    required this.onConverterUrlCommitted,
    this.responseJsonForCopy = '',
  });

  final PostyTheme theme;
  /// Current URL (persisted via [PostyController]).
  final String converterUrl;
  /// Called after user taps **Apply** with a validated URL string.
  final ValueChanged<String> onConverterUrlCommitted;
  /// Raw / formatted JSON from the response Preview tab — **Copy JSON** fills clipboard.
  final String responseJsonForCopy;

  @override
  State<QuicktypeConverterTab> createState() => _QuicktypeConverterTabState();
}

class _QuicktypeConverterTabState extends State<QuicktypeConverterTab> {
  late final TextEditingController _urlCtrl;
  WebViewController? _web;
  double _progress = 0;
  String? _error;

  Uri get _effectiveUri =>
      Uri.parse(PostyDefaults.normalizeQuicktypeConverterUrl(widget.converterUrl));

  WebViewController _buildController(Uri uri) {
    late final PlatformWebViewControllerCreationParams params;
    if (!kIsWeb && WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    return WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) =>
              mounted ? setState(() => _progress = p.toDouble()) : null,
          onPageFinished: (_) => mounted ? setState(() => _error = null) : null,
          onWebResourceError: (WebResourceError e) {
            if (mounted) setState(() => _error = e.description);
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.converterUrl);
    if (!kIsWeb) {
      _web = _buildController(_effectiveUri);
    }
  }

  @override
  void didUpdateWidget(covariant QuicktypeConverterTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.converterUrl != widget.converterUrl && !kIsWeb) {
      _urlCtrl.text = widget.converterUrl;
      final next = Uri.parse(
        PostyDefaults.normalizeQuicktypeConverterUrl(widget.converterUrl),
      );
      _web?.loadRequest(next);
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyUrl(BuildContext context) async {
    final normalized =
        PostyDefaults.normalizeQuicktypeConverterUrl(_urlCtrl.text);
    _urlCtrl.text = normalized;
    widget.onConverterUrlCommitted(normalized);
    if (!kIsWeb && _web != null) {
      await _web!.loadRequest(Uri.parse(normalized));
      if (!mounted) return;
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    if (kIsWeb) {
      return _webFallback(context, t);
    }

    final web = _web!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Converter URL · default quicktype',
          style: TextStyle(color: t.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: TextStyle(color: t.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: PostyDefaults.quicktypeConverterUrl,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _applyUrl(context),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _applyUrl(context),
              style: FilledButton.styleFrom(
                backgroundColor: t.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () async {
                final body = widget.responseJsonForCopy;
                if (body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nothing to copy — preview has no JSON yet'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                await Clipboard.setData(ClipboardData(text: body));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Response JSON copied — paste in converter')),
                );
              },
              icon: const Icon(Icons.content_copy, size: 18),
              label: const Text('Copy JSON from response'),
            ),
          ],
        ),
        Text(
          'Paste copied JSON into the left pane on quicktype (or another tool at your URL); pick Dart under Language.',
          style: TextStyle(color: t.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Material(
            color: t.warningColor.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: t.warningColor, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => web.loadRequest(
                      Uri.parse(
                        PostyDefaults.normalizeQuicktypeConverterUrl(
                          widget.converterUrl,
                        ),
                      ),
                    ),
                    child: Text('Retry', style: TextStyle(color: t.primaryColor)),
                  ),
                ],
              ),
            ),
          ),
        if (_progress > 0 && _progress < 100)
          LinearProgressIndicator(
            value: _progress / 100,
            minHeight: 2,
            backgroundColor: t.borderColor,
            color: t.primaryColor,
          ),
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: WebViewWidget(controller: web),
        )),
      ],
    );
  }

  Widget _webFallback(BuildContext context, PostyTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Converter URL · default quicktype',
          style: TextStyle(color: t.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _urlCtrl,
          style: TextStyle(color: t.textPrimary, fontSize: 13),
          decoration: InputDecoration(
            hintText: PostyDefaults.quicktypeConverterUrl,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) async => _applyUrl(context),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton(
              onPressed: () => _applyUrl(context),
              style: FilledButton.styleFrom(
                backgroundColor: t.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Text('Apply'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () async {
                final u = Uri.parse(
                  PostyDefaults.normalizeQuicktypeConverterUrl(_urlCtrl.text),
                );
                widget.onConverterUrlCommitted(u.toString());
                await launchUrl(u, mode: LaunchMode.externalApplication);
              },
              style: FilledButton.styleFrom(
                backgroundColor: t.inputFill,
                foregroundColor: t.textPrimary,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open in browser'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () async {
            final body = widget.responseJsonForCopy;
            if (body.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nothing to copy — preview has no JSON yet'),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            await Clipboard.setData(ClipboardData(text: body));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Response JSON copied — paste in converter'),
              ),
            );
          },
          icon: const Icon(Icons.content_copy, size: 18),
          label: const Text('Copy JSON from response'),
        ),
        Text(
          'Web: open quicktype in an external tab, then paste JSON from the response.',
          style: TextStyle(color: t.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}
