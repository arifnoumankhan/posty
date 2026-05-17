import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:posty/src/models/posty_collection_node.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/workspace/posty_workspace.dart';

class PostySidebar extends StatefulWidget {
  const PostySidebar({
    super.key,
    required this.workspace,
    required this.theme,
  });

  final PostyWorkspace workspace;
  final PostyTheme theme;

  @override
  State<PostySidebar> createState() => _PostySidebarState();
}

class _PostySidebarState extends State<PostySidebar> {
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _tokenCtrl;

  PostyWorkspace get workspace => widget.workspace;
  PostyTheme get theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _baseUrlCtrl = TextEditingController(text: workspace.environment.baseUrl);
    _tokenCtrl = TextEditingController(text: workspace.environment.accessToken);
    workspace.addListener(_syncEnvFields);
  }

  @override
  void dispose() {
    workspace.removeListener(_syncEnvFields);
    _baseUrlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _syncEnvFields() {
    if (_baseUrlCtrl.text != workspace.environment.baseUrl) {
      _baseUrlCtrl.text = workspace.environment.baseUrl;
    }
    if (_tokenCtrl.text != workspace.environment.accessToken) {
      _tokenCtrl.text = workspace.environment.accessToken;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.panelBackground,
        border: Border(right: BorderSide(color: theme.borderColor)),
      ),
      child: ListenableBuilder(
        listenable: workspace,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              if (!workspace.showHistoryTab) _buildEnvironmentFields(),
              Expanded(
                child: workspace.showHistoryTab
                    ? _buildHistoryList()
                    : _buildCollectionsTree(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Collections')),
              ButtonSegment(value: true, label: Text('History')),
            ],
            selected: {workspace.showHistoryTab},
            onSelectionChanged: (s) => workspace.setShowHistoryTab(s.first),
          ),
          const SizedBox(height: 8),
          if (!workspace.showHistoryTab)
            Row(
              children: [
                IconButton(
                  tooltip: workspace.allFoldersExpanded
                      ? 'Collapse all folders'
                      : 'Expand all folders',
                  onPressed: () => workspace.toggleExpandCollapseAll(),
                  icon: Icon(
                    workspace.allFoldersExpanded
                        ? Icons.unfold_less
                        : Icons.unfold_more,
                  ),
                  color: theme.textPrimary,
                ),
                IconButton(
                  tooltip: 'New request',
                  onPressed: () => workspace.addNewRequest(),
                  icon: const Icon(Icons.add),
                  color: theme.textPrimary,
                ),
                IconButton(
                  tooltip: 'Import Insomnia YAML',
                  onPressed: () => _importInsomnia(context),
                  icon: const Icon(Icons.upload_file),
                  color: theme.textPrimary,
                ),
              ],
            ),
          if (workspace.showHistoryTab)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: workspace.history.isEmpty
                    ? null
                    : () => workspace.clearHistory(),
                child: Text(
                  'Clear',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Environment',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          _envField(
            label: 'base_url',
            controller: _baseUrlCtrl,
            onSubmitted: workspace.setEnvironmentBaseUrl,
          ),
          const SizedBox(height: 4),
          _envField(
            label: 'access_token',
            controller: _tokenCtrl,
            obscure: true,
            onSubmitted: workspace.setEnvironmentAccessToken,
          ),
        ],
      ),
    );
  }

  Widget _envField({
    required String label,
    required TextEditingController controller,
    required Future<void> Function(String) onSubmitted,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: theme.textPrimary, fontSize: 12),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: theme.textSecondary, fontSize: 11),
        filled: true,
        fillColor: theme.inputFill,
        border: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.borderColor)),
      ),
      onSubmitted: onSubmitted,
      onEditingComplete: () => onSubmitted(controller.text),
    );
  }

  Future<void> _importInsomnia(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['yaml', 'yml'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      final yaml =
          file.bytes != null ? utf8.decode(file.bytes!) : null;
      if (yaml == null || yaml.isEmpty) return;
      await workspace.importInsomniaYaml(yaml);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insomnia collection imported')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Widget _buildHistoryList() {
    if (workspace.history.isEmpty) {
      return Center(
        child: Text(
          'No history yet.\nSend a request to save it here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.textSecondary, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      itemCount: workspace.history.length,
      itemBuilder: (context, index) {
        final entry = workspace.history[index];
        final time = _formatTime(entry.sentAt);
        final status = entry.response?.statusCode;
        return ListTile(
          dense: true,
          title: Text(
            entry.label,
            style: TextStyle(color: theme.textPrimary, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$time${status != null ? ' · $status' : ''}',
            style: TextStyle(color: theme.textSecondary, fontSize: 11),
          ),
          onTap: () => workspace.selectHistory(index),
        );
      },
    );
  }

  Widget _buildCollectionsTree() {
    if (workspace.collections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Import an Insomnia export (.yaml) or add a new request.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }
    return ListView(
      children: [
        for (final node in workspace.collections) _buildNode(node, 0),
      ],
    );
  }

  Widget _buildNode(PostyCollectionNode node, int depth) {
    if (node.isFolder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => workspace.toggleFolderExpanded(node.id),
              onSecondaryTapUp: (d) =>
                  _showCollectionContextMenu(context, node, d.globalPosition),
              child: Padding(
                padding:
                    EdgeInsets.only(left: 8.0 + depth * 12, top: 6, bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      node.expanded ? Icons.folder_open : Icons.folder,
                      size: 18,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        node.name,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (node.expanded)
            for (final child in node.children) _buildNode(child, depth + 1),
        ],
      );
    }

    final request = node.request!;
    final selected = workspace.selectedNodeId == node.id;
    return Material(
      color: selected ? theme.inputFill : Colors.transparent,
      child: InkWell(
        onTap: () => workspace.selectCollectionNode(node.id),
        onSecondaryTapUp: (d) =>
            _showCollectionContextMenu(context, node, d.globalPosition),
        child: Padding(
          padding: EdgeInsets.only(
            left: 12.0 + depth * 12,
            top: 4,
            bottom: 4,
            right: 4,
          ),
          child: Row(
            children: [
              _MethodBadge(method: request.method, theme: theme),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(color: theme.textPrimary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCollectionContextMenu(
    BuildContext context,
    PostyCollectionNode node,
    Offset globalPosition,
  ) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      items: const [
        PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'add', child: Text('Add request')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'duplicate':
        await workspace.duplicateCollectionNode(node.id);
      case 'rename':
        await _promptRename(context, node);
      case 'add':
        await workspace.addNewRequestInContext(node.id);
      case 'delete':
        await _confirmDelete(context, node);
    }
  }

  Future<void> _promptRename(BuildContext context, PostyCollectionNode node) async {
    final controller = TextEditingController(text: node.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await workspace.renameCollectionNode(node.id, name);
    }
  }

  Future<void> _confirmDelete(BuildContext context, PostyCollectionNode node) async {
    final message = node.isFolder
        ? 'Delete folder "${node.name}" and everything inside it?'
        : 'Delete request "${node.name}"?';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await workspace.deleteCollectionNode(node.id);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method, required this.theme});

  final HttpMethod method;
  final PostyTheme theme;

  @override
  Widget build(BuildContext context) {
    final color = switch (method) {
      HttpMethod.get => const Color(0xFF9B6BFF),
      HttpMethod.post => const Color(0xFF4CAF50),
      HttpMethod.put => const Color(0xFFFF9800),
      HttpMethod.patch => const Color(0xFF26A69A),
      HttpMethod.delete => const Color(0xFFE53935),
      HttpMethod.head => theme.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
