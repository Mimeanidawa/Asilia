import 'package:url_launcher/url_launcher.dart';

/// Digits (and a leading +) that the phone app can dial.
String dialablePhone(String raw) {
  final trimmed = raw.trim();
  final buf = StringBuffer();
  for (var i = 0; i < trimmed.length; i++) {
    final c = trimmed[i];
    if (c == '+' && buf.isEmpty) {
      buf.write(c);
    } else if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
      buf.write(c);
    }
  }
  return buf.toString();
}

/// Opens the device phone app and places a normal call to [phone].
Future<bool> callPhoneNumber(String phone) async {
  final dial = dialablePhone(phone);
  if (dial.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: dial);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
