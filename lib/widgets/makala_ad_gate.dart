import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ads_service.dart';
import '../theme/app_colors.dart';
import '../utils/remove_ads_flow.dart';

/// Full-screen gate: free users must finish an interstitial or rewarded ad.
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
  bool _busy = false;
  String? _error;
  int _failCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoPlay());
  }

  Future<void> _autoPlay() async {
    final ads = context.read<AdsService>();
    await ads.initialize();
    await ads.preload();
    if (!mounted) return;
    // Small delay so preload can finish when coming from cold start.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || _busy) return;
    await _playAd(preferRewarded: false);
  }

  Future<void> _playAd({required bool preferRewarded}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final ads = context.read<AdsService>();
    final shown = preferRewarded
        ? await ads.showRewardedOnly(
            onCompleted: _unlock,
            onFailed: () => _onFail('Video haikupatikana. Jaribu tena.'),
          )
        : await ads.showMakalaEntryAd(
            onCompleted: _unlock,
            onFailed: () => _onFail('Tangazo halikupatikana. Jaribu tena.'),
          );

    if (!mounted) return;
    if (!shown) {
      setState(() => _busy = false);
    }
  }

  void _unlock() {
    if (!mounted) return;
    widget.onUnlocked();
  }

  void _onFail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failCount++;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _busy ? null : widget.onCancel,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: AppColors.forest,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 48,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tazama tangazo ili usome',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Watumiaji wa bure hutazama tangazo fupi kabla ya kusoma makala. Premium huondoa matangazo yote.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.forest.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.red600,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(color: AppColors.forest),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _playAd(preferRewarded: false),
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: const Text(
                      'Tazama tangazo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _playAd(preferRewarded: true),
                    icon: const Icon(Icons.ondemand_video_rounded),
                    label: const Text(
                      'Tazama video (rewarded)',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.forest,
                      side: BorderSide(
                        color: AppColors.forest.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (_failCount >= 3) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: widget.onUnlocked,
                    child: Text(
                      'Endelea kusoma (mtandao umeshindwa)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _busy ? null : () => openRemoveAdsPayment(context),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text(
                    'Je Umechoka na Matangazo? Zima matangazo yote hapa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
