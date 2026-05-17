import 'package:flutter/material.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/state/posty_controller.dart';
import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/widgets/form_body_editor.dart';
import 'package:posty/src/widgets/key_value_editor.dart';
import 'package:posty/src/widgets/posty_scope.dart';
import 'package:posty/src/widgets/posty_url_preview.dart';

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
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => _TabBar(
            theme: theme,
            index: controller.requestTabIndex,
            tabs: [
              _TabSpec('Params', controller.enabledQueryCount),
              _TabSpec('Body', controller.bodyTabBadgeCount),
              _TabSpec('Auth', controller.authType == AuthType.none ? null : 1),
              _TabSpec('Headers', controller.enabledHeaderCount),
            ],
            onTap: controller.setRequestTab,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => IndexedStack(
              index: controller.requestTabIndex.clamp(0, 3),
              children: [
                _ParamsTab(controller: controller, theme: theme),
                _BodyTab(controller: controller, theme: theme),
                _AuthTab(controller: controller, theme: theme),
                _HeadersTab(controller: controller, theme: theme),
              ],
            ),
          ),
        ),
      ],
    );
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
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => PostyUrlPreview(
            key: ValueKey('params-${controller.previewUrl}'),
            url: controller.previewUrl,
            theme: theme,
            label: 'URL preview',
          ),
        ),
        const SizedBox(height: 12),
        KeyValueEditor(
          key: ValueKey('query-${controller.queryParams.length}'),
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
  late final FocusNode _jsonFocus;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(text: widget.controller.jsonBody);
    _jsonFocus = FocusNode();
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_jsonFocus.hasFocus) return;
    if (_jsonController.text != widget.controller.jsonBody) {
      _jsonController.text = widget.controller.jsonBody;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _jsonFocus.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        return ListView(
          children: [
            DropdownButtonFormField<BodyType>(
              key: ValueKey('body-type-${c.bodyType.name}'),
              initialValue: c.bodyType,
              decoration: InputDecoration(
                labelText: 'Body type',
                labelStyle: TextStyle(color: theme.textSecondary),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.borderColor),
                ),
              ),
              dropdownColor: theme.inputFill,
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              items: const [
                DropdownMenuItem(
                  value: BodyType.none,
                  child: Text('No body'),
                ),
                DropdownMenuItem(
                  value: BodyType.json,
                  child: Text('JSON'),
                ),
                DropdownMenuItem(
                  value: BodyType.form,
                  child: Text('Multipart form'),
                ),
              ],
              onChanged: (value) {
                if (value != null) c.setBodyType(value);
              },
            ),
            const SizedBox(height: 16),
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
                focusNode: _jsonFocus,
                onChanged: c.setJsonBody,
                maxLines: null,
                minLines: 12,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  hintText: '{\n  "key": "value"\n}',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ] else if (c.bodyType == BodyType.form)
              FormBodyEditor(
                key: ValueKey('form-${c.formBody.length}'),
                rows: c.formBody,
                theme: theme,
                onChanged: c.updateFormBody,
                onAdd: c.addFormBodyRow,
                onRemove: c.removeFormBodyRow,
                toolbar: TextButton(
                  onPressed: c.clearFormBody,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Delete all', style: TextStyle(fontSize: 12)),
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.http_outlined,
                        size: 48,
                        color: theme.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No body for this request',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select JSON or Multipart form in the dropdown above',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
  late final TextEditingController _bearer;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _apiHeader;
  late final TextEditingController _apiValue;
  late final FocusNode _bearerFocus;
  late final FocusNode _userFocus;
  late final FocusNode _passFocus;
  late final FocusNode _apiHeaderFocus;
  late final FocusNode _apiValueFocus;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _bearer = TextEditingController(text: c.bearerToken);
    _user = TextEditingController(text: c.basicUsername);
    _pass = TextEditingController(text: c.basicPassword);
    _apiHeader = TextEditingController(text: c.apiKeyHeader);
    _apiValue = TextEditingController(text: c.apiKeyValue);
    _bearerFocus = FocusNode();
    _userFocus = FocusNode();
    _passFocus = FocusNode();
    _apiHeaderFocus = FocusNode();
    _apiValueFocus = FocusNode();
    widget.controller.addListener(_syncFromController);
  }

  void _syncFromController() {
    final c = widget.controller;
    if (!_bearerFocus.hasFocus && _bearer.text != c.bearerToken) {
      _bearer.text = c.bearerToken;
    }
    if (!_userFocus.hasFocus && _user.text != c.basicUsername) {
      _user.text = c.basicUsername;
    }
    if (!_passFocus.hasFocus && _pass.text != c.basicPassword) {
      _pass.text = c.basicPassword;
    }
    if (!_apiHeaderFocus.hasFocus && _apiHeader.text != c.apiKeyHeader) {
      _apiHeader.text = c.apiKeyHeader;
    }
    if (!_apiValueFocus.hasFocus && _apiValue.text != c.apiKeyValue) {
      _apiValue.text = c.apiKeyValue;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _bearer.dispose();
    _user.dispose();
    _pass.dispose();
    _apiHeader.dispose();
    _apiValue.dispose();
    _bearerFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _apiHeaderFocus.dispose();
    _apiValueFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => ListView(
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
              focusNode: _bearerFocus,
              decoration: const InputDecoration(labelText: 'Bearer token'),
              obscureText: true,
              onChanged: (value) {
                c.setBearerToken(value);
                PostyScope.maybeOf(context)?.setEnvironmentAccessToken(value);
              },
            ),
          if (c.authType == AuthType.basic) ...[
            TextField(
              controller: _user,
              focusNode: _userFocus,
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: c.setBasicUsername,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pass,
              focusNode: _passFocus,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: c.setBasicPassword,
            ),
          ],
          if (c.authType == AuthType.apiKey) ...[
            TextField(
              controller: _apiHeader,
              focusNode: _apiHeaderFocus,
              decoration: const InputDecoration(labelText: 'Header name'),
              onChanged: c.setApiKeyHeader,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiValue,
              focusNode: _apiValueFocus,
              decoration: const InputDecoration(labelText: 'API key value'),
              obscureText: true,
              onChanged: c.setApiKeyValue,
            ),
          ],
        ],
      ),
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
      key: ValueKey('headers-${controller.headers.length}'),
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
