import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;
  static String? _currentUrl;

  static Future<void> playPreview(String previewUrl) async {
    try {
      if (_currentUrl != previewUrl) {
        // Yeni şarkı çalınıyorsa
        await _player.stop();
        await _player.setUrl(previewUrl);
        _currentUrl = previewUrl;
      }
      
      await _player.play();
      _isPlaying = true;
      
      // 30 saniye sonra otomatik durdur
      Future.delayed(Duration(seconds: 30), () {
        if (_isPlaying && _currentUrl == previewUrl) {
          _player.stop();
          _isPlaying = false;
        }
      });
      
    } catch (e) {
      print('Şarkı çalma hatası: $e');
    }
  }

  static Future<void> play() async {
    try {
      await _player.play();
      _isPlaying = true;
    } catch (e) {
      print('Şarkı çalma hatası: $e');
    }
  }

  static Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      print('Şarkı durdurma hatası: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentUrl = null;
    } catch (e) {
      print('Şarkı durdurma hatası: $e');
    }
  }

  static Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('Şarkı konumlandırma hatası: $e');
    }
  }

  static bool get isPlaying => _isPlaying;
  static String? get currentUrl => _currentUrl;
  
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  static Stream<Duration?> get positionStream => _player.positionStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  
  static Duration? get position => _player.position;
  static Duration? get duration => _player.duration;
}