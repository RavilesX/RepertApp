import 'package:flutter_test/flutter_test.dart';
import 'package:repertapp/models/song.dart';
import 'package:repertapp/utils/song_formatting.dart';

Song _song({
  String artist = '',
  String title = '',
  String keyNote = 'C',
  String keyAccidental = 'Ninguno',
  String keyMode = 'Mayor',
}) =>
    Song(
      id: '$artist-$title',
      artist: artist,
      title: title,
      keyNote: keyNote,
      keyAccidental: keyAccidental,
      keyMode: keyMode,
      capo: 'Sin capo',
    );

void main() {
  group('titleCase', () {
    test('capitalises each word', () {
      expect(SongFormatting.titleCase('de música ligera'), 'De Música Ligera');
    });

    test('preserves intentional casing in the rest of the word', () {
      expect(SongFormatting.titleCase('REM unplugged'), 'REM Unplugged');
      expect(SongFormatting.titleCase('ac/dc live'), 'Ac/dc Live');
    });

    test('collapses repeated whitespace', () {
      expect(SongFormatting.titleCase('  a   b  '), 'A B');
    });

    test('empty string stays empty', () {
      expect(SongFormatting.titleCase(''), '');
    });
  });

  group('capoLabel', () {
    test('passes the no-capo sentinel through', () {
      expect(SongFormatting.capoLabel('Sin capo'), 'Sin capo');
    });

    test('prefixes a numeric fret', () {
      expect(SongFormatting.capoLabel('3'), 'Capo 3');
    });
  });

  group('sorted', () {
    final a = _song(artist: 'Zoé', title: 'Labios Rotos', keyNote: 'A');
    final b = _song(artist: 'aterciopelados', title: 'Bolero Falaz', keyNote: 'G');
    final c = _song(artist: 'Mon Laferte', title: 'Amárrame', keyNote: 'C');
    final input = [a, b, c];

    test('by title ascending is case-insensitive', () {
      final r = SongFormatting.sorted(input, SortColumn.title);
      expect(r.map((s) => s.title), ['Amárrame', 'Bolero Falaz', 'Labios Rotos']);
    });

    test('descending reverses order', () {
      final r =
          SongFormatting.sorted(input, SortColumn.title, ascending: false);
      expect(r.map((s) => s.title), ['Labios Rotos', 'Bolero Falaz', 'Amárrame']);
    });

    test('by artist ignores case (lowercase artist not pushed last)', () {
      final r = SongFormatting.sorted(input, SortColumn.artist);
      expect(r.map((s) => s.artist), ['aterciopelados', 'Mon Laferte', 'Zoé']);
    });

    test('by key uses keyLabel', () {
      final r = SongFormatting.sorted(input, SortColumn.key);
      expect(r.map((s) => s.keyLabel), ['A', 'C', 'G']);
    });

    test('does not mutate the input list', () {
      final copy = [...input];
      SongFormatting.sorted(input, SortColumn.title);
      expect(input, copy);
    });
  });
}
