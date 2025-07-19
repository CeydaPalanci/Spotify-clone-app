import 'package:flutter/material.dart';
import 'package:client/features/playlist/service/favorite_service.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:client/features/home/view/api_constants.dart';
import 'package:client/features/home/view/pages/song_detail.dart';
import 'package:client/features/playlist/models/song.dart';
import 'package:client/features/playlist/viewmodel/player_viewmodel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:client/features/playlist/service/audio_service.dart';
import 'package:provider/provider.dart';

class LikedSongsScreen extends StatefulWidget {
  @override
  State<LikedSongsScreen> createState() => _LikedSongsScreenState();
}

class _LikedSongsScreenState extends State<LikedSongsScreen> {
  List<Song> songs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        isLoading = true;
      });

      final favorites = await FavoriteService.getFavorites();
      
      // API'dan gelen favori şarkıları Song nesnelerine dönüştür
      final List<Song> songList = favorites.map((json) => Song.fromJson(json)).toList();
      
      setState(() {
        songs = songList;
        isLoading = false;
      });
    } catch (e) {
      print('Favoriler yüklenirken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String streamUrl) async {
    try {
      final success = await FavoriteService.removeFavorite(streamUrl);
      if (success) {
        // Favorileri yeniden yükle
        await _loadFavorites();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şarkı favorilerden kaldırıldı'),
            backgroundColor: Color(0xFF1DB954),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şarkı kaldırılırken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Favori kaldırma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4F24DC), // Ana mor ton
              Color(0xFF3D1CA9), // Orta ton
              Color(0xFF2B1476), // Koyu mor
              Colors.black,
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildHeaderImage(),
              _buildPlaylistHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                    ),
                  ),
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1DB954),
                          ),
                        )
                      : songs.isEmpty
                          ? Center(
                              child: Text(
                                'Henüz favori şarkınız yok',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final song = songs[index];
                                return ListTile(
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
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey[800],
                                    ),
                                    child: song.imageUrl != null && song.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              song.imageUrl.startsWith('http')
                                                  ? song.imageUrl
                                                  : '${ApiConstants.baseUrl}${song.imageUrl}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Icon(
                                                Icons.music_note,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.music_note,
                                            color: Colors.white,
                                          ),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.favorite,
                                      color: Color(0xFF1DB954),
                                    ),
                                    onPressed: () => _removeFavorite(song.streamUrl),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Container(
        height: 180,
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          image: const DecorationImage(
            image: AssetImage("lib/assets/image/heart.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaylistHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
      child: Row(
        children: [
          Icon(Icons.download_for_offline, color: Colors.green),
          SizedBox(width: 10),
          Text("${songs.length} şarkı", style: TextStyle(color: Colors.grey)),
          Spacer(),
          // Karışık çal butonu
          GestureDetector(
            onTap: () => _playShuffle(),
            child: Icon(Icons.shuffle, color: Color(0xFF1DB954)),
          ),
          SizedBox(width: 10),
          // Play butonu
          GestureDetector(
            onTap: () => _playFromBeginning(),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFF1DB954),
              child: Icon(Icons.play_arrow, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
