// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:client/core/theme/app_pallete.dart';
import 'package:flutter/foundation.dart';
import 'package:client/features/playlist/models/song.dart';
import 'package:client/features/playlist/service/audio_service.dart';
import 'package:client/features/playlist/service/favorite_service.dart';
import 'package:client/features/playlist/viewmodel/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';

class MusicPlayerScreen extends StatefulWidget {
  final Song song;
  const MusicPlayerScreen({Key? key, required this.song}) : super(key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class SongDetailPage extends StatelessWidget {
  const SongDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Song song = ModalRoute.of(context)!.settings.arguments as Song;
    return MusicPlayerScreen(song: song);
  }
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  Color backgroundColor = Colors.black; // Arka plan rengi başlangıç
  late PaletteGenerator palette;
  bool isFavorite = true; // Başlangıçta şarkı favori değil
  bool _isDragging = false;
  double _sliderValue = 0.0;
  Song? _currentDisplayedSong;

  @override
  void initState() {
    super.initState();
    _currentDisplayedSong = widget.song;
    _updateBackgrundColor();
    _checkFavoriteStatus();
  }

  Future<void> _updateBackgrundColor() async {
    final imageProvider = NetworkImage(widget.song.imageUrl);
    palette = await PaletteGenerator.fromImageProvider(imageProvider);
    setState(() {
      backgroundColor = palette.darkVibrantColor?.color ?? Colors.black;
    });
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final favorites = await FavoriteService.getFavorites();
      final isFav = favorites.any((fav) => 
        fav['streamUrl'] == widget.song.streamUrl || 
        fav['audio'] == widget.song.streamUrl
      );
      
      setState(() {
        isFavorite = isFav;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Favori durumu kontrol edilirken hata: $e');
      }
    }
  }

  Future<String?> fetchDeezerPreviewUrl(int deezerId) async {
    if (kDebugMode) {
      print("fetchDeezerPreviewUrl çağrıldı: $deezerId");
    }
    final response =
        await http.get(Uri.parse('https://api.deezer.com/track/$deezerId'));
    if (kDebugMode) {
      print("API response alındı");
    }
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (kDebugMode) {
        print("Preview URL alındı");
      }
      return data['preview'];
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, player, child) {
        // Şarkı değiştiğinde sayfayı güncelle
        if (player.currentSong != null && 
            player.currentSong!.deezerId != _currentDisplayedSong?.deezerId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _currentDisplayedSong = player.currentSong;
            });
            _updateBackgrundColor();
            _checkFavoriteStatus();
          });
        }
        
        // Slider değerini güncelle (sürükleme sırasında değilse)
        if (!_isDragging && player.duration.inMilliseconds > 0) {
          _sliderValue = player.position.inMilliseconds / player.duration.inMilliseconds;
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                            iconSize: 40,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.keyboard_arrow_down_sharp,
                                color: Colors.white))),
                    const SizedBox(height: 20),
                    const Column(
                      children: [
                        Text("KİTAPLIĞIN'DAN ÇALINIYOR",
                            style: TextStyle(color: Colors.white70, fontSize: 15)),
                        Text(
                          'Beğenilen Şarkılar',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _currentDisplayedSong?.imageUrl ?? widget.song.imageUrl,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0), // Görselle hizalanır
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentDisplayedSong?.title ?? widget.song.title,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentDisplayedSong?.artist ?? widget.song.artist,
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          try {
                            final currentSong = _currentDisplayedSong ?? widget.song;
                            bool success;
                            if (isFavorite) {
                              // Favoriden çıkar
                              success = await FavoriteService.removeFavorite(currentSong.streamUrl);
                            } else {
                              // Favoriye ekle
                              success = await FavoriteService.addFavorite({
                                'deezerId': currentSong.deezerId,
                                'title': currentSong.title,
                                'artist': currentSong.artist,
                                'album': currentSong.album,
                                'streamUrl': currentSong.streamUrl,
                                'imageUrl': currentSong.imageUrl,
                                'duration': currentSong.duration,
                              });
                            }
                            
                            if (success) {
                              setState(() {
                                isFavorite = !isFavorite;
                              });
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isFavorite 
                                    ? '${currentSong.title} beğenilenlere eklendi'
                                    : '${currentSong.title} beğenilenlerden çıkarıldı'),
                                  backgroundColor: Color(0xFF1DB954),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('İşlem başarısız'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (kDebugMode) {
                              print('Favori işlemi hatası: $e');
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Favori işlemi hatası: $e'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Color(0xFF1DB954) : Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Slider
                Slider(
                  value: _sliderValue.clamp(0.0, 1.0),
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) {
                    setState(() {
                      _sliderValue = value;
                      _isDragging = true;
                    });
                  },
                  onChangeEnd: (value) async {
                    setState(() {
                      _isDragging = false;
                    });
                    // Şarkıyı yeni konuma taşı
                    final newPosition = Duration(
                      milliseconds: (value * player.duration.inMilliseconds).round(),
                    );
                    await player.seek(newPosition);
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(player.position),
                        style: TextStyle(color: Colors.white54)
                      ),
                      Text(
                        _formatDuration(player.duration),
                        style: TextStyle(color: Colors.white54)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Karışık Çal (Shuffle)
                    IconButton(
                      icon: Icon(
                        Icons.shuffle, 
                        color: player.isShuffle ? Color(0xFF1DB954) : Colors.white
                      ),
                      onPressed: () {
                        player.toggleShuffle();
                      },
                    ),

                    const SizedBox(width: 30),

                    // Önceki Şarkı
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 40, color: Colors.white),
                      onPressed: () async {
                        if (player.playlist.isNotEmpty) {
                          await player.playPrevious();
                          // Yeni şarkı için sayfayı güncelle
                          if (player.currentSong != null) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/song-detail',
                              arguments: player.currentSong,
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(width: 10),

                    // Play/Pause Butonu
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                          icon: Icon(
                              player.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black),
                          iconSize: 32,
                          onPressed: () async {
                            final currentSong = _currentDisplayedSong ?? widget.song;
                            if (player.currentSong?.streamUrl == currentSong.streamUrl) {
                              // Aynı şarkı çalıyorsa play/pause toggle yap
                              await player.togglePlayPause();
                            } else {
                              // Yeni şarkı çal
                              if (kDebugMode) {
                                print("song.deezerId: ${currentSong.deezerId}");
                              }
                              final previewUrl =
                                  await fetchDeezerPreviewUrl(int.parse(currentSong.deezerId));
                              if (kDebugMode) {
                                print("Gelen previewUrl: $previewUrl");
                              }
                              if (previewUrl != null && previewUrl.isNotEmpty) {
                                if (kDebugMode) {
                                  print("Çalınıyor...");
                                }
                                await player.playSongWithPreview(currentSong, previewUrl);
                              } else {
                                if (kDebugMode) {
                                  print("Preview yok!");
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Bu şarkının önizlemesi yok!')),
                                );
                              }
                            }
                          }),
                    ),

                    const SizedBox(width: 10),

                    // Sonraki Şarkı
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 40, color: Colors.white),
                      onPressed: () async {
                        if (player.playlist.isNotEmpty) {
                          await player.playNext();
                          // Yeni şarkı için sayfayı güncelle
                          if (player.currentSong != null) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/song-detail',
                              arguments: player.currentSong,
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(width: 30),

                    // Tekrar Çal (Repeat)
                    IconButton(
                      icon: Icon(
                        Icons.repeat, 
                        color: player.isRepeat ? Color(0xFF1DB954) : Colors.white
                      ),
                      onPressed: () {
                        player.toggleRepeat();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
