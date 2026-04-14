// ============================================================
// MESSAGES SCREEN — Chat estudiante ↔ tutor en tiempo real
// Usa Supabase Realtime para mensajes instantáneos
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:escuelamak/core/theme/app_theme.dart';

// Modelo de mensaje
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        receiverId: j['receiver_id'] as String,
        content: j['content'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        isRead: j['is_read'] as bool? ?? false,
      );
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _supabase = Supabase.instance.client;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  List<MessageModel> _messages = [];
  List<Map<String, dynamic>> _tutors = [];
  String? _selectedTutorId;
  String? _selectedTutorName;
  String? _myId;
  bool _loading = true;
  bool _sending = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Inicializa: obtiene el usuario actual y carga los tutores
  Future<void> _init() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Obtener ID del app_user correspondiente al auth user
    final res = await _supabase
        .from('app_users')
        .select('id')
        .eq('auth_user_id', user.id)
        .single();

    _myId = res['id'] as String?;
    if (_myId == null) return;

    await _loadTutors();
    setState(() => _loading = false);
  }

  // Carga los tutores disponibles para chatear
  Future<void> _loadTutors() async {
    final res = await _supabase
        .from('app_users')
        .select('id, name, email')
        .inFilter('role', ['tutor', 'teacher', 'admin']).order('name');

    setState(() {
      _tutors = List<Map<String, dynamic>>.from(res);
    });

    // Si solo hay un tutor, seleccionarlo automáticamente
    if (_tutors.length == 1) {
      _selectTutor(_tutors[0]['id'], _tutors[0]['name']);
    }
  }

  // Selecciona un tutor y carga la conversación
  void _selectTutor(String tutorId, String tutorName) {
    _channel?.unsubscribe();
    setState(() {
      _selectedTutorId = tutorId;
      _selectedTutorName = tutorName;
      _messages = [];
    });
    _loadMessages();
    _subscribeRealtime();
  }

  // Carga mensajes históricos
  Future<void> _loadMessages() async {
    if (_myId == null || _selectedTutorId == null) return;

    try {
      final res = await _supabase
          .from('student_messages')
          .select()
          .or('and(sender_id.eq.$_myId,receiver_id.eq.$_selectedTutorId),and(sender_id.eq.$_selectedTutorId,receiver_id.eq.$_myId)')
          .order('created_at');

      setState(() {
        _messages = (res as List).map((j) => MessageModel.fromJson(j)).toList();
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('MessagesScreen: Error cargando mensajes - $e');
      // Intentar query alternativa como fallback
      try {
        final res = await _supabase
            .from('student_messages')
            .select()
            .eq('sender_id', _myId!)
            .order('created_at');

        setState(() {
          _messages =
              (res as List).map((j) => MessageModel.fromJson(j)).toList();
        });
      } catch (_) {
        // Si falla el fallback, mostrar lista vacía
        setState(() => _messages = []);
      }
    }
  }

  // Suscripción en tiempo real para nuevos mensajes
  void _subscribeRealtime() {
    if (_myId == null || _selectedTutorId == null) return;

    _channel = _supabase
        .channel('messages_${_myId}_$_selectedTutorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'student_messages',
          callback: (payload) {
            final msg = MessageModel.fromJson(payload.newRecord);
            // Solo agregar si es de esta conversación
            if ((msg.senderId == _myId && msg.receiverId == _selectedTutorId) ||
                (msg.senderId == _selectedTutorId && msg.receiverId == _myId)) {
              setState(() => _messages.add(msg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  // Envía un mensaje
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _myId == null || _selectedTutorId == null) return;

    setState(() => _sending = true);
    _controller.clear();

    try {
      await _supabase.from('student_messages').insert({
        'sender_id': _myId,
        'receiver_id': _selectedTutorId,
        'content': text,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el mensaje')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(
        color: AppTheme.studentColor,
      ));
    }

    // Si no hay tutor seleccionado, mostrar lista de tutores
    if (_selectedTutorId == null) {
      return _buildTutorList();
    }

    return _buildChat();
  }

  // Lista de tutores para seleccionar
  Widget _buildTutorList() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              'Selecciona con quién chatear',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: _tutors.isEmpty
                ? const Center(
                    child: Text(
                      'No hay tutores disponibles',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tutors.length,
                    itemBuilder: (ctx, i) {
                      final t = _tutors[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.studentColor,
                            child: Text(
                              (t['name'] as String)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            t['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(t['email'] as String),
                          trailing: const Icon(Icons.chat_rounded,
                              color: AppTheme.studentColor),
                          onTap: () => _selectTutor(
                            t['id'] as String,
                            t['name'] as String,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Pantalla del chat
  Widget _buildChat() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.studentColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _selectedTutorId = null;
            _selectedTutorName = null;
            _messages = [];
            _channel?.unsubscribe();
          }),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: Text(
                (_selectedTutorName ?? 'T').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTutorName ?? 'Tutor',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'En línea',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Inicia la conversación',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = _messages[i];
                      final isMine = msg.senderId == _myId;
                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                      );
                    },
                  ),
          ),

          // Campo de texto para escribir
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón enviar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton.small(
                    onPressed: _sending ? null : _sendMessage,
                    backgroundColor: AppTheme.studentColor,
                    elevation: 0,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Burbuja de mensaje
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.studentColor : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white60 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
