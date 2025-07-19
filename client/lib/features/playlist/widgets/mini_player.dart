import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/player_viewmodel.dart';
import '../models/song.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({Key? key}) : super(key: key);

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  bool _isDragging = false;
  double _sliderValue = 0.0;

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
        if (!player.isVisible || player.currentSong == null) {
          return const SizedBox.shrink();
        }

        // Slider değerini güncelle (sürükleme sırasında değilse)
        if (!_isDragging && player.duration.inMilliseconds > 0) {
          _sliderValue = player.position.inMilliseconds / player.duration.inMilliseconds;
        }

        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context, 
              '/song-detail', 
              arguments: player.currentSong
            );
          },
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 0.5),
              ),
            ),
                    child: Column(
          children: [
            // Ana mini player içeriği
            Expanded(
              child: Row(
                    children: [
                      // Kapak görseli
                      Container(
                        margin: const EdgeInsets.all(8),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(player.currentSong!.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Şarkı adı ve sanatçı
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.currentSong!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              player.currentSong!.artist,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Play/Pause butonu
                      IconButton(
                        icon: Icon(
                          player.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          await player.togglePlayPause();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                // Slider - Alta taşındı ve beyaz renk
                Container(
                  height: 2,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.grey[800],
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withAlpha(32),
                      trackHeight: 2.0,
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 4.0,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 8.0,
                      ),
                    ),
                    child: Slider(
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 