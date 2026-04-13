import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/song.dart';
import '../services/image_service.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../widgets/music_background.dart';

const List<String> kNotes = [
  'C', 'D', 'E', 'F', 'G', 'A', 'B', 'Desconocida'
];
const List<String> kAccidentals = ['Ninguno', '#', 'b'];
const List<String> kModes = ['Mayor', 'Menor'];
const List<String> kCapos = [
  'Sin capo', '1', '2', '3', '4', '5', '6'
];

class SongForm extends StatefulWidget {
  final Song? initial;
  const SongForm({super.key, this.initial});

  @override
  State<SongForm> createState() => _SongFormState();
}

class _SongFormState extends State<SongForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _artistCtrl;
  late TextEditingController _titleCtrl;

  late String _keyNote;
  late String _keyAccidental;
  late String _keyMode;
  late String _capo;
  String? _imagePath;
  String? _thumbPath;
  late String _songId;
  String? _previousImagePath;
  String? _previousThumbPath;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _artistCtrl = TextEditingController(text: s?.artist ?? '');
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _keyNote = s?.keyNote ?? kNotes.first;
    _keyAccidental = s?.keyAccidental ?? kAccidentals.first;
    _keyMode = s?.keyMode ?? kModes.first;
    _capo = s?.capo ?? kCapos.first;
    _imagePath = s?.imagePath;
    _thumbPath = s?.thumbPath;
    _previousImagePath = s?.imagePath;
    _previousThumbPath = s?.thumbPath;
    _songId = s?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _artistCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    SoundService.instance.ok();
    if (_previousImagePath != null && _previousImagePath != _imagePath) {
      await ImageService.instance.deleteIfExists(_previousImagePath);
    }
    if (_previousThumbPath != null && _previousThumbPath != _thumbPath) {
      await ImageService.instance.deleteIfExists(_previousThumbPath);
    }
    if (!mounted) return;
    final song = Song(
      id: _songId,
      artist: _artistCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      keyNote: _keyNote,
      keyAccidental: _keyAccidental,
      keyMode: _keyMode,
      capo: _capo,
      imagePath: _imagePath,
      thumbPath: _thumbPath,
    );
    Navigator.of(context).pop(song);
  }

  Future<void> _chooseImage() async {
    SoundService.instance.button();
    final source = await showModalBottomSheet<_PickSource>(
      context: context,
      backgroundColor: AppColors.bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.neonCyan),
              title: Text('Tomar foto',
                  style:
                      GoogleFonts.poppins(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, _PickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.neonPink),
              title: Text('Elegir de galería',
                  style:
                      GoogleFonts.poppins(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, _PickSource.gallery),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: Text('Quitar imagen',
                    style:
                        GoogleFonts.poppins(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, _PickSource.remove),
              ),
          ],
        ),
      ),
    );
    if (source == null) return;
    if (source == _PickSource.remove) {
      setState(() {
        _imagePath = null;
        _thumbPath = null;
      });
      return;
    }
    setState(() => _pickingImage = true);
    try {
      final picked = source == _PickSource.camera
          ? await ImageService.instance.takePhoto(_songId)
          : await ImageService.instance.pickFromGallery(_songId);
      if (!mounted) return;
      if (picked != null) {
        if (_imagePath != null && _imagePath != _previousImagePath) {
          await ImageService.instance.deleteIfExists(_imagePath);
        }
        if (_thumbPath != null && _thumbPath != _previousThumbPath) {
          await ImageService.instance.deleteIfExists(_thumbPath);
        }
        if (!mounted) return;
        setState(() {
          _imagePath = picked.imagePath;
          _thumbPath = picked.thumbPath;
        });
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
              color: AppColors.neonPurple, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
      );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T> onChanged,
    String Function(T)? labelBuilder,
    bool isDense = false,
    bool enabled = true,
  }) {
    String display(T v) => labelBuilder?.call(v) ?? '$v';
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isDense: isDense,
        isExpanded: true,
        dropdownColor: AppColors.bgMid,
        style: GoogleFonts.poppins(color: AppColors.textPrimary),
        decoration: _decoration(label),
        items: items
            .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    display(e),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
            .toList(),
        onChanged: enabled
            ? (v) {
                if (v != null) {
                  SoundService.instance.button();
                  onChanged(v);
                }
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          editing ? 'Modificar canción' : 'Nueva canción',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          const MusicBackground(),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  TextFormField(
                    controller: _artistCtrl,
                    maxLength: 50,
                    style:
                        GoogleFonts.poppins(color: AppColors.textPrimary),
                    decoration: _decoration('Artista'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleCtrl,
                    maxLength: 50,
                    style:
                        GoogleFonts.poppins(color: AppColors.textPrimary),
                    decoration: _decoration('Canción'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Requerido'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text('Tonalidad',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 10),
                  Builder(builder: (_) {
                    final unknown = _keyNote == 'Desconocida';
                    return Row(
                      children: [
                        Expanded(
                            child: _dropdown(
                                label: 'Nota',
                                value: _keyNote,
                                items: kNotes,
                                onChanged: (v) =>
                                    setState(() => _keyNote = v))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _dropdown(
                                label: '#/b',
                                value: _keyAccidental,
                                items: kAccidentals,
                                enabled: !unknown,
                                labelBuilder: (v) =>
                                    v == 'Ninguno' ? '—' : v,
                                onChanged: (v) => setState(
                                    () => _keyAccidental = v))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _dropdown(
                                label: 'Modo',
                                value: _keyMode,
                                items: kModes,
                                enabled: !unknown,
                                onChanged: (v) =>
                                    setState(() => _keyMode = v))),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  _dropdown(
                    label: 'Capotrasto',
                    value: _capo,
                    items: kCapos,
                    onChanged: (v) => setState(() => _capo = v),
                  ),
                  const SizedBox(height: 24),
                  _ImagePickerField(
                    previewPath: _thumbPath ?? _imagePath,
                    busy: _pickingImage,
                    onTap: _chooseImage,
                  ),
                  const SizedBox(height: 28),
                  _SubmitButton(
                    label: editing ? 'Guardar cambios' : 'Agregar',
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PickSource { camera, gallery, remove }

class _ImagePickerField extends StatelessWidget {
  final String? previewPath;
  final bool busy;
  final VoidCallback onTap;
  const _ImagePickerField({
    required this.previewPath,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = previewPath != null;
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: hasImage ? 180 : 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.cardFill,
          border: Border.all(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(File(previewPath!), fit: BoxFit.cover)
            else
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded,
                        color: AppColors.neonPurple),
                    const SizedBox(width: 10),
                    Text(
                      'Agregar imagen',
                      style: GoogleFonts.poppins(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasImage)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Cambiar',
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            if (busy)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SubmitButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonPurple,
              AppColors.neonBlue,
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x884E61FF),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
