import '../models/admin_models.dart';

/// Placeholder values until real analytics/users APIs are wired.
class MockData {
  MockData._();

  static const DashboardStats stats = DashboardStats(
    totalUsers: 0,
    premiumUsers: 0,
    freeUsers: 0,
    monthlyRevenue: 0,
    totalRevenue: 0,
    userGrowthRate: 0,
    revenueGrowthRate: 0,
    premiumConversionRate: 0,
    activeToday: 0,
    churnRate: 0,
  );

  static const List<MonthlyMetric> userGrowth = [];
  static const List<MonthlyMetric> revenueData = [];
  static const List<MonthlyMetric> premiumGrowth = [];
  static const List<AdminUser> users = [];
  static const List<AdminNotification> notifications = [];
  static const List<RecentActivity> recentActivities = [];
  static const List<ContentItem> contentItems = [];
}
