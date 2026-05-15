import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/state/posty_controller.dart';
import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/widgets/key_value_editor.dart';

class RequestTabs extends StatelessWidget {
  const RequestTabs({
    super.key,
    required this.controller,
    required this.theme,
  });

  final PostyController controller;
  final PostyTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabBar(
          theme: theme,
          index: controller.requestTabIndex,
          tabs: [
            _TabSpec('Params', controller.enabledQueryCount),
            const _TabSpec('Body', null),
            _TabSpec('Auth', controller.authType == AuthType.none ? null : 1),
            _TabSpec('Headers', controller.enabledHeaderCount),
          ],
          onTap: controller.setRequestTab,
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildTabContent(context)),
      ],
    );
  }

  Widget _buildTabContent(BuildContext context) {
    switch (controller.requestTabIndex) {
      case 0:
        return _ParamsTab(controller: controller, theme: theme);
      case 1:
        return _BodyTab(controller: controller, theme: theme);
      case 2:
        return _AuthTab(controller: controller, theme: theme);
      case 3:
        return _HeadersTab(controller: controller, theme: theme);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.theme,
    required this.index,
    required this.tabs,
    required this.onTap,
  });

  final PostyTheme theme;
  final int index;
  final List<_TabSpec> tabs;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = index == i;
          final label = tab.count != null ? '${tab.label} (${tab.count})' : tab.label;
          return InkWell(
            onTap: () => onTap(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        }),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.count);
  final String label;
  final int? count;
}

class _ParamsTab extends StatelessWidget {
  const _ParamsTab({required this.controller, required this.theme});

  final PostyController controller;
  final PostyTheme theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('URL PREVIEW', style: TextStyle(color: theme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.inputFill,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  controller.previewUrl,
                  style: TextStyle(color: theme.textPrimary, fontSize: 12),
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 18, color: theme.textSecondary),
                onPressed: () => _copy(context, controller.previewUrl),
                tooltip: 'Copy URL',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KeyValueEditor(
          rows: controller.queryParams,
          theme: theme,
          onChanged: controller.updateQueryParam,
          onAdd: controller.addQueryParam,
          onRemove: controller.removeQueryParam,
          toolbar: Wrap(
            spacing: 8,
            children: [
              _toolbarButton('Import from URL', controller.importQueryFromUrl),
              _toolbarButton('Delete all', controller.clearQueryParams),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolbarButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: theme.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied'), duration: Duration(seconds: 2)),
    );
  }
}

class _BodyTab extends StatefulWidget {
  const _BodyTab({required this.controller, required this.theme});

  final PostyController controller;
  final PostyTheme theme;

  @override
  State<_BodyTab> createState() => _BodyTabState();
}

class _BodyTabState extends State<_BodyTab> {
  late final TextEditingController _jsonController;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: widget.controller.jsonBody);
  }

  @override
  void didUpdateWidget(_BodyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_jsonController.text != widget.controller.jsonBody &&
        !(_jsonController.selection.isValid && _jsonController.selection.isCollapsed == false)) {
      _jsonController.text = widget.controller.jsonBody;
    }
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final c = widget.controller;
    return ListView(
      children: [
        SegmentedButton<BodyType>(
          segments: const [
            ButtonSegment(value: BodyType.none, label: Text('None')),
            ButtonSegment(value: BodyType.json, label: Text('JSON')),
            ButtonSegment(value: BodyType.form, label: Text('Form')),
          ],
          selected: {c.bodyType},
          onSelectionChanged: (s) => c.setBodyType(s.first),
        ),
        const SizedBox(height: 12),
        if (c.bodyType == BodyType.json) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                c.formatJsonBody();
                _jsonController.text = c.jsonBody;
              },
              child: const Text('Format JSON'),
            ),
          ),
          TextField(
            controller: _jsonController,
            onChanged: c.setJsonBody,
            maxLines: 12,
            style: TextStyle(
              color: theme.textPrimary,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            decoration: const InputDecoration(
              hintText: '{\n  "key": "value"\n}',
              alignLabelWithHint: true,
            ),
          ),
        ] else if (c.bodyType == BodyType.form)
          KeyValueEditor(
            rows: c.formBody,
            theme: theme,
            onChanged: c.updateFormBody,
            onAdd: c.addFormBodyRow,
            onRemove: c.removeFormBodyRow,
          )
        else
          Text(
            'No body for this request.',
            style: TextStyle(color: theme.textSecondary),
          ),
      ],
    );
  }
}

class _AuthTab extends StatefulWidget {
  const _AuthTab({required this.controller, required this.theme});

  final PostyController controller;
  final PostyTheme theme;

  @override
  State<_AuthTab> createState() => _AuthTabState();
}

class _AuthTabState extends State<_AuthTab> {
  late TextEditingController _bearer;
  late TextEditingController _user;
  late TextEditingController _pass;
  late TextEditingController _apiHeader;
  late TextEditingController _apiValue;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _bearer = TextEditingController(text: c.bearerToken);
    _user = TextEditingController(text: c.basicUsername);
    _pass = TextEditingController(text: c.basicPassword);
    _apiHeader = TextEditingController(text: c.apiKeyHeader);
    _apiValue = TextEditingController(text: c.apiKeyValue);
  }

  @override
  void dispose() {
    _bearer.dispose();
    _user.dispose();
    _pass.dispose();
    _apiHeader.dispose();
    _apiValue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListView(
      children: [
        DropdownButtonFormField<AuthType>(
          initialValue: c.authType,
          decoration: const InputDecoration(labelText: 'Auth type'),
          items: AuthType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
              .toList(),
          onChanged: (v) {
            if (v != null) c.setAuthType(v);
          },
        ),
        const SizedBox(height: 12),
        if (c.authType == AuthType.bearer)
          TextField(
            controller: _bearer,
            decoration: const InputDecoration(labelText: 'Bearer token'),
            obscureText: true,
            onChanged: c.setBearerToken,
          ),
        if (c.authType == AuthType.basic) ...[
          TextField(
            controller: _user,
            decoration: const InputDecoration(labelText: 'Username'),
            onChanged: c.setBasicUsername,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pass,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            onChanged: c.setBasicPassword,
          ),
        ],
        if (c.authType == AuthType.apiKey) ...[
          TextField(
            controller: _apiHeader,
            decoration: const InputDecoration(labelText: 'Header name'),
            onChanged: c.setApiKeyHeader,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _apiValue,
            decoration: const InputDecoration(labelText: 'API key value'),
            obscureText: true,
            onChanged: c.setApiKeyValue,
          ),
        ],
      ],
    );
  }
}

class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.controller, required this.theme});

  final PostyController controller;
  final PostyTheme theme;

  @override
  Widget build(BuildContext context) {
    return KeyValueEditor(
      rows: controller.headers,
      theme: theme,
      onChanged: controller.updateHeader,
      onAdd: controller.addHeader,
      onRemove: controller.removeHeader,
      toolbar: TextButton(
        onPressed: controller.addPresetHeaderAcceptJson,
        child: Text(
          '+ Accept: application/json',
          style: TextStyle(color: theme.primaryColor, fontSize: 12),
        ),
      ),
    );
  }
}
