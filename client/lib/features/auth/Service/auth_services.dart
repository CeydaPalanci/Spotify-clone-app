import 'dart:convert';
import 'package:client/features/home/view/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';

  // Token'ı kaydetmek için
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Token'ı almak için
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Login metodu
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        print('Login isteği gönderiliyor');
      }
      final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (kDebugMode) {
        print('Login yanıtı: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Token'ı kaydet
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return data;
      } else {
        throw Exception('Giriş başarısız: ${response.body}');
      }
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }

  // Register metodu
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    Function(String)? onSuccess,
  }) async {
    http.Response? response;
    try {
      if (kDebugMode) {
        print('Register isteği gönderiliyor');
      }
      response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      if (kDebugMode) {
        print('Register yanıtı: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Yanıt JSON değilse, başarılı mesajını direkt kullan
        if (response.body.trim() == 'Kayıt başarılı.') {
          onSuccess?.call(response.body);
          return {'message': response.body};
        }
        
        // JSON yanıt için normal işlem
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        onSuccess?.call('Kayıt işlemi başarıyla tamamlandı!');
        return data;
      } else {
        throw Exception('Kayıt işlemi başarısız: Status Code: ${response.statusCode}, Response: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Register hatası: $e');
      }
      // JSON parse hatası ise, başarılı mesajını kullan
      if (e is FormatException && response != null && response.body.trim() == 'Kayıt başarılı.') {
        onSuccess?.call(response.body);
        return {'message': response.body};
      }
      throw Exception('Kayıt işlemi sırasında hata: $e');
    }
  }

  // Token gerektiren istekler için header oluşturma
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Örnek token gerektiren bir istek metodu
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Profil bilgileri alınamadı: ${response.body}');
      }
    } catch (e) {
      throw Exception('Bir hata oluştu: $e');
    }
  }
}
