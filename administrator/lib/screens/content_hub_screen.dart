import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/content_sections.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_ui.dart';
import '../widgets/url_image.dart';
import 'post_editor_screen.dart';

class ContentHubScreen extends StatefulWidget {
  const ContentHubScreen({super.key});

  @override
  State<ContentHubScreen> createState() => _ContentHubScreenState();
}

class _ContentHubScreenState extends State<ContentHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  List<Map<String, dynamic>> _carousels = [];
  List<Map<String, dynamic>> _posts = [];
  String _section = AdminContentSections.dodoso;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (mounted && !_tabs.indexIsChanging) setState(() {});
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<AdminProvider>();
    try {
      _carousels = await provider.contentService.fetchCarousels();
      _posts = await provider.contentService.fetchPosts(section: _section);
    } catch (e) {
      if (mounted) {
        _showMessage('Imeshindwa kupakia maudhui: ${_errorText(e)}', isError: true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : AdminColors.forest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        backgroundColor: AdminColors.card,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          AdminPageHeader(
            title: 'Maudhui',
            subtitle: 'Carousel & makala',
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Carousel'),
                Tab(text: 'Makala'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildCarousels(),
                _buildPosts(),
              ],
            ),
          ),
        ],
      ),
      ),
      // Parent shell uses extendBody + floating AdminBottomNav — lift FAB clear of it.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: AdminBottomNav.contentBottomInset(context, extra: 8),
        ),
        child: FloatingActionButton.extended(
          onPressed: () =>
              _tabs.index == 0 ? _showCarouselForm() : _showPostForm(),
          backgroundColor: AdminColors.emerald,
          foregroundColor: const Color(0xFF052E16),
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(_tabs.index == 0 ? 'Carousel' : 'Makala'),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3.5),
          ],
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
    String? label,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: selected ? AdminColors.emerald : AdminColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: AdminColors.card,
        selectedColor: AdminColors.emerald.withValues(alpha: 0.18),
        checkmarkColor: AdminColors.emerald,
        showCheckmark: selected,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? AdminColors.emerald.withValues(alpha: 0.5)
                : AdminColors.cardBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildCarousels() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AdminColors.emerald));
    final bottomPad = AdminBottomNav.contentBottomInset(context, extra: 96);
    if (_carousels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.view_carousel_rounded, size: 48, color: AdminColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Hakuna carousel iliyoongezwa bado.\nBonyeza + Carousel kuweka ya kwanza.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
      itemCount: _carousels.length,
      itemBuilder: (_, i) {
        final c = _carousels[i];
        final imgUrl = c['imageUrl'] as String? ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showCarouselForm(existing: c),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: AdminColors.surface,
                        child: imgUrl.isNotEmpty
                            ? UrlImage(url: imgUrl, borderRadius: 12, showBorder: true)
                            : Container(
                                color: AdminColors.emerald.withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: const Icon(Icons.view_carousel_rounded, color: AdminColors.emerald, size: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          if ((c['subtitle'] as String? ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              c['subtitle'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textDim,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: AdminColors.blue,
                      label: 'Hariri',
                      tooltip: 'Hariri',
                      onTap: () => _showCarouselForm(existing: c),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AdminColors.rose,
                      tooltip: 'Futa',
                      onTap: () => _deleteCarousel(c['id'] as String),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (i * 40).ms);
      },
    );
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_categoryFilter == null) return _posts;
    return _posts.where((p) => p['category'] == _categoryFilter).toList();
  }

  List<String> get _sectionCategories => AdminContentSections.categoriesFor(_section);

  Widget _buildPostCard(Map<String, dynamic> p, int index) {
    final cat = p['category'] as String? ?? '';
    final catLabel = cat.isEmpty
        ? '—'
        : AdminContentSections.categoryLabel(cat, section: _section);
    final isPublished = p['isPublished'] == true;
    final isPremium = p['isPremium'] == true;
    final priceVal = p['price'];
    final price = priceVal is num ? priceVal : num.tryParse(priceVal?.toString() ?? '') ?? 0;
    final title = p['title'] as String? ?? 'Makala';
    final imageUrl = p['imageUrl'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPostForm(existing: p),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section: Image + Expanded Title & Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 58,
                        height: 58,
                        color: AdminColors.surface,
                        child: imageUrl.isNotEmpty
                            ? UrlImage(
                                url: imageUrl,
                                borderRadius: 12,
                                showBorder: true,
                              )
                            : Container(
                                color: AdminColors.emerald.withValues(alpha: 0.12),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: AdminColors.emerald,
                                  size: 26,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 5,
                            children: [
                              _buildBadge(catLabel, AdminColors.emerald, icon: Icons.folder_open_rounded),
                              if (isPremium)
                                _buildBadge(
                                  TzsFormat.full(price),
                                  AdminColors.amber,
                                  icon: Icons.workspace_premium_rounded,
                                )
                              else
                                _buildBadge('BURE', AdminColors.blue, icon: Icons.check_circle_outline_rounded),
                              _buildBadge(
                                isPublished ? 'Imechapishwa' : 'Rasimu',
                                isPublished ? AdminColors.success : AdminColors.textMuted,
                                icon: isPublished ? Icons.public_rounded : Icons.edit_note_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(color: AdminColors.divider, height: 1),
                const SizedBox(height: 8),

                // Bottom row: Visibility status indicator + Action buttons
                Row(
                  children: [
                    // Status dot & text
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPublished ? AdminColors.emerald : AdminColors.textDim,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              isPublished ? 'Inaonekana kwa watumiaji' : 'Imefichwa (Rasimu)',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textDim,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions
                    if (isPublished) ...[
                      _buildActionButton(
                        icon: Icons.send_rounded,
                        color: AdminColors.emerald,
                        label: 'Tuma',
                        tooltip: 'Tuma taarifa kwa watumiaji',
                        onTap: () => _sharePost(p),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildActionButton(
                      icon: isPublished ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: isPublished ? AdminColors.textDim : AdminColors.emerald,
                      label: isPublished ? 'Ficha' : 'Onyesha',
                      tooltip: isPublished ? 'Ficha makala' : 'Chapisha makala',
                      onTap: () => _togglePublish(p['id'] as String),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      color: AdminColors.blue,
                      label: 'Hariri',
                      tooltip: 'Hariri makala',
                      onTap: () => _showPostForm(existing: p),
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AdminColors.rose,
                      tooltip: 'Futa makala',
                      onTap: () => _deletePost(p['id'] as String),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 30).ms);
  }

  Widget _buildPosts() {
    final categories = _sectionCategories;
    final visible = _filteredPosts;
    return Column(
      children: [
        // Section selector chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: AdminContentSections.sections.map((s) {
              final sel = _section == s.$1;
              return _buildFilterChip(
                label: s.$2,
                selected: sel,
                onSelected: (_) async {
                  setState(() {
                    _section = s.$1;
                    _categoryFilter = null;
                    _loading = true;
                  });
                  try {
                    _posts = await context.read<AdminProvider>().contentService.fetchPosts(section: _section);
                  } catch (e) {
                    if (mounted) _showMessage('Imeshindwa kupakia makala: ${_errorText(e)}', isError: true);
                  }
                  if (mounted) setState(() => _loading = false);
                },
              );
            }).toList(),
          ),
        ),
        // Sub-category filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            children: [
              _buildFilterChip(
                label: 'Zote (${_posts.length})',
                selected: _categoryFilter == null,
                onSelected: (_) => setState(() => _categoryFilter = null),
              ),
              ...categories.map((cat) {
                final count = _posts.where((p) => p['category'] == cat).length;
                final sel = _categoryFilter == cat;
                return _buildFilterChip(
                  label: '${AdminContentSections.categoryLabel(cat, section: _section)} ($count)',
                  selected: sel,
                  onSelected: (_) => setState(() => _categoryFilter = sel ? null : cat),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AdminColors.emerald))
              : visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _categoryFilter == null
                              ? 'Hakuna makala katika sehemu hii.\nBonyeza + Makala kuongeza.'
                              : 'Hakuna makala katika Aina hii bado.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        10,
                        16,
                        AdminBottomNav.contentBottomInset(context, extra: 96),
                      ),
                      itemCount: visible.length,
                      itemBuilder: (_, i) => _buildPostCard(visible[i], i),
                    ),
        ),
      ],
    );
  }

  Future<void> _showCarouselForm({Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title'] as String? ?? '');
    final subCtrl = TextEditingController(text: existing?['subtitle'] as String? ?? '');
    final imgCtrl = TextEditingController(text: existing?['imageUrl'] as String? ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Carousel (Kiswahili)', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            _field(titleCtrl, 'Kichwa', hint: 'Mfano: Tiba ya Asili'),
            _field(subCtrl, 'Maneno ya chini', hint: 'Maelezo mafupi ya carousel'),
            _field(imgCtrl, 'URL ya Picha', keyboard: TextInputType.url, hint: 'https://mfano.com/picha.jpg'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(ctx);
                final nav = Navigator.of(ctx);
                try {
                  final body = {
                    'title': titleCtrl.text.trim(),
                    'subtitle': subCtrl.text.trim(),
                    'imageUrl': imgCtrl.text.trim(),
                    'isPublished': true,
                  };
                  if (body['title'] == '') {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Kichwa kinahitajika', style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  final svc = context.read<AdminProvider>().contentService;
                  if (existing != null) {
                    await svc.updateCarousel(existing['id'] as String, body);
                  } else {
                    await svc.createCarousel(body);
                  }
                  nav.pop();
                  await _load();
                  if (mounted) _showMessage('Carousel imehifadhiwa');
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Imeshindwa kuhifadhi: ${_errorText(e)}', style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.emerald, minimumSize: const Size(double.infinity, 48)),
              child: const Text('Hifadhi'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPostForm({Map<String, dynamic>? existing}) async {
    final categories = AdminContentSections.categoriesFor(_section);
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditorScreen(
          section: _section,
          categories: categories,
          existing: existing,
        ),
      ),
    );
    if (result == null || !mounted) return;

    try {
      final svc = context.read<AdminProvider>().contentService;
      if (existing != null) {
        await svc.updatePost(existing['id'] as String, result);
        _showMessage('Makala imesasishwa');
      } else {
        await svc.createPost(result);
        _showMessage('Makala imehifadhiwa');
      }
      await _load();
    } catch (e) {
      _showMessage('Imeshindwa kuhifadhi makala: ${_errorText(e)}', isError: true);
    }
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1, TextInputType keyboard = TextInputType.text, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: GoogleFonts.inter(color: AdminColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.inter(color: AdminColors.textDim),
          hintStyle: GoogleFonts.inter(color: AdminColors.textDim.withValues(alpha: 0.7), fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _deleteCarousel(String id) async {
    try {
      await context.read<AdminProvider>().contentService.deleteCarousel(id);
      await _load();
      _showMessage('Carousel imefutwa');
    } catch (e) {
      _showMessage('Imeshindwa kufuta: ${_errorText(e)}', isError: true);
    }
  }

  Future<void> _deletePost(String id) async {
    try {
      await context.read<AdminProvider>().contentService.deletePost(id);
      await _load();
      _showMessage('Makala imefutwa');
    } catch (e) {
      _showMessage('Imeshindwa kufuta: ${_errorText(e)}', isError: true);
    }
  }

  Future<void> _togglePublish(String id) async {
    try {
      await context.read<AdminProvider>().contentService.togglePublishPost(id);
      await _load();
    } catch (e) {
      _showMessage('Imeshindwa kubadilisha hali: ${_errorText(e)}', isError: true);
    }
  }

  Future<void> _sharePost(Map<String, dynamic> post) async {
    final title = post['title'] as String? ?? 'Makala';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Text('Tuma makala?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Watumiaji watapokea taarifa ya "$title" na wataweza kubofya kuisoma.',
          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ghairi', style: GoogleFonts.inter(color: AdminColors.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Tuma', style: GoogleFonts.inter(color: AdminColors.emerald, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<AdminProvider>();
    try {
      final result = await provider.contentService.sharePost(
        post['id'] as String,
        title: title,
        body: (post['excerpt'] as String?)?.trim().isNotEmpty == true
            ? post['excerpt'] as String
            : 'Gusa kusoma makala kamili',
      );
      final notification = result['notification'] as Map<String, dynamic>?;
      final sent = notification?['sent'] == true || notification?['status'] == 'sent';
      if (!mounted) return;
      _showMessage(
        sent
            ? 'Makala imetumwa. Watumiaji wanaweza kubofya kuisoma.'
            : 'Imehifadhiwa. Hakikisha Firebase imeunganishwa kwenye server.',
        isError: !sent,
      );
      await provider.refreshNotifications();
    } catch (e) {
      _showMessage('Imeshindwa kutuma: ${_errorText(e)}', isError: true);
    }
  }
}
