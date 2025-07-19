class Playlist {
  final int id;
  final String name;
  final String imageUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }
}
