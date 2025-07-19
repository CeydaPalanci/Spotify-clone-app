import 'package:flutter/material.dart';
import '../models/song.dart';
import '../service/audio_service.dart';
import '../service/recent_songs_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlayerViewModel extends ChangeNotifier {
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isVisible = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<Song> _playlist = [];
  int _currentIndex = 0;
  bool _isShuffle = false;
  bool _isRepeat = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isVisible => _isVisible;
  Duration get position => _position;
  Duration get duration => _duration;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;

  PlayerViewModel() {
    // Audio service stream'lerini dinle
    AudioService.positionStream.listen((position) {
      if (position != null) {
        _position = position;
        notifyListeners();
      }
    });

    AudioService.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    AudioService.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      
              // Şarkı bittiğinde otomatik geçiş
        if (!state.playing && _position.inMilliseconds > 0 && 
            _position.inMilliseconds >= _duration.inMilliseconds - 1000) {
          playNext();
        }
      
      notifyListeners();
    });
  }

  // Playlist ayarla
  void setPlaylist(List<Song> songs, int startIndex) {
    _playlist = List<Song>.from(songs);
    _currentIndex = startIndex;
    _currentSong = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
    notifyListeners();
  }

  // Tek şarkı çal
  Future<void> playSong(Song song) async {
    _currentSong = song;
    _isVisible = true;
    notifyListeners();
    
    // Son çalınan şarkılar listesine ekle
    await RecentSongsService.addRecentSong(song);
    
    // Audio service ile şarkıyı çal
    await AudioService.playPreview(song.streamUrl);
  }

  Future<void> playSongWithPreview(Song song, String previewUrl) async {
    _currentSong = song;
    _isVisible = true;
    notifyListeners();
    
    // Son çalınan şarkılar listesine ekle
    await RecentSongsService.addRecentSong(song);
    
    // Audio service ile şarkıyı çal
    await AudioService.playPreview(previewUrl);
  }

  // Playlist ile çal
  Future<void> playPlaylist(List<Song> songs, int startIndex) async {
    setPlaylist(songs, startIndex);
    if (_currentSong != null) {
      await playSong(_currentSong!);
    }
  }

  // Sonraki şarkı
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    
    if (_isShuffle) {
      // Karışık modda rastgele şarkı seç
      int randomIndex;
      do {
        randomIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
      } while (randomIndex == _currentIndex && _playlist.length > 1);
      _currentIndex = randomIndex;
    } else {
      // Sıralı modda sonraki şarkı
      _currentIndex = (_currentIndex + 1) % _playlist.length;
    }
    
    _currentSong = _playlist[_currentIndex];
    await _playSongWithPreview(_currentSong!);
  }

  // Önceki şarkı
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    if (_isShuffle) {
      // Karışık modda rastgele şarkı seç
      int randomIndex;
      do {
        randomIndex = DateTime.now().millisecondsSinceEpoch % _playlist.length;
      } while (randomIndex == _currentIndex && _playlist.length > 1);
      _currentIndex = randomIndex;
    } else {
      // Sıralı modda önceki şarkı
      _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    }
    
    _currentSong = _playlist[_currentIndex];
    await _playSongWithPreview(_currentSong!);
  }

  // Preview URL ile şarkı çal (private method)
  Future<void> _playSongWithPreview(Song song) async {
    try {
      // Deezer API'den preview URL al
      final response = await http.get(
        Uri.parse('https://api.deezer.com/track/${song.deezerId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final previewUrl = data['preview'];
        
        if (previewUrl != null && previewUrl.isNotEmpty) {
          await playSongWithPreview(song, previewUrl);
        } else {
          print('Preview URL bulunamadı: ${song.title}');
          // Preview URL yoksa streamUrl'i dene
          await playSong(song);
        }
      } else {
        print('Deezer API hatası: ${response.statusCode}');
        // API hatası durumunda streamUrl'i dene
        await playSong(song);
      }
    } catch (e) {
      print('Preview URL alma hatası: $e');
      // Hata durumunda streamUrl'i dene
      await playSong(song);
    }
  }

  // Karışık modu toggle
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // Tekrar modu toggle
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_currentSong == null) return;
    
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    await AudioService.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resume() async {
    await AudioService.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await AudioService.seek(position);
  }

  void hide() {
    _isVisible = false;
    _currentSong = null;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _playlist.clear();
    _currentIndex = 0;
    AudioService.stop();
    notifyListeners();
  }
} 