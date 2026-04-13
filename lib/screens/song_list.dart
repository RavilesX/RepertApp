import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/song.dart';
import '../services/backup_service.dart';
import '../services/image_service.dart';
import '../services/sound_service.dart';
import '../storage/song_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/music_background.dart';
import 'image_viewer.dart';
import 'song_form.dart';

enum SortColumn { artist, title, key }

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final SongStorage _storage = SongStorage();
  List<Song> _songs = [];
  SortColumn _sortBy = SortColumn.title;
  bool _asc = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final songs = await _storage.loadAll();
    setState(() {
      _songs = songs;
      _loading = false;
    });
  }

  Future<void> _persist() async => _storage.saveAll(_songs);

  String _sortKeyFor(Song s, SortColumn col) {
    switch (col) {
      case SortColumn.artist:
        return s.artist.toLowerCase();
      case SortColumn.title:
        return s.title.toLowerCase();
      case SortColumn.key:
        return s.keyLabel.toLowerCase();
    }
  }

  List<Song> get _sorted {
    final list = [..._songs];
    list.sort((a, b) {
      final cmp = _sortKeyFor(a, _sortBy).compareTo(_sortKeyFor(b, _sortBy));
      return _asc ? cmp : -cmp;
    });
    return list;
  }

  String _titleCase(String input) {
    return input.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  String _capoLabel(String capo) =>
      capo == 'Sin capo' ? 'Sin capo' : 'Capo $capo';

  Future<void> _addSong() async {
    SoundService.instance.button();
    final song = await Navigator.of(context).push<Song>(
      MaterialPageRoute(builder: (_) => const SongForm()),
    );
    if (song != null) {
      setState(() => _songs.add(song));
      await _persist();
    }
  }

  Future<void> _editSong(Song s) async {
    SoundService.instance.button();
    final updated = await Navigator.of(context).push<Song>(
      MaterialPageRoute(builder: (_) => SongForm(initial: s)),
    );
    if (updated != null) {
      setState(() {
        final idx = _songs.indexWhere((x) => x.id == updated.id);
        if (idx >= 0) _songs[idx] = updated;
      });
      await _persist();
    }
  }

  Future<void> _openImage(Song s) async {
    SoundService.instance.button();
    if (s.imagePath == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(imagePath: s.imagePath!),
      ),
    );
  }

  Future<void> _deleteSong(Song s) async {
    SoundService.instance.button();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgMid,
        title: const Text('Eliminar canción'),
        content: Text('¿Eliminar "${s.title}" de ${s.artist}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      await ImageService.instance.deleteIfExists(s.imagePath);
      await ImageService.instance.deleteIfExists(s.thumbPath);
      setState(() => _songs.removeWhere((x) => x.id == s.id));
      await _persist();
    }
  }

  Future<void> _exportBackup() async {
    SoundService.instance.button();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final zip = await BackupService.instance.exportToZip(_songs);
      await BackupService.instance.shareZip(zip);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  Future<void> _importBackup() async {
    SoundService.instance.button();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await BackupService.instance.importFromPicker(
        existing: _songs,
        storage: _storage,
      );
      if (result == null) return;
      await _load();
      SoundService.instance.ok();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Importadas ${result.imported} canciones'
            '${result.replaced > 0 ? " (${result.replaced} reemplazadas)" : ""}.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al importar: $e')),
      );
    }
  }

  Future<void> _showBackupMenu(Offset globalPos) async {
    SoundService.instance.button();
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      color: AppColors.bgMid,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        overlay.size.width - globalPos.dx,
        overlay.size.height - globalPos.dy,
      ),
      items: const [
        PopupMenuItem(value: 'export', child: Text('Exportar repertorio')),
        PopupMenuItem(value: 'import', child: Text('Importar repertorio')),
      ],
    );
    if (selected == 'export') await _exportBackup();
    if (selected == 'import') await _importBackup();
  }

  Future<void> _showRowMenu(Song s, Offset globalPos) async {
    SoundService.instance.button();
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      color: AppColors.bgMid,
      position: RelativeRect.fromLTRB(
        globalPos.dx,
        globalPos.dy,
        overlay.size.width - globalPos.dx,
        overlay.size.height - globalPos.dy,
      ),
      items: const [
        PopupMenuItem(value: 'edit', child: Text('Modificar')),
        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
      ],
    );
    if (selected == 'edit') await _editSong(s);
    if (selected == 'delete') await _deleteSong(s);
  }

  Future<void> _openSortSheet() async {
    SoundService.instance.button();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SortBottomSheet(
        initialSortBy: _sortBy,
        initialAsc: _asc,
        onSortBy: (v) {
          SoundService.instance.button();
          setState(() => _sortBy = v);
        },
        onAsc: (v) {
          SoundService.instance.button();
          setState(() => _asc = v);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.black,
      floatingActionButton: _AddButton(onTap: _addSong),
      body: Stack(
        children: [
          const MusicBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                children: [
                  _Header(
                    onSortTap: _openSortSheet,
                    onMenuTap: _showBackupMenu,
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : sorted.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay canciones.\nToca + para agregar una.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.only(bottom: 96),
                                itemCount: sorted.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 18),
                                itemBuilder: (context, index) {
                                  final s = sorted[index];
                                  return _SongCard(
                                    title: _titleCase(s.title),
                                    artist: _titleCase(s.artist),
                                    keyLabel: s.keyLabel,
                                    capoLabel: _capoLabel(s.capo),
                                    hasImage: s.imagePath != null,
                                    glowColor: AppColors.iconGlowPalette[
                                        index % AppColors.iconGlowPalette.length],
                                    onTap: () => _openImage(s),
                                    onLongPress: (globalPos) =>
                                        _showRowMenu(s, globalPos),
                                  );
                                },
                              ),
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

class _Header extends StatelessWidget {
  final VoidCallback onSortTap;
  final ValueChanged<Offset> onMenuTap;
  const _Header({required this.onSortTap, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'RepertApp',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onSortTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder),
              gradient: const LinearGradient(
                colors: [
                  Color(0x1AFFFFFF),
                  Color(0x10FFFFFF),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x553E7BFF),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Text(
              'A–Z',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Builder(builder: (ctx) {
          return GestureDetector(
            onTapDown: (d) => onMenuTap(d.globalPosition),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
                gradient: const LinearGradient(
                  colors: [
                    Color(0x1AFFFFFF),
                    Color(0x10FFFFFF),
                  ],
                ),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SongCard extends StatefulWidget {
  final String title;
  final String artist;
  final String keyLabel;
  final String capoLabel;
  final bool hasImage;
  final Color glowColor;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;

  const _SongCard({
    required this.title,
    required this.artist,
    required this.keyLabel,
    required this.capoLabel,
    required this.hasImage,
    required this.glowColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 0.04,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(seconds: 1),
          ),
          (instance) {
            instance.onLongPressStart =
                (details) => widget.onLongPress(details.globalPosition);
          },
        ),
      },
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.scale(
            scale: 1 - _ctrl.value,
            child: child,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Stack(
                children: [
                  Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: AppColors.cardBorder, width: 1.2),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x18FFFFFF),
                      Color(0x10FFFFFF),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glowColor.withValues(alpha: 0.15),
                      blurRadius: 24,
                      spreadRadius: -8,
                    ),
                    const BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                widget.glowColor.withValues(alpha: 0.6),
                            blurRadius: 28,
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: widget.glowColor,
                        size: 42,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.artist,
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _Chip(
                                label: widget.keyLabel,
                                glowColor: widget.glowColor,
                              ),
                              _Chip(
                                label: widget.capoLabel,
                                glowColor: AppColors.neonPink,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
                  if (widget.hasImage)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                          border: Border.all(
                              color: AppColors.cardBorder),
                        ),
                        child: const Icon(
                          Icons.image_rounded,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color glowColor;

  const _Chip({required this.label, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: glowColor.withValues(alpha: 0.5)),
        color: glowColor.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonPurple,
              AppColors.neonBlue,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x884E61FF),
              blurRadius: 30,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

class _SortBottomSheet extends StatefulWidget {
  final SortColumn initialSortBy;
  final bool initialAsc;
  final ValueChanged<SortColumn> onSortBy;
  final ValueChanged<bool> onAsc;

  const _SortBottomSheet({
    required this.initialSortBy,
    required this.initialAsc,
    required this.onSortBy,
    required this.onAsc,
  });

  @override
  State<_SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<_SortBottomSheet> {
  late SortColumn _sortBy = widget.initialSortBy;
  late bool _asc = widget.initialAsc;

  void _setSort(SortColumn v) {
    setState(() => _sortBy = v);
    widget.onSortBy(v);
  }

  void _setAsc(bool v) {
    setState(() => _asc = v);
    widget.onAsc(v);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          margin: const EdgeInsets.only(top: 80),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: AppColors.cardBorder),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xEE181A2D),
                Color(0xEE1D1631),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 28,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 22),
              _sectionTitle('Ordenar por:'),
              const SizedBox(height: 8),
              _radioTile<SortColumn>(
                label: 'Artista',
                value: SortColumn.artist,
                groupValue: _sortBy,
                onChanged: _setSort,
              ),
              _radioTile<SortColumn>(
                label: 'Canción',
                value: SortColumn.title,
                groupValue: _sortBy,
                onChanged: _setSort,
              ),
              _radioTile<SortColumn>(
                label: 'Tonalidad',
                value: SortColumn.key,
                groupValue: _sortBy,
                onChanged: _setSort,
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 12),
              _sectionTitle('Orden:'),
              const SizedBox(height: 8),
              _radioTile<bool>(
                label: 'Ascendente',
                value: true,
                groupValue: _asc,
                onChanged: _setAsc,
              ),
              _radioTile<bool>(
                label: 'Descendente',
                value: false,
                groupValue: _asc,
                onChanged: _setAsc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _radioTile<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T> onChanged,
  }) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              activeColor: AppColors.neonPurple,
              // ignore: deprecated_member_use
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 18,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
