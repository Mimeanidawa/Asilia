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

class MakalaMessageParser {
  static final RegExp _tag = RegExp(
    r'\[MAKALA:([^|\]]+)\|([^|\]]+)(?:\|([^\]]*))?\]',
  );
  static final RegExp _urlLine = RegExp(r'^https?://[^\s]+/makala/[^\s]+$');

  static List<MakalaMessagePart> parse(String input) {
    final parts = <MakalaMessagePart>[];
    var cursor = 0;
    String? linkedUrl;

    for (final m in _tag.allMatches(input)) {
      if (m.start > cursor) {
        _appendText(parts, input.substring(cursor, m.start));
      }
      final id = (m.group(1) ?? '').trim();
      final title = (m.group(2) ?? 'Makala').trim();
      final imageUrl = (m.group(3) ?? '').trim();
      if (id.isNotEmpty) {
        parts.add(
          MakalaArticlePart(
            id: id,
            title: title,
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
            shareUrl: MakalaShare.publicUrl(id),
          ),
        );
        linkedUrl = MakalaShare.publicUrl(id);
      }
      cursor = m.end;
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

  void _copyLink(BuildContext context) {
    final url = part.shareUrl ?? MakalaShare.publicUrl(part.id);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kiungo kimenakiliwa', style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = part.imageUrl != null && part.imageUrl!.isNotEmpty;

    return Material(
      color: AdminColors.card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copyLink(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: UrlImage(
                  url: part.imageUrl!,
                  borderRadius: 0,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: Row(
                children: [
                  if (!hasImage)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AdminColors.emerald.withValues(alpha: 0.15),
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
    final hasArticle = parts.any((p) => p is MakalaArticlePart);

    if (!hasArticle) {
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
