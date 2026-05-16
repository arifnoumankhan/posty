import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posty/src/theme/posty_theme.dart';

/// Compact full-request URL display; grows vertically when the URL wraps.
class PostyUrlPreview extends StatelessWidget {
  const PostyUrlPreview({
    super.key,
    required this.url,
    required this.theme,
    this.label = 'URL preview',
  });

  final String url;
  final PostyTheme theme;
  final String label;

  static const double _fontSize = 11;
  static const double _lineHeight = 1.35;

  @override
  Widget build(BuildContext context) {
    final display = url.trim().isEmpty ? '—' : url.trim();
    final style = TextStyle(
      color: theme.textPrimary,
      fontSize: _fontSize,
      height: _lineHeight,
      fontFamily: 'monospace',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(color: theme.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(
            minHeight: _fontSize * _lineHeight + 16,
            maxHeight: _fontSize * _lineHeight * 8 + 16,
          ),
          decoration: BoxDecoration(
            color: theme.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    display,
                    key: ValueKey(display),
                    style: style,
                  ),
                ),
              ),
              if (display != '—')
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: theme.textSecondary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () => _copy(context, display),
                  tooltip: 'Copy URL',
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
