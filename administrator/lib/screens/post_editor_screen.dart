import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/content_blocks.dart';
import '../models/content_sections.dart';
import '../theme/admin_colors.dart';
import '../utils/block_accent_style.dart';
import '../utils/content_tag_style.dart';
import '../widgets/admin_blur.dart';
import '../widgets/admin_ui.dart';
import '../widgets/embedded_video_player.dart';
import '../widgets/stable_text_field.dart';
import '../widgets/url_image.dart';

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({
    super.key,
    required this.section,
    required this.categories,
    this.existing,
  });

  final String section;
  final List<String> categories;
  final Map<String, dynamic>? existing;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _excerptCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '2000');

  late String _category;
  late List<String> _categoryOptions;
  late List<ContentBlock> _blocks;
  bool _isPremium = false;
  bool _isPublished = false;
  bool _preview = false;
  bool _titleValid = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _categoryOptions = List<String>.from(widget.categories);
    final existingCat = e?['category'] as String?;
    if (existingCat != null &&
        existingCat.isNotEmpty &&
        !_categoryOptions.contains(existingCat)) {
      _categoryOptions = [existingCat, ..._categoryOptions];
    }
    if (_categoryOptions.isEmpty) {
      _categoryOptions = ['mimea'];
    }
    _category = (existingCat != null && existingCat.isNotEmpty)
        ? existingCat
        : _categoryOptions.first;
    _titleCtrl.text = e?['title'] as String? ?? '';
    _subtitleCtrl.text = e?['subtitle'] as String? ?? '';
    _excerptCtrl.text = e?['excerpt'] as String? ?? '';
    _coverCtrl.text = e?['imageUrl'] as String? ?? '';
    _priceCtrl.text = '${e?['price'] ?? 2000}';
    _isPremium = e?['isPremium'] as bool? ?? false;
    _isPublished = e?['isPublished'] as bool? ?? true;
    _titleValid = _titleCtrl.text.trim().isNotEmpty;
    _titleCtrl.addListener(_onTitleChanged);
    _blocks = RichContentBody.parse(e?['content'] as String? ?? '').blocks;
    if (_blocks.isEmpty) {
      _blocks = [ContentBlock.paragraph('')];
    }
  }

  void _onTitleChanged() {
    final valid = _titleCtrl.text.trim().isNotEmpty;
    if (valid != _titleValid) setState(() => _titleValid = valid);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _excerptCtrl.dispose();
    _coverCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> buildPayload() {
    final normalized = RichContentBody.normalizeBlocks(_blocks.where(_blockHasContent).toList());
    final body = RichContentBody(blocks: normalized);
    final excerpt = _excerptCtrl.text.trim().isNotEmpty
        ? _excerptCtrl.text.trim()
        : body.toPlainText().split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');

    var cover = _coverCtrl.text.trim();
    if (cover.isEmpty) {
      for (final block in normalized) {
        if (block.type == ContentBlockType.image && block.url.trim().isNotEmpty) {
          cover = block.url.trim();
          break;
        }
      }
    }

    return {
      'section': widget.section,
      'category': _category,
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'excerpt': excerpt.length > 160 ? '${excerpt.substring(0, 157)}...' : excerpt,
      'content': body.toJsonString(),
      'imageUrl': cover,
      'price': int.tryParse(_priceCtrl.text) ?? 2000,
      'isPremium': _isPremium,
      'isPublished': _isPublished,
      'readTimeMinutes': body.estimateReadMinutes(),
    };
  }

  bool _blockHasContent(ContentBlock b) {
    return switch (b.type) {
      ContentBlockType.divider => true,
      ContentBlockType.paragraph ||
      ContentBlockType.quote ||
      ContentBlockType.callout ||
      ContentBlockType.heading =>
        b.text.trim().isNotEmpty,
      ContentBlockType.tag => b.text.trim().isNotEmpty,
      ContentBlockType.image || ContentBlockType.video || ContentBlockType.audio => b.url.trim().isNotEmpty,
      ContentBlockType.list => b.items.any((i) => i.trim().isNotEmpty),
    };
  }

  void _addBlock(ContentBlock block) {
    setState(() => _blocks.add(block));
  }

  void _updateBlock(int index, ContentBlock block) {
    _blocks[index] = block;
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
      if (_blocks.isEmpty) _blocks.add(ContentBlock.paragraph(''));
    });
  }

  void _moveBlock(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionLabel = AdminContentSections.sectionLabel(widget.section);

    return AdminBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: const AdminBarBlur(),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: AdminColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Makala mpya' : 'Hariri makala',
                style: GoogleFonts.plusJakartaSans(
                  color: AdminColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              Text(
                sectionLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: AdminColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: _preview ? 'Hariri' : 'Onyesho',
              onPressed: () => setState(() => _preview = !_preview),
              icon: Icon(
                _preview ? Icons.edit_rounded : Icons.visibility_outlined,
                color: AdminColors.emerald,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: _titleValid ? () => Navigator.pop(context, buildPayload()) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.emerald,
                  disabledBackgroundColor: AdminColors.cardBorder,
                  foregroundColor: const Color(0xFF052E16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Hifadhi',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _preview
            ? null
            : FloatingActionButton.extended(
                onPressed: _showAddBlockSheet,
                backgroundColor: AdminColors.emerald,
                foregroundColor: const Color(0xFF052E16),
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Ongeza',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
                ),
              ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            if (_preview)
              _PreviewCard(
                title: _titleCtrl.text,
                subtitle: _subtitleCtrl.text,
                coverUrl: _coverCtrl.text,
                blocks: _blocks,
              )
            else ...[
              // Title — always first, always visible
              TextField(
                controller: _titleCtrl,
                style: GoogleFonts.plusJakartaSans(
                  color: AdminColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.6,
                ),
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Kichwa cha makala…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textDim,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              TextField(
                controller: _subtitleCtrl,
                style: GoogleFonts.plusJakartaSans(
                  color: AdminColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Maneno ya chini (hiari)',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textDim,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryChips(),
              const SizedBox(height: 16),
              _buildCoverField(),
              const SizedBox(height: 16),
              _buildPublishRow(),
              if (_isPremium) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.plusJakartaSans(color: AdminColors.textPrimary),
                  decoration: _softDeco('Bei (TZS)', hint: '2000'),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _excerptCtrl,
                maxLines: 2,
                style: GoogleFonts.plusJakartaSans(color: AdminColors.textPrimary, fontSize: 13),
                decoration: _softDeco('Muhtasari (hiari)', hint: 'Muhtasari mfupi…'),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Text(
                    'Maudhui',
                    style: GoogleFonts.plusJakartaSans(
                      color: AdminColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_blocks.length} vipengele',
                    style: GoogleFonts.plusJakartaSans(
                      color: AdminColors.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                onReorder: _moveBlock,
                itemCount: _blocks.length,
                itemBuilder: (ctx, i) {
                  final block = _blocks[i];
                  return Padding(
                    key: ValueKey(block.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BlockEditorCard(
                      index: i,
                      block: block,
                      onChanged: (b) => _updateBlock(i, b),
                      onDelete: () => _removeBlock(i),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showAddBlockSheet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Ongeza kipengele',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.emerald,
                  side: BorderSide(color: AdminColors.emerald.withValues(alpha: 0.4)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categoryOptions.map((c) {
        final selected = _category == c;
        final label = AdminContentSections.categoryLabel(c, section: widget.section);
        return GestureDetector(
          onTap: () => setState(() => _category = c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AdminColors.emeraldGlow : AdminColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AdminColors.emerald.withValues(alpha: 0.55)
                    : AdminColors.cardBorder,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: selected ? AdminColors.emerald : AdminColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCoverField() {
    final cover = _coverCtrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cover.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: UrlImage(
              url: cover,
              height: 160,
              width: double.infinity,
              borderRadius: 16,
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _coverCtrl,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.url,
          style: GoogleFonts.plusJakartaSans(color: AdminColors.textPrimary, fontSize: 13),
          decoration: _softDeco(
            'Picha ya jalada (URL)',
            hint: 'https://i.ibb.co/...',
            prefix: Icons.image_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPublishRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        children: [
          _ToggleRow(
            title: 'Chapisha',
            subtitle: 'Ionekane kwa watumiaji',
            value: _isPublished,
            onChanged: (v) => setState(() => _isPublished = v),
          ),
          Divider(height: 1, color: AdminColors.cardBorder.withValues(alpha: 0.7)),
          _ToggleRow(
            title: 'Premium',
            subtitle: 'Inahitaji malipo',
            value: _isPremium,
            onChanged: (v) => setState(() => _isPremium = v),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBlockSheet() async {
    final choice = await showAdminSheet<ContentBlock>(
      context: context,
      backgroundColor: AdminColors.surface,
      builder: (ctx) {
        final items = <(ContentBlock, IconData, String, String)>[
          (ContentBlock.paragraph(''), Icons.notes_rounded, 'Aya', 'Andika maandishi'),
          (ContentBlock.heading('', level: 2), Icons.title_rounded, 'Kichwa', 'Kichwa cha sehemu'),
          (ContentBlock(type: ContentBlockType.image), Icons.image_rounded, 'Picha', 'Weka URL ya picha'),
          (ContentBlock(type: ContentBlockType.video), Icons.videocam_rounded, 'Video', 'YouTube au video URL'),
          (ContentBlock.list(), Icons.list_rounded, 'Orodha', 'Vipengele vilivyoorodheshwa'),
          (ContentBlock.callout(''), Icons.lightbulb_outline_rounded, 'Ujumbe', 'Kidokezo au tahadhari'),
          (ContentBlock(type: ContentBlockType.quote), Icons.format_quote_rounded, 'Nukuu', 'Maneno yaliyonukuliwa'),
          (ContentBlock.tag(''), Icons.tag_rounded, 'Lebo', 'Hashtag / lebo'),
          (ContentBlock(type: ContentBlockType.audio), Icons.mic_rounded, 'Sauti', 'Faili la sauti'),
          (ContentBlock(type: ContentBlockType.divider), Icons.horizontal_rule_rounded, 'Mstari', 'Mgawanyo'),
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AdminColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ongeza kipengele',
                    style: GoogleFonts.plusJakartaSans(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: AdminColors.cardBorder.withValues(alpha: 0.6),
                    ),
                    itemBuilder: (_, i) {
                      final item = items[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AdminColors.emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.$2, color: AdminColors.emerald, size: 20),
                        ),
                        title: Text(
                          item.$3,
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          item.$4,
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item.$1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice != null) _addBlock(choice);
  }

  InputDecoration _softDeco(String label, {String? hint, IconData? prefix}) => InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefix != null ? Icon(prefix, size: 18, color: AdminColors.textMuted) : null,
        hintStyle: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 13),
        labelStyle: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AdminColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AdminColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AdminColors.emerald.withValues(alpha: 0.7), width: 1.4),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AdminColors.emerald.withValues(alpha: 0.45),
            activeThumbColor: AdminColors.emerald,
          ),
        ],
      ),
    );
  }
}

class _BlockEditorCard extends StatefulWidget {
  const _BlockEditorCard({
    required this.index,
    required this.block,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final ContentBlock block;
  final ValueChanged<ContentBlock> onChanged;
  final VoidCallback onDelete;

  @override
  State<_BlockEditorCard> createState() => _BlockEditorCardState();
}

class _BlockEditorCardState extends State<_BlockEditorCard> {
  late ContentBlock _block;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
  }

  @override
  void didUpdateWidget(covariant _BlockEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.id != widget.block.id) {
      _block = widget.block;
    }
  }

  void _emit(ContentBlock next) {
    setState(() => _block = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final b = _block;
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 0),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_indicator_rounded, color: AdminColors.textDim, size: 20),
                ),
                const SizedBox(width: 4),
                Icon(_iconFor(b.type), size: 15, color: AdminColors.emerald),
                const SizedBox(width: 6),
                Text(
                  _labelFor(b.type),
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.error, size: 18),
                  onPressed: widget.onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
            child: _buildFields(b),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(ContentBlock b) {
    return switch (b.type) {
      ContentBlockType.paragraph => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StableTextField(
              value: b.text,
              onChanged: (v) => _emit(b.copyWith(text: v)),
              hint: 'Andika aya yako hapa...',
              maxLines: 8,
              minLines: 3,
              style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 15, height: 1.75),
              decoration: _bareDeco(),
            ),
            if (ContentBlock.parseHashtagLine(b.text) != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _TagPreviewChip(tag: ContentBlock.parseHashtagLine(b.text)!),
              ),
          ],
        ),
      ContentBlockType.tag => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StableTextField(value: b.text, onChanged: (v) => _emit(b.copyWith(text: v)), hint: 'Jina la lebo (bila #)', decoration: _bareDeco()),
            const SizedBox(height: 8),
            StableTextField(value: b.caption, onChanged: (v) => _emit(b.copyWith(caption: v)), hint: 'Maelezo (hiari)', decoration: _bareDeco()),
            if (b.text.trim().isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 10), child: _TagPreviewChip(tag: b)),
          ],
        ),
      ContentBlockType.heading => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _levelChip('H1', 1, b.level, b),
                const SizedBox(width: 6),
                _levelChip('H2', 2, b.level, b),
                const SizedBox(width: 6),
                _levelChip('H3', 3, b.level, b),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BlockAccentStyle.accents.map((a) => _accentDot(a, b)).toList(),
            ),
            const SizedBox(height: 10),
            StableTextField(
              key: ValueKey('heading-${b.id}-${b.accent}-${b.level}'),
              value: b.text,
              onChanged: (v) => _emit(b.copyWith(text: v)),
              hint: 'Andika kichwa...',
              maxLines: 2,
              style: _headingStyle(b.level, b.accent),
              decoration: _bareDeco(borderColor: BlockAccentStyle.colorFor(b.accent)),
            ),
          ],
        ),
      ContentBlockType.callout => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: BlockAccentStyle.calloutVariants.map((v) => _calloutChip(v.$1, v.$2, v.$3, b)).toList(),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              key: ValueKey('callout-${b.id}-${b.accent}'),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BlockAccentStyle.backgroundFor(b.accent),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: BlockAccentStyle.colorFor(BlockAccentStyle.variantColorKey(b.accent)), width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(BlockAccentStyle.iconForCallout(b.accent), size: 16, color: BlockAccentStyle.colorFor(BlockAccentStyle.variantColorKey(b.accent))),
                      const SizedBox(width: 6),
                      Text(
                        BlockAccentStyle.labelForCallout(b.accent),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: BlockAccentStyle.colorFor(BlockAccentStyle.variantColorKey(b.accent)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StableTextField(
                    value: b.title,
                    onChanged: (v) => _emit(b.copyWith(title: v)),
                    hint: 'Kichwa cha ujumbe (hiari)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AdminColors.textPrimary),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(color: AdminColors.textDim),
                    ),
                  ),
                  StableTextField(
                    value: b.text,
                    onChanged: (v) => _emit(b.copyWith(text: v)),
                    hint: 'Andika ujumbe wako hapa...',
                    maxLines: 5,
                    minLines: 2,
                    style: GoogleFonts.inter(fontSize: 14, height: 1.6, color: AdminColors.textPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintStyle: TextStyle(color: AdminColors.textDim),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ContentBlockType.image || ContentBlockType.video => Column(
          children: [
            StableTextField(
              value: b.url,
              onChanged: (v) => _emit(b.copyWith(url: v)),
              hint: b.type == ContentBlockType.image
                  ? 'https://mfano.com/picha.jpg'
                  : 'https://youtube.com/watch?v=... au https://mfano.com/video.mp4',
              keyboardType: TextInputType.url,
              decoration: _bareDeco(),
            ),
            const SizedBox(height: 8),
            StableTextField(
              value: b.caption,
              onChanged: (v) => _emit(b.copyWith(caption: v)),
              hint: 'Maelezo ya picha/video (hiari)',
              decoration: _bareDeco(),
            ),
            if (b.type == ContentBlockType.image && b.url.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              UrlImage(
                url: b.url.trim(),
                height: 160,
                width: double.infinity,
                borderRadius: 12,
              ),
            ],
            if (b.type == ContentBlockType.video && b.url.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              EmbeddedVideoPlayer(url: b.url.trim()),
            ],
          ],
        ),
      ContentBlockType.audio => Column(
          children: [
            StableTextField(
              value: b.url,
              onChanged: (v) => _emit(b.copyWith(url: v)),
              hint: 'https://mfano.com/sauti.mp3',
              keyboardType: TextInputType.url,
              decoration: _bareDeco(),
            ),
            const SizedBox(height: 8),
            StableTextField(
              value: b.title,
              onChanged: (v) => _emit(b.copyWith(title: v)),
              hint: 'Jina la sauti (mfano: Maelezo ya daktari)',
              decoration: _bareDeco(),
            ),
          ],
        ),
      ContentBlockType.quote => Container(
          padding: const EdgeInsets.only(left: 12),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AdminColors.emerald, width: 3)),
          ),
          child: StableTextField(
            value: b.text,
            onChanged: (v) => _emit(b.copyWith(text: v)),
            hint: 'Nukuu...',
            maxLines: 4,
            style: GoogleFonts.inter(fontStyle: FontStyle.italic, fontSize: 14, height: 1.6, color: AdminColors.textSecondary),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(8), hintStyle: TextStyle(color: AdminColors.textDim)),
          ),
        ),
      ContentBlockType.divider => Container(
          height: 32,
          alignment: Alignment.center,
          child: Container(height: 2, decoration: BoxDecoration(gradient: AdminColors.emeraldGradient, borderRadius: BorderRadius.circular(1))),
        ),
      ContentBlockType.list => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _listStyleChip('• Nukta', 'bullet', b.listStyle, b),
                const SizedBox(width: 8),
                _listStyleChip('1. Namba', 'numbered', b.listStyle, b),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
              decoration: BoxDecoration(
                color: AdminColors.emeraldGlow.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  ...b.items.asMap().entries.map((e) {
                    return Padding(
                      key: ValueKey('list-item-${b.id}-${e.key}'),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(top: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AdminColors.emerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.listStyle == 'numbered' ? '${e.key + 1}' : '•',
                              style: GoogleFonts.inter(
                                color: AdminColors.emerald,
                                fontWeight: FontWeight.w800,
                                fontSize: b.listStyle == 'numbered' ? 12 : 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StableTextField(
                              value: e.value,
                              onChanged: (v) {
                                final items = List<String>.from(b.items);
                                items[e.key] = v;
                                _emit(b.copyWith(items: items));
                              },
                              hint: 'Andika kipengele ${e.key + 1}...',
                              maxLines: 3,
                              minLines: 1,
                              decoration: _bareDeco(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AdminColors.textDim, size: 18),
                            onPressed: b.items.length <= 1
                                ? null
                                : () {
                                    final items = List<String>.from(b.items)..removeAt(e.key);
                                    _emit(b.copyWith(items: items));
                                  },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _emit(b.copyWith(items: [...b.items, ''])),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AdminColors.emerald),
                      label: Text('Ongeza kipengele', style: GoogleFonts.inter(color: AdminColors.emerald, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    };
  }

  InputDecoration _bareDeco({Color? borderColor}) => InputDecoration(
        filled: true,
        fillColor: AdminColors.bg,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor ?? AdminColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor ?? AdminColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor ?? AdminColors.emerald, width: 1.5),
        ),
      );

  Widget _levelChip(String label, int level, int current, ContentBlock b) {
    final sel = current == level;
    return GestureDetector(
      onTap: () => _emit(b.copyWith(level: level)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AdminColors.emeraldGlow : AdminColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? AdminColors.emerald : AdminColors.cardBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(color: sel ? AdminColors.emerald : AdminColors.textDim, fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }

  Widget _accentDot(String accent, ContentBlock b) {
    final sel = b.accent == accent;
    final color = BlockAccentStyle.colorFor(accent);
    return GestureDetector(
      onTap: () => _emit(b.copyWith(accent: accent)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: sel ? 34 : 28,
        height: sel ? 34 : 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: sel ? Colors.white : AdminColors.cardBorder, width: sel ? 3 : 1),
          boxShadow: sel
              ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 10, spreadRadius: 1)]
              : null,
        ),
        child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
      ),
    );
  }

  Widget _calloutChip(String variant, String label, IconData icon, ContentBlock b) {
    final sel = b.accent == variant;
    final color = BlockAccentStyle.colorFor(BlockAccentStyle.variantColorKey(variant));
    return GestureDetector(
      onTap: () => _emit(b.copyWith(accent: variant)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? color.withValues(alpha: 0.15) : AdminColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : AdminColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: sel ? color : AdminColors.textDim),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? color : AdminColors.textDim)),
          ],
        ),
      ),
    );
  }

  Widget _listStyleChip(String label, String style, String current, ContentBlock b) {
    final sel = current == style;
    return GestureDetector(
      onTap: () => _emit(b.copyWith(listStyle: style)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? AdminColors.emeraldGlow : AdminColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? AdminColors.emerald : AdminColors.cardBorder),
        ),
        child: Text(label, style: GoogleFonts.inter(color: sel ? AdminColors.emerald : AdminColors.textDim, fontSize: 12)),
      ),
    );
  }

  TextStyle _headingStyle(int level, String accent) {
    final color = BlockAccentStyle.colorFor(accent);
    return switch (level) {
      1 => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: color, height: 1.2),
      2 => GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: color, height: 1.25),
      _ => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color, height: 1.3),
    };
  }

  IconData _iconFor(ContentBlockType t) => switch (t) {
        ContentBlockType.paragraph => Icons.notes_rounded,
        ContentBlockType.tag => Icons.tag_rounded,
        ContentBlockType.heading => Icons.title_rounded,
        ContentBlockType.image => Icons.image_rounded,
        ContentBlockType.video => Icons.videocam_rounded,
        ContentBlockType.audio => Icons.mic_rounded,
        ContentBlockType.quote => Icons.format_quote_rounded,
        ContentBlockType.callout => Icons.chat_bubble_outline_rounded,
        ContentBlockType.list => Icons.list_rounded,
        ContentBlockType.divider => Icons.horizontal_rule_rounded,
      };

  String _labelFor(ContentBlockType t) => switch (t) {
        ContentBlockType.paragraph => 'Aya',
        ContentBlockType.tag => 'Lebo #',
        ContentBlockType.heading => 'Kichwa',
        ContentBlockType.image => 'Picha',
        ContentBlockType.video => 'Video',
        ContentBlockType.audio => 'Sauti',
        ContentBlockType.quote => 'Nukuu',
        ContentBlockType.callout => 'Ujumbe',
        ContentBlockType.list => 'Orodha',
        ContentBlockType.divider => 'Mstari',
      };
}

class _TagPreviewChip extends StatelessWidget {
  const _TagPreviewChip({required this.tag});
  final ContentBlock tag;

  @override
  Widget build(BuildContext context) {
    final color = ContentTagStyle.colorFor(tag.text);
    final label = ContentTagStyle.displayLabel(tag.text);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text('#$label', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        if (tag.caption.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(child: Text(tag.caption, style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12))),
        ],
      ],
    );
  }
}

TextStyle _previewHeadingStyle(int level, String accent) {
  final color = BlockAccentStyle.colorFor(accent);
  return switch (level) {
    1 => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: color, height: 1.2),
    2 => GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: color, height: 1.25),
    _ => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color, height: 1.3),
  };
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.title, required this.subtitle, required this.coverUrl, required this.blocks});
  final String title;
  final String subtitle;
  final String coverUrl;
  final List<ContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverUrl.trim().isNotEmpty)
            UrlImage(
              url: coverUrl.trim(),
              height: 160,
              width: double.infinity,
              borderRadius: 12,
            ),
          if (coverUrl.trim().isNotEmpty) const SizedBox(height: 16),
          if (title.isNotEmpty)
            Text(title, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF1B4332))),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AdminColors.textDim)),
          ],
          const SizedBox(height: 20),
          ...blocks.where(_hasContent).map((b) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _previewBlock(b))),
        ],
      ),
    );
  }

  bool _hasContent(ContentBlock b) => switch (b.type) {
        ContentBlockType.divider => true,
        ContentBlockType.paragraph || ContentBlockType.quote || ContentBlockType.callout || ContentBlockType.heading => b.text.trim().isNotEmpty,
        ContentBlockType.tag => b.text.trim().isNotEmpty,
        ContentBlockType.image || ContentBlockType.video || ContentBlockType.audio => b.url.trim().isNotEmpty,
        ContentBlockType.list => b.items.any((i) => i.trim().isNotEmpty),
      };

  Widget _previewBlock(ContentBlock b) {
    return switch (b.type) {
      ContentBlockType.paragraph => () {
          final tag = ContentBlock.parseHashtagLine(b.text);
          if (tag != null) return _TagPreviewChip(tag: tag);
          return Text(b.text, style: GoogleFonts.inter(fontSize: 14, height: 1.75, color: const Color(0xFF4B5563)));
        }(),
      ContentBlockType.tag => _TagPreviewChip(tag: b),
      ContentBlockType.heading => Text(b.text, style: _previewHeadingStyle(b.level, b.accent)),
      ContentBlockType.callout => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BlockAccentStyle.backgroundFor(b.accent),
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: BlockAccentStyle.colorFor(BlockAccentStyle.variantColorKey(b.accent)), width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b.title.isNotEmpty) Text(b.title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
              if (b.title.isNotEmpty) const SizedBox(height: 6),
              Text(b.text, style: GoogleFonts.inter(fontSize: 14, height: 1.6)),
            ],
          ),
        ),
      ContentBlockType.image when b.url.isNotEmpty => Column(
          children: [
            UrlImage(url: b.url, borderRadius: 12),
            if (b.caption.isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 6), child: Text(b.caption, style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textDim, fontStyle: FontStyle.italic))),
          ],
        ),
      ContentBlockType.video when b.url.isNotEmpty => Column(
          children: [
            EmbeddedVideoPlayer(url: b.url),
            if (b.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(b.caption, style: GoogleFonts.inter(fontSize: 11, color: AdminColors.textDim, fontStyle: FontStyle.italic)),
              ),
          ],
        ),
      ContentBlockType.audio => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AdminColors.emeraldGlow, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.graphic_eq_rounded, color: AdminColors.emerald),
            const SizedBox(width: 10),
            Expanded(child: Text(b.title.isNotEmpty ? b.title : 'Sauti', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
          ]),
        ),
      ContentBlockType.quote => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminColors.emeraldGlow,
            borderRadius: BorderRadius.circular(10),
            border: const Border(left: BorderSide(color: AdminColors.emerald, width: 3)),
          ),
          child: Text(b.text, style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: const Color(0xFF1B4332))),
        ),
      ContentBlockType.divider => const Divider(),
      ContentBlockType.list => _ListPreview(items: b.items, listStyle: b.listStyle),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ListPreview extends StatelessWidget {
  const _ListPreview({required this.items, required this.listStyle});

  final List<String> items;
  final String listStyle;

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AdminColors.emeraldGlow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: visible.asMap().entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AdminColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    listStyle == 'numbered' ? '${e.key + 1}' : '•',
                    style: GoogleFonts.inter(
                      color: AdminColors.emerald,
                      fontWeight: FontWeight.w800,
                      fontSize: listStyle == 'numbered' ? 12 : 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: GoogleFonts.inter(fontSize: 14, height: 1.55, color: const Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
