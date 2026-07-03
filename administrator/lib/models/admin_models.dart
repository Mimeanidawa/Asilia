enum UserPlan { free, premium }

enum UserStatus { active, suspended, banned }

enum NotificationTarget { all, premium, free }

enum NotificationStatus { sent, scheduled, draft, failed }

enum ContentType { herb, condition, article }

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.plan,
    required this.status,
    required this.joinedAt,
    required this.lastActiveAt,
    required this.sessionCount,
    required this.country,
  });

  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserPlan plan;
  final UserStatus status;
  final DateTime joinedAt;
  final DateTime lastActiveAt;
  final int sessionCount;
  final String country;

  AdminUser copyWith({UserPlan? plan, UserStatus? status}) => AdminUser(
        id: id,
        name: name,
        email: email,
        avatarUrl: avatarUrl,
        plan: plan ?? this.plan,
        status: status ?? this.status,
        joinedAt: joinedAt,
        lastActiveAt: lastActiveAt,
        sessionCount: sessionCount,
        country: country,
      );
}

class MonthlyMetric {
  const MonthlyMetric({required this.month, required this.value});
  final String month;
  final double value;
}

class DashboardStats {
  const DashboardStats({
    required this.totalUsers,
    required this.premiumUsers,
    required this.freeUsers,
    required this.monthlyRevenue,
    required this.totalRevenue,
    required this.userGrowthRate,
    required this.revenueGrowthRate,
    required this.premiumConversionRate,
    required this.activeToday,
    required this.churnRate,
  });

  final int totalUsers;
  final int premiumUsers;
  final int freeUsers;
  final double monthlyRevenue;
  final double totalRevenue;
  final double userGrowthRate;
  final double revenueGrowthRate;
  final double premiumConversionRate;
  final int activeToday;
  final double churnRate;
}

class AdminNotification {
  AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.status,
    required this.createdAt,
    this.scheduledAt,
    this.sentCount = 0,
  });

  final String id;
  final String title;
  final String body;
  final NotificationTarget target;
  NotificationStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  int sentCount;
}

class RecentActivity {
  const RecentActivity({
    required this.id,
    required this.description,
    required this.type,
    required this.timestamp,
    this.userName,
  });

  final String id;
  final String description;
  final String type;
  final DateTime timestamp;
  final String? userName;
}

class ContentItem {
  ContentItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.createdAt,
    required this.isPublished,
    this.views = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final ContentType type;
  final DateTime createdAt;
  bool isPublished;
  int views;
}
