import '../models/admin_models.dart';

class AdminDataMapper {
  AdminDataMapper._();

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static UserStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'suspended':
        return UserStatus.suspended;
      case 'banned':
        return UserStatus.banned;
      default:
        return UserStatus.active;
    }
  }

  static AdminUser userFromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      name: (json['fullName'] as String?)?.trim().isNotEmpty == true
          ? (json['fullName'] as String).trim()
          : '—',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      authProvider: json['authProvider'] as String? ?? 'phone',
      plan: json['isPremium'] == true ? UserPlan.premium : UserPlan.free,
      status: _parseStatus(json['status'] as String?),
      joinedAt: _parseDate(json['createdAt']),
      lastActiveAt: _parseDate(json['updatedAt'] ?? json['createdAt']),
      messageCount: _asInt(json['messageCount']),
      purchaseCount: _asInt(json['purchaseCount']),
      totalSpent: _asInt(json['totalSpent']),
      premiumUntil: json['premiumUntil'] != null ? _parseDate(json['premiumUntil']) : null,
      purchasedContentIds: (json['purchasedContentIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
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
