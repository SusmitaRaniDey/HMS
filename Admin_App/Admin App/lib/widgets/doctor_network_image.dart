import 'dart:async';

import 'package:flutter/material.dart';

/// Network image tailored for doctor avatars.
///
/// Image.network does not retry transient failures. This widget cleans the URL
/// and retries a failed request before showing the supplied fallback.
class DoctorNetworkImage extends StatefulWidget {
  const DoctorNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? imageUrl;
  final Widget fallback;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<DoctorNetworkImage> createState() => _DoctorNetworkImageState();
}

class _DoctorNetworkImageState extends State<DoctorNetworkImage> {
  static const _maxRetries = 2;
  int _attempt = 0;
  Timer? _retryTimer;

  String? get _url {
    final value = widget.imageUrl?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;
    return uri.toString();
  }

  @override
  void didUpdateWidget(covariant DoctorNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryTimer?.cancel();
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _retry() {
    if (_attempt >= _maxRetries || _retryTimer?.isActive == true) return;
    _retryTimer = Timer(Duration(milliseconds: 500 * (_attempt + 1)), () {
      if (mounted) setState(() => _attempt++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return widget.fallback;
    final retryUrl = Uri.parse(url)
        .replace(
          queryParameters: {
            ...Uri.parse(url).queryParameters,
            if (_attempt > 0) '_image_retry': '$_attempt',
          },
        )
        .toString();
    return Image.network(
      retryUrl,
      key: ValueKey(retryUrl),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (context, error, stackTrace) {
        _retry();
        return widget.fallback;
      },
    );
  }
}
