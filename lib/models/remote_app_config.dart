class ScreenMessageConfig {
  const ScreenMessageConfig({
    this.enabled = false,
    this.id = '',
    this.title = '',
    this.body = '',
    this.style = 'info',
    this.dismissible = true,
  });

  final bool enabled;
  final String id;
  final String title;
  final String body;
  final String style;
  final bool dismissible;

  bool get isVisible => enabled && body.trim().isNotEmpty;

  factory ScreenMessageConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ScreenMessageConfig();
    return ScreenMessageConfig(
      enabled: json['enabled'] == true,
      id: '${json['id'] ?? ''}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      style: '${json['style'] ?? 'info'}',
      dismissible: json['dismissible'] != false,
    );
  }
}

class AppUpdateConfig {
  const AppUpdateConfig({
    this.forceUpdate = false,
    this.minVersion = '',
    this.minBuild = 0,
    this.title = 'Update Required',
    this.message =
        'A new version of Dawa Asili is available. Update now to continue.',
    this.storeUrl =
        'https://play.google.com/store/apps/details?id=com.asilia',
  });

  final bool forceUpdate;
  final String minVersion;
  final int minBuild;
  final String title;
  final String message;
  final String storeUrl;

  factory AppUpdateConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppUpdateConfig();
    return AppUpdateConfig(
      forceUpdate: json['forceUpdate'] == true,
      minVersion: '${json['minVersion'] ?? ''}',
      minBuild: (json['minBuild'] as num?)?.toInt() ??
          int.tryParse('${json['minBuild'] ?? ''}') ??
          0,
      title: '${json['title'] ?? 'Update Required'}',
      message: '${json['message'] ?? ''}',
      storeUrl:
          '${json['storeUrl'] ?? 'https://play.google.com/store/apps/details?id=com.asilia'}',
    );
  }
}

class AboutAppConfig {
  const AboutAppConfig({
    this.appName = 'Dawa Asili',
    this.appVersion = '1.1.6',
    this.appDescription =
        'Elimu ya dawa za asili kutoka mizizi, miti na matunda kwa Kiswahili fasaha. Tunakuletea maarifa asilia ya afya na tiba salama za kiasili.',
    this.contactPhone = '+255 700 000 000',
    this.contactEmail = 'info@dawaasili.com',
    this.website = 'https://dawaasili.co.tz',
    this.disclaimer =
        'Elimu na taarifa zote zilizomo humu ni kwa ajili ya kujifunza na kuelimisha tu.',
    this.showLicenses = false,
  });

  final String appName;
  final String appVersion;
  final String appDescription;
  final String contactPhone;
  final String contactEmail;
  final String website;
  final String disclaimer;
  final bool showLicenses;

  factory AboutAppConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AboutAppConfig();
    return AboutAppConfig(
      appName: '${json['appName'] ?? 'Dawa Asili'}',
      appVersion: '${json['appVersion'] ?? '1.1.6'}',
      appDescription: '${json['appDescription'] ?? 'Elimu ya dawa za asili kutoka mizizi, miti na matunda kwa Kiswahili fasaha.'}',
      contactPhone: '${json['contactPhone'] ?? '+255 700 000 000'}',
      contactEmail: '${json['contactEmail'] ?? 'info@dawaasili.com'}',
      website: '${json['website'] ?? 'https://dawaasili.co.tz'}',
      disclaimer: '${json['disclaimer'] ?? 'Elimu na taarifa zote zilizomo humu ni kwa ajili ya kujifunza na kuelimisha tu.'}',
      showLicenses: json['showLicenses'] == true,
    );
  }
}

class RemoteAppConfig {
  const RemoteAppConfig({
    this.screenMessage = const ScreenMessageConfig(),
    this.update = const AppUpdateConfig(),
    this.about = const AboutAppConfig(),
  });

  final ScreenMessageConfig screenMessage;
  final AppUpdateConfig update;
  final AboutAppConfig about;

  factory RemoteAppConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RemoteAppConfig();
    return RemoteAppConfig(
      screenMessage: ScreenMessageConfig.fromJson(
        json['screenMessage'] as Map<String, dynamic>?,
      ),
      update: AppUpdateConfig.fromJson(
        json['update'] as Map<String, dynamic>?,
      ),
      about: AboutAppConfig.fromJson(
        json['about'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// Compare semver-ish strings: "1.2.0" vs "1.1.9". Returns <0 if a<b.
int compareAppVersions(String a, String b) {
  List<int> parts(String v) => v
      .split(RegExp(r'[^0-9]+'))
      .where((p) => p.isNotEmpty)
      .map((p) => int.tryParse(p) ?? 0)
      .toList();

  final ap = parts(a);
  final bp = parts(b);
  final len = ap.length > bp.length ? ap.length : bp.length;
  for (var i = 0; i < len; i++) {
    final av = i < ap.length ? ap[i] : 0;
    final bv = i < bp.length ? bp[i] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}
