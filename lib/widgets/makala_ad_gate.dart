import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';
import '../theme/app_colors.dart';
import '../utils/remove_ads_flow.dart';

/// Full-screen gate: auto-plays a random interstitial or rewarded ad.
class MakalaAdGate extends StatefulWidget {
  const MakalaAdGate({
    super.key,
    required this.onUnlocked,
    required this.onCancel,
  });

  final VoidCallback onUnlocked;
  final VoidCallback onCancel;

  @override
  State<MakalaAdGate> createState() => _MakalaAdGateState();
}

class _MakalaAdGateState extends State<MakalaAdGate> {
  bool _playing = true;
  bool _canSkip = false;
  int _attempts = 0;
  static const _maxAttempts = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlay());
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted && _playing) setState(() => _canSkip = true);
    });
  }

  Future<void> _autoPlay() async {
    if (!mounted) return;
    final ads = context.read<AdsService>();
    await ads.initialize();
    await ads.preload();

    while (mounted && _playing && _attempts < _maxAttempts) {
      _attempts++;
      final shown = await ads.showMakalaEntryAd(
        onCompleted: _unlock,
        onFailed: () {},
        grantRewardOnDismiss: true,
      );
      if (shown || !mounted) return;

      await Future<void>.delayed(Duration(milliseconds: 800 * _attempts));
      await ads.preload();
    }

    if (!mounted || !_playing) return;
    _unlock();
  }

  void _unlock() {
    if (!mounted) return;
    setState(() {
      _playing = false;
      _canSkip = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) widget.onUnlocked();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.forest,
                ),
              ),
              const Spacer(),
              if (_playing) ...[
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading ad…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest.withValues(alpha: 0.65),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.article_outlined,
                  size: 40,
                  color: AppColors.forest.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Opening article…',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const Spacer(),
              if (_canSkip && _playing)
                TextButton(
                  onPressed: _unlock,
                  child: const Text(
                    'Continue without ad',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              TextButton.icon(
                onPressed: () => openRemoveAdsPayment(context),
                icon: const Icon(Icons.block_rounded, size: 18),
                label: const Text(
                  'Remove all ads',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
