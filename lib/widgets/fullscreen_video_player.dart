import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'embedded_video_player.dart';

void openFullscreenVideo(BuildContext context, String url, {String? caption}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FullscreenVideoPlayer(url: url, caption: caption),
    ),
  );
}

class FullscreenVideoPlayer extends StatelessWidget {
  const FullscreenVideoPlayer({super.key, required this.url, this.caption});

  final String url;
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
          caption?.isNotEmpty == true ? caption! : 'Video',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: Center(
        child: EmbeddedVideoPlayer(
          url: url,
          borderRadius: 0,
          fullscreen: true,
        ),
      ),
    );
  }
}
