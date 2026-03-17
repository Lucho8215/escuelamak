import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:escuelamak/core/theme/app_theme.dart';
import 'package:escuelamak/features/classes/presentation/classes_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  final String rol;
  final String nombre;
  const HomeScreen({super.key, required this.rol, required this.nombre});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Color get _color => AppTheme.colorForRole(widget.rol);
  String get _titulo {
    if (widget.rol == 'admin') return 'Panel Admin';
    if (widget.rol == 'teacher') return 'Mi Aula';
    return 'Mi Aprendizaje';
  }

  String get _inicial => widget.nombre.isNotEmpty
      ? widget.nombre.split(' ').first[0].toUpperCase()
      : 'U';
  String get _primerNombre =>
      widget.nombre.isNotEmpty ? widget.nombre.split(' ').first : 'Usuario';
  List<_Modulo> get _modulos {
    if (widget.rol == 'admin')
      return [
        _Modulo('Usuarios', Icons.people_rounded, Colors.blue),
        _Modulo('Cursos', Icons.book_rounded, Colors.green),
        _Modulo('Permisos', Icons.admin_panel_settings, Colors.red),
        _Modulo('Reportes', Icons.bar_chart_rounded, Colors.orange),
        _Modulo('Mensajes', Icons.chat_rounded, Colors.purple),
        _Modulo('Config', Icons.settings_rounded, Colors.grey)
      ];
    if (widget.rol == 'teacher')
      return [
        _Modulo('Clases', Icons.class_rounded, Colors.blue),
        _Modulo('Tareas', Icons.assignment_rounded, Colors.orange),
        _Modulo('Quizzes', Icons.quiz_rounded, Colors.purple),
        _Modulo('Calificar', Icons.grade_rounded, Colors.green),
        _Modulo('Mensajes', Icons.chat_rounded, Colors.teal),
        _Modulo('Horario', Icons.calendar_today_rounded, Colors.red)
      ];
    return [
      _Modulo('Clases', Icons.book_rounded, Colors.green),
      _Modulo('Tareas', Icons.assignment_rounded, Colors.orange),
      _Modulo('Quizzes', Icons.quiz_rounded, Colors.purple),
      _Modulo('Mensajes', Icons.chat_rounded, Colors.blue),
      _Modulo('Horario', Icons.calendar_today_rounded, Colors.red),
      _Modulo('Perfil', Icons.person_rounded, Colors.teal)
    ];
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Cerrar sesion'),
                content: const Text('Seguro que quieres salir?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 40)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Salir'))
                ]));
    if (ok == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: _color,
          foregroundColor: Colors.white,
          title: Text(_titulo,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
                icon: const Icon(Icons.logout_rounded), onPressed: _logout)
          ]),
      body: IndexedStack(index: _tab, children: [
        _buildInicio(),
        ClassesScreen(),
        _buildMensajes(),
        _buildPerfil()
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: _color,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _tab = i),
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Inicio'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded), label: 'Clases'),
          BottomNavigationBarItem(
              icon: _BadgeMensajes(color: _color), label: 'Mensajes'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildInicio() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FadeSlideIn(
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _color.withOpacity(0.2))),
                child: Row(children: [
                  CircleAvatar(
                      radius: 28,
                      backgroundColor: _color,
                      child: Text(_inicial,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Hola, $_primerNombre!',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _color)),
                        const SizedBox(height: 4),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: _color,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(widget.rol.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)))
                      ]))
                ]))),
        const SizedBox(height: 24),
        FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: Text('Modulos disponibles',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _modulos
                .asMap()
                .entries
                .map((e) => FadeSlideIn(
                    delay: Duration(milliseconds: 100 + e.key * 50),
                    child: GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('${e.value.label} - Proximamente'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating)),
                        child: Container(
                            decoration: BoxDecoration(
                                color: e.value.color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: e.value.color.withOpacity(0.2))),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(e.value.icon,
                                      color: e.value.color, size: 30),
                                  const SizedBox(height: 8),
                                  Text(e.value.label,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: e.value.color),
                                      textAlign: TextAlign.center)
                                ])))))
                .toList()),
      ]),
    );
  }

  Widget _buildMensajes() => _MessagesWidget();
  Widget _buildPerfil() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 32),
          FadeSlideIn(
              child: CircleAvatar(
                  radius: 52,
                  backgroundColor: _color,
                  child: Text(_inicial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w700)))),
          const SizedBox(height: 16),
          FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Text(widget.nombre,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700))),
          const SizedBox(height: 8),
          FadeSlideIn(
              delay: const Duration(milliseconds: 120),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                      color: _color, borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.rol.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)))),
          const SizedBox(height: 40),
          FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text('Cerrar sesion',
                          style: TextStyle(color: Colors.red, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: _logout)))
        ]));
  }
}

