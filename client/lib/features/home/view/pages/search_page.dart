import 'package:client/features/home/view/api_constants.dart';
import 'package:client/features/home/view/pages/model/update_playlist_model.dart';
import 'package:client/features/playlist/models/song.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:client/features/playlist/service/favorite_service.dart';
import 'package:client/features/playlist/viewmodel/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Song> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> searchSongs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isLoading = false;
      });
      return;
    }

    // Debouncing: Önceki timer'ı iptal et
    _debounceTimer?.cancel();
    
    // Yeni timer başlat (500ms bekle)
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      if (query != _currentQuery) {
        _currentQuery = query;
        
        setState(() {
          _isLoading = true;
        });

        try {
          final response = await http.get(
            Uri.parse('https://api.deezer.com/search?q=${Uri.encodeComponent(query)}&limit=15'),
          ).timeout(Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final results = data['data'] as List;
            
            List<Song> songs = results
                .map<Song>((json) => Song.fromDeezer(json))
                .toList();

            if (mounted) {
              setState(() {
                _searchResults = songs;
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            print('API Hatası: ${response.statusCode}');
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          print('Arama hatası: $e');
        }
      }
    });
  }

  void onMenuSelect(String value, Song song) async {
    print('onMenuSelect çağrıldı: $value, şarkı: ${song.title}');
    
    if (value == 'favorite') {
      print('Beğenilenlere ekleniyor: ${song.title}');
      
      // Song objesini Map'e çevir
      final songData = {
        'deezerId': song.deezerId,
        'title': song.title,
        'artist': song.artist,
        'album': song.album,
        'streamUrl': song.streamUrl,
        'imageUrl': song.imageUrl,
        'duration': song.duration,
      };
      
      try {
        final success = await FavoriteService.addFavorite(songData);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${song.title} beğenilenlere eklendi'),
              backgroundColor: Color(0xFF1DB954),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${song.title} beğenilenlere eklenirken hata oluştu'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Favori ekleme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favori ekleme hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (value == 'playlist') {
      print('Çalma listesi seçim dialog\'u açılıyor...');
      _showPlaylistSelectionDialog(song);
    }
  }

  Future<List<dynamic>> fetchPlaylists() async {
    print('fetchPlaylists başladı');
    try {
      final headers = await PlaylistService.getAuthHeaders();
      print('Headers alındı: $headers');
      
      final url = '${ApiConstants.baseUrl}/api/playlists';
      print('API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Çalma listeleri başarıyla alındı: ${data.length} adet');
        return data;
      } else {
        throw Exception('Çalma listeleri yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Çalma listeleri getirme hatası: $e');
      throw e;
    }
  }

  Future<void> addSongToPlaylist(int playlistId, Song song) async {
    try {
      final headers = await PlaylistService.getAuthHeaders();
      
      final songData = {
        'playlistId': playlistId,
        'DeezerId': song.deezerId,
        'Title': song.title,
        'Artist': song.artist,
        'Album': song.album,
        'StreamUrl': song.streamUrl,
        'ImageUrl': song.imageUrl,
        'Duration': song.duration,
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/playlists/add-song'),
        headers: {
          ...headers,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(songData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${song.title} çalma listesine eklendi'),
            backgroundColor: Color(0xFF1DB954),
          ),
        );
      } else {
        throw Exception('Şarkı eklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('Şarkı ekleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şarkı eklenirken hata oluştu: $e'),
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

  void _showPlaylistSelectionDialog(Song song) async {
    print('_showPlaylistSelectionDialog başladı');
    try {
      print('Çalma listeleri getiriliyor...');
      final playlists = await fetchPlaylists();
      print('Çalma listeleri alındı: ${playlists.length} adet');
      
      if (playlists.isEmpty) {
        print('Çalma listesi yok');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Henüz çalma listeniz yok'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      print('Dialog gösteriliyor...');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          print('Dialog builder çağrıldı');
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Çalma Listesi Seç',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    leading: playlist['imageUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              '${ApiConstants.baseUrl}${playlist['imageUrl']}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[800],
                                child: Icon(Icons.music_note, color: Colors.white),
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: Icon(Icons.music_note, color: Colors.white),
                          ),
                    title: Text(
                      playlist['name'] ?? 'Bilinmeyen Çalma Listesi',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      print('Çalma listesi seçildi: ${playlist['name']}');
                      Navigator.pop(context);
                      await addSongToPlaylist(playlist['id'], song);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'İptal',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
      print('Dialog gösterildi');
    } catch (e) {
      print('Dialog gösterme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çalma listeleri yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
            child: TextField(
              onChanged: (value) => searchSongs(value),
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ne dinlemek istiyorsun?',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
                strokeWidth: 2,
              ),
            ),
          Expanded(
            child: _searchResults.isEmpty && !_isLoading
                ? Center(
                    child: Text(
                      'Şarkı veya sanatçı ara...',
                      style: TextStyle(color: Colors.grey[400], fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final song = _searchResults[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () async {
                            // Deezer API'den preview URL'i al
                            try {
                              final previewUrl = await fetchDeezerPreviewUrl(int.parse(song.deezerId));
                              if (previewUrl != null && previewUrl.isNotEmpty) {
                                // PlayerViewModel'i tetikle
                                Provider.of<PlayerViewModel>(context, listen: false).playSongWithPreview(song, previewUrl);
                                
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                song.imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[800],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                        color: Color(0xFF1DB954),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: Icon(Icons.music_note, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton<String>(
                            color: Colors.grey[700],
                            onSelected: (value) => onMenuSelect(value, song),
                            icon: Icon(Icons.more_vert, color: Colors.white),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'favorite',
                                child: Row(
                                  children: [
                                    Icon(Icons.favorite, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Beğenilenlere Ekle'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'playlist',
                                child: Row(
                                  children: [
                                    Icon(Icons.playlist_add, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Çalma Listesine Ekle'),
                                    
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
