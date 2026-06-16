import 'package:flutter_test/flutter_test.dart';
import 'package:repertapp/models/song.dart';

Song _song({
  String id = '1',
  String artist = 'Soda Stereo',
  String title = 'De Música Ligera',
  String keyNote = 'C',
  String keyAccidental = 'Ninguno',
  String keyMode = 'Mayor',
  String capo = 'Sin capo',
  String? imagePath,
  String? thumbPath,
}) =>
    Song(
      id: id,
      artist: artist,
      title: title,
      keyNote: keyNote,
      keyAccidental: keyAccidental,
      keyMode: keyMode,
      capo: capo,
      imagePath: imagePath,
      thumbPath: thumbPath,
    );

void main() {
  group('Song.keyLabel', () {
    test('major, no accidental', () {
      expect(_song(keyNote: 'C', keyMode: 'Mayor').keyLabel, 'C');
    });

    test('minor adds m', () {
      expect(_song(keyNote: 'A', keyMode: 'Menor').keyLabel, 'Am');
    });

    test('accidental is appended', () {
      expect(
        _song(keyNote: 'F', keyAccidental: '#', keyMode: 'Mayor').keyLabel,
        'F#',
      );
    });

    test('minor + accidental: accidental precedes the m', () {
      expect(
        _song(keyNote: 'B', keyAccidental: 'b', keyMode: 'Menor').keyLabel,
        'Bbm',
      );
    });

    test('Desconocida ignores accidental and mode', () {
      expect(
        _song(keyNote: 'Desconocida', keyAccidental: '#', keyMode: 'Menor')
            .keyLabel,
        'Desconocida',
      );
    });
  });

  group('Song JSON round-trip', () {
    test('preserves all fields including image paths', () {
      final original = _song(
        imagePath: '/data/song_images/1_123.webp',
        thumbPath: '/data/song_images/1_123_thumb.webp',
      );
      final restored = Song.fromJson(original.toJson());
      expect(restored.toMap(), original.toMap());
    });

    test('null image paths survive', () {
      final restored = Song.fromJson(_song().toJson());
      expect(restored.imagePath, isNull);
      expect(restored.thumbPath, isNull);
    });
  });

  group('Song.fromMap legacy note migration', () {
    test('Spanish solfège names map to international notation', () {
      const cases = {
        'Do': 'C',
        'Re': 'D',
        'Mi': 'E',
        'Fa': 'F',
        'Sol': 'G',
        'La': 'A',
        'Si': 'B',
      };
      cases.forEach((legacy, expected) {
        final song = Song.fromMap(_song(keyNote: legacy).toMap());
        expect(song.keyNote, expected, reason: '$legacy -> $expected');
      });
    });

    test('already-migrated notes are left untouched', () {
      final song = Song.fromMap(_song(keyNote: 'G').toMap());
      expect(song.keyNote, 'G');
    });

    test('Desconocida is left untouched', () {
      final song = Song.fromMap(_song(keyNote: 'Desconocida').toMap());
      expect(song.keyNote, 'Desconocida');
    });
  });
}
