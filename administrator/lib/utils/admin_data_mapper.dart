import '../models/admin_models.dart';

class AdminDataMapper {
  AdminDataMapper._();

  static AdminUser userFromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'active';
    UserStatus status;
    switch (statusStr) {
      case 'suspended':
        status = UserStatus.suspended;
      case 'banned':
        status = UserStatus.banned;
      default:
        status = UserStatus.active;
    }

    return AdminUser(
      id: json['id'] as String,
      name: json['fullName'] as String? ?? '—',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      authProvider: json['authProvider'] as String? ?? 'phone',
      plan: json['isPremium'] == true ? UserPlan.premium : UserPlan.free,
      status: status,
      joinedAt: DateTime.parse(json['createdAt'] as String),
      lastActiveAt: DateTime.parse(json['updatedAt'] as String? ?? json['createdAt'] as String),
      messageCount: json['messageCount'] as int? ?? 0,
      purchaseCount: json['purchaseCount'] as int? ?? 0,
      totalSpent: json['totalSpent'] as int? ?? 0,
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.parse(json['premiumUntil'] as String)
          : null,
      purchasedContentIds: List<String>.from(json['purchasedContentIds'] as List? ?? []),
    );
  }

  static DashboardStats statsFromJson(Map<String, dynamic> json) => DashboardStats(
        totalUsers: json['totalUsers'] as int? ?? 0,
        premiumUsers: json['premiumUsers'] as int? ?? 0,
        freeUsers: json['freeUsers'] as int? ?? 0,
        monthlyRevenue: (json['monthlyRevenue'] as num?)?.toDouble() ?? 0,
        totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
        userGrowthRate: (json['userGrowthRate'] as num?)?.toDouble() ?? 0,
        revenueGrowthRate: (json['revenueGrowthRate'] as num?)?.toDouble() ?? 0,
        premiumConversionRate: (json['premiumConversionRate'] as num?)?.toDouble() ?? 0,
        activeToday: json['activeToday'] as int? ?? 0,
        churnRate: (json['churnRate'] as num?)?.toDouble() ?? 0,
      );

  static List<MonthlyMetric> metricsFromJson(List list) => list
      .map((e) => MonthlyMetric(
            month: e['month'] as String,
            value: (e['value'] as num).toDouble(),
          ))
      .toList();

  static List<RecentActivity> activitiesFromJson(List list) => list
      .map((e) => RecentActivity(
            id: e['id'] as String,
            description: e['description'] as String,
            type: e['type'] as String,
            timestamp: DateTime.parse(e['timestamp'] as String),
            userName: e['userName'] as String?,
          ))
      .toList();
}
