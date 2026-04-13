import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class SongStorage {
  static const _key = 'songs_v1';

  Future<List<Song>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map(Song.fromJson).toList();
  }

  Future<void> saveAll(List<Song> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, songs.map((s) => s.toJson()).toList());
  }
}
