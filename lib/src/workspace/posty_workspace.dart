import 'package:flutter/foundation.dart';
import 'package:posty/src/import/insomnia_yaml_importer.dart';
import 'package:posty/src/models/posty_collection_node.dart';
import 'package:posty/src/models/posty_enums.dart';
import 'package:posty/src/models/posty_environment.dart';
import 'package:posty/src/models/posty_history_entry.dart';
import 'package:posty/src/models/posty_request.dart';
import 'package:posty/src/persistence/posty_local_store.dart';
import 'package:posty/src/state/posty_controller.dart';

class PostyWorkspace extends ChangeNotifier {
  PostyWorkspace({
    required this.controller,
    required String persistenceId,
    PostyLocalStore? store,
    PostyEnvironment? initialEnvironment,
  })  : _store = store ?? PostyLocalStore(namespace: persistenceId),
        _initialEnvironment = initialEnvironment ?? const PostyEnvironment(),
        environment = initialEnvironment ?? const PostyEnvironment();

  final PostyEnvironment _initialEnvironment;

  final PostyController controller;
  final PostyLocalStore _store;

  PostyEnvironment environment;
  List<PostyHistoryEntry> history = [];
  List<PostyCollectionNode> collections = [];
  String? selectedNodeId;
  bool showHistoryTab = false;
  bool allFoldersExpanded = true;
  bool _loaded = false;
  bool _wasLoading = false;

  bool get isLoaded => _loaded;

  void setShowHistoryTab(bool value) {
    showHistoryTab = value;
    notifyListeners();
  }

  Future<void> load() async {
    history = await _store.loadHistory();
    collections = await _store.loadCollections();
    final savedEnv = await _store.loadEnvironment();
    if (savedEnv != null) {
      environment = savedEnv;
    } else {
      environment = _initialEnvironment;
      await _persistEnvironment();
    }
    _applyEnvironmentToController();
    _loaded = true;
    notifyListeners();
  }

  void initEnvironment({
    required String baseUrl,
    String? accessToken,
  }) {
    environment = PostyEnvironment(
      baseUrl: baseUrl,
      accessToken: accessToken ?? environment.accessToken,
    );
    _applyEnvironmentToController();
    _persistEnvironment();
  }

  Future<void> setEnvironmentBaseUrl(String baseUrl) async {
    environment = environment.copyWith(baseUrl: baseUrl.trim());
    collections = _mapAllRequests(
      collections,
      (req) => req.copyWith(
        baseUrl: environment.baseUrl.isNotEmpty
            ? environment.baseUrl
            : req.baseUrl,
      ),
    );
    _applyEnvironmentToController();
    await _persistEnvironment();
    await _persistCollections();
    notifyListeners();
  }

  Future<void> setEnvironmentAccessToken(String token) async {
    environment = environment.copyWith(accessToken: token);
    collections = _mapAllRequests(
      collections,
      (req) => _applyEnvToRequest(req),
    );
    _applyEnvironmentToController();
    await _persistEnvironment();
    await _persistCollections();
    notifyListeners();
  }

  void _applyEnvironmentToController() {
    if (environment.baseUrl.isNotEmpty) {
      controller.baseUrl = environment.baseUrl;
    }
    if (environment.accessToken.isNotEmpty) {
      controller.authType = AuthType.bearer;
      controller.bearerToken = environment.accessToken;
    }
  }

  PostyRequest _applyEnvToRequest(PostyRequest req) {
    var updated = req;
    if (environment.baseUrl.isNotEmpty) {
      updated = updated.copyWith(baseUrl: environment.baseUrl);
    }
    if (environment.accessToken.isNotEmpty) {
      updated = updated.copyWith(
        authType: AuthType.bearer,
        bearerToken: environment.accessToken,
      );
    }
    return updated;
  }

  Future<void> _persistEnvironment() async {
    await _store.saveEnvironment(environment);
  }

  void attachControllerListener() {
    controller.addListener(_onControllerChanged);
  }

