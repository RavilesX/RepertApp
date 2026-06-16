import 'package:flutter_test/flutter_test.dart';
import 'package:repertapp/models/song.dart';
import 'package:repertapp/storage/song_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Song _song(String id, String title) => Song(
      id: id,
      artist: 'Artist $id',
      title: title,
      keyNote: 'C',
      keyAccidental: 'Ninguno',
      keyMode: 'Mayor',
      capo: 'Sin capo',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loadAll on a fresh store returns empty', () async {
    expect(await SongStorage().loadAll(), isEmpty);
  });

  test('saveAll then loadAll round-trips the list', () async {
    final storage = SongStorage();
    final songs = [_song('1', 'Uno'), _song('2', 'Dos')];

    await storage.saveAll(songs);
    final loaded = await storage.loadAll();

    expect(loaded.map((s) => s.id), ['1', '2']);
    expect(loaded.map((s) => s.title), ['Uno', 'Dos']);
  });

  test('saveAll overwrites the previous list', () async {
    final storage = SongStorage();
    await storage.saveAll([_song('1', 'Uno')]);
    await storage.saveAll([_song('2', 'Dos')]);

    final loaded = await storage.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.single.id, '2');
  });

  test('saving an empty list clears storage', () async {
    final storage = SongStorage();
    await storage.saveAll([_song('1', 'Uno')]);
    await storage.saveAll([]);

    expect(await storage.loadAll(), isEmpty);
  });
}
