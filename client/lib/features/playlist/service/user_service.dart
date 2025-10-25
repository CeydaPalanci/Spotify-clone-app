import 'dart:convert';
import 'package:client/features/home/view/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
      if (kDebugMode) {
        print('Kullanıcı bilgisi kaydedilirken hata: $e');
      }
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
      if (kDebugMode) {
        print('Kullanıcı bilgisi getirilirken hata: $e');
      }
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
      if (kDebugMode) {
        print('Kullanıcı bilgisi güncellenirken hata: $e');
      }
    }
  }

  // Kullanıcı bilgilerini sil (çıkış yaparken)
  static Future<void> clearUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      if (kDebugMode) {
        print('Kullanıcı bilgisi silinirken hata: $e');
      }
    }
  }

  // Auth headers'ı getir
  static Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Auth headers alınırken hata: $e');
      }
      return {'Content-Type': 'application/json'};
    }
  }

  // Token'ı kontrol et (debug için)
  static Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      // Token bilgisi güvenlik nedeniyle loglanmaz
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Token alınırken hata: $e');
      }
      return null;
    }
  }

  // Hesabı sil
  static Future<bool> deleteAccount() async {
    try {
      final headers = await _getAuthHeaders();
      if (kDebugMode) {
        print('Delete account headers hazırlandı');
      }
      
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/delete-account'),
        headers: headers,
      );

      if (kDebugMode) {
        print('Delete account response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        // Başarılı silme durumunda local verileri de temizle
        await clearUserInfo();
        return true;
      } else {
        if (kDebugMode) {
          print('Hesap silme hatası: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Hesap silme işlemi sırasında hata: $e');
      }
      return false;
    }
  }
} 