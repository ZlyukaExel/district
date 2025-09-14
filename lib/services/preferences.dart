import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String nicknameKey = 'player_nickname';

  static Future<void> saveNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(nicknameKey, nickname);
  }

  static Future<String> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString(nicknameKey);
    return (nickname == null || nickname.trim().isEmpty)
        ? 'пользователь'
        : nickname;
  }
}
