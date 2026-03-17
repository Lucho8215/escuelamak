// ============================================================
// CLASSES SCREEN — Lista y detalle de clases
// ============================================================
// Carga las clases desde Supabase tabla 'classes'.
// Muestra imagen, título, estado, recursos (video/PDF).
// Al tocar una clase abre el detalle completo.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:escuelamak/core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// MODELO: ClassModel
// ─────────────────────────────────────────────────────────────
class ClassModel {
  final String id;
  final String titulo;
  final String? imageUrl;
  final String? resourceLink; // URL del video
  final String? resourceFileUrl; // URL del PDF
  final String? observation; // Descripción larga
  final String status; // "open" / "closed"
  final String? startDate;
  final String? endDate;
  final int maxStudents;
  final int enrollmentCount;

  const ClassModel({
    required this.id,
    required this.titulo,
    this.imageUrl,
    this.resourceLink,
    this.resourceFileUrl,
    this.observation,
    required this.status,
    this.startDate,
    this.endDate,
    required this.maxStudents,
    required this.enrollmentCount,
  });

  // Limpia strings vacíos — los trata como null
  static String? _clean(dynamic v) {
    final s = v as String?;
    return (s == null || s.trim().isEmpty) ? null : s.trim();
  }

  factory ClassModel.fromJson(Map<String, dynamic> j) => ClassModel(
        id: j['id'] as String,
        titulo: j['title'] as String? ?? j['name'] as String? ?? 'Sin título',
        imageUrl: _clean(j['image_url']),
        resourceLink: _clean(j['resource_link']),
        resourceFileUrl: _clean(j['resource_file_url']),
        observation: _clean(j['observation']),
        status: j['status'] as String? ?? 'open',
        startDate: _clean(j['start_date']),
        endDate: _clean(j['end_date']),
        maxStudents: j['max_students'] as int? ?? 20,
        enrollmentCount: j['enrollment_count'] as int? ?? 0,
      );

  bool get isOpen => status == 'open';
  bool get hasImage => imageUrl != null;
  bool get hasVideo => resourceLink != null;
  bool get hasPdf => resourceFileUrl != null;
  bool get hasCupos => enrollmentCount < maxStudents;
}

// ─────────────────────────────────────────────────────────────
// PANTALLA 1: ClassesScreen — Lista de clases
// ─────────────────────────────────────────────────────────────
class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _supabase = Supabase.instance.client;

  List<ClassModel> _clases = [];
  bool _loading = true;
  bool _hasError = false;
  String _search = '';
  String _filter = 'all'; // 'all', 'open', 'closed'

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  // ── CARGAR CLASES DESDE SUPABASE ──────────────────────────
  Future<void> _loadClasses() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final res = await _supabase
          .from('classes')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      setState(() {
        _clases = (res as List).map((j) => ClassModel.fromJson(j)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  // ── CLASES FILTRADAS ─────────────────────────────────────
  List<ClassModel> get _filtered {
    var list = _clases;
    if (_filter == 'open') list = list.where((c) => c.isOpen).toList();
    if (_filter == 'closed') list = list.where((c) => !c.isOpen).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((c) => c.titulo.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(children: [
        // ── BARRA DE BÚSQUEDA ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar clases...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => setState(() => _search = ''),
                    )
                  : null,
            ),
          ),
        ),

        // ── FILTROS ────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _Chip('Todas', 'all', _filter == 'all',
                () => setState(() => _filter = 'all'), AppTheme.seedColor),
            const SizedBox(width: 8),
            _Chip('Abiertas', 'open', _filter == 'open',
                () => setState(() => _filter = 'open'), Colors.green),
            const SizedBox(width: 8),
            _Chip('Cerradas', 'closed', _filter == 'closed',
                () => setState(() => _filter = 'closed'), Colors.red),
          ]),
        ),

        // ── CONTADOR ──────────────────────────────────────
        if (!_loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} clases',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),

        // ── CONTENIDO ─────────────────────────────────────
        Expanded(
          child: _hasError
              ? _Error(onRetry: _loadClasses)
              : _loading
                  ? _Skeleton()
                  : _filtered.isEmpty
                      ? _Empty(search: _search)
                      : RefreshIndicator(
                          onRefresh: _loadClasses,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => FadeSlideIn(
                              delay: Duration(milliseconds: i * 60),
                              child: _ClassCard(
                                clase: _filtered[i],
                                onTap: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ClassDetailScreen(clase: _filtered[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Chip de filtro
// ─────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _Chip(this.label, this.value, this.selected, this.onTap, this.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Tarjeta de clase
// ─────────────────────────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final ClassModel clase;
  final VoidCallback onTap;
  const _ClassCard({required this.clase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = clase.isOpen ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Imagen
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: clase.hasImage
                ? CachedNetworkImage(
                    imageUrl: clase.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _ImagePlaceholder(),
                    errorWidget: (_, __, ___) => _ImagePlaceholder(),
                  )
                : _ImagePlaceholder(),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + estado
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        clase.titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        clase.isOpen ? 'Abierta' : 'Cerrada',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Fecha
                if (clase.startDate != null)
                  Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _fmtDate(clase.startDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ]),
                const SizedBox(height: 8),

                // Recursos + cupos
                Row(children: [
                  if (clase.hasVideo) ...[
                    const Icon(Icons.play_circle_rounded,
                        size: 15, color: Colors.red),
                    const SizedBox(width: 3),
                    Text('Video',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        )),
                    const SizedBox(width: 10),
                  ],
                  if (clase.hasPdf) ...[
                    const Icon(Icons.picture_as_pdf_rounded,
                        size: 15, color: Colors.deepOrange),
                    const SizedBox(width: 3),
                    Text('PDF',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        )),
                  ],
                  const Spacer(),
                  Icon(Icons.people_rounded,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(
                    '${clase.enrollmentCount}/${clase.maxStudents}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('dd MMM yyyy', 'es').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        color: Colors.green.shade50,
        child: Center(
          child: Icon(Icons.school_outlined,
              size: 42, color: Colors.green.shade200),
        ),
      );
}

// Estados de la lista
class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            SkeletonBox(width: double.infinity, height: 150, radius: 0),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                SkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                SkeletonBox(width: 160, height: 12),
              ]),
            ),
          ]),
        ),
      );
}

