import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/home/view/pages/create_playlist.dart';
import 'package:flutter/foundation.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/playlist/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:client/features/home/view/pages/library_screen.dart';
import 'package:client/features/playlist/service/recent_songs_service.dart';
import 'package:client/features/playlist/service/favorite_service.dart';
import 'package:client/features/playlist/models/song.dart';
import 'package:client/features/playlist/service/user_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Song> _recentSongs = [];
  List<Song> _favoriteSongs = [];
  List<Map<String, dynamic>> _recentArtists = [];
  bool _isLoading = true;
  Map<String, String> _userInfo = {
    'username': 'Kullanıcı',
    'email': 'kullanici@email.com',
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LibraryScreen()),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CreatePlaylistScreen(sourcePage: 'home')),
      ).then((_) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['resetIndex'] == true) {
      setState(() {
        _selectedIndex = 0;
      });
    }
    
    // Sadece sayfa ilk kez yüklendiğinde verileri yenile
    if (_recentSongs.isEmpty && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadData();
      });
    }
  }

  // Sayfa geri döndüğünde çağrılacak metod
  void refreshData() {
    _loadData(forceRefresh: true);
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    // Eğer veriler zaten yüklüyse ve force refresh istenmiyorsa, tekrar yükleme
    if (!_isLoading && _recentSongs.isNotEmpty && !forceRefresh) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        // Eski verileri temizle
        _recentSongs.clear();
        _favoriteSongs.clear();
        _recentArtists.clear();
      });

      // Kullanıcı bilgilerini yükle
      final userInfo = await UserService.getUserInfo();
      
      // Son çalınan şarkıları yükle
      final recentSongs = await RecentSongsService.getRecentSongs();
      
      // Favori şarkıları yükle
      final favorites = await FavoriteService.getFavorites();
      final favoriteSongs = favorites.map((json) => Song.fromJson(json)).toList();

      // Son dinlenen sanatçıları yükle
      final recentArtists = await _loadRecentArtists(recentSongs);

      if (mounted) {
        setState(() {
          _userInfo = userInfo;
          _recentSongs = recentSongs;
          _favoriteSongs = favoriteSongs;
          _recentArtists = recentArtists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Veri yüklenirken hata: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Son dinlenen sanatçıları yükle
  Future<List<Map<String, dynamic>>> _loadRecentArtists(List<Song> songs) async {
    List<Map<String, dynamic>> artists = [];
    Set<String> uniqueArtists = {};
    
    for (var song in songs) {
      if (!uniqueArtists.contains(song.artist) && artists.length < 6) {
        uniqueArtists.add(song.artist);
        
        // Deezer API'den sanatçı bilgilerini çek
        try {
          final artistInfo = await _fetchArtistInfo(song.artist);
          artists.add({
            'name': song.artist,
            'imageUrl': artistInfo['picture_medium'] ?? 'lib/assets/image/default-image.png',
            'deezerId': artistInfo['id']?.toString() ?? '',
          });
        } catch (e) {
          if (kDebugMode) {
            print('Sanatçı bilgisi çekilemedi: $e');
          }
          artists.add({
            'name': song.artist,
            'imageUrl': 'lib/assets/image/default-image.png',
            'deezerId': '',
          });
        }
      }
    }
    
    return artists;
  }

  // Deezer API'den sanatçı bilgilerini çek
  Future<Map<String, dynamic>> _fetchArtistInfo(String artistName) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.deezer.com/search/artist?q=${Uri.encodeComponent(artistName)}&limit=1'),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          return data['data'][0];
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sanatçı arama hatası: $e');
      }
    }
    
    return {};
  }

  List<Map<String, dynamic>> get categoriesWithImages {
    List<Map<String, dynamic>> categories = [];
    
    // Beğenilen Şarkılar - Her zaman sabit kalp ikonu kullan
    categories.add({
      "title": "Beğenilen Şarkılar",
      "image": "lib/assets/image/heart.png",
      "type": "favorites",
    });
    
    // En çok dinlenen albüm kategorisi - Dinamik başlık ve resim
    if (_recentSongs.isNotEmpty) {
      // En çok tekrar eden albümü bul
      Map<String, int> albumCounts = {};
      Map<String, Song> albumSongs = {};
      
      for (var song in _recentSongs) {
        albumCounts[song.imageUrl] = (albumCounts[song.imageUrl] ?? 0) + 1;
        albumSongs[song.imageUrl] = song; // Her albüm için bir şarkı sakla
      }
      
      var mostPlayedEntry = albumCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      String mostPlayedImage = mostPlayedEntry.key;
      Song mostPlayedSong = albumSongs[mostPlayedImage]!;
      
      categories.add({
        "title": "${mostPlayedSong.artist} - ${mostPlayedSong.album}",
        "image": mostPlayedImage,
        "type": "recent",
        "song": mostPlayedSong,
      });
    } else {
      categories.add({
        "title": "Çalmaya Doyamadıkların",
        "image": "lib/assets/image/calmaya_doyamadiklarin.png",
        "type": "recent",
      });
    }
    
    // Son çalınan şarkılardan farklı albümleri ekle (maksimum 3 tane)
    if (_recentSongs.isNotEmpty) {
      // Son çalınan şarkılardan farklı albümleri al
      Set<String> uniqueAlbums = {};
      List<Song> uniqueAlbumSongs = [];
      
      for (var song in _recentSongs) {
        if (!uniqueAlbums.contains(song.imageUrl) && uniqueAlbumSongs.length < 3) {
          uniqueAlbums.add(song.imageUrl);
          uniqueAlbumSongs.add(song);
        }
      }
      
      for (int i = 0; i < uniqueAlbumSongs.length; i++) {
        var song = uniqueAlbumSongs[i];
        categories.add({
          "title": "${song.artist} - ${song.album}",
          "image": song.imageUrl,
          "type": "album",
          "song": song,
        });
      }
    }
    
    return categories;
  }

  List<Map<String, dynamic>> get recentSongsList {
    // Son çalınan şarkıları döndür (maksimum 4 tane)
    return _recentSongs.take(4).map((song) => {
      "title": song.title,
      "desc": song.artist,
      "image": song.imageUrl,
      "song": song,
    }).toList();
  }

  final List<String> categories = [
    'Tümü',
    'Müzik',
    'Podcast',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.account_circle_rounded,
                size: 32, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, color: Colors.grey[400], size: 20),
                SizedBox(width: 8),
                Text(
                  'Ne dinlemek istiyorsun?',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Pallete.backgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                _userInfo['username'] ?? 'Kullanıcı',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _userInfo['email'] ?? 'kullanici@email.com',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: const Text(
                  'Ayarlar',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Ayarlar sayfasına yönlendirme
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.white),
                title: const Text(
                  'Yardım',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Yardım sayfasına yönlendirme
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'Hesabını Sil',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  // Hesap silme onayı
                  bool? confirmDelete = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text(
                          'Hesabını Sil',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'İptal',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(
                              'Sil',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDelete == true) {
                    // Loading göster
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey[900],
                          content: Row(
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF1DB954),
                                strokeWidth: 2,
                              ),
                              SizedBox(width: 20),
                              Text(
                                'Hesap siliniyor...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    // Hesabı sil
                    bool success = await UserService.deleteAccount();
                    
                    // Loading dialogunu kapat
                    Navigator.of(context).pop();

                    if (success) {
                      // Başarılı silme
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hesabınız başarıyla silindi.'),
                          backgroundColor: Color(0xFF1DB954),
                        ),
                      );
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      // Hata durumu
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hesap silinirken bir hata oluştu.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1DB954),
                strokeWidth: 2,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategoriler (Tümü, Müzik, Podcast)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  backgroundColor: Color(0xFF1DB954),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  label: Text('Tümü',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  backgroundColor: Colors.grey[850],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  label: Text('Müzik',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      )),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  backgroundColor: Colors.grey[850],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  label: Text('Podcast',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Kategoriler
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categoriesWithImages.map((category) {
                          return GestureDetector(
                            onTap: () {
                              if (category["type"] == "favorites") {
                                Navigator.pushNamed(context, '/favourites');
                              } else if (category["type"] == "album" && category["song"] != null) {
                                // Albüm kategorisine tıklandığında şarkı detay sayfasına git
                                final song = category["song"] as Song;
                                Navigator.pushNamed(
                                  context,
                                  '/song-detail',
                                  arguments: song,
                                );
                              }
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width / 2 - 24,
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: Colors.grey[850],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  category["image"]!.startsWith('lib/assets/')
                                      ? Image.asset(
                                          category["image"]!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.fill,
                                        )
                                      : Image.network(
                                          category["image"]!,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.fill,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.grey[700],
                                              child: Icon(Icons.music_note, color: Colors.white),
                                            );
                                          },
                                        ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category["title"]!,
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 24),

                      // Son Çalınanlar bölümü - sadece şarkı çalınmışsa göster
                      if (_recentSongs.isNotEmpty) ...[
                        Text(
                          "Son Çalınanlar",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recentSongsList.length,
                            itemBuilder: (context, index) {
                              final mix = recentSongsList[index];
                              return Container(
                                width: 140,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.all(8),
                                child: GestureDetector(
                                  onTap: () {
                                    if (mix['song'] != null) {
                                      final song = mix['song'] as Song;
                                      // Şarkı detay sayfasına git
                                      Navigator.pushNamed(
                                        context,
                                        '/song-detail',
                                        arguments: song,
                                      );
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 100,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: mix['image']!.startsWith('lib/assets/')
                                              ? Image.asset(
                                                  mix['image']!,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                )
                                              : Image.network(
                                                  mix['image']!,
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[700],
                                                      child: Icon(Icons.music_note, color: Colors.white, size: 40),
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        mix['title']!,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        mix['desc']!,
                                        style: TextStyle(fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      SizedBox(height: 24),

                // Son Dinlenen Sanatçılar bölümü
                if (_recentArtists.isNotEmpty) ...[
                  Text(
                    "Son Dinlenen Sanatçılar",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentArtists.length,
                      itemBuilder: (context, index) {
                        final artist = _recentArtists[index];
                        return Container(
                          width: 100,
                          margin: EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                              // Sanatçı fotoğrafı (yuvarlak)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                          ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: artist['imageUrl'].startsWith('lib/assets/')
                                      ? Image.asset(
                                          artist['imageUrl'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[700],
                                              child: Icon(Icons.person, color: Colors.white, size: 40),
                                            );
                                          },
                                        )
                                      : Image.network(
                                          artist['imageUrl'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[700],
                                              child: Icon(Icons.person, color: Colors.white, size: 40),
                                            );
                                          },
                            ),
                          ),
                              ),
                              SizedBox(height: 8),
                              // Sanatçı adı
                              Text(
                                artist['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                    ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: 24),
                  ],
                ),
              ),

      // Alt menü çubuğu
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),
          BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Ana Sayfa"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.library_music), label: "Kitaplığın"),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: "Oluştur"),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Color(0xFF1DB954),
            unselectedItemColor: Colors.white70,
            backgroundColor: Colors.black,
          ),
        ],
      ),
    );
  }
}
