import 'package:client/core/theme/theme.dart';
import 'package:client/features/auth/view/pages/login_page.dart';
import 'package:client/features/auth/view/pages/signup_page.dart';
import 'package:client/features/home/view/pages/create_playlist.dart';
import 'package:client/features/home/view/pages/favourites_page.dart';
import 'package:client/features/home/view/pages/home_page.dart';
import 'package:client/features/home/view/pages/library_screen.dart';
import 'package:client/features/home/view/pages/playlist_page.dart';
import 'package:client/features/home/view/pages/search_page.dart';
import 'package:client/features/home/view/pages/song_add.dart';
import 'package:client/features/home/view/pages/song_detail.dart';
import 'package:client/features/home/view/pages/update_playlist.dart';
import 'package:client/features/playlist/viewmodel/player_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerViewModel()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: AppTheme.darkThemeMode,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => LoginPage(),
          '/home': (context) => HomePage(),
          '/library': (context) => LibraryScreen(),
          '/create-playlist': (context) => CreatePlaylistScreen(sourcePage: 'home'),
          '/playlist': (context) => PlaylistScreen(name: '', imageUrl: '', id: "y"),
          '/favourites': (context) => LikedSongsScreen(),
          '/login': (context) => const LoginPage(),
          '/update_playlist': (context) => UpdatePlaylistScreen(updateName: '', updateImageUrl: '', id: ""),
          '/song-add': (context) => SongAddPage(playlistId: 0),
          '/search': (context) => SearchPage(),
          '/song-detail': (context) => SongDetailPage(),
        },
      ),
    );
  }
}