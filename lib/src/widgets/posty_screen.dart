import 'package:flutter/material.dart';
import 'package:posty/src/state/posty_controller.dart';
import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/widgets/request_bar.dart';
import 'package:posty/src/widgets/request_tabs.dart';
import 'package:posty/src/widgets/response_panel.dart';

class PostyScreen extends StatefulWidget {
  const PostyScreen({
    super.key,
    this.initialBaseUrl = '',
    this.initialHeaders,
    this.controller,
    this.onRequestSent,
    this.showHistoryDrawer = false,
    this.historyRequests,
    this.onHistorySelected,
  });

  final String initialBaseUrl;
  final Map<String, String>? initialHeaders;
  final PostyController? controller;
  final void Function(PostyController controller)? onRequestSent;
  final bool showHistoryDrawer;
  final List<String>? historyRequests;
  final void Function(int index)? onHistorySelected;

  @override
  State<PostyScreen> createState() => _PostyScreenState();
}

class _PostyScreenState extends State<PostyScreen> {
  late final PostyController _controller;
  late PostyTheme _theme;
  bool _useDark = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        PostyController(
          initialBaseUrl: widget.initialBaseUrl,
          initialHeaders: widget.initialHeaders,
        );
    _theme = PostyTheme.dark();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (!_controller.isLoading &&
        _controller.lastResponse != null &&
        widget.onRequestSent != null) {
      widget.onRequestSent!(_controller);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _useDark = !_useDark;
      _theme = _useDark ? PostyTheme.dark() : PostyTheme.light();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme.toThemeData(),
      child: Scaffold(
        backgroundColor: _theme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: _theme.panelBackground,
          foregroundColor: _theme.textPrimary,
          elevation: 0,
          title: const Text('Posty'),
          actions: [
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.baseUrl.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text(
                      Uri.tryParse(_controller.baseUrl)?.host ?? 'API',
                      style: TextStyle(color: _theme.textSecondary, fontSize: 12),
                    ),
                    backgroundColor: _theme.inputFill,
                    side: BorderSide(color: _theme.borderColor),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(_useDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              tooltip: 'Toggle theme',
            ),
            if (widget.showHistoryDrawer)
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                  tooltip: 'History',
                ),
              ),
          ],
        ),
        endDrawer: widget.showHistoryDrawer ? _buildHistoryDrawer() : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Row(
                children: [
                  Expanded(child: _buildRequestPanel()),
                  VerticalDivider(width: 1, color: _theme.borderColor),
                  Expanded(child: _buildResponsePanel()),
                ],
              );
            }
            return Column(
              children: [
                SizedBox(height: constraints.maxHeight * 0.48, child: _buildRequestPanel()),
                Divider(height: 1, color: _theme.borderColor),
                Expanded(child: _buildResponsePanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRequestPanel() {
    return Container(
      color: _theme.panelBackground,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RequestBar(
            controller: _controller,
            theme: _theme,
            onSend: _controller.send,
            onCancel: _controller.cancel,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RequestTabs(controller: _controller, theme: _theme),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsePanel() {
    return Container(
      color: _theme.panelBackground,
      padding: const EdgeInsets.all(12),
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ResponsePanel(
          controller: _controller,
          theme: _theme,
          onCopyBody: () {
            final body = _controller.formattedResponseBody;
            if (body.isNotEmpty) {
              copyToClipboard(context, body, message: 'Response copied');
            }
          },
        ),
      ),
    );
  }

  Widget? _buildHistoryDrawer() {
    final items = widget.historyRequests;
    if (items == null || items.isEmpty) return null;
    return Drawer(
      backgroundColor: _theme.panelBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'History',
                style: TextStyle(
                  color: _theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      items[index],
                      style: TextStyle(color: _theme.textPrimary, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.onHistorySelected?.call(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
