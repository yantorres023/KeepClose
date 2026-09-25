import 'package:url_launcher/url_launcher.dart';

/// Opens the OS messaging/phone apps. KeepClose never sends anything itself;
/// the user always composes and sends in their own app.
abstract class Launcher {
  Future<bool> message(String phone);
  Future<bool> call(String phone);
}

class UrlLauncher implements Launcher {
  static String _clean(String phone) =>
      phone.replaceAll(RegExp(r'[^0-9+*#]'), '');

  Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> message(String phone) =>
      _open(Uri(scheme: 'sms', path: _clean(phone)));

  @override
  Future<bool> call(String phone) =>
      _open(Uri(scheme: 'tel', path: _clean(phone)));
}
