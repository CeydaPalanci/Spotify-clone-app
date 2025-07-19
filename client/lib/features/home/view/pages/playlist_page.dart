import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:client/features/home/view/pages/song_add.dart';
import 'package:client/features/home/view/pages/song_detail.dart';
import 'package:client/features/home/view/pages/update_playlist.dart';
import 'package:client/features/playlist/models/song.dart';
import 'package:client/features/playlist/service/favorite_service.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:client/features/playlist/service/user_service.dart';
import 'package:client/features/playlist/viewmodel/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_constants.dart';

class PlaylistScreen extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String? id;

  const PlaylistScreen({
    required this.name,
    required this.imageUrl,
    required this.id,
  });
  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Song> songs = [];
  bool isLoading = true;
  

  Future<List<dynamic>> fetchSongsForPlaylist(int playlistId) async {
    print('Şarkılar çekiliyor, Playlist ID: $playlistId');
    print('API URL: ${ApiConstants.baseUrl}/api/playlists/$playlistId/songs');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/playlists/$playlistId/songs'),
    );

    print('API Response Status: ${response.statusCode}');
    print('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Şarkılar yüklenemedi: ${response.statusCode}');
    }

  }

  Future<void> _deleteSongFromPlaylist(int playlistId, int songId) async {
    try {
      final headers = await PlaylistService.getAuthHeaders();

      print('Şarkı siliniyor - Playlist ID: $playlistId, Song ID: $songId');

      // Backend'de PlaylistSongs tablosundan silme
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/playlists/delete-song/$songId'),
        headers: headers,
      );

      print('Silme response status: ${response.statusCode}');
      print('Silme response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Şarkı başarıyla silindi');
        return; // Başarılı
      } else {
        print('❌ Şarkı silinemedi: ${response.statusCode}');
        print('❌ Hata detayı: ${response.body}');
        throw Exception('Şarkı silinemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Şarkı silme hatası: $e');
      throw e;
    }
  }

  Future<void> _deletePlaylist(String id) async {
    try {
      final headers = await PlaylistService.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/playlists/${id}'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        Navigator.of(context).pop(); // Dialog'u kapat
        Navigator.of(context).pop(); // Playlist sayfasını kapat
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalma listesi başarıyla silindi'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalma listesi silinirken bir hata oluştu'),
            duration: Duration(seconds: 2),
          ),
        );
        print(response.body);
        print(response.statusCode);
      }
    } catch (e) {
      print('Hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bir hata oluştu'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Map<int, bool> isFavorite = {};
  Map<int, int> songIds = {}; // Şarkı index'i -> songId mapping
  String playlistOwner = "by Ceyda Palancı"; // Varsayılan değer

  // Playlist süresini hesapla
  String calculatePlaylistDuration() {
    if (songs.isEmpty) return "0 dk. 0 sn.";
    
    int totalSeconds = 0;
    for (var song in songs) {
      totalSeconds += song.duration;
    }
    
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    
    return "$minutes dk. $seconds sn.";
  }

  // Playlist sahibini al
  Future<void> getPlaylistOwner() async {
    try {
      final userInfo = await UserService.getUserInfo();
      setState(() {
        playlistOwner = "by ${userInfo['username'] ?? 'Ceyda Palancı'}";
      });
    } catch (e) {
      print('Kullanıcı bilgisi alınırken hata: $e');
      // Hata durumunda varsayılan değer kalır
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSongs();
    getPlaylistOwner();
  }

  Future<void> _loadSongs() async {
    try {
      if (widget.id != null) {
        final fetchedSongs = await fetchSongsForPlaylist(int.parse(widget.id!));
        print('API\'den gelen şarkılar: $fetchedSongs'); // Debug için
        
        // API'dan gelen şarkıları Song nesnelerine dönüştür
        final List<Song> songList = fetchedSongs.map((json) => Song.fromJson(json)).toList();
        
        // Her şarkı için id bilgisini sakla
        for (int i = 0; i < fetchedSongs.length; i++) {
          final json = fetchedSongs[i];
          final songId = json['id'] as int?;
          if (songId != null) {
            songIds[i] = songId; // songIds map'ine ekle
          }
        }
        
        // Favori durumlarını kontrol et
        await _checkFavoriteStatus(songList);
        
        setState(() {
          songs = songList; // Artık Song nesneleri listesi
          isLoading = false;
        });
      }
    } catch (e) {
      print('Şarkılar yüklenirken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkFavoriteStatus(List<Song> songs) async {
    try {
      // Kullanıcının favorilerini getir
      final favorites = await FavoriteService.getFavorites();
      
      // Her şarkı için favori durumunu kontrol et
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        final songStreamUrl = song.streamUrl;
        
        // Favoriler listesinde bu şarkı var mı kontrol et
        final isFav = favorites.any((fav) => 
          fav['streamUrl'] == songStreamUrl || 
          fav['audio'] == songStreamUrl
        );
        
        isFavorite[i] = isFav;
      }
    } catch (e) {
      print('Favori durumu kontrol edilirken hata: $e');
      // Hata durumunda tüm şarkıları favori değil olarak işaretle
      for (int i = 0; i < songs.length; i++) {
        isFavorite[i] = false;
      }
    }
  }

  Future<void> _updateFavoriteStatus(int index) async {
    try {
      // Kullanıcının favorilerini getir
      final favorites = await FavoriteService.getFavorites();
      final song = songs[index];
      final songStreamUrl = song.streamUrl;
      
      // Bu şarkının favori durumunu kontrol et
      final isFav = favorites.any((fav) => 
        fav['streamUrl'] == songStreamUrl || 
        fav['audio'] == songStreamUrl
      );
      
      setState(() {
        isFavorite[index] = isFav;
      });
    } catch (e) {
      print('Favori durumu güncellenirken hata: $e');
    }
  }

  Future<String?> fetchDeezerPreviewUrl(int deezerId) async {
    print("fetchDeezerPreviewUrl çağrıldı: $deezerId");
    final response =
        await http.get(Uri.parse('https://api.deezer.com/track/$deezerId'));
    print("API response: ${response.body}");
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Preview: ${data['preview']}");
      return data['preview'];
    }
    return null;
  }

  // En baştan çal
  Future<void> _playFromBeginning() async {
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çalacak şarkı bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // PlayerViewModel'e playlist'i set et
      final player = Provider.of<PlayerViewModel>(context, listen: false);
      player.setPlaylist(songs, 0);
      
      // İlk şarkıyı çal
      final firstSong = songs[0];
      final previewUrl = await fetchDeezerPreviewUrl(int.parse(firstSong.deezerId));
      
      if (previewUrl != null && previewUrl.isNotEmpty) {
        // PlayerViewModel'i tetikle
        player.playSongWithPreview(firstSong, previewUrl);
        
        // Song detail sayfasına git
        Navigator.pushNamed(
          context,
          '/song-detail',
          arguments: firstSong,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu şarkının önizlemesi yok!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şarkı çalınırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Karışık çal
  Future<void> _playShuffle() async {
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çalacak şarkı bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // PlayerViewModel'e playlist'i set et ve shuffle modunu aç
      final player = Provider.of<PlayerViewModel>(context, listen: false);
      player.setPlaylist(songs, 0);
      player.toggleShuffle(); // Shuffle modunu aç
      
      // Rastgele bir şarkı seç
      final randomIndex = DateTime.now().millisecondsSinceEpoch % songs.length;
      final randomSong = songs[randomIndex];
      final previewUrl = await fetchDeezerPreviewUrl(int.parse(randomSong.deezerId));
      
      if (previewUrl != null && previewUrl.isNotEmpty) {
        // PlayerViewModel'i tetikle
        player.playSongWithPreview(randomSong, previewUrl);
        
        // Song detail sayfasına git
        Navigator.pushNamed(
          context,
          '/song-detail',
          arguments: randomSong,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bu şarkının önizlemesi yok!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şarkı çalınırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 63, 62, 62),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst bar (geri + üç nokta menüsü)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const BackButton(color: Colors.white),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey[900],
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (BuildContext context) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit,
                                        color: Colors.white),
                                    title: const Text('Çalma listesini düzenle',
                                        style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UpdatePlaylistScreen(
                                            updateName: widget.name,
                                            updateImageUrl: widget.imageUrl,
                                            id: widget.id ?? '',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete,
                                        color: Colors.white),
                                    title: const Text('Çalma listesini sil',
                                        style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: Colors.grey[900],
                                            title: const Text(
                                              'Çalma Listesini Sil',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            content: const Text(
                                              'Bu çalma listesini silmek istediğinize emin misiniz?',
                                              style: TextStyle(
                                                  color: Colors.white70),
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text(
                                                  'İptal',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              TextButton(
                                                  child: const Text(
                                                    'Sil',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF1DB954)),
                                                  ),
                                                  onPressed: () async {
                                                    if (widget.id != null) {
                                                      await _deletePlaylist(
                                                          widget.id!);
                                                    } else {
                                                      print(
                                                          "Playlist ID null! Silme işlemi yapılamıyor.");
                                                    }
                                                  }),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.add,
                                        color: Colors.white),
                                    title: const Text(
                                        'Çalma listesine şarkı ekle',
                                        style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SongAddPage(
                                            playlistId: int.parse(widget.id!),
                                          ),
                                        ),
                                      );
                                      // Şarkı ekleme işlemi
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Kapak ve bilgiler
              Column(
                children: [
                  Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            fit: BoxFit.cover,
                            imageUrl:
                                '${ApiConstants.baseUrl}${widget.imageUrl}',
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          ))),
                  const SizedBox(height: 10),
                  Text(widget.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(calculatePlaylistDuration(),
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                ],
              ),
              // Playlist sahibi + butonlar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(playlistOwner,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15)),
                      ),
                    ),
                    // Karışık çal butonu
                    GestureDetector(
                      onTap: () => _playShuffle(),
                      child: Icon(Icons.shuffle, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    // Play butonu
                    GestureDetector(
                      onTap: () => _playFromBeginning(),
                      child: CircleAvatar(
                        backgroundColor: Color(0xFF1DB954),
                        child: Icon(Icons.play_arrow, color: Colors.black),
                        radius: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Şarkı listesi

              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1DB954),
                        ),
                      )
                    : songs.isEmpty
                        ? const Center(
                            child: Text(
                              'Bu çalma listesinde henüz şarkı yok',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          )
                        : ListView.builder(
                            itemCount: songs.length,
                            itemBuilder: (context, index) {
                              final song = songs[index];

                              return Dismissible(
                                key: Key(song.title),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (direction) async {
                                  final songToDelete = songs[index];
                                  final playlistId = int.parse(widget.id!);
                                  final songId = songIds[index];

                                  try {
                                    if (songId != null) {
                                      // Önce API'den sil
                                      await _deleteSongFromPlaylist(playlistId, songId);
                                    }

                                    // Başarılı olursa UI'dan kaldır
                                    setState(() {
                                      songs.removeAt(index);
                                      isFavorite.remove(index);
                                      songIds.remove(index);
                                      
                                      // Index'leri yeniden düzenle
                                      final newSongIds = <int, int>{};
                                      songIds.forEach((key, value) {
                                        if (key > index) {
                                          newSongIds[key - 1] = value;
                                        } else {
                                          newSongIds[key] = value;
                                        }
                                      });
                                      songIds.clear();
                                      songIds.addAll(newSongIds);
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${songToDelete.title} silindi'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Color(0xFF1DB954),
                                      ),
                                    );
                                  } catch (e) {
                                    // Hata durumunda kullanıcıya bilgi ver
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Şarkı silinirken hata oluştu: $e'),
                                        duration: Duration(seconds: 3),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    print('Şarkı silme hatası: $e');
                                  }
                                },
                                child: ListTile(
                                  onTap: () async {
                                    // Deezer API'den preview URL'i al
                                    try {
                                      final previewUrl = await fetchDeezerPreviewUrl(int.parse(song.deezerId));
                                      if (previewUrl != null && previewUrl.isNotEmpty) {
                                        // PlayerViewModel'e playlist'i set et ve şarkıyı çal
                                        final player = Provider.of<PlayerViewModel>(context, listen: false);
                                        player.setPlaylist(songs, index); // Playlist'i set et, tıklanan şarkıdan başla
                                        player.playSongWithPreview(song, previewUrl);
                                        
                                        // Song detail sayfasına git
                                        Navigator.pushNamed(
                                          context,
                                          '/song-detail',
                                          arguments: song,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Bu şarkının önizlemesi yok!'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Şarkı çalınırken hata oluştu: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Builder(
                                      builder: (context) {
                                        // Farklı olası resim field'larını kontrol et
                                        String? imageUrl = song.imageUrl;

                                        print(
                                            'Şarkı: ${song.title}, Resim URL: $imageUrl'); // Debug için

                                        if (imageUrl != null &&
                                            imageUrl.isNotEmpty) {
                                          // URL zaten tam ise direkt kullan, değilse base URL ekle
                                          String fullImageUrl = imageUrl
                                                  .startsWith('http')
                                              ? imageUrl
                                              : '${ApiConstants.baseUrl}$imageUrl';

                                          return CachedNetworkImage(
                                            imageUrl: fullImageUrl,
                                            height: 50,
                                            width: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 50,
                                              width: 50,
                                              color: Colors.grey[800],
                                              child: Icon(Icons.music_note,
                                                  color: Colors.white),
                                            ),
                                            errorWidget: (context, url, error) {
                                              print(
                                                  'Resim yükleme hatası: $error, URL: $fullImageUrl'); // Debug için
                                              return Container(
                                                height: 50,
                                                width: 50,
                                                color: Colors.grey[800],
                                                child: Icon(Icons.error,
                                                    color: Colors.white),
                                              );
                                            },
                                          );
                                        } else {
                                          return Container(
                                            height: 50,
                                            width: 50,
                                            color: Colors.grey[800],
                                            child: Icon(Icons.music_note,
                                                color: Colors.white),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                  ),
                                  trailing: IconButton(
                                      icon: Icon(
                                        isFavorite[index] == true
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite[index] == true
                                            ? Color(0xFF1DB954)
                                            : Colors.white,
                                      ),
                                      onPressed: () async {
                                        final headers = await PlaylistService
                                            .getAuthHeaders();
                                        final token = headers['Authorization'];

                                        if (token == null || token.isEmpty) {
                                          // Kullanıcı giriş yapmamış
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('Lütfen giriş yapın')),
                                          );
                                          return;
                                        }

                                        bool alreadyFav =
                                            isFavorite[index] == true;

                                        bool success = alreadyFav
                                            ? await FavoriteService
                                                .removeFavorite(song.streamUrl)
                                            : await FavoriteService.addFavorite({
                                                'deezerId': song.deezerId,
                                                'title': song.title,
                                                'artist': song.artist,
                                                'album': song.album,
                                                'streamUrl': song.streamUrl,
                                                'imageUrl': song.imageUrl,
                                                'duration': song.duration,
                                              });

                                        if (success) {
                                          // Favori durumunu backend'den yeniden kontrol et
                                          await _updateFavoriteStatus(index);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('İşlem başarısız')),
                                          );
                                        }
                                      }),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
