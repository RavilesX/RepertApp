import 'dart:convert';

class Song {
  String id;
  String artist;
  String title;
  String keyNote;
  String keyAccidental;
  String keyMode;
  String capo;

  Song({
    required this.id,
    required this.artist,
    required this.title,
    required this.keyNote,
    required this.keyAccidental,
    required this.keyMode,
    required this.capo,
  });

  String get keyLabel => _formatChord(keyNote, keyAccidental, keyMode);

  static String _formatChord(String note, String accidental, String mode) {
    final acc = accidental == 'Ninguno' ? '' : accidental;
    final m = mode == 'Menor' ? 'm' : '';
    return '$note$m$acc';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'artist': artist,
        'title': title,
        'keyNote': keyNote,
        'keyAccidental': keyAccidental,
        'keyMode': keyMode,
        'capo': capo,
      };

  static const Map<String, String> _noteMigration = {
    'Do': 'C',
    'Re': 'D',
    'Mi': 'E',
    'Fa': 'F',
    'Sol': 'G',
    'La': 'A',
    'Si': 'B',
  };

  static String _migrateNote(String n) => _noteMigration[n] ?? n;

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        id: map['id'] as String,
        artist: map['artist'] as String,
        title: map['title'] as String,
        keyNote: _migrateNote(map['keyNote'] as String),
        keyAccidental: map['keyAccidental'] as String,
        keyMode: map['keyMode'] as String,
        capo: map['capo'] as String,
      );

  String toJson() => jsonEncode(toMap());
  factory Song.fromJson(String source) =>
      Song.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