class _Modulo {
  final String label;
  final IconData icon;
  final Color color;
  const _Modulo(this.label, this.icon, this.color);
}

// ── MENSAJES INTEGRADO ──────────────────────────────────────
class _MessagesWidget extends StatefulWidget {
  @override
  State<_MessagesWidget> createState() => _MessagesWidgetState();
}

class _MessagesWidgetState extends State<_MessagesWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _convs = [];
  bool _loading = true;
  String get _myId => _supabase.auth.currentUser?.id ?? '';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _supabase
          .from('conversations')
          .select()
          .contains('participant_ids', [_myId]).order('last_message_at',
              ascending: false);
      final list = List<Map<String, dynamic>>.from(res);
      for (final c in list) {
        final ids = List<String>.from(c['participant_ids'] ?? []);
        final otherId = ids.firstWhere((id) => id != _myId, orElse: () => '');
        if (otherId.isEmpty) continue;
        try {
          final u = await _supabase
              .from('app_users')
              .select('name')
              .eq('auth_user_id', otherId)
              .maybeSingle();
          c['other_name'] = u?['name'] ?? 'Usuario';
          c['other_id'] = otherId;
        } catch (_) {
          c['other_name'] = 'Usuario';
          c['other_id'] = otherId;
        }
      }
      setState(() {
        _convs = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _newChat() async {
    final users = await _supabase
        .from('app_users')
        .select('auth_user_id, name, role')
        .neq('auth_user_id', _myId)
        .order('name');
    if (!mounted) return;
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Column(children: [
              const SizedBox(height: 16),
              const Text('Nueva conversacion',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Expanded(
                  child: ListView.builder(
                      itemCount: (users as List).length,
                      itemBuilder: (_, i) {
                        final u = users[i];
                        final name = u['name'] as String? ?? 'Usuario';
                        final rol = u['role'] as String? ?? 'student';
                        return ListTile(
                            leading: CircleAvatar(
                                backgroundColor: AppTheme.colorForRole(rol),
                                child: Text(name[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700))),
                            title: Text(name),
                            onTap: () async {
                              Navigator.pop(ctx);
                              final otherId = u['auth_user_id'] as String;
                              final ex = await _supabase
                                  .from('conversations')
                                  .select()
                                  .contains('participant_ids',
                                      [_myId, otherId]).maybeSingle();
                              String cid;
                              if (ex != null) {
                                cid = ex['id'] as String;
                              } else {
                                final n = await _supabase
                                    .from('conversations')
                                    .insert({
                                      'participant_ids': [_myId, otherId]
                                    })
                                    .select()
                                    .single();
                                cid = n['id'] as String;
                              }
                              if (mounted) {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => _ChatWidget(
                                            convId: cid,
                                            otherName: name,
                                            otherId: otherId)));
                                _load();
                              }
                            });
                      }))
            ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _convs.isEmpty
              ? Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No tienes mensajes aun',
                          style: TextStyle(color: Colors.grey))
                    ]))
              : ListView.separated(
                  itemCount: _convs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (ctx, i) {
                    final c = _convs[i];
                    final name = c['other_name'] as String? ?? 'Usuario';
                    return ListTile(
                        leading: CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.purple.shade100,
                            child: Text(name[0].toUpperCase(),
                                style: TextStyle(
                                    color: Colors.purple.shade800,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18))),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            c['last_message'] as String? ?? 'Sin mensajes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade500)),
                        onTap: () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                                builder: (_) => _ChatWidget(
                                    convId: c['id'] as String,
                                    otherName: name,
                                    otherId: c['other_id'] as String? ??
                                        ''))).then((_) => _load()));
                  }),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          onPressed: _newChat,
          child: const Icon(Icons.edit_rounded)),
    );
  }
}

