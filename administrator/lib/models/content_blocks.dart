import 'dart:convert';

enum ContentBlockType {
  paragraph,
  heading,
  tag,
  image,
  video,
  audio,
  quote,
  divider,
  list,
}

class ContentBlock {
  const ContentBlock({
    required this.type,
    this.text = '',
    this.level = 2,
    this.url = '',
    this.caption = '',
    this.title = '',
    this.listStyle = 'bullet',
    this.items = const [],
  });

  final ContentBlockType type;
  final String text;
  final int level;
  final String url;
  final String caption;
  final String title;
  final String listStyle;
  final List<String> items;

  ContentBlock copyWith({
    ContentBlockType? type,
    String? text,
    int? level,
    String? url,
    String? caption,
    String? title,
    String? listStyle,
    List<String>? items,
  }) {
    return ContentBlock(
      type: type ?? this.type,
      text: text ?? this.text,
      level: level ?? this.level,
      url: url ?? this.url,
      caption: caption ?? this.caption,
      title: title ?? this.title,
      listStyle: listStyle ?? this.listStyle,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return switch (type) {
      ContentBlockType.paragraph => {'type': 'paragraph', 'text': text},
      ContentBlockType.heading => {'type': 'heading', 'text': text, 'level': level},
      ContentBlockType.tag => {'type': 'tag', 'text': text, 'caption': caption},
      ContentBlockType.image => {'type': 'image', 'url': url, 'caption': caption},
      ContentBlockType.video => {'type': 'video', 'url': url, 'caption': caption},
      ContentBlockType.audio => {'type': 'audio', 'url': url, 'title': title},
      ContentBlockType.quote => {'type': 'quote', 'text': text},
      ContentBlockType.divider => {'type': 'divider'},
      ContentBlockType.list => {'type': 'list', 'style': listStyle, 'items': items},
    };
  }

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'paragraph';
    return switch (typeStr) {
      'heading' => ContentBlock(
          type: ContentBlockType.heading,
          text: json['text'] as String? ?? '',
          level: json['level'] as int? ?? 2,
        ),
      'tag' => ContentBlock(
          type: ContentBlockType.tag,
          text: json['text'] as String? ?? '',
          caption: json['caption'] as String? ?? '',
        ),
      'image' => ContentBlock(
          type: ContentBlockType.image,
          url: json['url'] as String? ?? '',
          caption: json['caption'] as String? ?? '',
        ),
      'video' => ContentBlock(
          type: ContentBlockType.video,
          url: json['url'] as String? ?? '',
          caption: json['caption'] as String? ?? '',
        ),
      'audio' => ContentBlock(
          type: ContentBlockType.audio,
          url: json['url'] as String? ?? '',
          title: json['title'] as String? ?? '',
        ),
      'quote' => ContentBlock(
          type: ContentBlockType.quote,
          text: json['text'] as String? ?? '',
        ),
      'divider' => const ContentBlock(type: ContentBlockType.divider),
      'list' => ContentBlock(
          type: ContentBlockType.list,
          listStyle: json['style'] as String? ?? 'bullet',
          items: List<String>.from(json['items'] as List? ?? []),
        ),
      _ => ContentBlock(
          type: ContentBlockType.paragraph,
          text: json['text'] as String? ?? '',
        ),
    };
  }

  static ContentBlock paragraph(String text) =>
      ContentBlock(type: ContentBlockType.paragraph, text: text);

  static ContentBlock heading(String text, {int level = 2}) =>
      ContentBlock(type: ContentBlockType.heading, text: text, level: level);

  static ContentBlock tag(String name, {String caption = ''}) =>
      ContentBlock(type: ContentBlockType.tag, text: name, caption: caption);

  static ContentBlock? parseHashtagLine(String line) {
    final match = RegExp(r'^#([\w\u00C0-\u024F]+)(?:\s+(.*))?$').firstMatch(line.trim());
    if (match == null) return null;
    return ContentBlock.tag(match.group(1)!, caption: match.group(2)?.trim() ?? '');
  }

  String get plainText {
    return switch (type) {
      ContentBlockType.paragraph || ContentBlockType.quote => text,
      ContentBlockType.heading => text,
      ContentBlockType.tag => caption.isNotEmpty ? '#$text $caption' : '#$text',
      ContentBlockType.image || ContentBlockType.video => caption,
      ContentBlockType.audio => title,
      ContentBlockType.list => items.join(' '),
      ContentBlockType.divider => '',
    };
  }
}

class RichContentBody {
  const RichContentBody({this.version = 1, required this.blocks});

  final int version;
  final List<ContentBlock> blocks;

  bool get isEmpty => blocks.isEmpty;

  String toPlainText() => blocks.map((b) => b.plainText).where((t) => t.isNotEmpty).join('\n\n');

  int estimateReadMinutes() {
    final words = toPlainText().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 200).ceil().clamp(1, 60);
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  static List<ContentBlock> normalizeBlocks(List<ContentBlock> blocks) {
    final out = <ContentBlock>[];
    for (final block in blocks) {
      if (block.type == ContentBlockType.paragraph && block.text.trim().startsWith('#')) {
        final tag = ContentBlock.parseHashtagLine(block.text);
        if (tag != null) {
          out.add(tag);
          continue;
        }
      }
      out.add(block);
    }
    return out;
  }

  factory RichContentBody.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['blocks'] as List? ?? [];
    return RichContentBody(
      version: json['version'] as int? ?? 1,
      blocks: rawBlocks.map((b) => ContentBlock.fromJson(Map<String, dynamic>.from(b as Map))).toList(),
    );
  }

  static RichContentBody parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const RichContentBody(blocks: []);

    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic> && decoded.containsKey('blocks')) {
          return RichContentBody.fromJson(decoded);
        }
      } catch (_) {}
    }

    if (trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed) as List;
        return RichContentBody(
          blocks: decoded
              .map((b) => ContentBlock.fromJson(Map<String, dynamic>.from(b as Map)))
              .toList(),
        );
      } catch (_) {}
    }

    return RichContentBody(
      blocks: trimmed
          .split(RegExp(r'\n{2,}'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => ContentBlock.parseHashtagLine(p) ?? ContentBlock.paragraph(p))
          .toList(),
    );
  }
}
