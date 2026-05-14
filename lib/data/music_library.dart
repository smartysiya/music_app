/// Central data model for a Song.
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final String imageUrl;
  final String genre;
  final String license;
  final String? localPath; // null = not downloaded yet

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.imageUrl,
    this.genre = 'Electronic',
    this.license = 'CC BY-NC 4.0',
    this.localPath,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? duration,
    String? imageUrl,
    String? genre,
    String? license,
    String? localPath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      genre: genre ?? this.genre,
      license: license ?? this.license,
      localPath: localPath ?? this.localPath,
    );
  }
}

/// Shared in-memory library — expand by adding more Song objects here.
class MusicLibrary {
  static const List<Song> songs = [
    Song(
      id: '1',
      title: 'Faded',
      artist: 'Alan Walker',
      album: 'Different World',
      duration: '3:32',
      imageUrl: 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=400',
      genre: 'Progressive House',
      license: 'Merlin (on behalf of Alan Walker Recordings)',
    ),
    Song(
      id: '2',
      title: 'Alone',
      artist: 'Alan Walker',
      album: 'Different World',
      duration: '2:57',
      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
      genre: 'Electro House',
      license: 'SME (on behalf of Alan Walker Recordings)',
    ),
    Song(
      id: '3',
      title: 'Happier',
      artist: 'Marshmello',
      album: 'Joytime III',
      duration: '4:38',
      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      genre: 'Pop / EDM',
      license: 'Astralwerks; LatinAutor - SonyATV',
    ),
    Song(
      id: '4',
      title: 'Hate the Other Side',
      artist: 'Marshmello',
      album: 'Joytime III',
      duration: '3:40',
      imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
      genre: 'Trap / Hip-Hop',
      license: 'Juice WRLD (on behalf of Grade A Productions/Interscope)',
    ),
    Song(
      id: '5',
      title: 'Levels',
      artist: 'Avicii',
      album: 'True',
      duration: '3:18',
      imageUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=400',
      genre: 'EDM',
      license: 'UMG (on behalf of Avicii Music)',
    ),
    Song(
      id: '6',
      title: 'Wake Me Up',
      artist: 'Avicii',
      album: 'True',
      duration: '4:07',
      imageUrl: 'https://images.unsplash.com/photo-1493225457124-a1a2a5f5f92a?w=400',
      genre: 'Folktronica',
      license: 'Universal Music AB',
    ),
    Song(
      id: '7',
      title: 'The Spectre',
      artist: 'Alan Walker',
      album: 'Different World',
      duration: '3:15',
      imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
      genre: 'Big Room House',
      license: 'Alan Walker Recordings',
    ),
    Song(
      id: '8',
      title: 'Titanium',
      artist: 'David Guetta',
      album: 'Nothing But the Beat',
      duration: '4:05',
      imageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      genre: 'Dance-Pop',
      license: 'Parlophone / Warner Music Group',
    ),
  ];

  static List<String> get albums =>
      songs.map((s) => s.album).toSet().toList();

  static List<String> get artists =>
      songs.map((s) => s.artist).toSet().toList();

  static List<Song> songsByAlbum(String album) =>
      songs.where((s) => s.album == album).toList();

  static List<Song> songsByArtist(String artist) =>
      songs.where((s) => s.artist == artist).toList();

  static String coverForAlbum(String album) =>
      songsByAlbum(album).first.imageUrl;

  static String coverForArtist(String artist) =>
      songsByArtist(artist).first.imageUrl;
}