class _ChatWidget extends StatefulWidget {
  final String convId, otherName, otherId;
  const _ChatWidget(
      {required this.convId, required this.otherName, required this.otherId});
  @override
  State<_ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<_ChatWidget> {
  final _supabase = Supabase.instance.client;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _stream;
  String get _myId => _supabase.auth.currentUser?.id ?? '';
  @override
  void initState() {
    super.initState();
    _stream = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.convId)
        .order('created_at', ascending: true)
        .map((d) => List<Map<String, dynamic>>.from(d));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    _ctrl.clear();
    try {
      await _supabase.from('messages').insert({
        'conversation_id': widget.convId,
        'sender_id': _myId,
        'receiver_id': widget.otherId,
        'contenido': t
      });
      _scrollToBottom();
    } catch (_) {
      _ctrl.text = t;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          titleSpacing: 0,
          title: Row(children: [
            CircleAvatar(
                radius: 18,
                backgroundColor: Colors.purple.shade300,
                child: Text(widget.otherName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14))),
            const SizedBox(width: 10),
            Text(widget.otherName,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
          ])),
      body: Column(children: [
        Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _stream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final data = snap.data ?? [];
                  if (data.isEmpty)
                    return Center(
                        child: Text('Inicia la conversacion',
                            style: TextStyle(color: Colors.grey.shade400)));
                  _scrollToBottom();
                  return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: data.length,
                      itemBuilder: (_, i) {
                        final m = data[i];
                        final esMio = m['sender_id'] == _myId;
                        final texto = m['contenido'] as String? ?? '';
                        final hora =
                            DateTime.tryParse(m['created_at'] as String? ?? '');
                        return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                                mainAxisAlignment: esMio
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                children: [
                                  Container(
                                      constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.of(ctx).size.width *
                                                  0.68),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                          color: esMio
                                              ? Colors.purple.shade600
                                              : const Color(0xFFDCF8C6),
                                          borderRadius: BorderRadius.only(
                                              topLeft:
                                                  const Radius.circular(18),
                                              topRight:
                                                  const Radius.circular(18),
                                              bottomLeft: Radius.circular(
                                                  esMio ? 18 : 4),
                                              bottomRight: Radius.circular(
                                                  esMio ? 4 : 18))),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(texto,
                                                style: TextStyle(
                                                    color: esMio
                                                        ? Colors.white
                                                        : const Color(0xFF1A1A1A),
                                                    fontSize: 14,
                                                    height: 1.4)),
                                            const SizedBox(height: 4),
                                            Text(
                                                hora != null
                                                    ? DateFormat('HH:mm')
                                                        .format(hora.toLocal())
                                                    : '',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: esMio
                                                        ? Colors.white60
                                                        : const Color(0xFF25A244)))
                                          ]))
                                ]));
                      });
                })),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: SafeArea(
                child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              GestureDetector(
                  onTap: _send,
                  child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: Colors.purple.shade700,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20)))
            ]))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Badge de mensajes no leídos
// Muestra un punto rojo con el número de mensajes no leídos
// Se actualiza en tiempo real con Supabase Stream
// ─────────────────────────────────────────────────────────────
class _BadgeMensajes extends StatefulWidget {
  final Color color;
  const _BadgeMensajes({required this.color});

  @override
  State<_BadgeMensajes> createState() => _BadgeMensajesState();
}

class _BadgeMensajesState extends State<_BadgeMensajes> {
  final _supabase = Supabase.instance.client;
  int _noLeidos = 0;
  String get _myId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _cargarNoLeidos();

    // Escuchar nuevos mensajes en tiempo real
    _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', _myId)
        .listen((data) {
          final noLeidos = data.where((m) => m['is_read'] == false).length;
          if (mounted) setState(() => _noLeidos = noLeidos);
        });
  }

  Future<void> _cargarNoLeidos() async {
    try {
      final res = await _supabase
          .from('messages')
          .select()
          .eq('receiver_id', _myId)
          .eq('is_read', false);
      if (mounted) setState(() => _noLeidos = (res as List).length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat_rounded),

        // Badge rojo — solo aparece si hay mensajes no leídos
        if (_noLeidos > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _noLeidos > 99 ? '99+' : '$_noLeidos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
