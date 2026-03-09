import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const sessionKey = 'healthchat.session';
  static const selectedConversationKey = 'healthchat.selectedConversation';

  Future<String?> loadSessionRaw() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(sessionKey);
  }

  Future<void> saveSessionRaw(String rawJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sessionKey, rawJson);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
  }

  Future<String?> loadSelectedConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(selectedConversationKey);
  }

  Future<void> saveSelectedConversationId(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedConversationKey, conversationId);
  }

  Future<void> clearSelectedConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(selectedConversationKey);
  }
}
