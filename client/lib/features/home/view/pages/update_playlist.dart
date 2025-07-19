import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:client/features/playlist/service/playlist_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../api_constants.dart';

class UpdatePlaylistScreen extends StatefulWidget {
  final String updateName;
  final String updateImageUrl;
  final String id;
  const UpdatePlaylistScreen(
      {super.key,
      required this.updateName,
      required this.updateImageUrl,
      required this.id});

  @override
  _UpdatePlaylistScreenState createState() => _UpdatePlaylistScreenState();
}

class _UpdatePlaylistScreenState extends State<UpdatePlaylistScreen> {
  late TextEditingController _controller;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.updateName);
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resim seçilirken bir hata oluştu'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> updatePlaylist(String id,
      {String? name, File? imageFile}) async {
    try {

      var uri = Uri.parse('${ApiConstants.baseUrl}/api/playlists/$id');
      var request = http.MultipartRequest('PUT', uri);

      final headers = await PlaylistService.getAuthHeaders();
      request.headers.addAll(headers);

      // Eğer yeni isim varsa ekle
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }

      // Eğer resim varsa ekle
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('imageFile', imageFile.path),
        );
      }

      // Sunucuya isteği gönder
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Güncellenmiş playlist objesini veya en azından güncel veriyi oluştur
        final updatedPlaylist = {
          'id': id,
          'name': name ?? widget.updateName,
          'imageUrl':
              '${ApiConstants.baseUrl}${widget.updateImageUrl}', // güncel resim url'sini API'den alman gerekir
        };

        Navigator.of(context).pop(updatedPlaylist); // Geri dön ve veriyi gönder
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Çalma listesi başarıyla güncellendi'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${response.statusCode}'),
            duration: Duration(seconds: 2),
          ),
        );
        print(response.body);
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
                  Colors.grey, // Spotify Green
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Çalma listesini Düzenle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.black45,
                        ),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: _image != null
                                ? Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    fit: BoxFit.cover,
                                    imageUrl:
                                        '${ApiConstants.baseUrl}${widget.updateImageUrl}',
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                  )),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Resmi değiştir",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: '',
                        contentPadding: EdgeInsets.only(bottom: 8),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
                            Navigator.pop(context);
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
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: () {
                            updatePlaylist(widget.id,
                                name: _controller.text, imageFile: _image);
                          },
                          child: const Text('Kaydet',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
