import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

void openFullscreenImage(BuildContext context, String imageUrl, {String? caption}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FullscreenImageViewer(imageUrl: imageUrl, caption: caption),
    ),
  );
}

class FullscreenImageViewer extends StatelessWidget {
  const FullscreenImageViewer({super.key, required this.imageUrl, this.caption});

  final String imageUrl;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Text(
          caption?.isNotEmpty == true ? caption! : 'Picha',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: AppColors.emerald400),
            ),
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}
