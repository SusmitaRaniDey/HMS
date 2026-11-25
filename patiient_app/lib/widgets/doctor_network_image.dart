import 'dart:async';
import 'package:flutter/material.dart';

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
  int _attempt = 0;
  Timer? _timer;
  String? get _url {
    final value = widget.imageUrl?.trim();
    final uri = value == null ? null : Uri.tryParse(value);
    if (value == null || value.isEmpty || uri == null || !uri.hasScheme) {
      return null;
    }
    return uri.toString();
  }

  @override
  void didUpdateWidget(covariant DoctorNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _timer?.cancel();
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    if (_attempt >= 2 || _timer?.isActive == true) return;
    _timer = Timer(Duration(milliseconds: 500 * (_attempt + 1)), () {
      if (mounted) setState(() => _attempt++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return widget.fallback;
    final uri = Uri.parse(url);
    final retryUrl = uri
        .replace(
          queryParameters: {
            ...uri.queryParameters,
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
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorBuilder: (_, __, ___) {
        _retry();
        return widget.fallback;
      },
    );
  }
}
