class Song {
  final String deezerId;
  final String title;
  final String artist;
  final String album;
  final String streamUrl;
  final String imageUrl;
  final int duration;

  Song({
    required this.deezerId,
    required this.title,
    required this.artist,
    required this.album,
    required this.streamUrl,
    required this.imageUrl,
    required this.duration,
  });

  factory Song.fromJamendo(Map<String, dynamic> json) {
    return Song(
      deezerId: json['id']?.toString() ?? '',
      title: json['name'] ?? '',
      artist: json['artist_name'] ?? '',
      album: json['album_name'] ?? '',
      streamUrl: json['audio'] ?? '',
      imageUrl: json['album_image'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  factory Song.fromDeezer(Map<String, dynamic> json) {
    return Song(
      deezerId: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      artist: json['artist']?['name'] ?? '',
      album: json['album']?['title'] ?? '',
      streamUrl: json['preview'] ?? '',
      imageUrl: json['album']?['cover_medium'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      deezerId: json['deezerId']?.toString() ?? "",
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      streamUrl: json['streamUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  // Backend'den gelen playlist şarkıları için
  factory Song.fromPlaylistJson(Map<String, dynamic> json) {
    return Song(
      deezerId: json['deezerId']?.toString() ?? "",
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      album: json['album'] ?? '',
      streamUrl: json['streamUrl'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  // SongId'yi almak için getter
  String get id => deezerId;

  // JSON'a çevirme metodu
  Map<String, dynamic> toJson() {
    return {
      'deezerId': deezerId,
      'title': title,
      'artist': artist,
      'album': album,
      'streamUrl': streamUrl,
      'imageUrl': imageUrl,
      'duration': duration,
    };
  }
}
