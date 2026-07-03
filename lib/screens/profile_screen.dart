import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/herb_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _activeTab;
  bool _showAddReminder = false;
  String _remTitle = '';
  String _remTime = '08:00 AM';
  String _remHerb = '';
  bool _pushNotifications = true;
  bool _offlineCache = false;

  static const _reminderTimes = [
    '06:00 AM',
    '08:00 AM',
    '01:00 PM',
    '04:00 PM',
    '08:00 PM',
    '10:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userService = context.watch<UserService>();

    if (_activeTab != null) {
      return _buildTabOverlay(context, app);
    }

    return SizedBox.expand(
      child: ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          color: Colors.white,
          child: const Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.emerald800, size: 18),
              SizedBox(width: 8),
              Text(
                'MTUMIAJI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: userService.isLoggedIn
              ? Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.emerald50,
                      child: Text(
                        userService.user!.fullName.isNotEmpty
                            ? userService.user!.fullName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userService.user!.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                          Text(
                            userService.user!.phone ?? userService.user!.email ?? '',
                            style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                          ),
                          const SizedBox(height: 6),
                          if (userService.user!.isPremiumActive)
                            const _MembershipBadge()
                          else
                            GestureDetector(
                              onTap: () => userService.purchasePremium(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'PATA PREMIUM',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.amber),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => userService.logout(),
                      icon: Icon(Icons.logout, color: AppColors.gray400, size: 20),
                    ),
                  ],
                )
              : _GuestProfileCard(
                  onJoin: () => app.navigate(AppScreen.auth),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MEZA YA ELIMU',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gray400,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.favorite,
                iconColor: AppColors.red600,
                label: 'My Saved Herbs',
                badge: '${app.favorites.length}',
                badgeColor: AppColors.red50,
                badgeTextColor: AppColors.red600,
                onTap: () => setState(() => _activeTab = 'favorites'),
              ),
              const SizedBox(height: 8),
              _MenuTile(
                icon: Icons.notifications_none,
                iconColor: AppColors.amber,
                label: 'Reminders Alerts',
                badge: '${app.reminders.where((r) => r.active).length} active',
                badgeColor: const Color(0xFFFFFBEB),
                badgeTextColor: const Color(0xFF78350F),
                onTap: () => setState(() => _activeTab = 'reminders'),
              ),
              const SizedBox(height: 8),
              _MenuTile(
                icon: Icons.history,
                iconColor: Colors.blue,
                label: 'Consultation History',
                badge: '${app.questions.length} cases',
                badgeColor: AppColors.blue50,
                badgeTextColor: AppColors.blue900,
                onTap: () => setState(() => _activeTab = 'questions'),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                pushNotifications: _pushNotifications,
                offlineCache: _offlineCache,
                onTogglePush: (v) => setState(() => _pushNotifications = v),
                onToggleOffline: (v) => setState(() => _offlineCache = v),
              ),
              const SizedBox(height: 16),
              _MenuTile(
                icon: Icons.info_outline,
                iconColor: AppColors.forest,
                label: 'About Dawa Asili & Disclaimer',
                onTap: () => setState(() => _activeTab = 'about'),
              ),
              const SizedBox(height: 16),
              Material(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await app.resetProfileState();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Simulated profile reset successfully. State restored to original default of Dawa Asili.',
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.red600, size: 18),
                        SizedBox(width: 12),
                        Text(
                          'Reset Local Profile State',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.red600,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: Color(0xFFFECACA)),
                      ],
                    ),
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

  Widget _buildTabOverlay(BuildContext context, AppProvider app) {
    return SizedBox.expand(
      child: Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.gray500),
                onPressed: () => setState(() {
                  _activeTab = null;
                  _showAddReminder = false;
                }),
              ),
              Text(
                '${_activeTab!} directory'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              if (_activeTab == 'favorites') _buildFavorites(context, app),
              if (_activeTab == 'reminders') _buildReminders(context, app),
              if (_activeTab == 'questions') _buildQuestions(app),
              if (_activeTab == 'about') _buildAbout(),
            ],
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildFavorites(BuildContext context, AppProvider app) {
    if (app.favorites.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border,
        message: 'Hakuna vipendwa bado.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Favorite Botanical Herbs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.forest,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${app.favorites.length} herbs',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.red600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...app.favorites.map((fid) {
          final h = herbById(fid);
          if (h == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() => _activeTab = null);
                  app.navigate(AppScreen.herbDetails, herbId: h.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      HerbImage(url: h.imageUrl, width: 48, height: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forest,
                              ),
                            ),
                            Text(
                              h.scientificName,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.gray400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.forest.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReminders(BuildContext context, AppProvider app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Active Alerts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.forest,
              ),
            ),
            FloatingActionButton.small(
              onPressed: () => setState(() => _showAddReminder = true),
              backgroundColor: AppColors.forest,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        if (_showAddReminder) ...[
          const SizedBox(height: 12),
          _AddReminderForm(
            title: _remTitle,
            time: _remTime,
            onTitleChanged: (v) => setState(() => _remTitle = v),
            onTimeChanged: (v) => setState(() => _remTime = v),
            onClose: () => setState(() => _showAddReminder = false),
            onSubmit: () {
              if (_remTitle.trim().isEmpty) return;
              app.addReminder(_remTitle.trim(), _remTime, _remHerb);
              setState(() {
                _remTitle = '';
                _showAddReminder = false;
              });
            },
          ),
        ],
        const SizedBox(height: 12),
        if (app.reminders.isEmpty)
          const _EmptyState(message: 'Hakuna vikumbusho vilivyowekwa.')
        else
          ...app.reminders.map((rem) {
            final herb = herbById(rem.herbId);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.03),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rem.title,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                rem.time,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.emerald800,
                                ),
                              ),
                              if (herb != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.forest.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: Text(
                                    herb.name,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: AppColors.emerald900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        rem.active ? Icons.power_settings_new : Icons.power_off,
                        color: rem.active
                            ? AppColors.emerald800
                            : AppColors.gray400,
                        size: 18,
                      ),
                      onPressed: () => app.toggleReminder(rem.id),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade300,
                        size: 18,
                      ),
                      onPressed: () => app.deleteReminder(rem.id),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildQuestions(AppProvider app) {
    if (app.questions.isEmpty) {
      return const _EmptyState(
        message:
            'No previous digital cases or expert consultations log files are found.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diagnosed Cases & Symptoms',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 12),
        ...app.questions.map(
          (q) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.forest.withValues(alpha: 0.03),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      q.timestamp.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray400,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CASE CLOSED',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.emerald900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Q: "${q.query}"',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                    border: const Border(
                      left: BorderSide(color: AppColors.amber, width: 2),
                    ),
                  ),
                  child: Text(
                    q.answer,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.03)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.amber, size: 28),
          const SizedBox(height: 8),
          const Text(
            'Our Mission: Preserving Wisdom',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          Text(
            'Dawa Asili Platform • Ver 4.0',
            style: TextStyle(fontSize: 9, color: AppColors.gray400),
          ),
          const SizedBox(height: 16),
          Text(
            'At Dawa Asili, we are committed to compiling, researching, and sharing traditional African herbal remedies. Native plants are magnificent partners in holistic metabolic balance, tissue cooling, and preventative wellness.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TAARIFA YA ELIMU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7F1D1D),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  '1. Dawa Asili ni programu ya ELIMU tu — jifunze kuhusu mimea, mizizi, miti na matunda ya asili.',
                  '2. Hatutoi ushauri wa kimatibabu, matibabu, au dawa. Hatuhakikishi kupona au kuponywa.',
                  '3. Kwa matatizo ya afya, wasiliana na mtaalamu wa afya aliyehitimu.',
                ].map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
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

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.emerald50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, color: AppColors.forest, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Karibu Dawa Asili!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest),
          ),
          const SizedBox(height: 6),
          Text(
            'Jiunge ili kusoma makala, kuuliza Mwalimu, na kufungua maudhui ya Premium',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Jiunge au Ingia', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipBadge extends StatelessWidget {
  const _MembershipBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PREMIUM MEMBER',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: AppColors.amber,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeTextColor,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.forest.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.pushNotifications,
    required this.offlineCache,
    required this.onTogglePush,
    required this.onToggleOffline,
  });

  final bool pushNotifications;
  final bool offlineCache;
  final ValueChanged<bool> onTogglePush;
  final ValueChanged<bool> onToggleOffline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 16, color: AppColors.amber),
              SizedBox(width: 8),
              Text(
                'APPLICATION SETTINGS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.emerald800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SettingRow(
            label: 'Push Notification Alerts',
            desc: 'For healing alerts',
            value: pushNotifications,
            onChanged: onTogglePush,
          ),
          _SettingRow(
            label: 'Offline Remedies Cache',
            desc: 'Dawa directory offline',
            value: offlineCache,
            onChanged: onToggleOffline,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
                Text(desc, style: TextStyle(fontSize: 9, color: AppColors.gray400)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.emerald800,
          ),
        ],
      ),
    );
  }
}

class _AddReminderForm extends StatelessWidget {
  const _AddReminderForm({
    required this.title,
    required this.time,
    required this.onTitleChanged,
    required this.onTimeChanged,
    required this.onClose,
    required this.onSubmit,
  });

  final String title;
  final String time;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onTimeChanged;
  final VoidCallback onClose;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ONGEZA KIKUMBUSHO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onClose,
              ),
            ],
          ),
          TextField(
            onChanged: onTitleChanged,
            decoration: const InputDecoration(
              labelText: 'Kichwa cha kikumbusho',
              hintText: 'Mfano: Soma somo la leo',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: time,
            decoration: const InputDecoration(labelText: 'Muda wa kila siku'),
            items: _ProfileScreenState._reminderTimes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) {
              if (v != null) onTimeChanged(v);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Save Healing Reminder',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.icon, required this.message});

  final IconData? icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 40, color: AppColors.red600.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: AppColors.gray400, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
