import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class RecentSongsService {
  static const String _recentSongsKey = 'recent_songs';
  static const int _maxRecentSongs = 10;

  // Son çalınan şarkıyı kaydet
  static Future<void> addRecentSong(Song song) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSongsJson = prefs.getString(_recentSongsKey);
      
      List<Map<String, dynamic>> recentSongs = [];
      if (recentSongsJson != null) {
        recentSongs = List<Map<String, dynamic>>.from(
          jsonDecode(recentSongsJson).map((x) => Map<String, dynamic>.from(x))
        );
      }

      // Aynı şarkı varsa kaldır (tekrar eklemek için)
      recentSongs.removeWhere((s) => s['deezerId'] == song.deezerId);

      // Yeni şarkıyı başa ekle
      recentSongs.insert(0, {
        'deezerId': song.deezerId,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'streamUrl': song.streamUrl,
        'imageUrl': song.imageUrl,
        'duration': song.duration,
        'playedAt': DateTime.now().toIso8601String(),
      });

      // Maksimum sayıyı aşarsa en eski şarkıları kaldır
      if (recentSongs.length > _maxRecentSongs) {
        recentSongs = recentSongs.take(_maxRecentSongs).toList();
      }

      await prefs.setString(_recentSongsKey, jsonEncode(recentSongs));
    } catch (e) {
      print('Son çalınan şarkı kaydedilirken hata: $e');
    }
  }

  // Son çalınan şarkıları getir
  static Future<List<Song>> getRecentSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSongsJson = prefs.getString(_recentSongsKey);
      
      if (recentSongsJson == null) {
        return [];
      }

      final recentSongs = List<Map<String, dynamic>>.from(
        jsonDecode(recentSongsJson).map((x) => Map<String, dynamic>.from(x))
      );

      return recentSongs.map((songData) => Song.fromJson(songData)).toList();
    } catch (e) {
      print('Son çalınan şarkılar getirilirken hata: $e');
      return [];
    }
  }

  // Son çalınan şarkıları temizle
  static Future<void> clearRecentSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSongsKey);
    } catch (e) {
      print('Son çalınan şarkılar temizlenirken hata: $e');
    }
  }

  // Son çalınan şarkı sayısını getir
  static Future<int> getRecentSongsCount() async {
    final songs = await getRecentSongs();
    return songs.length;
  }
} 