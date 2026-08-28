import 'dart:convert';

class CarouselSlide {
  const CarouselSlide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.linkSection,
    this.linkId,
    this.sortOrder = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? linkSection;
  final String? linkId;
  final int sortOrder;

  factory CarouselSlide.fromJson(Map<String, dynamic> json) => CarouselSlide(
        id: json['id'] as String,
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        linkSection: json['linkSection'] as String?,
        linkId: json['linkId'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}

class ContentPost {
  const ContentPost({
    required this.id,
    required this.section,
    this.category,
    required this.title,
    this.subtitle = '',
    this.excerpt = '',
    this.content = '',
    this.imageUrl = '',
    this.isPremium = false,
    this.price = 2000,
    this.readTimeMinutes = 5,
    this.hasAccess = true,
  });

  final String id;
  final String section;
  final String? category;
  final String title;
  final String subtitle;
  final String excerpt;
  final String content;
  final String imageUrl;
  final bool isPremium;
  final int price;
  final int readTimeMinutes;
  final bool hasAccess;

  String get readTimeLabel => '$readTimeMinutes dk';

  String get categoryLabel {
    switch (category) {
      case 'darasa_huru': return 'Darasa Huru';
      case 'mizizi': return 'Mizizi';
      case 'miti': return 'Miti';
      case 'matunda': return 'Matunda';
      case 'mimea': return 'Mimea';
      case 'wanawake': return 'Wanawake';
      case 'watoto': return 'Watoto';
      case 'wanaume': return 'Wanaume';
      case 'vyakula': return 'Vyakula';
      default: return category ?? '';
    }
  }

  String get displayImageUrl {
    if (imageUrl.trim().isNotEmpty) return imageUrl;
    return firstImageFromContent(content);
  }

  ContentPost copyWith({String? content, bool? hasAccess, String? imageUrl}) => ContentPost(
        id: id,
        section: section,
        category: category,
        title: title,
        subtitle: subtitle,
        excerpt: excerpt,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        isPremium: isPremium,
        price: price,
        readTimeMinutes: readTimeMinutes,
        hasAccess: hasAccess ?? this.hasAccess,
      );

  factory ContentPost.fromJson(Map<String, dynamic> json) {
    final content = _jsonString(json, const ['content']);
    var image = _jsonString(json, const ['imageUrl', 'image_url']);
    if (image.isEmpty) image = firstImageFromContent(content);
    return ContentPost(
      id: json['id'] as String,
      section: json['section'] as String,
      category: json['category'] as String?,
      title: _sanitizeText(json['title'] as String? ?? ''),
      subtitle: _sanitizeText(_jsonString(json, const ['subtitle'])),
      excerpt: _sanitizeText(_jsonString(json, const ['excerpt'])),
      content: content,
      imageUrl: _normalizeStoredImageUrl(image),
      isPremium: json['isPremium'] as bool? ?? json['is_premium'] as bool? ?? false,
      price: (json['price'] as num?)?.toInt() ?? 2000,
      readTimeMinutes:
          (json['readTimeMinutes'] as num?)?.toInt() ??
          (json['read_time_minutes'] as num?)?.toInt() ??
          5,
      hasAccess: json['hasAccess'] as bool? ?? json['has_access'] as bool? ?? true,
    );
  }
}

String _sanitizeText(String input) {
  if (input.isEmpty) return '';
  final units = input.codeUnits;
  final out = StringBuffer();
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 < units.length) {
        final low = units[i + 1];
        if (low >= 0xDC00 && low <= 0xDFFF) {
          out.writeCharCode(u);
          out.writeCharCode(low);
          i++;
          continue;
        }
      }
      continue;
    }
    if (u >= 0xDC00 && u <= 0xDFFF) continue;
    out.writeCharCode(u);
  }
  return out.toString();
}

String _jsonString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

List<dynamic> _contentBlocks(dynamic parsed) {
  if (parsed is List) return parsed;
  if (parsed is Map && parsed['blocks'] is List) {
    return parsed['blocks'] as List;
  }
  return const [];
}

String firstImageFromContent(String content) {
  final raw = content.trim();
  if (raw.isEmpty) return '';

  try {
    final parsed = jsonDecode(raw);
    for (final block in _contentBlocks(parsed)) {
      if (block is! Map) continue;
      final type = block['type']?.toString();
      final url = block['url']?.toString().trim() ?? '';
      if (type == 'image' && url.isNotEmpty) return url;
    }
  } catch (_) {}

  final img = RegExp(r'''<img[^>]+src=["']([^"']+)["']''', caseSensitive: false)
      .firstMatch(raw);
  if (img != null && img.group(1)!.trim().isNotEmpty) return img.group(1)!.trim();

  final md = RegExp(r'!\[[^\]]*]\((https?:[^)\s]+)\)').firstMatch(raw);
  if (md != null) return md.group(1)!.trim();

  return '';
}

String _normalizeStoredImageUrl(String raw) {
  final url = raw.trim();
  if (url.isEmpty) return '';
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  if (host != 'i.postimg.cc') return url;
  final parts = uri.pathSegments.where((p) => p.isNotEmpty).toList();
  if (parts.length < 2) return url;
  final file = parts.last.toLowerCase();
  final blocked = file.startsWith('file-00000000') ||
      RegExp(r'^file-[0-9a-f]{20,}').hasMatch(file);
  if (!blocked) return url;
  final ext = file.contains('.') ? file.split('.').last : 'png';
  return '${uri.scheme}://${uri.host}/${parts.first}/image.$ext';
}

