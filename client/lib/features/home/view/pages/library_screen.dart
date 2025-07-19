// ignore_for_file: use_key_in_widget_constructors

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:client/core/theme/app_pallete.dart';
import 'package:client/features/playlist/service/user_service.dart';
import 'package:client/features/home/view/pages/model/update_playlist_model.dart';
import 'package:client/features/home/view/pages/playlist_page.dart';
import 'package:client/features/home/view/pages/update_playlist.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:client/features/playlist/widgets/mini_player.dart';
import 'package:flutter/material.dart';
import 'package:client/features/home/view/pages/create_playlist.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

class LibraryScreen extends StatefulWidget {
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Playlist> playlists = [];
  String username = 'Kullanıcı Adı';
  String email = 'kullanici@email.com';
  String selectedCategory = 'Çalma Listeleri'; // Varsayılan seçili kategori

  final List<String> categories = [
    'Çalma Listeleri',
    'Beğenilen Şarkılar',
  ];

  final likedPlaylist = Playlist(
    id: -1, // özel bir id, çakışmasın diye negatif
    name: "Beğenilenler",
    imageUrl: "lib/assets/image/heart.png",
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getPlaylists();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await UserService.getUserInfo();
    setState(() {
      username = userInfo['username'] ?? 'Kullanıcı Adı';
      email = userInfo['email'] ?? 'kullanici@email.com';
    });
  }

  Future<void> _getPlaylists() async {
    print("Get isteği atılıyor");

    final headers = await PlaylistService.getAuthHeaders();

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/playlists'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      print("Get isteği başarılı");
      print(response.body);
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        playlists = data.map((json) => Playlist.fromJson(json)).toList();
      });
    } else {
      print("Get isteği başarısız");
      print(response.statusCode);
    }
  }

  Future<void> _logout() async {
    await UserService.clearUserInfo();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Filtrelenmiş playlist listesini döndür
  List<Playlist> getFilteredPlaylists() {
    switch (selectedCategory) {
      case 'Çalma Listeleri':
        return playlists; // Sadece kullanıcının çalma listeleri
      case 'Beğenilen Şarkılar':
        return [likedPlaylist]; // Sadece beğenilenler
      default:
        return [likedPlaylist, ...playlists]; // Tümü
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrelenmiş playlist listesi
    List<Playlist> displayPlaylists = getFilteredPlaylists();
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
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Kitaplığın',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
           /*  IconButton(
              icon: const Icon(Icons.search, size: 28, color: Colors.white),
              onPressed: () {
                // Arama işlemi
              },
            ), */
            const SizedBox(width: 4),
          ],
        ),
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
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                email,
                style: const TextStyle(
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
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Çıkış Yap',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori Butonları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: categories.map((cat) {
                    bool isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = cat;
                          });
                        },
                        child: Chip(
                          backgroundColor: isSelected 
                              ? Color(0xFF1DB954) 
                              : Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected 
                                  ? Color(0xFF1DB954) 
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          label: Text(cat,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Grid listesi
              Expanded(
                child: displayPlaylists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              selectedCategory == 'Çalma Listeleri' 
                                  ? Icons.playlist_add 
                                  : Icons.favorite_border,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              selectedCategory == 'Çalma Listeleri'
                                  ? 'Henüz çalma listeniz yok'
                                  : 'Henüz beğendiğiniz şarkı yok',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              selectedCategory == 'Çalma Listeleri'
                                  ? 'İlk çalma listenizi oluşturmak için + butonuna tıklayın'
                                  : 'Beğendiğiniz şarkılar burada görünecek',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: displayPlaylists.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                    itemBuilder: (context, index) {
                      final playlist = displayPlaylists[index];
                      return GestureDetector(
                        onTap: () {
                          if (playlist.id == -1) {
                            Navigator.pushNamed(context, '/favourites');
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistScreen(
                                  name: playlist.name,
                                  imageUrl: playlist.imageUrl,
                                  id: playlist.id.toString(),
                                ),
                              ),
                            );
                          }
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                child: playlist.id == -1
                                    ? Image.asset(
                                        playlist.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: playlist.imageUrl.isNotEmpty
                                            ? "${ApiConstants.baseUrl}${playlist.imageUrl}"
                                            : "lib/assets/image/default-image.png",
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              playlist.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          /* // Sabit müzik çubuğu
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/song-detail');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                height: 75,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[900]!,
                      Colors.grey[850]!,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Albüm kapağı
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'lib/assets/image/billie.png',
                        width: 55,
                        height: 55,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 12),

                    // Şarkı adı ve sanatçı
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "WILDFLOWER",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Billie Eilish",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[300]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 10),
                          Container(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.grey[800],
                                thumbColor: Color(0xFF1DB954),
                                overlayColor: Color(0xFF1DB954).withAlpha(32),
                                trackHeight: 2.0,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 0.0,
                                ),
                                overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 0.0,
                                ),
                              ),
                              child: Slider(
                                value: 0.3,
                                onChanged: (value) {
                                  // Slider değeri değiştiğinde yapılacak işlemler
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Oynat/Durdur butonu
                    IconButton(
                      onPressed: () {
                        // oynat/durdur işlemleri buraya
                      },
                      icon: Icon(Icons.play_arrow),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ), */
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(),
          BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home), label: "Ana Sayfa"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.library_music), label: "Kİtaplığın"),
              BottomNavigationBarItem(icon: Icon(Icons.add), label: "Oluştur"),
            ],
            currentIndex: 1,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/home');
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreatePlaylistScreen(sourcePage: 'library'),
                  ),
                );
              }
            },
            selectedItemColor: Color(0xFF1DB954),
            unselectedItemColor: Colors.white70,
            backgroundColor: Colors.black,
          ),
        ],
      ),
    );
  }
}
