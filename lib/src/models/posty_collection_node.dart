import 'package:posty/src/models/posty_request.dart';

enum PostyCollectionNodeKind { folder, request }

class PostyCollectionNode {
  const PostyCollectionNode({
    required this.id,
    required this.name,
    required this.kind,
    this.request,
    this.children = const [],
    this.expanded = true,
  });

  final String id;
  final String name;
  final PostyCollectionNodeKind kind;
  final PostyRequest? request;
  final List<PostyCollectionNode> children;
  final bool expanded;

  bool get isFolder => kind == PostyCollectionNodeKind.folder;
  bool get isRequest => kind == PostyCollectionNodeKind.request;

  PostyCollectionNode copyWith({
    String? id,
    String? name,
    PostyCollectionNodeKind? kind,
    PostyRequest? request,
    List<PostyCollectionNode>? children,
    bool? expanded,
  }) {
    return PostyCollectionNode(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      request: request ?? this.request,
      children: children ?? this.children,
      expanded: expanded ?? this.expanded,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind.name,
        if (request != null) 'request': request!.toJson(),
        'children': children.map((c) => c.toJson()).toList(),
        'expanded': expanded,
      };

  factory PostyCollectionNode.fromJson(Map<String, dynamic> json) {
    return PostyCollectionNode(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      kind: PostyCollectionNodeKind.values.firstWhere(
        (e) => e.name == json['kind'],
        orElse: () => PostyCollectionNodeKind.folder,
      ),
      request: json['request'] == null
          ? null
          : PostyRequest.fromJson(json['request'] as Map<String, dynamic>),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((e) => PostyCollectionNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      expanded: json['expanded'] as bool? ?? true,
    );
  }

  /// Deep-clone this subtree with new ids (for duplicate).
  PostyCollectionNode duplicateSubtree({String Function()? newId}) {
    final idFactory = newId ?? () => PostyCollectionIds.newId();
    if (isRequest && request != null) {
      return PostyCollectionNode(
        id: idFactory(),
        name: '$name (copy)',
        kind: PostyCollectionNodeKind.request,
        request: PostyRequest.fromJson(request!.toJson()),
      );
    }
    return PostyCollectionNode(
      id: idFactory(),
      name: name,
      kind: PostyCollectionNodeKind.folder,
      expanded: expanded,
      children: children.map((c) => c.duplicateSubtree(newId: newId)).toList(),
    );
  }
}

abstract final class PostyCollectionIds {
  static var _counter = 0;

  static String newId() {
    _counter += 1;
    final ms = DateTime.now().millisecondsSinceEpoch;
    return 'col_${ms}_$_counter';
  }
}
