import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:posty/src/models/key_value_row.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/theme/posty_theme.dart';

typedef FormRowUpdater = void Function(
  int index, {
  String? key,
  String? value,
  bool? enabled,
  FormValueType? formValueType,
  String? filePath,
  String? fileName,
  List<int>? fileBytes,
  bool clearFile,
});

class FormBodyEditor extends StatefulWidget {
  const FormBodyEditor({
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
  final FormRowUpdater onChanged;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final Widget? toolbar;

  @override
  State<FormBodyEditor> createState() => _FormBodyEditorState();
}

class _FormBodyEditorState extends State<FormBodyEditor> {
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
  void didUpdateWidget(FormBodyEditor oldWidget) {
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
      final row = widget.rows[i];
      if (_keyControllers[i].text != row.key) {
        _keyControllers[i].text = row.key;
      }
      if (row.formValueType == FormValueType.text &&
          _valueControllers[i].text != row.value) {
        _valueControllers[i].text = row.value;
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

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final path = file.path;
    if ((path == null || path.isEmpty) &&
        (file.bytes == null || file.bytes!.isEmpty)) {
      return;
    }
    widget.onChanged(
      index,
      formValueType: FormValueType.file,
      filePath: path,
      fileName: file.name,
      fileBytes: file.bytes,
      value: '',
    );
    setState(() {});
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
            const SizedBox(width: 88),
            Expanded(
              flex: 2,
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
              flex: 3,
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
        ...List.generate(widget.rows.length, (index) => _buildRow(index, theme)),
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

  Widget _buildRow(int index, PostyTheme theme) {
    final row = widget.rows[index];
    final isFile = row.formValueType == FormValueType.file;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: row.enabled,
            onChanged: (v) => widget.onChanged(index, enabled: v ?? true),
            activeColor: theme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(
            width: 88,
            child: DropdownButtonFormField<FormValueType>(
              key: ValueKey('form-type-$index-${row.formValueType.name}'),
              initialValue: row.formValueType,
              isExpanded: true,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(
                  value: FormValueType.text,
                  child: Text('Text', style: TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: FormValueType.file,
                  child: Text('File', style: TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: (type) {
                if (type == null) return;
                if (type == FormValueType.text) {
                  widget.onChanged(
                    index,
                    formValueType: FormValueType.text,
                    clearFile: true,
                  );
                } else {
                  widget.onChanged(index, formValueType: FormValueType.file);
                }
                setState(() {});
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _keyControllers[index],
              focusNode: _keyFocusNodes[index],
              onChanged: (v) => widget.onChanged(index, key: v),
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'name',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: isFile
                ? OutlinedButton.icon(
                    onPressed: () => _pickFile(index),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      row.fileName?.isNotEmpty == true
                          ? row.fileName!
                          : 'Choose file',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  )
                : TextField(
                    controller: _valueControllers[index],
                    focusNode: _valueFocusNodes[index],
                    onChanged: (v) => widget.onChanged(index, value: v),
                    style: TextStyle(color: theme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'value',
                      isDense: true,
                    ),
                  ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: theme.textSecondary,
              size: 20,
            ),
            onPressed: () => widget.onRemove(index),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}
