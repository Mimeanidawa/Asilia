import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
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
  String _section = 'dodoso';

  static const _sections = [
    ('dodoso', 'Dodoso'),
    ('chagua_mada', 'Chagua Mada'),
    ('vyakula_matunda', 'Vyakula na Matunda'),
    ('jifunze', 'Jifunze'),
  ];

  static const _categories = {
    'dodoso': ['mizizi', 'miti', 'matunda', 'mimea'],
    'chagua_mada': ['mimea', 'wanawake', 'watoto', 'wanaume'],
    'jifunze': ['matunda', 'mizizi', 'miti', 'mimea', 'vyakula'],
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
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
      backgroundColor: AdminColors.bg,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            backgroundColor: AdminColors.bg,
            pinned: true,
            toolbarHeight: 72,
            title: Text('Maudhui', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AdminColors.emerald,
              labelColor: AdminColors.emerald,
              unselectedLabelColor: AdminColors.textDim,
              tabs: const [Tab(text: 'Carousel'), Tab(text: 'Makala')],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabs.index == 0 ? _showCarouselForm() : _showPostForm(),
        backgroundColor: AdminColors.emerald,
        icon: const Icon(Icons.add),
        label: Text(_tabs.index == 0 ? 'Carousel' : 'Makala'),
      ),
    );
  }

  Widget _buildCarousels() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AdminColors.emerald));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _carousels.length,
      itemBuilder: (_, i) {
        final c = _carousels[i];
        return Card(
          color: AdminColors.surface,
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              title: Text(c['title'] as String, style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(c['subtitle'] as String? ?? '', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, color: AdminColors.emerald, size: 18), onPressed: () => _showCarouselForm(existing: c)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteCarousel(c['id'] as String)),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (i * 50).ms);
      },
    );
  }

  Widget _buildPosts() {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _sections.map((s) {
              final sel = _section == s.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s.$2),
                  selected: sel,
                  onSelected: (_) async {
                    setState(() => _section = s.$1);
                    try {
                      _posts = await context.read<AdminProvider>().contentService.fetchPosts(section: _section);
                    } catch (e) {
                      if (mounted) _showMessage('Imeshindwa kupakia makala: ${_errorText(e)}', isError: true);
                    }
                    if (mounted) setState(() {});
                  },
                  selectedColor: AdminColors.emerald.withOpacity(0.2),
                  checkmarkColor: AdminColors.emerald,
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AdminColors.emerald))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (_, i) {
                    final p = _posts[i];
                    return Card(
                      color: AdminColors.surface,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          title: Text(p['title'] as String, style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${p['category'] ?? ''} ${p['isPremium'] == true ? '• PREMIUM TZS ${p['price']}' : ''} ${p['isPublished'] == true ? '• Published' : '• Draft'}',
                            style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(p['isPublished'] == true ? Icons.visibility : Icons.visibility_off, color: AdminColors.emerald, size: 18),
                                onPressed: () => _togglePublish(p['id'] as String),
                              ),
                              IconButton(icon: const Icon(Icons.edit, color: AdminColors.emerald, size: 18), onPressed: () => _showPostForm(existing: p)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deletePost(p['id'] as String)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
    final categories = _categories[_section] ?? ['general'];
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
}
