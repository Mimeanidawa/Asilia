import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'herb_image.dart';

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
          child: HerbImage(
            url: imageUrl,
            fit: BoxFit.contain,
            borderRadius: 0,
            fullWidth: true,
            height: MediaQuery.sizeOf(context).height * 0.85,
          ),
        ),
      ),
    );
  }
}
