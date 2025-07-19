import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/view/api_constants.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:client/features/playlist/viewmodel/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:client/features/playlist/models/song.dart';
import 'package:provider/provider.dart';

class SongAddPage extends StatefulWidget {
  final int playlistId;

  const SongAddPage({super.key, required this.playlistId});

  @override
  State<SongAddPage> createState() => _SongAddPageState();
}

class _SongAddPageState extends State<SongAddPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _songs = [];
  List<Song> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    fetchSongsFromDeezer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> searchSongs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
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
          _isSearching = true;
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

  Future<void> addSongToPlaylist({
    required int playlistId,
    required String deezerId,
    required String title,
    required String artist,
    required String album,
    required String streamUrl,
    required String imageUrl,
    required int duration,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/playlists/add-song');
      final headers = {'Content-Type': 'application/json'};

      final body = jsonEncode({
        'playlistId': playlistId,
        'DeezerId': deezerId,
        'Title': title,
        'Artist': artist,
        'Album': album,
        'StreamUrl': streamUrl,
        'ImageUrl': imageUrl,
        'Duration': duration,
      });

      print('Şarkı ekleme isteği gönderiliyor...');
      print('URL: $url');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Şarkı başarıyla eklendi!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title çalma listesine eklendi!'),
              backgroundColor: Color(0xFF1DB954),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Hata oluştu: ${response.statusCode}');
        print('Hata detayı: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Şarkı eklenirken hata oluştu: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('İstek atılırken hata oluştu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağlantı hatası: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> fetchSongsFromDeezer() async {
    try {
      final response = await http.get(Uri.parse('https://api.deezer.com/chart'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final trackList = data['tracks']['data'];

        //şarkıları rastgele sırala ve 20 tanesini al
        List<Song> allSongs = [];
        
        for (var json in trackList) {
          try {
            allSongs.add(Song.fromDeezer(json));
          } catch (e) {
            print('Şarkı dönüştürme hatası: $e');
            print('Problemli JSON: $json');
            continue; // Bu şarkıyı atla ve devam et
          }
        }
        
        allSongs.shuffle();
        final limitedSongs = allSongs.take(20).toList();

        setState(() {
          _songs = limitedSongs;
        });
      } else {
        print("Şarkılar yüklenemedi: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Deezer API'den şarkı çekme hatası: $e");
      // Kullanıcıya hata mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şarkılar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          'Şarkı veya sanatçı ara...',
          style: TextStyle(color: Colors.grey[400], fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final song = _searchResults[index];
        return _buildSongTile(song);
      },
    );
  }

  Widget _buildRecommendedSongs() {
    return ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return _buildSongTile(song);
      },
    );
  }

  Widget _buildSongTile(Song song) {
    return ListTile(
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
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          song.imageUrl,
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
      ),
      title: Text(
        song.title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        onPressed: () async {
          // Loading göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Şarkı ekleniyor...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );
          
          await addSongToPlaylist(
            playlistId: widget.playlistId,
            deezerId: song.deezerId,
            title: song.title,
            artist: song.artist,
            album: song.album,
            streamUrl: song.streamUrl,
            imageUrl: song.imageUrl,
            duration: song.duration,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pallete.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bu çalma listesine ekle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => searchSongs(value),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  constraints: BoxConstraints(maxHeight: 40),
                  icon: Icon(Icons.search, color: Colors.white),
                  hintText: 'Ne dinlemek istiyorsun?',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  color: Color(0xFF1DB954),
                  strokeWidth: 2,
                ),
              ),
            
            // Content based on search state
            if (!_isSearching) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Önerilen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Expanded(
              child: _isSearching 
                ? _buildSearchResults()
                : _buildRecommendedSongs(),
            ),
          ],
        ),
      ),
    );
  }
}