class RecommendedItem {
  const RecommendedItem({
    required this.id,
    required this.section,
    this.category,
    required this.title,
    required this.excerpt,
    this.imageUrl = '',
    this.readTimeMinutes = 5,
    this.isPremium = false,
    this.price = 0,
  });

  final String id;
  final String section;
  final String? category;
  final String title;
  final String excerpt;
  final String imageUrl;
  final int readTimeMinutes;
  final bool isPremium;
  final int price;

  factory RecommendedItem.fromJson(Map<String, dynamic> json) => RecommendedItem(
        id: json['id'] as String,
        section: json['section'] as String,
        category: json['category'] as String?,
        title: json['title'] as String,
        excerpt: json['excerpt'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        readTimeMinutes: json['readTimeMinutes'] as int? ?? 5,
        isPremium: json['isPremium'] as bool? ?? false,
        price: json['price'] as int? ?? 0,
      );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    this.authProvider = 'phone',
    this.isPremium = false,
    this.premiumUntil,
    this.messageCount = 0,
  });

  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String authProvider;
  final bool isPremium;
  final DateTime? premiumUntil;
  final int messageCount;

  bool get isPremiumActive =>
      isPremium && (premiumUntil == null || premiumUntil!.isAfter(DateTime.now()));

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        authProvider: json['authProvider'] as String? ?? 'phone',
        isPremium: json['isPremium'] as bool? ?? false,
        premiumUntil: json['premiumUntil'] != null
            ? DateTime.tryParse(json['premiumUntil'] as String)
            : null,
        messageCount: json['messageCount'] as int? ?? 0,
      );
}

class MwalimuSettings {
  const MwalimuSettings({
    this.mwalimuName = 'Mwalimu',
    this.mwalimuImage = '',
    this.mwalimuWelcome = 'Karibu!',
    this.freeMessageLimit = 5,
    this.premiumPrice = 15000,
    this.adsPromoModalEnabled = true,
  });

  final String mwalimuName;
  final String mwalimuImage;
  final String mwalimuWelcome;
  final int freeMessageLimit;
  final int premiumPrice;
  final bool adsPromoModalEnabled;

  factory MwalimuSettings.fromJson(Map<String, dynamic> json) {
    final price = json['premiumPrice'] as int? ?? 15000;
    return MwalimuSettings(
      mwalimuName: json['mwalimuName'] as String? ??
          json['mtabibuName'] as String? ??
          'Mwalimu',
      mwalimuImage: json['mwalimuImage'] as String? ??
          json['mtabibuImage'] as String? ??
          '',
      mwalimuWelcome: json['mwalimuWelcome'] as String? ??
          json['mtabibuWelcome'] as String? ??
          'Karibu!',
      freeMessageLimit: json['freeMessageLimit'] as int? ?? 5,
      premiumPrice: price < 500 ? 15000 : price,
      adsPromoModalEnabled: json['adsPromoModalEnabled'] as bool? ?? true,
    );
  }
}

class MwalimuMessage {
  const MwalimuMessage({
    required this.id,
    required this.senderType,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String senderType;
  final String content;
  final String createdAt;

  bool get isUser => senderType == 'user';
  bool get isAdmin => senderType == 'admin';

  factory MwalimuMessage.fromJson(Map<String, dynamic> json) => MwalimuMessage(
        id: json['id'] as String,
        senderType: json['senderType'] as String,
        content: json['content'] as String,
        createdAt: json['createdAt'] as String,
      );
}

/// Section & category constants — learning only (no matibabu)
class ContentSections {
  static const dodoso = 'dodoso';
  static const chaguaMada = 'chagua_mada';
  static const vyakulaMatunda = 'vyakula_matunda';
  static const jifunze = 'jifunze';
  static const darasaHuru = 'darasa_huru';
  static const allMakala = 'all_makala';

  static const dodosoCategories = ['darasa_huru', 'mizizi', 'miti', 'matunda', 'mimea'];
  static const chaguaMadaCategories = ['mimea', 'wanawake', 'watoto', 'wanaume'];
  static const vyakulaMatundaCategories = ['matunda', 'mizizi', 'miti', 'mimea', 'vyakula'];
  static const jifunzeCategories = ['matunda', 'mizizi', 'miti', 'mimea', 'vyakula'];

  static String categoryLabel(String cat) {
    switch (cat) {
      case 'darasa_huru': return 'Darasa Huru';
      case 'mizizi': return 'Mizizi';
      case 'miti': return 'Miti';
      case 'matunda': return 'Matunda';
      case 'mimea': return 'Mimea';
      case 'wanawake': return 'Wanawake';
      case 'watoto': return 'Watoto';
      case 'wanaume': return 'Wanaume';
      case 'vyakula': return 'Vyakula';
      case 'lishe': return 'Lishe';
      default: return cat;
    }
  }

  static String sectionLabel(String section) {
    switch (section) {
      case dodoso: return 'Dodoso';
      case chaguaMada: return 'Chagua Mada';
      case vyakulaMatunda: return 'Vyakula na Matunda';
      case jifunze: return 'Jifunze';
      case allMakala: return 'Makala';
      default: return section;
    }
  }
}
