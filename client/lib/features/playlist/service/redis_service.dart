import 'dart:convert';
import 'package:client/features/home/view/api_constants.dart';
import 'package:http/http.dart' as http;
import '../models/song.dart';
import 'package:flutter/foundation.dart';

class RedisService {
  static const String baseUrl = ApiConstants.baseUrl; // Backend URL'inizi buraya yazın
  
  // Kullanıcının son çaldığı şarkıyı Redis'e kaydet
  static Future<void> saveLastPlayedSong(String userId, Song song) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/redis/last-played'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'songId': song.id,
          'songData': song.toJson(),
        }),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Redis kaydetme hatası: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Redis servis hatası: $e');
      }
    }
  }

  // Kullanıcının son çaldığı şarkıyı Redis'ten al
  static Future<Song?> getLastPlayedSong(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/redis/last-played/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['songData'] != null) {
          return Song.fromJson(data['songData']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Redis okuma hatası: $e');
      }
    }
    return null;
  }

  // Kullanıcının çalma geçmişini Redis'e kaydet
  static Future<void> savePlayHistory(String userId, List<Song> songs) async {
    try {
      final songList = songs.map((song) => song.toJson()).toList();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/redis/play-history'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'songs': songList,
        }),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Çalma geçmişi kaydetme hatası: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Çalma geçmişi servis hatası: $e');
      }
    }
  }

  // Kullanıcının çalma geçmişini Redis'ten al
  static Future<List<Song>> getPlayHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/redis/play-history/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['songs'] != null) {
          final List<dynamic> songList = data['songs'];
          return songList.map((songData) => Song.fromJson(songData)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Çalma geçmişi okuma hatası: $e');
      }
    }
    return [];
  }

  // Şarkı pozisyonunu Redis'e kaydet
  static Future<void> saveSongPosition(String userId, String songId, Duration position) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/redis/song-position'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'songId': songId,
          'position': position.inMilliseconds,
        }),
      );

      if (response.statusCode != 200) {
        if (kDebugMode) {
          print('Şarkı pozisyonu kaydetme hatası: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Şarkı pozisyonu servis hatası: $e');
      }
    }
  }

  // Şarkı pozisyonunu Redis'ten al
  static Future<Duration?> getSongPosition(String userId, String songId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/redis/song-position/$userId/$songId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['position'] != null) {
          return Duration(milliseconds: data['position']);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Şarkı pozisyonu okuma hatası: $e');
      }
    }
    return null;
  }
} 