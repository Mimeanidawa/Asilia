import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  static const _tabs = ['All', 'Herbs', 'Conditions', 'Articles'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final items = provider.filteredContent;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AdminColors.bg,
            pinned: true,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '${items.length} items',
                        style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showAddSheet(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AdminColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AdminColors.emerald.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tabs.length,
                  itemBuilder: (_, idx) {
                    final tab = _tabs[idx];
                    final selected = provider.contentTabFilter == tab;
                    return GestureDetector(
                      onTap: () => provider.setContentTabFilter(tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AdminColors.emeraldGlow : AdminColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AdminColors.emerald : AdminColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          tab,
                          style: GoogleFonts.inter(
                            color: selected ? AdminColors.emerald : AdminColors.textDim,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: items.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            const Icon(Icons.article_rounded, color: AdminColors.textDim, size: 48),
                            const SizedBox(height: 12),
                            Text('No content here', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) => Animate(
                        delay: Duration(milliseconds: idx * 40),
                        effects: const [
                          FadeEffect(duration: Duration(milliseconds: 300)),
                          SlideEffect(begin: Offset(0, 0.05), end: Offset.zero, duration: Duration(milliseconds: 300)),
                        ],
                        child: _ContentCard(
                          item: items[idx],
                          onTogglePublish: () => provider.toggleContentPublished(items[idx].id),
                          onDelete: () => _confirmDelete(context, provider, items[idx]),
                        ),
                      ),
                      childCount: items.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminProvider provider, ContentItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Content?',
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '"${item.title}" will be permanently deleted.',
          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteContent(item.id);
              Navigator.pop(context);
            },
            child: Text('Delete', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _AddContentSheet(provider: provider),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.item,
    required this.onTogglePublish,
    required this.onDelete,
  });

  final ContentItem item;
  final VoidCallback onTogglePublish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(item.type);
    final typeIcon = _typeIcon(item.type);
    final typeLabel = _typeLabel(item.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: AdminColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                icon: const Icon(Icons.more_vert_rounded, color: AdminColors.textDim, size: 18),
                onSelected: (val) {
                  if (val == 'toggle') onTogglePublish();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          item.isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                          color: AdminColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.isPublished ? 'Unpublish' : 'Publish',
                          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16, color: AdminColors.error),
                        const SizedBox(width: 10),
                        Text('Delete', style: GoogleFonts.inter(color: AdminColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SmallBadge(label: typeLabel, color: typeColor),
              const SizedBox(width: 8),
              _SmallBadge(
                label: item.isPublished ? 'Published' : 'Draft',
                color: item.isPublished ? AdminColors.success : AdminColors.textDim,
              ),
              const Spacer(),
              const Icon(Icons.visibility_rounded, size: 11, color: AdminColors.textDim),
              const SizedBox(width: 3),
              Text(
                '${item.views}',
                style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('MMM d').format(item.createdAt),
                style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(ContentType t) {
    switch (t) {
      case ContentType.herb:
        return AdminColors.emerald;
      case ContentType.condition:
        return AdminColors.blue;
      case ContentType.article:
        return AdminColors.purple;
    }
  }

  IconData _typeIcon(ContentType t) {
    switch (t) {
      case ContentType.herb:
        return Icons.eco_rounded;
      case ContentType.condition:
        return Icons.medical_services_rounded;
      case ContentType.article:
        return Icons.article_rounded;
    }
  }

  String _typeLabel(ContentType t) {
    switch (t) {
      case ContentType.herb:
        return 'Herb';
      case ContentType.condition:
        return 'Condition';
      case ContentType.article:
        return 'Article';
    }
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---- Add Content Sheet ----

class _AddContentSheet extends StatefulWidget {
  const _AddContentSheet({required this.provider});
  final AdminProvider provider;

  @override
  State<_AddContentSheet> createState() => _AddContentSheetState();
}

class _AddContentSheetState extends State<_AddContentSheet> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  ContentType _type = ContentType.herb;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    widget.provider.addContentItem(
      ContentItem(
        id: 'c${DateTime.now().millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim().isEmpty ? _typeName(_type) : _subtitleCtrl.text.trim(),
        type: _type,
        createdAt: DateTime.now(),
        isPublished: false,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  String _typeName(ContentType t) {
    switch (t) {
      case ContentType.herb:
        return 'Herb · New Entry';
      case ContentType.condition:
        return 'Condition · New Entry';
      case ContentType.article:
        return 'Article · New Entry';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Content',
                style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: AdminColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Type', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: ContentType.values.map((t) {
              final selected = _type == t;
              final label = t == ContentType.herb ? 'Herb' : t == ContentType.condition ? 'Condition' : 'Article';
              final color = t == ContentType.herb ? AdminColors.emerald : t == ContentType.condition ? AdminColors.blue : AdminColors.purple;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AdminColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? color : AdminColors.cardBorder),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: selected ? color : AdminColors.textDim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('Title', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Content title...'),
          ),
          const SizedBox(height: 14),
          Text('Subtitle', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _subtitleCtrl,
            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Short description...'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text('Save Draft', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
