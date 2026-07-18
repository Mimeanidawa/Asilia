import 'package:flutter/material.dart';

/// Colors for content hashtags like #mmea, #miti, #matunda.
class ContentTagStyle {
  static const _palette = <String, Color>{
    'mmea': Color(0xFF059669),
    'mimea': Color(0xFF10B981),
    'miti': Color(0xFF92400E),
    'mizizi': Color(0xFF78350F),
    'matunda': Color(0xFFDC2626),
    'vyakula': Color(0xFFD97706),
    'wanawake': Color(0xFFDB2777),
    'wanaume': Color(0xFF2563EB),
    'watoto': Color(0xFF7C3AED),
    'darasa_huru': Color(0xFF047857),
    'dawa': Color(0xFF0F766E),
    'afya': Color(0xFF0891B2),
  };

  static const _fallbacks = [
    Color(0xFF059669),
    Color(0xFF2563EB),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
  ];

  static Color colorFor(String tag) {
    final key = tag.toLowerCase().replaceAll(' ', '_');
    if (_palette.containsKey(key)) return _palette[key]!;
    return _fallbacks[tag.hashCode.abs() % _fallbacks.length];
  }

  static String displayLabel(String tag) {
    switch (tag.toLowerCase()) {
      case 'mmea':
      case 'mimea':
        return 'Mimea';
      case 'miti':
        return 'Miti';
      case 'mizizi':
        return 'Mizizi';
      case 'matunda':
        return 'Matunda';
      case 'vyakula':
        return 'Vyakula';
      case 'wanawake':
        return 'Wanawake';
      case 'wanaume':
        return 'Wanaume';
      case 'watoto':
        return 'Watoto';
      case 'darasa_huru':
        return 'Darasa Huru';
      case 'lishe':
        return 'Lishe';
      default:
        if (tag.isEmpty) return tag;
        return tag[0].toUpperCase() + tag.substring(1);
    }
  }
}
