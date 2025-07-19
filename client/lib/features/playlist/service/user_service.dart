import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _userKey = 'user_info';

  // Kullanıcı bilgilerini kaydet
  static Future<void> saveUserInfo({
    required String username,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfo = {
        'username': username,
        'email': email,
      };
      await prefs.setString(_userKey, jsonEncode(userInfo));
    } catch (e) {
      print('Kullanıcı bilgisi kaydedilirken hata: $e');
    }
  }

  // Kullanıcı bilgilerini getir
  static Future<Map<String, String>> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoJson = prefs.getString(_userKey);
      
      if (userInfoJson != null) {
        final userInfo = jsonDecode(userInfoJson) as Map<String, dynamic>;
        return {
          'username': userInfo['username'] ?? 'Kullanıcı',
          'email': userInfo['email'] ?? 'kullanici@email.com',
        };
      }
    } catch (e) {
      print('Kullanıcı bilgisi getirilirken hata: $e');
    }
    
    // Varsayılan değerler
    return {
      'username': 'Kullanıcı',
      'email': 'kullanici@email.com',
    };
  }

  // Kullanıcı bilgilerini güncelle
  static Future<void> updateUserInfo({
    String? username,
    String? email,
  }) async {
    try {
      final currentInfo = await getUserInfo();
      final updatedInfo = {
        'username': username ?? currentInfo['username']!,
        'email': email ?? currentInfo['email']!,
      };
      await saveUserInfo(
        username: updatedInfo['username']!,
        email: updatedInfo['email']!,
      );
    } catch (e) {
      print('Kullanıcı bilgisi güncellenirken hata: $e');
    }
  }

  // Kullanıcı bilgilerini sil (çıkış yaparken)
  static Future<void> clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      print('Kullanıcı bilgisi silinirken hata: $e');
    }
  }
} 