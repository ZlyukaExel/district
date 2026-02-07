import 'package:district/preferences.dart';

class ClientInfo {
  final String id;
  String downloadDirectory;
  bool isVisible;

  ClientInfo({
    required this.id,
    required this.downloadDirectory,
    required this.isVisible,
  });

  static const _dirKey = 'download_directory';
  static const _visibleKey = 'node_visible';

  /// Загрузка настроек из SharedPreferences
  static Future<ClientInfo> load(String id) async {
    final defaultDir = 'Downloads';

    final dir = await Preferences.getString(_dirKey, defaultDir);
    final visibleStr = await Preferences.getString(_visibleKey, 'true');
    final visible = visibleStr.toLowerCase() == 'true';

    return ClientInfo(id: id, downloadDirectory: dir, isVisible: visible);
  }

  /// Сохранение настроек в SharedPreferences
  Future<void> save() async {
    await Preferences.setString(_dirKey, downloadDirectory);
    await Preferences.setString(_visibleKey, isVisible.toString());
  }

  @override
  String toString() =>
      'ClientInfo('
      'id: $id, '
      'downloadDirectory: $downloadDirectory, '
      'isVisible: $isVisible)';
}
