import 'package:flutter/material.dart';
import 'package:posty/src/widgets/posty_screen.dart';

/// Embeddable Posty client with a fixed height (for dev menus or settings).
class PostyPanel extends StatelessWidget {
  const PostyPanel({
    super.key,
    required this.height,
    this.initialBaseUrl = '',
    this.initialHeaders,
    this.initialQuicktypeConverterUrl = '',
    this.onRequestSent,
  });

  final double height;
  final String initialBaseUrl;
  final String initialQuicktypeConverterUrl;
  final Map<String, String>? initialHeaders;
  final void Function()? onRequestSent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: PostyScreen(
          initialBaseUrl: initialBaseUrl,
          initialHeaders: initialHeaders,
          initialQuicktypeConverterUrl: initialQuicktypeConverterUrl,
          onRequestSent: onRequestSent != null ? (_) => onRequestSent!() : null,
        ),
      ),
    );
  }
}
