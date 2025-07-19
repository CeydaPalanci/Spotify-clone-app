import 'dart:io';
import 'dart:ui';
import 'package:client/features/home/view/api_constants.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final String sourcePage;
  const CreatePlaylistScreen({Key? key, required this.sourcePage})
      : super(key: key);

  @override
  _CreatePlaylistScreenState createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _controller = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPlaylist() async {
    final playlistName = _controller.text.trim();

    if (playlistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çalma listesi adı boş olamaz')),
      );
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf seçilmedi')),
      );
      return;
    }

    try {
      print('POST atılıyor: $playlistName');

      final headers = await PlaylistService.getAuthHeaders();

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(
            '${ApiConstants.baseUrl}/api/playlists/upload'), // <-- BURAYI GÜNCELLE
      );
      request.headers.addAll(headers);
      request.fields['name'] = playlistName;

      // 📷 image dosyası var mı kontrol et
      if (_image != null) {
        final image = await http.MultipartFile.fromPath(
          'ImageFile', // ⚠️ BU İSİM DTO'daki ile birebir aynı olmalı
          _image!.path,
        );
        request.files.add(image);
      } else {
        print("❗ Resim dosyası boş!");
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Durum: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çalma listesi oluşturuldu!')),
        );
        if (widget.sourcePage == 'home') {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/library');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: ${response.statusCode}')));
      }
    } catch (e) {
      print('⚠️ HATA OLDU: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sunucuya bağlanılamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎨 Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1DB954), // Spotify Green
                  Colors.black, // Bottom black
                ],
              ),
            ),
          ),

          // 🌫 Blur Efekti
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.2), // Blur üstü hafif karartma
            ),
          ),

          // 📦 Asıl İçerik
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Çalma listene bir isim ver',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'Çalma listesi adı...',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF1DB954)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Çalma listene fotoğraf ekle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black45,
                    ),
                    child: _image == null
                        ? Center(
                            child: IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_a_photo,
                                  size: 50, color: Colors.grey),
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black45,
                                    ),
                                    padding: EdgeInsets.all(6),
                                    child:
                                        Icon(Icons.edit, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          if (widget.sourcePage == 'home') {
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            Navigator.pushReplacementNamed(context, '/library');
                          }
                        },
                        child: const Text('İptal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1DB954),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          _createPlaylist();
                        },
                        child: const Text('Oluştur',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
