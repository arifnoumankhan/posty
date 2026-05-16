import 'package:flutter/material.dart';
import 'package:posty/src/theme/posty_theme.dart';

const double _kSplitHandleThickness = 8;

/// Horizontal split with a draggable divider between [start] (left) and [end] (right).
class PostyHorizontalSplitView extends StatefulWidget {
  const PostyHorizontalSplitView({
    super.key,
    required this.theme,
    required this.start,
    required this.end,
    this.initialSplit = 0.5,
    this.minSplit = 0.2,
    this.maxSplit = 0.8,
  });

  final PostyTheme theme;
  final Widget start;
  final Widget end;
  final double initialSplit;
  final double minSplit;
  final double maxSplit;

  @override
  State<PostyHorizontalSplitView> createState() =>
      _PostyHorizontalSplitViewState();
}

class _PostyHorizontalSplitViewState extends State<PostyHorizontalSplitView> {
  late double _split = widget.initialSplit.clamp(widget.minSplit, widget.maxSplit);

  void _onDrag(double delta, double totalWidth) {
    final track = totalWidth - _kSplitHandleThickness;
    if (track <= 0) return;
    setState(() {
      _split = (_split + delta / track).clamp(widget.minSplit, widget.maxSplit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final track = constraints.maxWidth - _kSplitHandleThickness;
        final leftWidth = track * _split;

        return Row(
          children: [
            SizedBox(width: leftWidth, child: widget.start),
            _SplitHandle(
              theme: widget.theme,
              axis: Axis.horizontal,
              thickness: _kSplitHandleThickness,
              onDrag: (delta) => _onDrag(delta, constraints.maxWidth),
            ),
            SizedBox(
              width: track - leftWidth,
              child: widget.end,
            ),
          ],
        );
      },
    );
  }
}

/// Vertical split with a draggable divider between [start] (top) and [end] (bottom).
class PostyVerticalSplitView extends StatefulWidget {
  const PostyVerticalSplitView({
    super.key,
    required this.theme,
    required this.start,
    required this.end,
    this.initialSplit = 0.48,
    this.minSplit = 0.25,
    this.maxSplit = 0.75,
  });

  final PostyTheme theme;
  final Widget start;
  final Widget end;
  final double initialSplit;
  final double minSplit;
  final double maxSplit;

  @override
  State<PostyVerticalSplitView> createState() => _PostyVerticalSplitViewState();
}

class _PostyVerticalSplitViewState extends State<PostyVerticalSplitView> {
  late double _split = widget.initialSplit.clamp(widget.minSplit, widget.maxSplit);

  void _onDrag(double delta, double totalHeight) {
    final track = totalHeight - _kSplitHandleThickness;
    if (track <= 0) return;
    setState(() {
      _split = (_split + delta / track).clamp(widget.minSplit, widget.maxSplit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final track = constraints.maxHeight - _kSplitHandleThickness;
        final topHeight = track * _split;

        return Column(
          children: [
            SizedBox(height: topHeight, child: widget.start),
            _SplitHandle(
              theme: widget.theme,
              axis: Axis.vertical,
              thickness: _kSplitHandleThickness,
              onDrag: (delta) => _onDrag(delta, constraints.maxHeight),
            ),
            SizedBox(
              height: track - topHeight,
              child: widget.end,
            ),
          ],
        );
      },
    );
  }
}

class _SplitHandle extends StatefulWidget {
  const _SplitHandle({
    required this.theme,
    required this.axis,
    required this.thickness,
    required this.onDrag,
  });

  final PostyTheme theme;
  final Axis axis;
  final double thickness;
  final ValueChanged<double> onDrag;

  @override
  State<_SplitHandle> createState() => _SplitHandleState();
}

class _SplitHandleState extends State<_SplitHandle> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.axis == Axis.horizontal;
    final active = _hovering || _dragging;
    final accent = widget.theme.primaryColor;

    final child = MouseRegion(
      cursor: horizontal
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: horizontal ? (_) => setState(() => _dragging = true) : null,
        onHorizontalDragUpdate:
            horizontal ? (d) => widget.onDrag(d.delta.dx) : null,
        onHorizontalDragEnd:
            horizontal ? (_) => setState(() => _dragging = false) : null,
        onHorizontalDragCancel:
            horizontal ? () => setState(() => _dragging = false) : null,
        onVerticalDragStart: !horizontal ? (_) => setState(() => _dragging = true) : null,
        onVerticalDragUpdate:
            !horizontal ? (d) => widget.onDrag(d.delta.dy) : null,
        onVerticalDragEnd:
            !horizontal ? (_) => setState(() => _dragging = false) : null,
        onVerticalDragCancel:
            !horizontal ? () => setState(() => _dragging = false) : null,
        child: Container(
          width: horizontal ? widget.thickness : double.infinity,
          height: horizontal ? double.infinity : widget.thickness,
          alignment: Alignment.center,
          color: active
              ? accent.withValues(alpha: 0.12)
              : widget.theme.panelBackground,
          child: Container(
            width: horizontal ? 2 : double.infinity,
            height: horizontal ? double.infinity : 2,
            color: active ? accent : widget.theme.borderColor,
          ),
        ),
      ),
    );

    return horizontal
        ? child
        : SizedBox(width: double.infinity, child: child);
  }
}
