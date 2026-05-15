import 'package:flutter/material.dart';
import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/theme/posty_theme.dart';

typedef RowUpdater = void Function(int index, {String? key, String? value, bool? enabled});

class KeyValueEditor extends StatefulWidget {
  const KeyValueEditor({
    super.key,
    required this.rows,
    required this.theme,
    required this.onChanged,
    required this.onAdd,
    required this.onRemove,
    this.toolbar,
  });

  final List<KeyValueRow> rows;
  final PostyTheme theme;
  final RowUpdater onChanged;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final Widget? toolbar;

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  final List<TextEditingController> _keyControllers = [];
  final List<TextEditingController> _valueControllers = [];
  final List<FocusNode> _keyFocusNodes = [];
  final List<FocusNode> _valueFocusNodes = [];

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(KeyValueEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) {
      _syncControllers();
      return;
    }
    final anyFocused =
        _keyFocusNodes.any((n) => n.hasFocus) ||
        _valueFocusNodes.any((n) => n.hasFocus);
    if (anyFocused) return;
    for (var i = 0; i < widget.rows.length; i++) {
      if (_keyControllers[i].text != widget.rows[i].key) {
        _keyControllers[i].text = widget.rows[i].key;
      }
      if (_valueControllers[i].text != widget.rows[i].value) {
        _valueControllers[i].text = widget.rows[i].value;
      }
    }
  }

  void _syncControllers() {
    for (final c in _keyControllers) {
      c.dispose();
    }
    for (final c in _valueControllers) {
      c.dispose();
    }
    for (final n in _keyFocusNodes) {
      n.dispose();
    }
    for (final n in _valueFocusNodes) {
      n.dispose();
    }
    _keyControllers.clear();
    _valueControllers.clear();
    _keyFocusNodes.clear();
    _valueFocusNodes.clear();
    for (final row in widget.rows) {
      _keyControllers.add(TextEditingController(text: row.key));
      _valueControllers.add(TextEditingController(text: row.value));
      _keyFocusNodes.add(FocusNode());
      _valueFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final c in _keyControllers) {
      c.dispose();
    }
    for (final c in _valueControllers) {
      c.dispose();
    }
    for (final n in _keyFocusNodes) {
      n.dispose();
    }
    for (final n in _valueFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.toolbar != null) widget.toolbar!,
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Text(
                'Key',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Value',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 4),
        ...List.generate(widget.rows.length, (index) {
          final row = widget.rows[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Checkbox(
                  value: row.enabled,
                  onChanged: (v) => widget.onChanged(index, enabled: v ?? true),
                  activeColor: theme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Expanded(
                  child: TextField(
                    controller: _keyControllers[index],
                    focusNode: _keyFocusNodes[index],
                    onChanged: (v) => widget.onChanged(index, key: v),
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'key'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _valueControllers[index],
                    focusNode: _valueFocusNodes[index],
                    onChanged: (v) => widget.onChanged(index, value: v),
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(hintText: 'value'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.textSecondary, size: 20),
                  onPressed: () => widget.onRemove(index),
                  tooltip: 'Remove',
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onAdd,
            icon: Icon(Icons.add, size: 18, color: theme.primaryColor),
            label: Text('Add', style: TextStyle(color: theme.primaryColor)),
          ),
        ),
      ],
    );
  }
}
