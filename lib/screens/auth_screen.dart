import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/phone_format.dart';
import '../widgets/circle_back_button.dart';
import '../widgets/pressable_scale.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGmail = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<UserService>().clearError();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final userService = context.read<UserService>();
    final ok = await userService.signup(
      fullName: _nameController.text,
      phone: _isGmail ? null : formatPhoneForApi(_phoneController.text),
      email: _isGmail ? _emailController.text : null,
      password: _isGmail ? _passwordController.text : null,
      authProvider: _isGmail ? 'gmail' : 'phone',
    );
    if (!mounted) return;
    if (ok) {
      await context.read<NotificationService>().linkToUser(userService.token);
      if (!mounted) return;
      final mwalimu = context.read<MwalimuService>();
      await mwalimu.loadGuestState();
      if (!mounted) return;
      if (userService.token != null) {
        await mwalimu.flushGuestMessagesToServer(userService.token!);
        if (!mounted) return;
        await mwalimu.loadMessages(userService.token);
        if (!mounted) return;
      }
      context.read<AppProvider>().goBack();
    }
  }

  Future<void> _login() async {
    final userService = context.read<UserService>();
    final ok = await userService.login(
      email: _isGmail ? _emailController.text.trim() : null,
      phone: _isGmail ? null : formatPhoneForApi(_phoneController.text),
      password: _isGmail ? _passwordController.text : null,
    );
    if (!mounted) return;
    if (ok) {
      await context.read<NotificationService>().linkToUser(userService.token);
      if (!mounted) return;
      final mwalimu = context.read<MwalimuService>();
      await mwalimu.loadGuestState();
      if (!mounted) return;
      if (userService.token != null) {
        await mwalimu.flushGuestMessagesToServer(userService.token!);
        if (!mounted) return;
        await mwalimu.loadMessages(userService.token);
        if (!mounted) return;
      }
      context.read<AppProvider>().goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();

    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C2E1F), Color(0xFF1C4731), Color(0xFF065F46)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleBackButton(
                      onPressed: () => context.read<AppProvider>().goBack(),
                    ),
                    const Spacer(),
                    const Icon(Icons.eco, color: AppColors.cream, size: 24),
                  ],
                ),
              ),
              const Icon(Icons.spa, color: AppColors.cream, size: 48)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.5, 0.5)),
              const SizedBox(height: 12),
              Text(
                'Karibu Dawa Asili',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text(
                'Jiunge ili kusoma makala na kuuliza Mwalimu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppColors.radiusXl),
                    boxShadow: AppColors.elevationLg,
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        decoration: BoxDecoration(
                          color: AppColors.forest.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(AppColors.radiusPill),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.gray500,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(AppColors.radiusPill),
                          ),
                          dividerColor: Colors.transparent,
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: AppTypography.subtitle,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppTypography.subtitle,
                          ),
                          tabs: const [
                            Tab(text: 'Jiunge'),
                            Tab(text: 'Ingia'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildSignupForm(userService),
                            _buildLoginForm(userService),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignupForm(UserService userService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(_nameController, 'Jina Kamili', Icons.person_outline),
          const SizedBox(height: 14),
          Row(
            children: [
              _methodChip('Simu', !_isGmail, () => setState(() => _isGmail = false)),
              const SizedBox(width: 8),
              _methodChip('Gmail', _isGmail, () => setState(() => _isGmail = true)),
            ],
          ),
          const SizedBox(height: 14),
          if (_isGmail) ...[
            _field(_emailController, 'Barua pepe ya Gmail', Icons.email_outlined),
            const SizedBox(height: 14),
            _field(_passwordController, 'Nenosiri', Icons.lock_outline, obscure: true),
          ] else
            _field(_phoneController, 'Nambari ya Simu', Icons.phone_outlined,
                keyboard: TextInputType.phone),
          if (userService.error != null) ...[
            const SizedBox(height: 12),
            Text(userService.error!, style: const TextStyle(color: AppColors.red600, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          _submitButton('Jiunge Sasa', userService.isLoading, _signup),
        ],
      ),
    );
  }

  Widget _buildLoginForm(UserService userService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _methodChip('Simu', !_isGmail, () => setState(() => _isGmail = false)),
              const SizedBox(width: 8),
              _methodChip('Gmail', _isGmail, () => setState(() => _isGmail = true)),
            ],
          ),
          const SizedBox(height: 20),
          if (_isGmail) ...[
            _field(_emailController, 'Barua pepe', Icons.email_outlined),
            const SizedBox(height: 14),
            _field(_passwordController, 'Nenosiri', Icons.lock_outline, obscure: true),
          ] else
            _field(_phoneController, 'Nambari ya Simu', Icons.phone_outlined,
                keyboard: TextInputType.phone),
          if (userService.error != null) ...[
            const SizedBox(height: 12),
            Text(userService.error!, style: const TextStyle(color: AppColors.red600, fontSize: 12)),
          ],
          const SizedBox(height: 24),
          _submitButton('Ingia', userService.isLoading, _login),
        ],
      ),
    );
  }

  Widget _methodChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.forest : AppColors.canvas,
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
            border: Border.all(
              color: selected ? AppColors.forest : AppColors.borderLight,
            ),
            boxShadow: selected ? AppColors.elevationSm : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTypography.subtitle,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.forest, size: 20),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
        ),
      ),
    );
  }

  Widget _submitButton(String label, bool loading, VoidCallback onTap) {
    return PressableScale(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.forest,
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          boxShadow: AppColors.elevationMd,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: AppTypography.button,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}
