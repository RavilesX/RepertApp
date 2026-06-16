import '../models/song.dart';

/// Pure presentation/sorting helpers for [Song].
///
/// Kept free of Flutter and plugin imports so they can be unit-tested without
/// a widget binding.
class SongFormatting {
  const SongFormatting._();

  /// Capitalises the first letter of each whitespace-separated word and
  /// collapses runs of spaces. The rest of each word is preserved as typed, so
  /// intentional casing survives ("REM", "AC/DC", "iPhone" stay intact).
  static String titleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  /// Human label for a capo value. The sentinel 'Sin capo' is passed through;
  /// any other value is prefixed.
  static String capoLabel(String capo) =>
      capo == 'Sin capo' ? 'Sin capo' : 'Capo $capo';

  /// Lower-cased sort key for the given column.
  static String sortKey(Song s, SortColumn col) {
    switch (col) {
      case SortColumn.artist:
        return s.artist.toLowerCase();
      case SortColumn.title:
        return s.title.toLowerCase();
      case SortColumn.key:
        return s.keyLabel.toLowerCase();
    }
  }

  /// Returns a new list sorted by [col]; [ascending] flips the order.
  static List<Song> sorted(
    List<Song> songs,
    SortColumn col, {
    bool ascending = true,
  }) {
    final list = [...songs];
    list.sort((a, b) {
      final cmp = sortKey(a, col).compareTo(sortKey(b, col));
      return ascending ? cmp : -cmp;
    });
    return list;
  }
}

/// Column the song list is ordered by. Lives here (not in the screen) so the
/// sort helpers above stay plugin-free and testable.
enum SortColumn { artist, title, key }
