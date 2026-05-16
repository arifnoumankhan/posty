import 'package:flutter/material.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/state/posty_controller.dart';
import 'package:posty/src/theme/posty_theme.dart';
class RequestBar extends StatefulWidget {
  const RequestBar({
    super.key,
    required this.controller,
    required this.theme,
    required this.onSend,
    required this.onCancel,
  });

  final PostyController controller;
  final PostyTheme theme;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  @override
  State<RequestBar> createState() => _RequestBarState();
}

class _RequestBarState extends State<RequestBar> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _pathController;
  late final FocusNode _baseUrlFocus;
  late final FocusNode _pathFocus;
  bool _wasEditingUrl = false;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.controller.baseUrl);
    _pathController = TextEditingController(text: widget.controller.path);
    _baseUrlFocus = FocusNode();
    _pathFocus = FocusNode();
    _baseUrlFocus.addListener(_onUrlFocusChanged);
    _pathFocus.addListener(_onUrlFocusChanged);
    _baseUrlController.addListener(_syncUrlPreviewFromFields);
    _pathController.addListener(_syncUrlPreviewFromFields);
    FocusManager.instance.addListener(_onGlobalFocusChanged);
    widget.controller.urlCommitHandler = _commitUrlFromFields;
    widget.controller.addListener(_onControllerChanged);
  }

  /// Keeps [PostyController.previewUrl] in sync while typing (live preview).
  void _syncUrlPreviewFromFields() {
    widget.controller.setBaseUrl(_baseUrlController.text);
    widget.controller.setPath(_pathController.text);
  }

  void _commitUrlFromFields() {
    _syncUrlPreviewFromFields();
    widget.controller.commitRequestUrl();
  }

  void _onUrlFocusChanged() => _onGlobalFocusChanged();

  void _onGlobalFocusChanged() {
    if (!mounted) return;
    final editing = _baseUrlFocus.hasFocus || _pathFocus.hasFocus;
    if (_wasEditingUrl && !editing) {
      _commitUrlFromFields();
    }
    _wasEditingUrl = editing;
  }

  void _onControllerChanged() {
    if (!_baseUrlFocus.hasFocus &&
        _baseUrlController.text != widget.controller.baseUrl) {
      _baseUrlController.text = widget.controller.baseUrl;
    }
    if (!_pathFocus.hasFocus &&
        _pathController.text != widget.controller.path) {
      _pathController.text = widget.controller.path;
    }
  }

  @override
  void dispose() {
    if (widget.controller.urlCommitHandler == _commitUrlFromFields) {
      widget.controller.urlCommitHandler = null;
    }
    FocusManager.instance.removeListener(_onGlobalFocusChanged);
    widget.controller.removeListener(_onControllerChanged);
    _baseUrlFocus.removeListener(_onUrlFocusChanged);
    _pathFocus.removeListener(_onUrlFocusChanged);
    _baseUrlController.removeListener(_syncUrlPreviewFromFields);
    _pathController.removeListener(_syncUrlPreviewFromFields);
    _baseUrlFocus.dispose();
    _pathFocus.dispose();
    _baseUrlController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  void _handleSend() {
    _commitUrlFromFields();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _baseUrlController,
          focusNode: _baseUrlFocus,
          onTapOutside: (_) => _commitUrlFromFields(),
          onEditingComplete: () {
            _commitUrlFromFields();
            _pathFocus.requestFocus();
          },
          style: TextStyle(color: theme.textPrimary, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'https://api.example.com',
            labelText: 'Base URL',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: ListenableBuilder(
                listenable: c,
                builder: (context, _) => DropdownButtonFormField<HttpMethod>(
                  key: ValueKey(c.method),
                  initialValue: c.method,
                  isExpanded: true,
                  items: HttpMethod.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) c.setMethod(v);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _pathController,
                focusNode: _pathFocus,
                onTapOutside: (_) => _commitUrlFromFields(),
                onEditingComplete: _commitUrlFromFields,
                style: TextStyle(color: theme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '/connector/api/resource',
                  labelText: 'Endpoint',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ListenableBuilder(
              listenable: c,
              builder: (context, _) {
                if (c.isLoading) {
                  return OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.errorColor),
                    ),
                  );
                }
                return FilledButton(
                  onPressed: _handleSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Send'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
