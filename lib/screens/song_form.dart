import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/song.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';
import '../widgets/music_background.dart';

const List<String> kNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
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
  }

  @override
  void dispose() {
    _artistCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    SoundService.instance.ok();
    final song = Song(
      id: widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      artist: _artistCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      keyNote: _keyNote,
      keyAccidental: _keyAccidental,
      keyMode: _keyMode,
      capo: _capo,
    );
    Navigator.of(context).pop(song);
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
  }) {
    String display(T v) => labelBuilder?.call(v) ?? '$v';
    return DropdownButtonFormField<T>(
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
      onChanged: (v) {
        if (v != null) {
          SoundService.instance.button();
          onChanged(v);
        }
      },
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
                  Row(
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
                              labelBuilder: (v) =>
                                  v == 'Ninguno' ? '—' : v,
                              onChanged: (v) =>
                                  setState(() => _keyAccidental = v))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _dropdown(
                              label: 'Modo',
                              value: _keyMode,
                              items: kModes,
                              onChanged: (v) =>
                                  setState(() => _keyMode = v))),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _dropdown(
                    label: 'Capotrasto',
                    value: _capo,
                    items: kCapos,
                    onChanged: (v) => setState(() => _capo = v),
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
