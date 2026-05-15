import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:posty/posty.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PostyExampleApp());
}

class PostyExampleApp extends StatefulWidget {
  const PostyExampleApp({super.key});

  @override
  State<PostyExampleApp> createState() => _PostyExampleAppState();
}

class _PostyExampleAppState extends State<PostyExampleApp> {
  static const _baseUrlKey = 'posty_base_url';
  static const _historyKey = 'posty_history';

  String _baseUrl = 'https://httpbin.org';
  List<PostyRequest> _history = [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _baseUrl;
    final raw = prefs.getStringList(_historyKey) ?? [];
    _history = raw
        .map((e) => PostyRequest.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    setState(() => _ready = true);
  }

  Future<void> _saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
    _baseUrl = url;
  }

  Future<void> _pushHistory(PostyRequest request) async {
    _history = [request, ..._history].take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      _history.map((e) => jsonEncode(e.toJson())).toList(),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Posty Demo',
      home: _PostyHome(
        baseUrl: _baseUrl,
        history: _history,
        onBaseUrlChanged: _saveBaseUrl,
        onRequestSent: _pushHistory,
      ),
    );
  }
}

class _PostyHome extends StatefulWidget {
  const _PostyHome({
    required this.baseUrl,
    required this.history,
    required this.onBaseUrlChanged,
    required this.onRequestSent,
  });

  final String baseUrl;
  final List<PostyRequest> history;
  final Future<void> Function(String) onBaseUrlChanged;
  final Future<void> Function(PostyRequest) onRequestSent;

  @override
  State<_PostyHome> createState() => _PostyHomeState();
}

class _PostyHomeState extends State<_PostyHome> {
  late final PostyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PostyController(initialBaseUrl: widget.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyLabels = widget.history
        .map((r) => '${r.method.label} ${r.path.isEmpty ? '/' : r.path}')
        .toList();

    return PostyScreen(
      controller: _controller,
      initialBaseUrl: widget.baseUrl,
      showHistoryDrawer: true,
      historyRequests: historyLabels,
      onHistorySelected: (index) {
        if (index < widget.history.length) {
          _controller.loadRequest(widget.history[index]);
        }
      },
      onRequestSent: (c) async {
        await widget.onBaseUrlChanged(c.baseUrl);
        await widget.onRequestSent(c.toRequest());
        setState(() {});
      },
    );
  }
}
