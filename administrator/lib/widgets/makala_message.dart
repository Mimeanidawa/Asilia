import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/admin_colors.dart';
import '../utils/makala_share.dart';
import 'url_image.dart';

sealed class MakalaMessagePart {
  const MakalaMessagePart();
}

class MakalaTextPart extends MakalaMessagePart {
  const MakalaTextPart(this.text);
  final String text;
}

class MakalaArticlePart extends MakalaMessagePart {
  const MakalaArticlePart({
    required this.id,
    required this.title,
    this.imageUrl,
    this.shareUrl,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? shareUrl;
}

class MakalaImagePart extends MakalaMessagePart {
  const MakalaImagePart(this.url);
  final String url;
}

class MakalaMessageParser {
  static final RegExp _articleTag = RegExp(
    r'\[MAKALA:([^|\]]+)\|([^|\]]+)(?:\|([^\]]*))?\]',
  );
  static final RegExp _imageTag = RegExp(r'\[IMAGE:([^\]]+)\]');
  static final RegExp _urlLine = RegExp(r'^https?://[^\s]+/makala/[^\s]+$');

  static List<MakalaMessagePart> parse(String input) {
    final parts = <MakalaMessagePart>[];
    final matches = <({int start, int end, MakalaMessagePart part})>[];

    for (final m in _imageTag.allMatches(input)) {
      final url = (m.group(1) ?? '').trim();
      if (url.isNotEmpty) {
        matches.add((start: m.start, end: m.end, part: MakalaImagePart(url)));
      }
    }
    for (final m in _articleTag.allMatches(input)) {
      final id = (m.group(1) ?? '').trim();
      final title = (m.group(2) ?? 'Makala').trim();
      final imageUrl = (m.group(3) ?? '').trim();
      if (id.isNotEmpty) {
        matches.add((
          start: m.start,
          end: m.end,
          part: MakalaArticlePart(
            id: id,
            title: title,
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
            shareUrl: MakalaShare.publicUrl(id),
          ),
        ));
      }
    }

    matches.sort((a, b) => a.start.compareTo(b.start));

    var cursor = 0;
    String? linkedUrl;
    for (final item in matches) {
      if (item.start > cursor) {
        _appendText(parts, input.substring(cursor, item.start));
      }
      parts.add(item.part);
      if (item.part is MakalaArticlePart) {
        linkedUrl = MakalaShare.publicUrl((item.part as MakalaArticlePart).id);
      }
      cursor = item.end;
    }

    if (cursor < input.length) {
      final tail = input.substring(cursor);
      final lines = tail.split('\n');
      final kept = <String>[];
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          kept.add(line);
          continue;
        }
        if (_urlLine.hasMatch(trimmed) &&
            (linkedUrl == null || trimmed == linkedUrl)) {
          continue;
        }
        kept.add(line);
      }
      _appendText(parts, kept.join('\n'));
    }

    return parts;
  }

  static void _appendText(List<MakalaMessagePart> parts, String raw) {
    final text = raw.trim();
    if (text.isNotEmpty) parts.add(MakalaTextPart(text));
  }
}

class MakalaShareCard extends StatelessWidget {
  const MakalaShareCard({
    super.key,
    required this.part,
    this.compact = false,
  });

  final MakalaArticlePart part;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasImage = part.imageUrl != null && part.imageUrl!.isNotEmpty;

    return Material(
      color: AdminColors.emerald.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final url = part.shareUrl ?? MakalaShare.publicUrl(part.id);
          await Clipboard.setData(ClipboardData(text: url));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: compact ? 16 / 9 : 1.6,
                child: UrlImage(
                  url: part.imageUrl!,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                compact ? 8 : 10,
                compact ? 10 : 12,
                compact ? 8 : 10,
              ),
              child: Row(
                children: [
                  if (!hasImage)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AdminColors.emerald.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AdminColors.emerald,
                        size: 20,
                      ),
                    ),
                  if (!hasImage) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Makala',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.emerald,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          part.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 12 : 13,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: AdminColors.emerald.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MakalaChatImage extends StatelessWidget {
  const MakalaChatImage({super.key, required this.url, this.compact = false});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? 220 : 280,
          maxHeight: compact ? 220 : 320,
        ),
        child: UrlImage(
          url: url,
          fit: BoxFit.cover,
          width: compact ? 220 : 280,
          height: compact ? 180 : 240,
        ),
      ),
    );
  }
}

class MakalaMessageContent extends StatelessWidget {
  const MakalaMessageContent({
    super.key,
    required this.content,
    this.textStyle,
    this.compact = false,
  });

  final String content;
  final TextStyle? textStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final parts = MakalaMessageParser.parse(content);
    final hasRich = parts.any((p) => p is MakalaArticlePart || p is MakalaImagePart);

    if (!hasRich) {
      return Text(content, style: textStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final part in parts) ...[
          if (part is MakalaTextPart && part.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(part.text, style: textStyle),
            ),
          if (part is MakalaImagePart)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MakalaChatImage(url: part.url, compact: compact),
            ),
          if (part is MakalaArticlePart)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: MakalaShareCard(part: part, compact: compact),
            ),
        ],
      ],
    );
  }
}
