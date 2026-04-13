import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PickedImage {
  final String imagePath;
  final String thumbPath;
  const PickedImage({required this.imagePath, required this.thumbPath});
}

class ImageService {
  ImageService._();
  static final ImageService instance = ImageService._();

  final ImagePicker _picker = ImagePicker();

  Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/song_images');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<Directory> imagesDir() => _imagesDir();

  Future<PickedImage?> pickFromGallery(String songId) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file == null) return null;
    return _compressAndSave(file.path, songId);
  }

  Future<PickedImage?> takePhoto(String songId) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (file == null) return null;
    return _compressAndSave(file.path, songId);
  }

  Future<PickedImage?> _compressAndSave(
      String sourcePath, String songId) async {
    final dir = await _imagesDir();
    final useWebp = !kIsWeb && Platform.isAndroid;
    final ext = useWebp ? 'webp' : 'jpg';
    final format = useWebp ? CompressFormat.webp : CompressFormat.jpeg;
    final stamp = DateTime.now().millisecondsSinceEpoch;

    final fullPath = '${dir.path}/${songId}_$stamp.$ext';
    final thumbPath = '${dir.path}/${songId}_${stamp}_thumb.$ext';

    final full = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      fullPath,
      format: format,
      quality: useWebp ? 80 : 85,
      minWidth: 2000,
      minHeight: 2000,
    );
    if (full == null) return null;

    final thumb = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      thumbPath,
      format: format,
      quality: useWebp ? 70 : 75,
      minWidth: 400,
      minHeight: 400,
    );
    final thumbResult = thumb?.path ?? full.path;

    return PickedImage(imagePath: full.path, thumbPath: thumbResult);
  }

  Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    final f = File(path);
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }
}
