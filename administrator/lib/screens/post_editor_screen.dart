import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/content_blocks.dart';
import '../models/content_sections.dart';
import '../theme/admin_colors.dart';
import '../utils/block_accent_style.dart';
import '../utils/content_tag_style.dart';
import '../widgets/embedded_video_player.dart';
import '../widgets/stable_text_field.dart';

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
  bool _isPublished = true;
  bool _preview = false;
  bool _metaExpanded = false;
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

    return {
      'section': widget.section,
      'category': _category,
      'title': _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim(),
      'excerpt': excerpt.length > 160 ? '${excerpt.substring(0, 157)}...' : excerpt,
      'content': body.toJsonString(),
      'imageUrl': _coverCtrl.text.trim(),
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

  void _insertBlockAfter(int index, ContentBlock block) {
    setState(() => _blocks.insert(index + 1, block));
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
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AdminColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existing == null ? 'Makala Mpya' : 'Hariri Makala',
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _preview = !_preview),
            icon: Icon(_preview ? Icons.edit_rounded : Icons.visibility_rounded, size: 18, color: AdminColors.emerald),
            label: Text(
              _preview ? 'Hariri' : 'Onyesho',
              style: GoogleFonts.inter(color: AdminColors.emerald, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _titleValid ? () => Navigator.pop(context, buildPayload()) : null,
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.emerald,
              disabledBackgroundColor: AdminColors.cardBorder,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Text('Hifadhi', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _buildMetaSection(),
                const SizedBox(height: 20),
                if (_preview)
                  _PreviewCard(
                    title: _titleCtrl.text,
                    subtitle: _subtitleCtrl.text,
                    coverUrl: _coverCtrl.text,
                    blocks: _blocks,
                  )
                else
                  _buildBlockEditor(),
              ],
            ),
          ),
          if (!_preview) _buildAddToolbar(),
        ],
      ),
    );
  }

  Widget _buildMetaSection() {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _metaExpanded = !_metaExpanded),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, color: AdminColors.emerald, size: 18),
                    const SizedBox(width: 10),
                    Text('Maelezo ya Makala', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(_metaExpanded ? Icons.expand_less : Icons.expand_more, color: AdminColors.textDim),
                  ],
                ),
              ),
            ),
          ),
          if (_metaExpanded) ...[
            const Divider(height: 1, color: AdminColors.cardBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _categoryOptions.contains(_category) ? _category : _categoryOptions.first,
                    dropdownColor: AdminColors.surface,
                    decoration: _inputDeco('Kategoria'),
                    items: _categoryOptions
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              AdminContentSections.categoryLabel(c, section: widget.section),
                              style: GoogleFonts.inter(color: AdminColors.textPrimary),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    style: GoogleFonts.inter(color: AdminColors.textPrimary),
                    decoration: _inputDeco('Kichwa cha makala *', hint: 'Mfano: Faida za Moringa'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subtitleCtrl,
                    style: GoogleFonts.inter(color: AdminColors.textPrimary),
                    decoration: _inputDeco('Maneno ya chini', hint: 'Mfano: Matumizi ya kila siku'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _excerptCtrl,
                    maxLines: 2,
                    style: GoogleFonts.inter(color: AdminColors.textPrimary),
                    decoration: _inputDeco('Muhtasari (hiari)', hint: 'Muhtasari mfupi wa makala...'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _coverCtrl,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.url,
                    style: GoogleFonts.inter(color: AdminColors.textPrimary),
                    decoration: _inputDeco(
                      'URL ya picha ya jalada (i.ibb.co/... au i.postimg.cc/...)',
                      hint: 'https://i.ibb.co/...',
                    ),
                  ),
                  if (_coverCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: _coverCtrl.text.trim(),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: AdminColors.textPrimary),
                    decoration: _inputDeco('Bei (TZS)', hint: '2000'),
                  ),
                  _ToggleRow(
                    title: 'Premium',
                    value: _isPremium,
                    onChanged: (v) => setState(() => _isPremium = v),
                  ),
                  _ToggleRow(
                    title: 'Chapisha mara moja',
                    value: _isPublished,
                    onChanged: (v) => setState(() => _isPublished = v),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlockEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Maudhui ya Makala',
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Ongeza aya, vichwa vya rangi, picha, video na ujumbe — buruta kupanga upya',
          style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
        ),
        const SizedBox(height: 14),
        _threadInsertBar(-1),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: _moveBlock,
          itemCount: _blocks.length,
          itemBuilder: (ctx, i) {
            final block = _blocks[i];
            return Column(
              key: ValueKey(block.id),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BlockEditorCard(
                  index: i,
                  block: block,
                  onChanged: (b) => _updateBlock(i, b),
                  onDelete: () => _removeBlock(i),
                ),
                _threadInsertBar(i),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _threadInsertBar(int afterIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          _insertBtn(Icons.notes_outlined, 'Aya', () => _insertBlockAfter(afterIndex, ContentBlock.paragraph(''))),
          _insertBtn(Icons.title_rounded, 'Kichwa', () => _insertBlockAfter(afterIndex, ContentBlock.heading('', level: 2))),
          _insertBtn(Icons.chat_bubble_outline_rounded, 'Ujumbe', () => _insertBlockAfter(afterIndex, ContentBlock.callout(''))),
          _insertBtn(Icons.image_outlined, 'Picha', () => _insertBlockAfter(afterIndex, ContentBlock(type: ContentBlockType.image))),
          _insertBtn(Icons.videocam_outlined, 'Video', () => _insertBlockAfter(afterIndex, ContentBlock(type: ContentBlockType.video))),
          _insertBtn(Icons.list_rounded, 'Orodha', () => _insertBlockAfter(afterIndex, ContentBlock.list())),
          _insertBtn(Icons.tag_rounded, 'Lebo', () => _insertBlockAfter(afterIndex, ContentBlock.tag(''))),
        ],
      ),
    );
  }

  Widget _insertBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(20),
          color: AdminColors.emeraldGlow.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AdminColors.emerald),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AdminColors.emerald, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToolbar() {
    final items = [
      (ContentBlock.paragraph(''), Icons.notes_rounded, 'Aya'),
      (ContentBlock.heading('', level: 1), Icons.looks_one_rounded, 'H1'),
      (ContentBlock.heading('', level: 2), Icons.title_rounded, 'H2'),
      (ContentBlock.callout(''), Icons.chat_bubble_outline_rounded, 'Ujumbe'),
      (ContentBlock(type: ContentBlockType.image), Icons.image_rounded, 'Picha'),
      (ContentBlock(type: ContentBlockType.video), Icons.videocam_rounded, 'Video'),
      (ContentBlock(type: ContentBlockType.audio), Icons.mic_rounded, 'Sauti'),
      (ContentBlock.tag(''), Icons.tag_rounded, 'Lebo'),
      (ContentBlock(type: ContentBlockType.quote), Icons.format_quote_rounded, 'Nukuu'),
      (ContentBlock.list(), Icons.list_rounded, 'Orodha'),
      (ContentBlock(type: ContentBlockType.divider), Icons.horizontal_rule_rounded, 'Mstari'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: Icon(item.$2, size: 16, color: AdminColors.emerald),
                  label: Text(item.$3, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: AdminColors.emeraldGlow,
                  side: BorderSide(color: AdminColors.emerald.withValues(alpha: 0.3)),
                  onPressed: () => _addBlock(item.$1),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AdminColors.textDim.withValues(alpha: 0.7), fontSize: 13),
        labelStyle: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 13),
        filled: true,
        fillColor: AdminColors.bg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.emerald)),
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 0),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_indicator_rounded, color: AdminColors.textDim, size: 20),
                ),
                const SizedBox(width: 6),
                Icon(_iconFor(b.type), size: 15, color: AdminColors.emerald),
                const SizedBox(width: 6),
                Text(_labelFor(b.type), style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11, fontWeight: FontWeight.w700)),
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
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: b.url.trim(),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 160,
                    color: AdminColors.card,
                    child: const Center(child: CircularProgressIndicator(color: AdminColors.emerald, strokeWidth: 2)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 100,
                    alignment: Alignment.center,
                    color: AdminColors.card,
                    child: Text('Picha haipatikani', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12)),
                  ),
                ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: coverUrl.trim(), height: 160, width: double.infinity, fit: BoxFit.cover),
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
            ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: b.url, fit: BoxFit.cover)),
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
