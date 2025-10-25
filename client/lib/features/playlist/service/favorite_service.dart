import 'dart:convert';
import 'package:client/features/home/view/api_constants.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FavoriteService {
  static Future<bool> addFavorite(Map<String, dynamic> song) async {
    final headers =
        await PlaylistService.getAuthHeaders(); // JWT içeren headers

    // Eksik alan varsa işlemi iptal et
    if (song['streamUrl'] == null || song['streamUrl'].isEmpty) {
      print("⚠️ Şarkının streamUrl alanı eksik.");
      return false;
    }

    final body = {
      'DeezerId': song['deezerId'] ?? '',
      'Title': song['title'],
      'Artist': song['artist'],
      'Album': song['album'] ?? '',
      'StreamUrl': song['streamUrl'] ?? '',
      'ImageUrl': song['imageUrl'] ?? '',
      'Duration': song['duration'] ?? 0,
    };

    // Önce endpoint'i test edelim
    if (kDebugMode) {
      print("🔍 Favori ekleme endpoint'i test ediliyor...");
    }
    
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/playlists/favorite-add'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (kDebugMode) {
      print("Favori ekleme cevabı: ${response.statusCode}");
    }

    if (response.statusCode != 200) {
      if (kDebugMode) {
        print("❌ Favori ekleme başarısız: ${response.statusCode}");
      }
    }

    return response.statusCode == 200;
  }

  // 2. Favoriden çıkar
  static Future<bool> removeFavorite(String streamUrl) async {
    final headers = await PlaylistService.getAuthHeaders();

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/api/playlists/remove-favorite?streamUrl=${Uri.encodeComponent(streamUrl)}'),
      headers: headers,
    );

    if (kDebugMode) {
      print('Favoriden çıkarma cevabı: ${response.statusCode}');
    }
    return response.statusCode == 200;
  }

  // 3. Kullanıcının favorilerini getir
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final headers = await PlaylistService.getAuthHeaders();

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/playlists/get-favorite'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      if (kDebugMode) {
        print('Favori getirme hatası: ${response.statusCode}');
      }
      return [];
    }
  }
}