class _Empty extends StatelessWidget {
  final String search;
  const _Empty({required this.search});

  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            search.isNotEmpty
                ? 'No hay clases con "$search"'
                : 'No hay clases disponibles',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ));
}

class _Error extends StatelessWidget {
  final VoidCallback onRetry;
  const _Error({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 72, color: Colors.red.shade200),
          const SizedBox(height: 14),
          const Text('No se pudieron cargar las clases',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Verifica tu conexión',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.studentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 44),
            ),
          ),
        ],
      ));
}

// ─────────────────────────────────────────────────────────────
// PANTALLA 2: ClassDetailScreen — Detalle de clase
// ─────────────────────────────────────────────────────────────
class ClassDetailScreen extends StatelessWidget {
  final ClassModel clase;
  const ClassDetailScreen({super.key, required this.clase});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(slivers: [
        // AppBar con imagen expandible
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          backgroundColor: AppTheme.studentColor,
          foregroundColor: Colors.white,
          title: Text(
            clase.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: clase.hasImage
                ? CachedNetworkImage(
                    imageUrl: clase.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.green.shade100),
                    errorWidget: (_, __, ___) => Container(
                        color: Colors.green.shade50,
                        child: Icon(Icons.school_outlined,
                            size: 60, color: Colors.green.shade200)),
                  )
                : Container(
                    color: Colors.green.shade50,
                    child: Icon(Icons.school_outlined,
                        size: 60, color: Colors.green.shade200),
                  ),
          ),
        ),

        // Contenido
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                FadeSlideIn(
                  child: Text(clase.titulo,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const SizedBox(height: 12),

                // Badges
                FadeSlideIn(
                  delay: const Duration(milliseconds: 80),
                  child: Wrap(spacing: 8, children: [
                    _Badge(
                      clase.isOpen ? '✓ Abierta' : '✗ Cerrada',
                      clase.isOpen ? Colors.green : Colors.red,
                    ),
                    _Badge(
                      '${clase.enrollmentCount}/${clase.maxStudents} estudiantes',
                      Colors.blue,
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Descripción
                if (clase.observation != null) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _Section(
                      titulo: 'Descripción',
                      icono: Icons.info_outline_rounded,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          clase.observation!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Video
                if (clase.hasVideo) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _Section(
                      titulo: 'Video de la clase',
                      icono: Icons.play_circle_rounded,
                      child: _RecursoTile(
                        icono: Icons.play_circle_rounded,
                        color: Colors.red.shade600,
                        bg: Colors.red.shade50,
                        titulo: 'Ver video',
                        sub: 'Toca para reproducir',
                        onTap: () => _showSnack(
                            context, 'Reproductor de video - Próximamente'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // PDF
                if (clase.hasPdf) ...[
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _Section(
                      titulo: 'Material de clase',
                      icono: Icons.picture_as_pdf_rounded,
                      child: _RecursoTile(
                        icono: Icons.picture_as_pdf_rounded,
                        color: Colors.deepOrange,
                        bg: Colors.orange.shade50,
                        titulo: 'Archivo PDF',
                        sub: 'Toca para descargar',
                        onTap: () => _showSnack(
                            context, 'Descarga de PDF - Próximamente'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Botón matricularse
                if (clase.isOpen && clase.hasCupos)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.school_rounded),
                      label: const Text('Matricularme'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.studentColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          _showSnack(context, 'Matrícula - Próximamente'),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _showSnack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// Widgets auxiliares del detalle
class _Badge extends StatelessWidget {
  final String texto;
  final Color color;
  const _Badge(this.texto, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
      );
}

class _Section extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Widget child;
  const _Section(
      {required this.titulo, required this.icono, required this.child});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icono, size: 18, color: AppTheme.studentColor),
            const SizedBox(width: 8),
            Text(titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                )),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      );
}

class _RecursoTile extends StatelessWidget {
  final IconData icono;
  final Color color;
  final Color bg;
  final String titulo;
  final String sub;
  final VoidCallback onTap;

  const _RecursoTile({
    required this.icono,
    required this.color,
    required this.bg,
    required this.titulo,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    )),
                Text(sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    )),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey.shade400),
          ]),
        ),
      );
}
