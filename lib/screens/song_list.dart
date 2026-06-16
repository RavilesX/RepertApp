import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';
import '../services/backup_service.dart';
import '../services/image_service.dart';
import '../services/sound_service.dart';
import '../storage/song_storage.dart';
import '../theme/app_colors.dart';
import '../utils/song_formatting.dart';
import '../widgets/music_background.dart';
import '../widgets/pressable_scale.dart';
import 'image_viewer.dart';
import 'song_form.dart';

enum ViewMode { card, compact, list }

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
  ViewMode _viewMode = ViewMode.card;

  static const _kViewModeKey = 'view_mode';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await _storage.loadAll();
    final modeIndex = prefs.getInt(_kViewModeKey) ?? 0;
    setState(() {
      _songs = songs;
      _loading = false;
      _viewMode =
          ViewMode.values[modeIndex.clamp(0, ViewMode.values.length - 1)];
    });
  }

  Future<void> _persist() async => _storage.saveAll(_songs);

  Future<void> _saveViewMode(ViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kViewModeKey, mode.index);
  }

  void _cycleViewMode() {
    final next =
        ViewMode.values[(_viewMode.index + 1) % ViewMode.values.length];
    setState(() => _viewMode = next);
    _saveViewMode(next);
  }

  List<Song> get _sorted =>
      SongFormatting.sorted(_songs, _sortBy, ascending: _asc);

  Future<void> _addSong() async {
    SoundService.instance.button();
    final song = await Navigator.of(
      context,
    ).push<Song>(MaterialPageRoute(builder: (_) => const SongForm()));
    if (song != null) {
      setState(() => _songs.add(song));
      await _persist();
    }
  }

  Future<void> _editSong(Song s) async {
    SoundService.instance.button();
    final updated = await Navigator.of(
      context,
    ).push<Song>(MaterialPageRoute(builder: (_) => SongForm(initial: s)));
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
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
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
      messenger.showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
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
      messenger.showSnackBar(SnackBar(content: Text('Error al importar: $e')));
    }
  }

  Future<void> _showBackupMenu(Offset globalPos) async {
    SoundService.instance.button();
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
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

  IconData _viewModeIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.card:
        return Icons.view_agenda_outlined;
      case ViewMode.compact:
        return Icons.view_day_outlined;
      case ViewMode.list:
        return Icons.view_list_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final bottomInset = MediaQuery.of(context).padding.bottom;
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
              // Cap content width so the single column doesn't stretch edge to
              // edge on tablets / landscape; centered on wide screens.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      _Header(
                        onSortTap: _openSortSheet,
                        onMenuTap: _showBackupMenu,
                        viewMode: _viewMode,
                        viewModeIcon: _viewModeIcon(_viewMode),
                        onViewModeTap: _cycleViewMode,
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
                                padding: EdgeInsets.only(
                                  bottom: 96 + bottomInset,
                                ),
                                itemCount: sorted.length,
                                separatorBuilder: (_, _) {
                                  switch (_viewMode) {
                                    case ViewMode.card:
                                      return const SizedBox(height: 18);
                                    case ViewMode.compact:
                                      return const SizedBox(height: 10);
                                    case ViewMode.list:
                                      return const SizedBox.shrink();
                                  }
                                },
                                itemBuilder: (ctx, i) {
                                  final s = sorted[i];
                                  final glow =
                                      AppColors.iconGlowPalette[i %
                                          AppColors.iconGlowPalette.length];
                                  switch (_viewMode) {
                                    case ViewMode.card:
                                      return _SongCard(
                                        title: SongFormatting.titleCase(
                                          s.title,
                                        ),
                                        artist: SongFormatting.titleCase(
                                          s.artist,
                                        ),
                                        keyLabel: s.keyLabel,
                                        capoLabel: SongFormatting.capoLabel(
                                          s.capo,
                                        ),
                                        hasImage: s.imagePath != null,
                                        glowColor: glow,
                                        onTap: () => _openImage(s),
                                        onLongPress: (pos) =>
                                            _showRowMenu(s, pos),
                                      );
                                    case ViewMode.compact:
                                      return _CompactSongCard(
                                        title: SongFormatting.titleCase(
                                          s.title,
                                        ),
                                        artist: SongFormatting.titleCase(
                                          s.artist,
                                        ),
                                        keyLabel: s.keyLabel,
                                        capoLabel: SongFormatting.capoLabel(
                                          s.capo,
                                        ),
                                        hasImage: s.imagePath != null,
                                        glowColor: glow,
                                        onTap: () => _openImage(s),
                                        onLongPress: (pos) =>
                                            _showRowMenu(s, pos),
                                      );
                                    case ViewMode.list:
                                      return _ListSongRow(
                                        title: SongFormatting.titleCase(
                                          s.title,
                                        ),
                                        artist: SongFormatting.titleCase(
                                          s.artist,
                                        ),
                                        keyLabel: s.keyLabel,
                                        capoLabel: SongFormatting.capoLabel(
                                          s.capo,
                                        ),
                                        hasImage: s.imagePath != null,
                                        glowColor: glow,
                                        onTap: () => _openImage(s),
                                        onLongPress: (pos) =>
                                            _showRowMenu(s, pos),
                                      );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final VoidCallback onSortTap;
  final ValueChanged<Offset> onMenuTap;
  final ViewMode viewMode;
  final IconData viewModeIcon;
  final VoidCallback onViewModeTap;

  const _Header({
    required this.onSortTap,
    required this.onMenuTap,
    required this.viewMode,
    required this.viewModeIcon,
    required this.onViewModeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'RepertApp',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // View-mode toggle button
        Semantics(
          button: true,
          label: 'Cambiar vista',
          child: GestureDetector(
            onTap: onViewModeTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder),
                gradient: const LinearGradient(
                  colors: [Color(0x1AFFFFFF), Color(0x10FFFFFF)],
                ),
              ),
              child: Icon(
                viewModeIcon,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Sort button
        Semantics(
          button: true,
          label: 'Ordenar',
          child: GestureDetector(
            onTap: onSortTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.cardBorder),
                gradient: const LinearGradient(
                  colors: [Color(0x1AFFFFFF), Color(0x10FFFFFF)],
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
        ),
        const SizedBox(width: 10),
        // Backup / more-vert button
        Builder(
          builder: (ctx) {
            return Semantics(
              button: true,
              label: 'Respaldo',
              child: GestureDetector(
                onTapDown: (d) => onMenuTap(d.globalPosition),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                    gradient: const LinearGradient(
                      colors: [Color(0x1AFFFFFF), Color(0x10FFFFFF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card view — original large card, unchanged
// ---------------------------------------------------------------------------

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

class _SongCardState extends State<_SongCard> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: PressableScale(
        onTap: widget.onTap,
        onLongPressAt: widget.onLongPress,
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
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x18FFFFFF), Color(0x10FFFFFF)],
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
                              color: widget.glowColor.withValues(alpha: 0.6),
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
                        border: Border.all(color: AppColors.cardBorder),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Compact card view
// ---------------------------------------------------------------------------

class _CompactSongCard extends StatefulWidget {
  final String title;
  final String artist;
  final String keyLabel;
  final String capoLabel;
  final bool hasImage;
  final Color glowColor;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;

  const _CompactSongCard({
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
  State<_CompactSongCard> createState() => _CompactSongCardState();
}

class _CompactSongCardState extends State<_CompactSongCard> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: PressableScale(
        onTap: widget.onTap,
        onLongPressAt: widget.onLongPress,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder, width: 1.0),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x16FFFFFF), Color(0x0DFFFFFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: -6,
                      ),
                      const BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Music note icon — 38×38, glow blur 18
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.glowColor.withValues(alpha: 0.55),
                              blurRadius: 18,
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          color: widget.glowColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.poppins(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.artist}  ·  ${widget.keyLabel}  ·  ${widget.capoLabel}',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Image indicator — same position and size as card view
                if (widget.hasImage)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List row view
// ---------------------------------------------------------------------------

class _ListSongRow extends StatefulWidget {
  final String title;
  final String artist;
  final String keyLabel;
  final String capoLabel;
  final bool hasImage;
  final Color glowColor;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;

  const _ListSongRow({
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
  State<_ListSongRow> createState() => _ListSongRowState();
}

class _ListSongRowState extends State<_ListSongRow> {
  @override
  Widget build(BuildContext context) {
    final subtitleText =
        '${widget.artist}  ·  ${widget.keyLabel}  ·  ${widget.capoLabel}';

    // Subtler press feedback for the dense list — scale down only to 0.98.
    return RepaintBoundary(
      child: PressableScale(
        onTap: widget.onTap,
        onLongPressAt: widget.onLongPress,
        pressedScale: 0.98,
        duration: const Duration(milliseconds: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Leading — 32×32 music note circle with colored glow
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.glowColor.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: -3,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.music_note_rounded,
                        color: widget.glowColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle stack
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitleText,
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Trailing — image indicator
                    if (widget.hasImage) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.image_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Built-in divider — no separate separator needed
            const Divider(height: 1, thickness: 1, color: Color(0x22FFFFFF)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared chip widget
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// FAB
// ---------------------------------------------------------------------------

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Agregar canción',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 74,
          height: 74,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.neonPurple, AppColors.neonBlue],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x884E61FF),
                blurRadius: 30,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort bottom sheet
// ---------------------------------------------------------------------------

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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          margin: const EdgeInsets.only(top: 80),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 32 + bottomPad),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: AppColors.cardBorder),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xEE181A2D), Color(0xEE1D1631)],
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
          fontSize: 17,
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
                fontSize: 16,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
