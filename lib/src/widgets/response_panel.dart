import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posty/src/models/posty_response.dart';
import 'package:posty/src/state/posty_controller.dart';
import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/widgets/quicktype_converter_tab.dart';

class ResponsePanel extends StatelessWidget {
  const ResponsePanel({
    super.key,
    required this.controller,
    required this.theme,
    required this.onCopyBody,
  });

  final PostyController controller;
  final PostyTheme theme;
  final VoidCallback onCopyBody;

  @override
  Widget build(BuildContext context) {
    final response = controller.lastResponse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusStrip(
          theme: theme,
          controller: controller,
          response: response,
        ),
        const SizedBox(height: 8),
        _ResponseTabBar(theme: theme, controller: controller),
        const SizedBox(height: 8),
        Expanded(
          child: controller.responseTabIndex == 0
              ? _PreviewTab(
                  theme: theme,
                  body: controller.formattedResponseBody,
                  isEmpty: response == null,
                  onCopy: onCopyBody,
                )
              : controller.responseTabIndex == 1
                  ? _HeadersTab(theme: theme, response: response)
                  : QuicktypeConverterTab(
                      theme: theme,
                      converterUrl: controller.quicktypeConverterUrl,
                      onConverterUrlCommitted: controller.setQuicktypeConverterUrl,
                      responseJsonForCopy: controller.formattedResponseBody,
                    ),
        ),
      ],
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.theme,
    required this.controller,
    required this.response,
  });

  final PostyTheme theme;
  final PostyController controller;
  final PostyResponse? response;

  @override
  Widget build(BuildContext context) {
    if (response == null && !controller.isLoading) {
      return Text(
        'Send a request to see the response',
        style: TextStyle(color: theme.textSecondary, fontSize: 13),
      );
    }
    if (controller.isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Text('Sending…', style: TextStyle(color: theme.textSecondary)),
        ],
      );
    }

    final r = response;
    if (r == null) {
      return const SizedBox.shrink();
    }

    final code = r.statusCode;
    Color pillColor = theme.textSecondary;
    if (code != null) {
      if (code >= 200 && code < 300) {
        pillColor = theme.successColor;
      } else if (code >= 400) {
        pillColor = theme.errorColor;
      } else {
        pillColor = theme.warningColor;
      }
    }

    final size = _formatBytes(r.bodyBytes);
    final timeLabel = controller.lastSentAt != null ? _relativeTime(controller.lastSentAt!) : '';

    return Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: pillColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: pillColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            r.statusLabel,
            style: TextStyle(color: pillColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text('${r.durationMs} ms', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        Text(size, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        if (timeLabel.isNotEmpty)
          Text(timeLabel, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _ResponseTabBar extends StatelessWidget {
  const _ResponseTabBar({required this.theme, required this.controller});

  final PostyTheme theme;
  final PostyController controller;

  @override
  Widget build(BuildContext context) {
    final headerCount = controller.lastResponse?.headers.length ?? 0;
    return Row(
      children: [
        _tab('Preview', 0),
        _tab('Headers ($headerCount)', 1),
        _tab('Convert to JSON', 2),
      ],
    );
  }

  Widget _tab(String label, int index) {
    final selected = controller.responseTabIndex == index;
    return InkWell(
      onTap: () => controller.setResponseTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? theme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? theme.textPrimary : theme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PreviewTab extends StatelessWidget {
  const _PreviewTab({
    required this.theme,
    required this.body,
    required this.isEmpty,
    required this.onCopy,
  });

  final PostyTheme theme;
  final String body;
  final bool isEmpty;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Center(
        child: Text('No response yet', style: TextStyle(color: theme.textSecondary)),
      );
    }
    final lines = body.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy body'),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.codeBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.borderColor),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText.rich(
                TextSpan(
                  children: _buildHighlightedLines(lines),
                ),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.45,
                  color: theme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<TextSpan> _buildHighlightedLines(List<String> lines) {
    // Syntax-highlight colours (dark & light aware)
    final bool isDark = theme.brightness == Brightness.dark;
    final Color lineNumColor  = theme.textSecondary.withValues(alpha: 0.35);
    final Color gutterColor   = theme.textSecondary.withValues(alpha: 0.2);
    final Color keyColor      = isDark ? const Color(0xFF79C0FF) : const Color(0xFF0550AE);
    final Color strColor      = isDark ? const Color(0xFF7EE787) : const Color(0xFF1A7F37);
    final Color numColor      = isDark ? const Color(0xFFFF9A4D) : const Color(0xFFD1242F);
    final Color boolNullColor = isDark ? const Color(0xFFD2A8FF) : const Color(0xFF8250DF);
    final Color punctColor    = theme.textSecondary.withValues(alpha: 0.6);
    final Color plainColor    = theme.textPrimary;

    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final lineNum = (i + 1).toString().padLeft(4);
      spans.add(TextSpan(
        text: lineNum,
        style: TextStyle(color: lineNumColor, fontSize: 11),
      ));
      spans.add(TextSpan(
        text: ' │ ',
        style: TextStyle(color: gutterColor),
      ));
      spans.addAll(_tokeniseLine(lines[i], keyColor, strColor, numColor, boolNullColor, punctColor, plainColor));
      spans.add(const TextSpan(text: '\n'));
    }
    return spans;
  }

  /// Tokenises a single JSON line into coloured [TextSpan]s.
  List<TextSpan> _tokeniseLine(
    String line,
    Color keyColor,
    Color strColor,
    Color numColor,
    Color boolNullColor,
    Color punctColor,
    Color plainColor,
  ) {
    final spans = <TextSpan>[];
    int pos = 0;
    final len = line.length;

    while (pos < len) {
      final ch = line[pos];

      // Whitespace — preserve as-is
      if (ch == ' ' || ch == '\t') {
        int end = pos + 1;
        while (end < len && (line[end] == ' ' || line[end] == '\t')) end++;
        spans.add(TextSpan(text: line.substring(pos, end)));
        pos = end;
        continue;
      }

      // String literal
      if (ch == '"') {
        int end = pos + 1;
        while (end < len) {
          if (line[end] == '\\') { end += 2; continue; }
          if (line[end] == '"') { end++; break; }
          end++;
        }
        final raw = line.substring(pos, end);
        // Is it a key? (followed by optional spaces then ':')
        bool isKey = false;
        int after = end;
        while (after < len && (line[after] == ' ' || line[after] == '\t')) after++;
        if (after < len && line[after] == ':') isKey = true;

        if (isKey) {
          spans.add(TextSpan(text: raw, style: TextStyle(color: keyColor, fontWeight: FontWeight.w600)));
        } else {
          spans.add(TextSpan(text: raw, style: TextStyle(color: strColor)));
        }
        pos = end;
        continue;
      }

      // Number
      if (ch == '-' || (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57)) {
        int end = pos + 1;
        while (end < len) {
          final c = line[end];
          if ((c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) ||
              c == '.' || c == 'e' || c == 'E' || c == '+' || c == '-') {
            end++;
          } else {
            break;
          }
        }
        spans.add(TextSpan(text: line.substring(pos, end), style: TextStyle(color: numColor)));
        pos = end;
        continue;
      }

      // Booleans and null
      if (line.startsWith('true', pos)) {
        spans.add(TextSpan(text: 'true', style: TextStyle(color: boolNullColor, fontStyle: FontStyle.italic)));
        pos += 4;
        continue;
      }
      if (line.startsWith('false', pos)) {
        spans.add(TextSpan(text: 'false', style: TextStyle(color: boolNullColor, fontStyle: FontStyle.italic)));
        pos += 5;
        continue;
      }
      if (line.startsWith('null', pos)) {
        spans.add(TextSpan(text: 'null', style: TextStyle(color: boolNullColor, fontStyle: FontStyle.italic)));
        pos += 4;
        continue;
      }

      // Punctuation: { } [ ] : ,
      if ('{}[],:'.contains(ch)) {
        spans.add(TextSpan(text: ch, style: TextStyle(color: punctColor)));
        pos++;
        continue;
      }

      // Fallback
      spans.add(TextSpan(text: ch, style: TextStyle(color: plainColor)));
      pos++;
    }
    return spans;
  }
}

class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.theme, required this.response});

  final PostyTheme theme;
  final PostyResponse? response;

  @override
  Widget build(BuildContext context) {
    final r = response;
    if (r == null) {
      return Center(
        child: Text('No headers', style: TextStyle(color: theme.textSecondary)),
      );
    }
    final headers = r.headers;
    if (headers.isEmpty) {
      return Center(
        child: Text('No headers', style: TextStyle(color: theme.textSecondary)),
      );
    }
    return ListView(
      children: headers.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SelectableText(
            '${e.key}: ${e.value.join(', ')}',
            style: TextStyle(color: theme.textPrimary, fontSize: 12, fontFamily: 'monospace'),
          ),
        );
      }).toList(),
    );
  }
}

void copyToClipboard(BuildContext context, String text, {String message = 'Copied'}) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}
