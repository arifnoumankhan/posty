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

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: widget.controller.baseUrl);
    _pathController = TextEditingController(text: widget.controller.path);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_baseUrlController.text != widget.controller.baseUrl) {
      _baseUrlController.text = widget.controller.baseUrl;
    }
    if (_pathController.text != widget.controller.path) {
      _pathController.text = widget.controller.path;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _baseUrlController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final c = widget.controller;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: DropdownButtonFormField<HttpMethod>(
            initialValue: c.method,
            isExpanded: true,
            items: HttpMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) c.setMethod(v);
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: _baseUrlController,
            onChanged: c.setBaseUrl,
            style: TextStyle(color: theme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'https://api.example.com',
              labelText: 'Base URL',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: _pathController,
            onChanged: c.setPath,
            style: TextStyle(color: theme.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: '/v1/resource',
              labelText: 'Path',
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (c.isLoading)
          OutlinedButton(
            onPressed: widget.onCancel,
            child: Text('Cancel', style: TextStyle(color: theme.errorColor)),
          )
        else
          FilledButton(
            onPressed: widget.onSend,
            style: FilledButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('Send'),
          ),
      ],
    );
  }
}
