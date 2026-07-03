import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/daily_lesson.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class DarasaHuruAdminScreen extends StatelessWidget {
  const DarasaHuruAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final lessons = provider.lessons;

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
                        'Darasa Huru',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Chapisha somo la kila siku',
                        style: GoogleFonts.inter(
                          color: AdminColors.textDim,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => provider.refreshLessons(),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AdminColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AdminColors.cardBorder),
                          ),
                          child: provider.lessonsLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AdminColors.emerald,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  color: AdminColors.textDim,
                                  size: 16,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showComposeSheet(context, provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
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
                              const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Somo Jipya',
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
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: lessons.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: AdminColors.textDim,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hakuna masomo bado',
                              style: GoogleFonts.inter(
                                color: AdminColors.textDim,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bofya "Somo Jipya" kuongeza darasa la leo',
                              style: GoogleFonts.inter(
                                color: AdminColors.textDim,
                                fontSize: 12,
                              ),
                            ),
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
                          SlideEffect(
                            begin: Offset(0, 0.05),
                            end: Offset.zero,
                            duration: Duration(milliseconds: 300),
                          ),
                        ],
                        child: _LessonCard(
                          lesson: lessons[idx],
                          onToggle: () =>
                              provider.toggleLessonPublished(lessons[idx].id),
                          onEdit: () => _showComposeSheet(
                            context,
                            provider,
                            existing: lessons[idx],
                          ),
                          onDelete: () =>
                              _confirmDelete(context, provider, lessons[idx]),
                        ),
                      ),
                      childCount: lessons.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AdminProvider provider,
    DailyLesson lesson,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Futa Somo?',
          style: GoogleFonts.inter(
            color: AdminColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"${lesson.title}" itafutwa kabisa.',
          style: GoogleFonts.inter(
            color: AdminColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ghairi',
              style: GoogleFonts.inter(color: AdminColors.textDim),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.deleteLesson(lesson.id);
              Navigator.pop(context);
            },
            child: Text(
              'Futa',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showComposeSheet(
    BuildContext context,
    AdminProvider provider, {
    DailyLesson? existing,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _ComposeLessonSheet(
        provider: provider,
        existing: existing,
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final DailyLesson lesson;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lesson.isToday && lesson.isPublished
              ? AdminColors.emerald.withOpacity(0.4)
              : AdminColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Image.network(
                lesson.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: AdminColors.surface,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: AdminColors.textDim,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (lesson.isToday)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'LEO',
                          style: GoogleFonts.inter(
                            color: AdminColors.amber,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    if (lesson.topicTag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.emerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lesson.topicTag!,
                          style: GoogleFonts.inter(
                            color: AdminColors.emerald,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      color: AdminColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AdminColors.textDim,
                        size: 18,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') onEdit();
                        if (val == 'toggle') onToggle();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        _menuItem('edit', Icons.edit_rounded, 'Hariri'),
                        _menuItem(
                          'toggle',
                          lesson.isPublished
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          lesson.isPublished ? 'Ficha' : 'Chapisha',
                        ),
                        _menuItem(
                          'delete',
                          Icons.delete_outline_rounded,
                          'Futa',
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.title,
                  style: GoogleFonts.inter(
                    color: AdminColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AdminColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _badge(
                      lesson.isPublished ? 'Published' : 'Draft',
                      lesson.isPublished
                          ? AdminColors.success
                          : AdminColors.textDim,
                    ),
                    const SizedBox(width: 8),
                    _badge(
                      '${lesson.readTimeMinutes} min',
                      AdminColors.blue,
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(lesson.publishedAt),
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
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String label, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AdminColors.error : AdminColors.textSecondary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ComposeLessonSheet extends StatefulWidget {
  const _ComposeLessonSheet({required this.provider, this.existing});

  final AdminProvider provider;
  final DailyLesson? existing;

  @override
  State<_ComposeLessonSheet> createState() => _ComposeLessonSheetState();
}

class _ComposeLessonSheetState extends State<_ComposeLessonSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _excerptCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _tagCtrl;
  late DateTime _publishDate;
  late int _readTime;
  bool _publishNow = false;
  bool _saving = false;

  static const _tags = ['Herbs', 'Remedies', 'Nutrition', 'Wellness', 'Health Tips'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _excerptCtrl = TextEditingController(text: e?.excerpt ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _imageCtrl = TextEditingController(
      text: e?.imageUrl ??
          'https://images.unsplash.com/photo-1505577058444-a3dab90d4253?w=800&q=80',
    );
    _tagCtrl = TextEditingController(text: e?.topicTag ?? 'Herbs');
    _publishDate = e?.publishedAt ?? DateTime.now();
    _readTime = e?.readTimeMinutes ?? 4;
    _publishNow = e?.isPublished ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _excerptCtrl.dispose();
    _contentCtrl.dispose();
    _imageCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);

    final normalized = DateTime(
      _publishDate.year,
      _publishDate.month,
      _publishDate.day,
    );

    final lesson = DailyLesson(
      id: widget.existing?.id ?? 'dh-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      excerpt: _excerptCtrl.text.trim().isEmpty
          ? _contentCtrl.text.trim().substring(
              0,
              _contentCtrl.text.trim().length.clamp(0, 120),
            )
          : _excerptCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim(),
      publishedAt: normalized,
      authorName: 'Dr. Mussa Hassan',
      readTimeMinutes: _readTime,
      topicTag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
      isPublished: _publishNow,
    );

    if (widget.existing != null) {
      await widget.provider.updateLesson(lesson);
    } else {
      await widget.provider.addLesson(lesson);
    }

    if (mounted) {
      Navigator.pop(context);
      final msg = widget.provider.lastPushNotification;
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.inter()),
            backgroundColor: AdminColors.emerald,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? 'Hariri Somo' : 'Somo Jipya',
                  style: GoogleFonts.inter(
                    color: AdminColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AdminColors.textDim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Kichwa cha Somo'),
            _field(_titleCtrl, 'Mfano: Mwarobaini — Nguvu ya Asili'),
            _label('Muhtasari'),
            _field(
              _excerptCtrl,
              'Sentensi 1-2 zinazovutia...',
              maxLines: 2,
            ),
            _label('Maudhui ya Somo'),
            _field(
              _contentCtrl,
              'Andika somo kamili hapa...',
              maxLines: 6,
            ),
            _label('Picha (URL)'),
            _field(_imageCtrl, 'https://...'),
            const SizedBox(height: 12),
            _label('Kategoria'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final selected = _tagCtrl.text == tag;
                return GestureDetector(
                  onTap: () => setState(() => _tagCtrl.text = tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminColors.emerald.withOpacity(0.2)
                          : AdminColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? AdminColors.emerald
                            : AdminColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        color: selected
                            ? AdminColors.emerald
                            : AdminColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tarehe ya Kuchapisha'),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _publishDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() => _publishDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AdminColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AdminColors.emerald,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, yyyy').format(_publishDate),
                                style: GoogleFonts.inter(
                                  color: AdminColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Muda wa Kusoma (dak)'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AdminColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.cardBorder),
                        ),
                        child: DropdownButton<int>(
                          value: _readTime,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          dropdownColor: AdminColors.surface,
                          style: GoogleFonts.inter(
                            color: AdminColors.textPrimary,
                            fontSize: 13,
                          ),
                          items: [3, 4, 5, 6, 8, 10].map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text('$m min'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _readTime = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Chapisha mara moja',
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Somo litaonekana kwenye app ya watumiaji',
                style: GoogleFonts.inter(
                  color: AdminColors.textDim,
                  fontSize: 11,
                ),
              ),
              value: _publishNow,
              activeThumbColor: AdminColors.emerald,
              onChanged: (v) => setState(() => _publishNow = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.existing != null ? 'Hifadhi Mabadiliko' : 'Chapisha Somo',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: AdminColors.textDim,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}
