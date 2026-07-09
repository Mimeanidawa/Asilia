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
import '../services/payment_service.dart';
import '../widgets/sonicpesa_payment_sheet.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/screen_header.dart';

class AskExpertScreen extends StatefulWidget {
  const AskExpertScreen({super.key});

  @override
  State<AskExpertScreen> createState() => _AskExpertScreenState();
}

class _AskExpertScreenState extends State<AskExpertScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  MwalimuService? _mwalimuService;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mwalimuService ??= context.read<MwalimuService>();
  }

  Future<void> _initChat() async {
    final user = context.read<UserService>();
    final mwalimu = _mwalimuService ?? context.read<MwalimuService>();
    mwalimu.setChatOpen(true);
    await mwalimu.loadSettings();
    await mwalimu.loadGuestState();
    if (user.token != null) {
      await mwalimu.flushGuestMessagesToServer(user.token!);
      await mwalimu.loadMessages(user.token);
    } else {
      await mwalimu.loadGuestMessages();
    }
  }

  @override
  void dispose() {
    _mwalimuService?.setChatOpen(false);
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
    final mwalimu = context.read<MwalimuService>();
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (!user.isLoggedIn) {
      if (!mwalimu.canSendAsGuest()) {
        _showSignupRequiredDialog();
        return;
      }
      _controller.clear();
      final ok = await mwalimu.sendGuestMessage(text);
      if (!ok && mounted) {
        if (!mwalimu.canSendAsGuest()) {
          _showSignupRequiredDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mwalimu.error ?? 'Imeshindwa kutuma ujumbe'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }
      _scrollToBottom();
      return;
    }

    if (!mwalimu.canSendMessage()) {
      _showPremiumDialog();
      return;
    }

    _controller.clear();
    final ok = await mwalimu.sendMessage(text, user.token!);
    if (!ok && mounted && !mwalimu.canSendMessage()) {
      _showPremiumDialog();
      return;
    }
    _scrollToBottom();
  }

  void _showSignupRequiredDialog() {
    final limit = context.read<MwalimuService>().settings.freeMessageLimit;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingia ili uendelee', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          'Umefikia kikomo cha maswali $limit bila kujiandikisha. Jisajili au ingia ili kuendelea kuwasiliana na Mwalimu.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Baadaye')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppProvider>().navigate(AppScreen.auth);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest),
            child: const Text('Jisajili / Ingia'),
          ),
        ],
      ),
    );
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
            onPressed: () async {
              Navigator.pop(ctx);
              final mwalimu = context.read<MwalimuService>();
              final result = await showSonicPesaPayment(
                context,
                type: PaymentType.premium,
                title: 'Premium — Dawa Asili',
                subtitle: 'Uliza Mwalimu bila kikomo kwa siku 30',
                amount: mwalimu.settings.premiumPrice,
              );
              if (result == SonicPesaPaymentResult.success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium imeamilishwa!'),
                    backgroundColor: AppColors.forest,
                  ),
                );
              }
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
    final chatMessages = user.isLoggedIn ? mwalimu.messages : mwalimu.guestMessages;
    final guestLimitReached = !user.isLoggedIn && !mwalimu.canSendAsGuest();

    if (chatMessages.length != _lastMessageCount) {
      _lastMessageCount = chatMessages.length;
      _scrollToBottom();
    }

    return SizedBox.expand(
      child: Column(
        children: [
          ScreenHeader(
            title: 'ULIZA MWALIMU',
            onBack: () => context.read<AppProvider>().goBack(),
            trailing: !user.isLoggedIn
                ? TextButton(
                    onPressed: () => context.read<AppProvider>().navigate(AppScreen.auth),
                    child: const Text('Ingia', style: TextStyle(fontWeight: FontWeight.w800)),
                  )
                : null,
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
                        mwalimu.displayName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest),
                      ),
                      Text(
                        'Mtaalamu wa Elimu ya Mimea na Asili',
                        style: TextStyle(fontSize: 11, color: AppColors.gray500),
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
                ...chatMessages.map((m) => _Bubble(
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
          if (guestLimitReached)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.amber.withValues(alpha: 0.12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jisajili au ingia ili uendelee kuwasiliana na Mwalimu.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<AppProvider>().navigate(AppScreen.auth),
                    child: const Text('Ingia', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
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
                    enabled: !guestLimitReached,
                    decoration: InputDecoration(
                      hintText: guestLimitReached
                          ? 'Jisajili ili uendelee kuuliza...'
                          : user.isLoggedIn
                              ? 'Uliza kuhusu mimea, mizizi, miti...'
                              : 'Uliza Hapa...',
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
                  color: guestLimitReached ? AppColors.gray400 : AppColors.forest,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: guestLimitReached ? _showSignupRequiredDialog : _send,
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
    final parts = !isUser ? _SharedArticleTagParser.parse(content) : const <_MessagePart>[];

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
              child: _buildContent(context, parts),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildContent(BuildContext context, List<_MessagePart> parts) {
    final textStyle = TextStyle(
      fontSize: 13,
      color: isUser ? Colors.white : AppColors.gray600,
      height: 1.45,
    );

    if (isUser || parts.isEmpty) {
      return Text(content, style: textStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (parts[i] is _TextPart && (parts[i] as _TextPart).text.trim().isNotEmpty)
            Text((parts[i] as _TextPart).text, style: textStyle),
          if (parts[i] is _ArticlePart)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _SharedArticleCard(part: parts[i] as _ArticlePart),
            ),
        ],
      ],
    );
  }
}

extension on UserService {
  bool get isPremiumActive => user?.isPremiumActive ?? false;
}

sealed class _MessagePart {
  const _MessagePart();
}

class _TextPart extends _MessagePart {
  const _TextPart(this.text);
  final String text;
}

class _ArticlePart extends _MessagePart {
  const _ArticlePart({required this.id, required this.title});
  final String id;
  final String title;
}

class _SharedArticleTagParser {
  static final RegExp _pattern = RegExp(r'\[MAKALA:([^|\]]+)\|([^\]]+)\]');

  static List<_MessagePart> parse(String input) {
    final parts = <_MessagePart>[];
    var cursor = 0;
    for (final m in _pattern.allMatches(input)) {
      if (m.start > cursor) {
        parts.add(_TextPart(input.substring(cursor, m.start)));
      }
      final id = (m.group(1) ?? '').trim();
      final title = (m.group(2) ?? 'Makala').trim();
      if (id.isNotEmpty) {
        parts.add(_ArticlePart(id: id, title: title));
      }
      cursor = m.end;
    }
    if (cursor < input.length) {
      parts.add(_TextPart(input.substring(cursor)));
    }
    return parts;
  }
}

class _SharedArticleCard extends StatelessWidget {
  const _SharedArticleCard({required this.part});

  final _ArticlePart part;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.emerald50.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context
            .read<AppProvider>()
            .navigate(AppScreen.contentDetail, contentId: part.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  part.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Soma',
                style: TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.forest),
            ],
          ),
        ),
      ),
    );
  }
}
