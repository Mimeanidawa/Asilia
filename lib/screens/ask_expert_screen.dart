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
import '../utils/image_url.dart';
import '../services/payment_service.dart';
import '../utils/tzs_format.dart';
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
  int _sendingCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initChat());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _mwalimuService ??= context.read<MwalimuService>();
    final draft = context.read<AppProvider>().consumePendingMwalimuMessage();
    if (draft != null && draft.trim().isNotEmpty) {
      _controller.text = draft;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _scrollToBottom();
    }
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
    if (mounted) {
      final draft = context.read<AppProvider>().consumePendingMwalimuMessage();
      if (draft != null && draft.trim().isNotEmpty) {
        _controller.text = draft;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        _scrollToBottom();
      }
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
      setState(() => _sendingCount++);
      _scrollToBottom();
      final ok = await mwalimu.sendGuestMessage(text);
      if (mounted) setState(() => _sendingCount = (_sendingCount - 1).clamp(0, 99));
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
    setState(() => _sendingCount++);
    _scrollToBottom();
    final ok = await mwalimu.sendMessage(text, user.token!);
    if (mounted) setState(() => _sendingCount = (_sendingCount - 1).clamp(0, 99));
    if (!ok && mounted) {
      if (!mwalimu.canSendMessage()) {
        _showPremiumDialog();
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
  }

  void _showSignupRequiredDialog() {
    final limit = context.read<MwalimuService>().settings.freeMessageLimit;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Ingia ili uendelee',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Umefikia kikomo cha maswali $limit bila kujiandikisha. Jisajili au ingia ili kuendelea kuwasiliana na Mwalimu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Baadaye'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppProvider>().navigate(AppScreen.auth);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
            ),
            child: const Text(
              'Jisajili / Ingia',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog() {
    final mwalimu = context.read<MwalimuService>();
    final limit = mwalimu.settings.freeMessageLimit;
    final price = mwalimu.settings.premiumPrice;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Kikomo cha Maswali',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Umefikia kikomo cha maswali $limit kwa watumiaji wa bure. Lipia Premium (${TzsFormat.full(price)}) ili kuendelea kujifunza bila kikomo na kufungua makala zote.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Funga'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final svc = context.read<MwalimuService>();
              await svc.loadSettings();
              if (!mounted) return;
              final result = await showAuraxPayment(
                context,
                type: PaymentType.premium,
                title: 'Premium — Dawa Asili',
                subtitle:
                    'Fungua makala zote + maswali bila kikomo kwa Mwalimu (siku 30)',
                amount: svc.settings.premiumPrice,
              );
              if (result == AuraxPaymentResult.success && mounted) {
                await AppRefresh.afterPremiumPurchase(context);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Premium imeamilishwa! Unaweza kuuliza bila kikomo.',
                    ),
                    backgroundColor: AppColors.forest,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.forest,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
            ),
            child: const Text(
              'Lipia Premium',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
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
    final chatMessages = user.isLoggedIn
        ? mwalimu.messages
        : mwalimu.guestMessages;
    final guestLimitReached = !user.isLoggedIn && !mwalimu.canSendAsGuest();

    if (chatMessages.length != _lastMessageCount) {
      _lastMessageCount = chatMessages.length;
      _scrollToBottom();
    }

    return SizedBox.expand(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Uliza Mwalimu',
            onBack: () => context.read<AppProvider>().goBack(),
            trailing: !user.isLoggedIn
                ? TextButton(
                    onPressed: () =>
                        context.read<AppProvider>().navigate(AppScreen.auth),
                    child: const Text(
                      'Ingia',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                : null,
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.surfaceElevated, AppColors.cream]),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.forest.withValues(alpha: 0.03),
                ),
              ),
            ),
            child: Row(
              children: [
                if (settings.mwalimuImage.isNotEmpty)
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: CachedNetworkImageProvider(
                      ImageUrl.display(settings.mwalimuImage),
                    ),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                        ),
                      ),
                      Text(
                        'Mtaalamu wa Elimu ya Mimea na Asili',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.isPremiumActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          if (mwalimu.isLoading && chatMessages.isNotEmpty)
            const LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.forest,
              backgroundColor: AppColors.emerald50,
            ),
          Expanded(
            child: PullToRefresh(
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _Bubble(
                    isUser: false,
                    content: settings.mwalimuWelcome,
                    avatarUrl: settings.mwalimuImage,
                  ),
                  if (mwalimu.isLoading && chatMessages.isEmpty)
                    const _MessageSkeleton()
                  else
                    ...chatMessages.map(
                      (m) => _Bubble(
                        isUser: m.isUser,
                        content: m.content,
                        avatarUrl: m.isAdmin ? settings.mwalimuImage : null,
                        sending: m.pending,
                        failed: m.failed,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (guestLimitReached)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jisajili au ingia ili uendelee kuwasiliana na Mwalimu.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<AppProvider>().navigate(AppScreen.auth),
                    child: const Text(
                      'Ingia',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              MediaQuery.paddingOf(context).bottom + 4,
            ),
            child: Material(
              color: AppColors.surfaceElevated.withValues(alpha: 0.97),
              elevation: 10,
              shadowColor: AppColors.forest.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
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
                          fillColor: AppColors.emerald50.withValues(alpha: 0.45),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: guestLimitReached
                          ? AppColors.gray400
                          : AppColors.forest,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: guestLimitReached
                            ? _showSignupRequiredDialog
                            : _send,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _sendingCount > 0
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageSkeleton extends StatelessWidget {
  const _MessageSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 8),
      child: Column(
        children: [
          _SkeletonBubble(alignEnd: false, widthFactor: 0.62),
          _SkeletonBubble(alignEnd: true, widthFactor: 0.48),
          _SkeletonBubble(alignEnd: false, widthFactor: 0.7),
          SizedBox(height: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.forest,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({required this.alignEnd, required this.widthFactor});

  final bool alignEnd;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.sizeOf(context).width * widthFactor,
        height: 42,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: alignEnd
              ? AppColors.forest.withValues(alpha: 0.12)
              : AppColors.emerald50,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(alignEnd ? 18 : 4),
            bottomRight: Radius.circular(alignEnd ? 4 : 18),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.isUser,
    required this.content,
    this.avatarUrl,
    this.sending = false,
    this.failed = false,
  });

  final bool isUser;
  final String content;
  final String? avatarUrl;
  final bool sending;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final parts = _SharedArticleTagParser.parse(content);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isUser && avatarUrl != null && avatarUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: CachedNetworkImageProvider(
                          ImageUrl.display(avatarUrl!),
                        ),
                      ),
                    ),
                  if (!isUser && (avatarUrl == null || avatarUrl!.isEmpty))
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.emerald50,
                        child: Icon(Icons.school, size: 14, color: AppColors.forest),
                      ),
                    ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.forest.withValues(alpha: sending ? 0.72 : 1)
                            : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        border: isUser
                            ? null
                            : Border.all(
                                color: AppColors.forest.withValues(alpha: 0.08),
                              ),
                      ),
                      child: _buildContent(context, parts),
                    ),
                  ),
                ],
              ),
              if (sending || failed)
                Padding(
                  padding: EdgeInsets.only(
                    top: 3,
                    right: isUser ? 4 : 0,
                    left: isUser ? 0 : 36,
                  ),
                  child: Text(
                    failed ? 'Imeshindwa kutuma' : 'Inatuma...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: failed ? Colors.red.shade700 : AppColors.gray500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<_MessagePart> parts) {
    final textStyle = TextStyle(
      fontSize: 13,
      color: isUser ? Colors.white : AppColors.gray600,
      height: 1.45,
    );

    final hasRich = parts.any((p) => p is _ArticlePart || p is _ImagePart);
    if (!hasRich) {
      return Text(content, style: textStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (parts[i] is _TextPart &&
              (parts[i] as _TextPart).text.trim().isNotEmpty)
            Text((parts[i] as _TextPart).text, style: textStyle),
          if (parts[i] is _ImagePart)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: ImageUrl.display((parts[i] as _ImagePart).url),
                  fit: BoxFit.cover,
                  width: 220,
                  height: 180,
                  placeholder: (_, __) => Container(
                    width: 220,
                    height: 180,
                    color: AppColors.emerald50,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 220,
                    height: 180,
                    color: AppColors.emerald50,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
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

class _ImagePart extends _MessagePart {
  const _ImagePart(this.url);
  final String url;
}

class _ArticlePart extends _MessagePart {
  const _ArticlePart({
    required this.id,
    required this.title,
    this.imageUrl,
  });
  final String id;
  final String title;
  final String? imageUrl;
}

class _SharedArticleTagParser {
  static final RegExp _pattern = RegExp(
    r'\[MAKALA:([^|\]]+)\|([^|\]]+)(?:\|([^\]]*))?\]',
  );
  static final RegExp _imageTag = RegExp(r'\[IMAGE:([^\]]+)\]');
  static final RegExp _urlLine = RegExp(r'^https?://[^\s]+/makala/[^\s]+$');

  static List<_MessagePart> parse(String input) {
    final parts = <_MessagePart>[];
    final matches = <({int start, int end, _MessagePart part})>[];

    for (final m in _imageTag.allMatches(input)) {
      final url = (m.group(1) ?? '').trim();
      if (url.isNotEmpty) {
        matches.add((start: m.start, end: m.end, part: _ImagePart(url)));
      }
    }
    for (final m in _pattern.allMatches(input)) {
      final id = (m.group(1) ?? '').trim();
      final title = (m.group(2) ?? 'Makala').trim();
      final imageUrl = (m.group(3) ?? '').trim();
      if (id.isNotEmpty) {
        matches.add((
          start: m.start,
          end: m.end,
          part: _ArticlePart(
            id: id,
            title: title,
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
          ),
        ));
      }
    }
    matches.sort((a, b) => a.start.compareTo(b.start));

    var cursor = 0;
    String? linkedUrl;
    for (final item in matches) {
      if (item.start > cursor) {
        _appendText(parts, input.substring(cursor, item.start));
      }
      parts.add(item.part);
      if (item.part is _ArticlePart) {
        linkedUrl = '/makala/${(item.part as _ArticlePart).id}';
      }
      cursor = item.end;
    }

    if (cursor < input.length) {
      final tail = input.substring(cursor);
      final lines = tail.split('\n');
      final kept = <String>[];
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          kept.add(line);
          continue;
        }
        if (_urlLine.hasMatch(trimmed) &&
            (linkedUrl == null || trimmed.contains(linkedUrl))) {
          continue;
        }
        kept.add(line);
      }
      _appendText(parts, kept.join('\n'));
    }
    return parts;
  }

  static void _appendText(List<_MessagePart> parts, String raw) {
    final text = raw.trim();
    if (text.isNotEmpty) parts.add(_TextPart(text));
  }
}

class _SharedArticleCard extends StatelessWidget {
  const _SharedArticleCard({required this.part});

  final _ArticlePart part;

  @override
  Widget build(BuildContext context) {
    final hasImage = part.imageUrl != null && part.imageUrl!.isNotEmpty;

    return Material(
      color: AppColors.emerald50.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.read<AppProvider>().navigate(
          AppScreen.contentDetail,
          contentId: part.id,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasImage)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: ImageUrl.display(part.imageUrl!),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.emerald50,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.emerald50,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.forest,
                      size: 28,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (!hasImage)
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: AppColors.forest,
                    ),
                  if (!hasImage) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Makala',
                          style: TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
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
                      ],
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
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.forest,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
