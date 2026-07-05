import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/pull_to_refresh.dart';

class AskExpertScreen extends StatefulWidget {
  const AskExpertScreen({super.key});

  @override
  State<AskExpertScreen> createState() => _AskExpertScreenState();
}

class _AskExpertScreenState extends State<AskExpertScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  Future<void> _initChat() async {
    final user = context.read<UserService>();
    final mwalimu = context.read<MwalimuService>();
    await mwalimu.loadSettings();
    if (user.token != null) {
      await mwalimu.loadMessages(user.token);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _refresh() async {
    await AppRefresh.mwalimu(context);
  }

  Future<void> _send() async {
    final user = context.read<UserService>();
    if (!user.isLoggedIn) {
      context.read<AppProvider>().navigate(AppScreen.auth);
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final mwalimu = context.read<MwalimuService>();
    if (!mwalimu.canSendMessage()) {
      _showPremiumDialog();
      return;
    }

    _controller.clear();
    await mwalimu.sendMessage(text, user.token!);
    _scrollToBottom();
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kikomo cha Maswali', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          'Umefikia kikomo cha maswali 5 kwa watumiaji wa bure. Lipia Premium ili kuendelea kujifunza bila kikomo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Funga')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserService>().purchasePremium();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest),
            child: const Text('Lipia Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mwalimu = context.watch<MwalimuService>();
    final user = context.watch<UserService>();
    final settings = mwalimu.settings;

    _scrollToBottom();

    return SizedBox.expand(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.school_rounded, color: AppColors.emerald800, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ULIZA MWALIMU',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.forest),
                ),
                const Spacer(),
                if (!user.isLoggedIn)
                  TextButton(
                    onPressed: () => context.read<AppProvider>().navigate(AppScreen.auth),
                    child: const Text('Ingia', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white, AppColors.cream]),
              border: Border(bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.03))),
            ),
            child: Row(
              children: [
                if (settings.mwalimuImage.isNotEmpty)
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: CachedNetworkImageProvider(settings.mwalimuImage),
                  )
                else
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.emerald50,
                    child: Icon(Icons.school, color: AppColors.forest),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.mwalimuName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest),
                      ),
                      Text(
                        'Mtaalamu wa Elimu ya Mimea na Asili',
                        style: TextStyle(fontSize: 11, color: AppColors.gray500),
                      ),
                      if (!mwalimu.isPremium && user.isLoggedIn && mwalimu.remainingMessages >= 0)
                        Text(
                          'Maswali ${mwalimu.remainingMessages} yamesalia',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amber),
                        ),
                    ],
                  ),
                ),
                if (user.isPremiumActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('PREMIUM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.amber)),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppColors.emerald50.withValues(alpha: 0.4),
            child: Text(
              'Kwa elimu tu — si ushauri wa kimatibabu. Jifunze kuhusu mizizi, miti na matunda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.gray500, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: PullToRefresh(
              onRefresh: _refresh,
              child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _Bubble(
                  isUser: false,
                  content: settings.mwalimuWelcome,
                  avatarUrl: settings.mwalimuImage,
                ),
                ...mwalimu.messages.map((m) => _Bubble(
                      isUser: m.isUser,
                      content: m.content,
                      avatarUrl: m.isAdmin ? settings.mwalimuImage : null,
                    )),
                if (mwalimu.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forest)),
                  ),
              ],
            ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: user.isLoggedIn ? 'Uliza kuhusu mimea, mizizi, miti...' : 'Ingia ili kuuliza...',
                      filled: true,
                      fillColor: AppColors.emerald50.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.forest,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _send,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.isUser, required this.content, this.avatarUrl});

  final bool isUser;
  final String content;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser && avatarUrl != null && avatarUrl!.isNotEmpty)
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(avatarUrl!),
            ),
          if (!isUser && (avatarUrl == null || avatarUrl!.isEmpty))
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.emerald50,
              child: Icon(Icons.school, size: 16, color: AppColors.forest),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.forest : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 13,
                  color: isUser ? Colors.white : AppColors.gray600,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

extension on UserService {
  bool get isPremiumActive => user?.isPremiumActive ?? false;
}
