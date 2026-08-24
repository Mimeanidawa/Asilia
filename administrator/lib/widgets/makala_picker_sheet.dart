import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/content_sections.dart';
import '../theme/admin_colors.dart';
import 'url_image.dart';

class MakalaPickerSheet extends StatefulWidget {
  const MakalaPickerSheet({super.key, required this.articles});

  final List<Map<String, dynamic>> articles;

  @override
  State<MakalaPickerSheet> createState() => _MakalaPickerSheetState();
}

class _MakalaPickerSheetState extends State<MakalaPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.articles;
    return widget.articles.where((p) {
      final title = (p['title'] as String? ?? '').toLowerCase();
      final section = (p['section'] as String? ?? '').toLowerCase();
      final category = (p['category'] as String? ?? '').toLowerCase();
      return title.contains(q) ||
          section.contains(q) ||
          category.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AdminColors.textDim.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shiriki makala',
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chagua makala — mtumiaji ataona kiungo cha kusoma moja kwa moja.',
                      style: GoogleFonts.inter(
                        color: AdminColors.textDim,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: GoogleFonts.inter(color: AdminColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tafuta makala…',
                        hintStyle:
                            GoogleFonts.inter(color: AdminColors.textDim),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AdminColors.textDim, size: 20),
                        filled: true,
                        fillColor: AdminColors.card,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _query.isEmpty
                              ? 'Hakuna makala zilizochapishwa'
                              : 'Hakuna matokeo kwa "$_query"',
                          style: GoogleFonts.inter(color: AdminColors.textDim),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return _ArticleTile(
                            post: p,
                            onTap: () => Navigator.pop(context, p),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ArticleTile extends StatelessWidget {
  const _ArticleTile({required this.post, required this.onTap});

  final Map<String, dynamic> post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = post['title'] as String? ?? 'Makala';
    final imageUrl = post['imageUrl'] as String? ?? '';
    final section = post['section'] as String? ?? '';
    final category = post['category'] as String? ?? '';
    final sectionLabel = section.isEmpty
        ? ''
        : AdminContentSections.sectionLabel(section);
    final categoryLabel = category.isEmpty
        ? ''
        : AdminContentSections.categoryLabel(category, section: section);

    return Material(
      color: AdminColors.card,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imageUrl.isNotEmpty
                      ? UrlImage(url: imageUrl, borderRadius: 12)
                      : Container(
                          color: AdminColors.emerald.withValues(alpha: 0.12),
                          alignment: Alignment.center,
                          child: const Icon(Icons.article_outlined,
                              color: AdminColors.emerald),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionLabel.isNotEmpty || categoryLabel.isNotEmpty)
                      Text(
                        [sectionLabel, categoryLabel]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AdminColors.emerald,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            size: 13,
                            color: AdminColors.textDim.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'Tuma kiungo kwa mtumiaji',
                          style: GoogleFonts.inter(
                            color: AdminColors.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AdminColors.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
