import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/song.dart';
import '../storage/song_storage.dart';
import 'image_service.dart';

class ImportResult {
  final int imported;
  final int replaced;
  const ImportResult({required this.imported, required this.replaced});
}

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _manifestName = 'songs.json';
  static const _imagesDirName = 'song_images';

  Future<File> exportToZip(List<Song> songs) async {
    final imagesDir = await ImageService.instance.imagesDir();
    final archive = Archive();

    final exportSongs = <Map<String, dynamic>>[];
    for (final s in songs) {
      final map = s.toMap();
      map['imagePath'] = _basename(s.imagePath);
      map['thumbPath'] = _basename(s.thumbPath);
      exportSongs.add(map);
    }
    final manifest = jsonEncode({
      'version': 1,
      'songs': exportSongs,
    });
    final manifestBytes = utf8.encode(manifest);
    archive.addFile(
        ArchiveFile(_manifestName, manifestBytes.length, manifestBytes));

    if (imagesDir.existsSync()) {
      final referenced = <String>{};
      for (final s in songs) {
        final i = _basename(s.imagePath);
        final t = _basename(s.thumbPath);
        if (i != null) referenced.add(i);
        if (t != null) referenced.add(t);
      }
      for (final entity in imagesDir.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!referenced.contains(name)) continue;
        final bytes = await entity.readAsBytes();
        archive.addFile(
            ArchiveFile('$_imagesDirName/$name', bytes.length, bytes));
      }
    }

    final zipBytes = ZipEncoder().encode(archive);
    final tmp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final outFile = File('${tmp.path}/repertapp_backup_$stamp.zip');
    await outFile.writeAsBytes(zipBytes);
    return outFile;
  }

  Future<void> shareZip(File zip) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zip.path)],
        text: 'Repertorio de RepertApp',
      ),
    );
  }

  Future<ImportResult?> importFromPicker({
    required List<Song> existing,
    required SongStorage storage,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;

    final bytes = await File(path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? manifestFile;
    for (final f in archive) {
      if (f.name == _manifestName) {
        manifestFile = f;
        break;
      }
    }
    if (manifestFile == null) {
      throw const FormatException('El archivo no contiene songs.json');
    }

    final manifestJson =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
    final rawSongs = (manifestJson['songs'] as List).cast<Map>();

    final imagesDir = await ImageService.instance.imagesDir();
    for (final f in archive) {
      if (!f.isFile) continue;
      if (!f.name.startsWith('$_imagesDirName/')) continue;
      final name = f.name.substring('$_imagesDirName/'.length);
      if (name.isEmpty) continue;
      final out = File('${imagesDir.path}/$name');
      await out.writeAsBytes(f.content as List<int>);
    }

    final merged = <String, Song>{for (final s in existing) s.id: s};
    int replaced = 0;
    for (final raw in rawSongs) {
      final map = raw.cast<String, dynamic>();
      final imgName = map['imagePath'] as String?;
      final thmName = map['thumbPath'] as String?;
      map['imagePath'] =
          imgName != null ? '${imagesDir.path}/$imgName' : null;
      map['thumbPath'] =
          thmName != null ? '${imagesDir.path}/$thmName' : null;
      final song = Song.fromMap(map);
      if (merged.containsKey(song.id)) replaced++;
      merged[song.id] = song;
    }

    final list = merged.values.toList();
    await storage.saveAll(list);
    return ImportResult(
      imported: rawSongs.length,
      replaced: replaced,
    );
  }

  String? _basename(String? path) {
    if (path == null) return null;
    final idx = path.lastIndexOf(Platform.pathSeparator);
    if (idx < 0) {
      final alt = path.lastIndexOf('/');
      return alt < 0 ? path : path.substring(alt + 1);
    }
    return path.substring(idx + 1);
  }
}
