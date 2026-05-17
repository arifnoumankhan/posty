import 'dart:convert';

import 'package:posty/src/models/posty_collection_node.dart';
import 'package:posty/src/models/posty_environment.dart';
import 'package:posty/src/models/posty_history_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostyLocalStore {
  PostyLocalStore({required this.namespace});

  final String namespace;
  static const maxHistoryEntries = 50;

  String get _historyKey => '${namespace}_posty_history_v1';
  String get _collectionsKey => '${namespace}_posty_collections_v1';
  String get _environmentKey => '${namespace}_posty_environment_v1';

  Future<List<PostyHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map((e) => PostyHistoryEntry.fromJson(
              jsonDecode(e) as Map<String, dynamic>,
            ))
        .toList();
  }

  Future<void> saveHistory(List<PostyHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = entries.take(maxHistoryEntries).toList();
    await prefs.setStringList(
      _historyKey,
      trimmed.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<List<PostyCollectionNode>> loadCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_collectionsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PostyCollectionNode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCollections(List<PostyCollectionNode> roots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _collectionsKey,
      jsonEncode(roots.map((e) => e.toJson()).toList()),
    );
  }

  Future<PostyEnvironment?> loadEnvironment() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_environmentKey);
    if (raw == null || raw.isEmpty) return null;
    return PostyEnvironment.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> saveEnvironment(PostyEnvironment env) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_environmentKey, jsonEncode(env.toJson()));
  }
}