  void detachControllerListener() {
    controller.removeListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_wasLoading &&
        !controller.isLoading &&
        controller.lastResponse != null) {
      _pushHistory();
    }
    _wasLoading = controller.isLoading;
  }

  Future<void> _pushHistory() async {
    final entry = PostyHistoryEntry(
      id: PostyCollectionIds.newId(),
      sentAt: controller.lastSentAt ?? DateTime.now(),
      request: controller.toRequest(),
      response: controller.snapshotResponse(),
    );
    history = [entry, ...history].take(PostyLocalStore.maxHistoryEntries).toList();
    await _store.saveHistory(history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = [];
    await _store.saveHistory(history);
    notifyListeners();
  }

  Future<void> importInsomniaYaml(String yaml) async {
    final result = InsomniaYamlImporter.parse(
      yaml,
      hostBaseUrl: environment.baseUrl,
      hostAccessToken: environment.accessToken,
    );
    final roots = result.roots
        .map((n) => _applyEnvToNode(n))
        .toList();
    final folder = PostyCollectionNode(
      id: PostyCollectionIds.newId(),
      name: result.workspaceName,
      kind: PostyCollectionNodeKind.folder,
      children: roots,
      expanded: allFoldersExpanded,
    );
    collections = [...collections, folder];
    await _store.saveCollections(collections);
    notifyListeners();
  }

  PostyCollectionNode _applyEnvToNode(PostyCollectionNode node) {
    if (node.isRequest && node.request != null) {
      return node.copyWith(request: _applyEnvToRequest(node.request!));
    }
    return node.copyWith(
      children: node.children.map(_applyEnvToNode).toList(),
      expanded: allFoldersExpanded,
    );
  }

  Future<void> _persistCollections() async {
    await _store.saveCollections(collections);
  }

  void selectHistory(int index) {
    if (index < 0 || index >= history.length) return;
    selectedNodeId = null;
    controller.loadHistoryEntry(history[index]);
    notifyListeners();
  }

  void selectCollectionNode(String id) {
    final node = findNode(id);
    if (node == null || !node.isRequest || node.request == null) return;
    selectedNodeId = id;
    controller.loadRequest(_applyEnvToRequest(node.request!));
    final q = node.request!.path.indexOf('?');
    if (q != -1) {
      controller.importQueryFromUrl();
    }
    notifyListeners();
  }

  Future<void> duplicateCollectionNode(String id) async {
    collections = _duplicateInTree(collections, id);
    await _persistCollections();
    notifyListeners();
  }

  Future<void> renameCollectionNode(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    collections = _mapNodes(
      collections,
      id,
      (n) => n.copyWith(name: trimmed),
    );
    await _persistCollections();
    notifyListeners();
  }

  Future<void> deleteCollectionNode(String id) async {
    collections = _removeFromTree(collections, id);
    if (selectedNodeId == id) {
      selectedNodeId = null;
      controller.newRequest(keepHeaders: true);
      _applyEnvironmentToController();
    }
    await _persistCollections();
    notifyListeners();
  }

  /// Folder id containing [id], or `null` if [id] is at the collections root.
  String? findParentFolderId(String targetId) {
    String? parent;
    void walk(List<PostyCollectionNode> nodes, String? parentFolderId) {
      for (final n in nodes) {
        if (parent != null) return;
        if (n.id == targetId) {
          parent = parentFolderId;
          return;
        }
        if (n.isFolder) {
          walk(n.children, n.id);
        }
      }
    }

    walk(collections, null);
    return parent;
  }

  Future<void> addNewRequestInContext(String nodeId) async {
    final node = findNode(nodeId);
    if (node == null) return;
    if (node.isFolder) {
      await addNewRequest(parentFolderId: nodeId);
    } else {
      await addNewRequest(parentFolderId: findParentFolderId(nodeId));
    }
  }

  List<PostyCollectionNode> _removeFromTree(
    List<PostyCollectionNode> nodes,
    String id,
  ) {
    final result = <PostyCollectionNode>[];
    for (final n in nodes) {
      if (n.id == id) continue;
      if (n.isFolder) {
        result.add(n.copyWith(children: _removeFromTree(n.children, id)));
      } else {
        result.add(n);
      }
    }
    return result;
  }

  List<PostyCollectionNode> _duplicateInTree(
    List<PostyCollectionNode> nodes,
    String id,
  ) {
    final out = <PostyCollectionNode>[];
    for (final n in nodes) {
      if (n.id == id) {
        out.add(n);
        out.add(_applyEnvToNode(n.duplicateSubtree()));
        continue;
      }
      if (n.isFolder) {
        out.add(n.copyWith(children: _duplicateInTree(n.children, id)));
      } else {
        out.add(n);
      }
    }
    return out;
  }

  Future<void> addNewRequest({String? parentFolderId}) async {
    final blank = PostyCollectionNode(
      id: PostyCollectionIds.newId(),
      name: 'New request',
      kind: PostyCollectionNodeKind.request,
      request: _applyEnvToRequest(
        PostyRequest(
          baseUrl: environment.baseUrl,
          headers: List.from(controller.headers),
        ),
      ),
    );

    if (parentFolderId == null) {
      collections = [...collections, blank];
    } else {
      collections = _insertInFolder(collections, parentFolderId, blank);
    }
    await _persistCollections();
    selectedNodeId = blank.id;
    controller.newRequest(keepHeaders: true);
    _applyEnvironmentToController();
    notifyListeners();
  }

  List<PostyCollectionNode> _insertInFolder(
    List<PostyCollectionNode> nodes,
    String folderId,
    PostyCollectionNode child,
  ) {
    return nodes.map((n) {
      if (n.id == folderId && n.isFolder) {
        return n.copyWith(children: [...n.children, child]);
      }
      if (n.isFolder) {
        return n.copyWith(children: _insertInFolder(n.children, folderId, child));
      }
      return n;
    }).toList();
  }

  Future<void> toggleFolderExpanded(String id) async {
    collections = _mapNodes(collections, id, (n) {
      if (n.isFolder) return n.copyWith(expanded: !n.expanded);
      return n;
    });
    await _persistCollections();
    notifyListeners();
  }

  Future<void> toggleExpandCollapseAll() async {
    allFoldersExpanded = !allFoldersExpanded;
    collections = _setAllFoldersExpanded(collections, allFoldersExpanded);
    await _persistCollections();
    notifyListeners();
  }

  List<PostyCollectionNode> _setAllFoldersExpanded(
    List<PostyCollectionNode> nodes,
    bool expanded,
  ) {
    return nodes.map((n) {
      if (n.isFolder) {
        return n.copyWith(
          expanded: expanded,
          children: _setAllFoldersExpanded(n.children, expanded),
        );
      }
      return n;
    }).toList();
  }

  PostyCollectionNode? findNode(String id, [List<PostyCollectionNode>? nodes]) {
    for (final n in nodes ?? collections) {
      if (n.id == id) return n;
      if (n.isFolder) {
        final found = findNode(id, n.children);
        if (found != null) return found;
      }
    }
    return null;
  }

  List<PostyCollectionNode> _mapNodes(
    List<PostyCollectionNode> nodes,
    String id,
    PostyCollectionNode Function(PostyCollectionNode) update,
  ) {
    return nodes.map((n) {
      if (n.id == id) return update(n);
      if (n.isFolder) {
        return n.copyWith(children: _mapNodes(n.children, id, update));
      }
      return n;
    }).toList();
  }

  List<PostyCollectionNode> _mapAllRequests(
    List<PostyCollectionNode> nodes,
    PostyRequest Function(PostyRequest) update,
  ) {
    return nodes.map((n) {
      if (n.isRequest && n.request != null) {
        return n.copyWith(request: update(n.request!));
      }
      if (n.isFolder) {
        return n.copyWith(children: _mapAllRequests(n.children, update));
      }
      return n;
    }).toList();
  }
}
